AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

function ENT:ConfigureLuaSeat(Pod, Player)
	XCF.ConfigureLuaSeat(self, Pod, Player)
	self.XCF_LiveData.LuaSeat = Pod

	self.Pod = Pod

	hook.Add("PlayerEnteredVehicle", self, function(_, Ply, Veh)
		if Veh == Pod then Ply:SetNoDraw(true) end
	end)

	-- Make the player visible and vulnerable when they leave the seat
	hook.Add("PlayerLeaveVehicle", self, function(_, Ply, Veh)
		if Veh == Pod then Ply:SetNoDraw(false) end
	end)

	-- Allow players to enter the seat externally by pressing walk + use on a prop on the same contraption as the baseplate
	hook.Add("PlayerUse", self, function(self, Ply, Ent)
		if not Ply:KeyDown(IN_WALK) then return end
		if IsValid(Ent) then
			local Contraption = Ent:GetContraption()
			local MyContraption = self:GetContraption()
			if Contraption and MyContraption and Contraption == MyContraption and IsValid(Pod) and Pod:GetDriver() ~= Ply and not self.XCF_LiveData.DisableAltE then
				Ply:EnterVehicle(Pod)
			end
		end
	end)
end

function ENT:XCF_PostUpdateEntityData()
	print("XCF_PostUpdateEntityData")
	self:SetSize(self.XCF_LiveData.Size)
end

function ENT:XCF_PreSpawn()
	print("XCF_PreSpawn")
	self:SetScaledModel("models/holograms/cube.mdl")
	self:SetMaterial("hunter/myplastic")
	self:SetUseType(SIMPLE_USE)
end

function ENT:XCF_PostSpawn(Owner, _, _, _, _)
	print("XCF_PostSpawn", Owner)

	-- Add seat if it was never created
	if not self.XCF_LiveData.LuaSeat then
		local Pod = XCF.GenerateLuaSeat(self, Owner, self:GetPos(), self:GetAngles(), self:GetModel(), true)
		self:ConfigureLuaSeat(Pod, Owner)
	end
end

function ENT:PostEntityPaste(Owner, _, _, _)
	print("PostEntityPaste", Owner)
	-- If we had a seat before duplication, find it and reconfigure it.
	local Pod = self.XCF_LiveData.LuaSeat
	if not IsValid(Pod) then -- Repair if the seat wasn't duplicated correctly
		Pod = XCF.GenerateLuaSeat(self, Owner, self:GetPos(), self:GetAngles(), self:GetModel(), true)
	end
	self.Pod = Pod
	self:ConfigureLuaSeat(Pod, Owner)
end

function ENT:XCF_PostMenuSpawn()
	print("XCF_PostMenuSpawn")
	self:SetAngles(Angle(0, 90, 0))
end

function ENT:UpdateOverlay()
	self:SetOverlayText("test")
end

function ENT:Think()
	self:UpdateOverlay()
end

XCF.AutoRegister(ENT, "xcf_baseplate", "xcf_baseplate")