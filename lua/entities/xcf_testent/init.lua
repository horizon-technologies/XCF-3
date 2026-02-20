-- init.lua --

-- Send shared and cl_init to the client
AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua") -- This runs shared.lua on the server

-- This code runs whenever the entity is created.
function ENT:Initialize()
	self:SetScaledModel("models/props_c17/oildrum001_explosive.mdl")

	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)

	WireLib.CreateInputs(self, {Scale = "Number"})
	WireLib.CreateOutputs(self, {Scale = "Number"})

	self:UpdateOverlay()
end

function ENT:UpdateOverlay()
	self:SetOverlayText("test")
end

function ENT:Think()
	self:UpdateOverlay()
end