DEFINE_BASECLASS("base_wire_entity") -- Use wiremod's base entity for easy wiremod integration

AddCSLuaFile("shared.lua") -- Send shared and cl_init to the client
AddCSLuaFile("cl_init.lua") -- Send shared and cl_init to the client

include("shared.lua") -- Includes and runs shared file on the server

function ENT:Initialize()
	self:SetModel("models/props_c17/oildrum001_explosive.mdl")

	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)

    WireLib.CreateInputs(self, {Scale = "Number"})
    WireLib.CreateOutputs(self, {Scale = "Number"})

    print("test")
end