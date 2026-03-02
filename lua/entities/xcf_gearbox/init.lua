AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

function ENT:XCF_PreSpawn()
	self:SetScaledModel("models/engines/transaxial_s.mdl")
	self:SetUseType(SIMPLE_USE)
end

XCF.AutoRegister(ENT)