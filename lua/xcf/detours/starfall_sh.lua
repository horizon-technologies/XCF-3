local IsXCFContraption = XCF.IsXCFContraption
hook.Add("XCF" .. "Detours_Starfall_PrePatchInstance", "StarfallChecks", function(Instance)
    if CLIENT then return end -- Only detour sv functions

    local _, eunwrap     = Instance.Types.Entity.Wrap, Instance.Types.Entity.Unwrap

    local function DetourMethod(Type, _, Method, _, Cond, Override)
        if Cond == false then return end
        local Func = Type.Methods[Method]
        Type.Methods[Method] = Override or function(self, ...)
            if IsXCFContraption(eunwrap(self)) then return end
            return Func(self, ...)
        end
        return Func
    end

    local CHECK_ENT = function(E, P) return DetectionPP.CantDetect(eunwrap(E), P) end
    local CHECK_PHY = function(E, P)
        local Phy = punwrap(E)
        if not IsValid(Phy) then return false end
        return DetectionPP.CantDetect(Phy:GetEntity(), P)
    end

    local DEFAULT_NIL           = function() return nil end

    local function DetourEntMethodReturningNil(Method, Cond) DetourMethod(Instance.Types.Entity, CHECK_ENT, Method, DEFAULT_NIL, Cond) end
    local function DetourPhysObjMethodReturningNil(Method, Cond) DetourMethod(Instance.Types.PhysObj, CHECK_PHY, Method, DEFAULT_NIL, Cond) end

    DetourEntMethodReturningNil("addAngleVelocity")
    DetourPhysObjMethodReturningNil("addAngleVelocity")

    DetourEntMethodReturningNil("addVelocity")
    DetourPhysObjMethodReturningNil("addVelocity")

    DetourEntMethodReturningNil("applyAngForce")
    DetourPhysObjMethodReturningNil("applyAngForce")

    DetourEntMethodReturningNil("setAngleVelocity")
    DetourPhysObjMethodReturningNil("setAngleVelocity")

    DetourEntMethodReturningNil("setAngles")
    DetourPhysObjMethodReturningNil("setAngles")

    DetourEntMethodReturningNil("setMass")
    DetourPhysObjMethodReturningNil("setMass")

    DetourEntMethodReturningNil("setMaterial")
    DetourPhysObjMethodReturningNil("setMaterial")

    DetourEntMethodReturningNil("setPos")
    DetourPhysObjMethodReturningNil("setPos")

    DetourEntMethodReturningNil("setVelocity")
    DetourPhysObjMethodReturningNil("setVelocity")

    DetourEntMethodReturningNil("applyForceCenter")
    DetourPhysObjMethodReturningNil("applyForceCenter")

    DetourEntMethodReturningNil("applyForceOffset")
    DetourPhysObjMethodReturningNil("applyForceOffset")

    DetourEntMethodReturningNil("applyTorque")
    DetourPhysObjMethodReturningNil("applyTorque")

    DetourEntMethodReturningNil("manipulateBoneAngles")
    DetourEntMethodReturningNil("manipulateBonePosition")
    DetourEntMethodReturningNil("setColor")
    DetourEntMethodReturningNil("setColor4Part")
    DetourEntMethodReturningNil("setLocalAngles")
    DetourEntMethodReturningNil("setLocalPos")
    DetourEntMethodReturningNil("setPhysMaterial")
    DetourEntMethodReturningNil("setSubMaterial")
    DetourEntMethodReturningNil("setFrozen")
    DetourEntMethodReturningNil("setParent")
    DetourEntMethodReturningNil("setFriction")
    DetourEntMethodReturningNil("setSolid")
    DetourEntMethodReturningNil("setCollisionGroup")
    DetourEntMethodReturningNil("setNoDraw")

    DetourPhysObjMethodReturningNil("calculateVelocityOffset")
    DetourPhysObjMethodReturningNil("setAngleDragCoefficient")
    DetourPhysObjMethodReturningNil("setBuoyancyRatio")
end)