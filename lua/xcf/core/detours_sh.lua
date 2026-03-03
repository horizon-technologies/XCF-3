local ParentTableName = "XCF"
local ParentTable = _G[ParentTableName]

ParentTable.Detours = ParentTable.Detours or {}

local Detours = ParentTable.Detours
Detours.Storage = Detours.Storage or {}

local Storage = Detours.Storage

-- Set Hook to nil to restore existing behavior
function Detours.New(Expression, Hook)
    local Getter = CompileString("return function() return " .. Expression .. " end")()
    local Setter = CompileString("return function(value) " .. Expression .. " = value end")()

    if not Getter or not Setter then ErrorNoHaltWithStack("Bad expression '" .. Expression .. "'") return end

    if not Storage[Expression] then
        local ok, f = pcall(Getter)
        if not ok then ErrorNoHaltWithStack("Bad expression '" .. Expression .. "': " .. tostring(f)) return end
        Storage[Expression] = f
    end

    Setter(Hook or Storage[Expression])
    return Storage[Expression]
end


function Detours.E2HelperSignatureToBaseSignature(helper_sig)
    return helper_sig
end


function Detours.SENT(ClassName, MethodName, Hook)
    return Detours.New("scripted_ents.GetStored(\"" .. ClassName .. "\").t." .. MethodName, Hook)
end

function Detours.Hook(HookName, UniqueName, Hook)
    return Detours.New("hook.GetTable[\"" .. HookName .. "\"][\"" .. UniqueName .. "\"]", Hook)
end
function Detours.Metatable(MetatableName, FunctionName, Hook)
    return Detours.New("FindMetaTable(\"" .. MetatableName .. "\")[\"" .. FunctionName .. "\"]", Hook)
end
function Detours.WireGate(GateName, Hook)
    return Detours.New("GateActions[\"" .. GateName .. "\"].output", Hook)
end

local E2Detours = {}
function Detours.Expression2(E2HelperSig, Hook)
    local Signature = "(wire_expression2_funcs[\"" .. E2HelperSig .. "\"] or {})[3]"
    local Obj = E2Detours[Signature]
    if not Obj then
        Obj = {
            -- Try getting the original now
            Hook = Hook
        }
        E2Detours[Signature] = Obj
    else
        Obj.Hook = Hook
    end

    return function(...)
        return Obj.Original(...)
    end
end

-- Starfall is a bit more annoying about this...
local SFDetours = {}
function Detours.Starfall(Expression, Hook)
    local Getter = CompileString("return function(instance) return " .. Expression .. " end")()
    local Setter = CompileString("return function(instance, value) " .. Expression .. " = value end")()
    local Obj = {
        Getter = Getter,
        Setter = Setter,
        Hook = Hook,
        -- Weakly keyed. Don't want instances staying alive,
        -- we just need to track instance -> functions
        Original = setmetatable({}, {__mode = "k"})
    }
    SFDetours[Expression] = Obj
    local Original = Obj.Original
    return function(Instance, ...)
        return Original[Instance](...)
    end
end

local function PatchExpression2Funcs()
    for Sig, Obj in pairs(E2Detours) do
        Storage[Sig] = nil
        Obj.Original = Detours.New(Sig, Obj.Hook)
    end
end

hook.Add("Expression2_PostLoadExtensions", ParentTableName .. "_Detours_AfterExpression2Loaded", PatchExpression2Funcs)

timer.Simple(1, function()
    if SF then
        local function PatchInstance(Instance)
            hook.Run(ParentTableName .. "Detours_Starfall_PrePatchInstance", Instance)
            for _, HookMethods in pairs(SFDetours) do
                local Getter, Setter, Hook = HookMethods.Getter, HookMethods.Setter, HookMethods.Hook
                HookMethods.Original[Instance] = Getter(Instance)
                local function NewHook(...)
                    Hook(Instance, ...)
                end
                Setter(Instance, NewHook)
            end
        end

        local OriginalCompile OriginalCompile = Detours.New("SF.Instance.Compile", function(...)
            local OK, Instance = OriginalCompile(...)
            if OK then
                PatchInstance(Instance)
            end
            return OK, Instance
        end)

        for Instance, _ in pairs(SF.allInstances) do
            PatchInstance(Instance)
        end
    end
end)

-- Some examples of this library
--[[

-- Basic Detour
    local Curtime_Orig Curtime_Orig = Detours.New("CurTime", function()
        return Curtime_Orig()
    end)

-- Expression 2 Function Detour
    local E2ApplyForce_Orig E2ApplyForce_Orig = Detours.Expression2("e:applyForce(v)", function(scope, args, ...)
        local ent = args[1]
        local contraption = ent:GetContraption()
        print(contraption, contraption.XCF_Baseplate)
        if contraption and contraption.XCF_Baseplate then
            return ent:CPPIGetOwner():Kill()
        end

        return E2ApplyForce_Orig(scope, args, ...)
    end)
]]

-----------------------------------------------------------
--- Not part of the library
function XCF.IsXCFContraption(ent)
    if not IsValid(ent) then return false end
    if ent.IsXCFEntity then return true end
    local contraption = ent:GetContraption()
    if contraption and contraption.XCF_Baseplate then return true end
    return false
end
