local Detours = XCF.Detours

local function IsXCFEntity(ent)
    return IsValid(ent) and ent.IsXCFEntity
end

timer.Simple(0.2, function()
    local function DetourGate(GateName)
        if not GateActions[GateName] then return end
        local Func Func = Detours.WireGate(GateName, function(Gate, Ent, ...)
            if IsXCFEntity(Ent) then return end
            return Func(Gate, Ent, ...)
        end)
    end

    DetourGate("entity_applyaf")
    DetourGate("entity_applytorq")
    DetourGate("entity_applyof")
    DetourGate("entity_applyf")
    DetourGate("entity_setmass")
    DetourGate("entity_setcol")
end)
