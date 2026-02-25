-- init.lua --

-- Send shared and cl_init to the client
AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua") -- This runs shared.lua on the server

-- This code runs whenever the entity is created.
function ENT:Initialize()
	self:SetScaledModel("models/hunter/blocks/cube075x075x075.mdl")

	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)

	WireLib.CreateInputs(self, {Roll = "Number"})
	WireLib.CreateOutputs(self, {State = "Number", Col = "Vector"})

	self:UpdateOverlay()
end

function ENT:XCF_PreSpawn()

end

function ENT:XCF_PostSpawn(Player, Pos, Angle, Data)
	-- print("XCF_PostSpawn", Player, Pos, Angle, Data)
end

function ENT:XCF_PostMenuSpawn()

end

function ENT:UpdateOverlay()
	self:SetOverlayText("test")
end

function ENT:Think()
	self:UpdateOverlay()
end

XCF.AutoRegister(ENT, "xcf_testent", "Fatecube")