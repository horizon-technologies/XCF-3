DEFINE_BASECLASS("base_wire_entity")

include("shared.lua")

-- function ENT:Initialize()
-- 	BaseClass.Initialize(self)

-- 	self.Initialized = true
-- end

-- function ENT:Update() end

-- function ENT:CalcAbsolutePosition() -- Faking sync
-- 	local PhysObj  = self:GetPhysicsObject()
-- 	local Position = self:GetPos()
-- 	local Angles   = self:GetAngles()

-- 	if IsValid(PhysObj) then
-- 		PhysObj:Sleep()
-- 	end

-- 	return Position, Angles
-- end

-- function ENT:Think(...)
-- 	if not self.Initialized then
-- 		self:Initialize()
-- 	end

-- 	return BaseClass.Think(self, ...)
-- end