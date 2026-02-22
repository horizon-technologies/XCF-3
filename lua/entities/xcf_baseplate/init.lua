AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

function ENT:Initialize()
	self:SetScaledModel("models/hunter/blocks/cube075x075x075.mdl")

	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)

	WireLib.CreateInputs(self, {Roll = "Number"})
	WireLib.CreateOutputs(self, {State = "Number", Col = "Vector"})

	self:UpdateOverlay()
end

function ENT:UpdateOverlay()
	self:SetOverlayText("test")
end

function ENT:Think()
	self:UpdateOverlay()
end