DEFINE_BASECLASS("base_wire_entity") -- Use wiremod's base entity for easy wiremod integration

AddCSLuaFile("shared.lua") -- Send shared and cl_init to the client
AddCSLuaFile("cl_init.lua") -- Send shared and cl_init to the client

include("shared.lua") -- Includes and runs shared file on the server

util.AddNetworkString "XCF_Scalable_Entity"

local ModelData = XCF.ModelData

-- Transmits a scalable entity's scale and model info to a specific player or all players
local function TransmitScaleInfo(Entity, To)
	local Data  = Entity.XCFScaleData
	local Scale = Data.Scale

	net.Start("XCF_Scalable_Entity")
	net.WriteUInt(Entity:EntIndex(), MAX_EDICT_BITS)
	net.WriteFloat(Scale[1])
	net.WriteFloat(Scale[2])
	net.WriteFloat(Scale[3])
	net.WriteString(Data.ModelPath)

	if To then net.Send(To) else net.Broadcast() end
end

function ENT:TransmitScaleInfo(To)
	TransmitScaleInfo(self, To)
end

net.Receive("XCF_Scalable_Entity", function(_, Player)
	local Entity = ents.GetByIndex(net.ReadUInt(MAX_EDICT_BITS)) -- Equivalent to Entity()

	if IsValid(Entity) and Entity.XCFIsScalable then
		TransmitScaleInfo(Entity, Player)
	end
end)

do -- Size and scale setter methods
	local function ResizeEntity(Entity, Scale)
		local Data = Entity.XCFScaleData
		Data.Size = Data.OriginalSize * Scale
		Data.Scale = Scale

		local Mesh = ModelData.GetModelMesh(Data.ModelPath, Scale)

		Entity:PhysicsInitMultiConvex(Mesh)
		Entity:SetMoveType(MOVETYPE_VPHYSICS)
		Entity:SetSolid(SOLID_VPHYSICS)
		Entity:EnableCustomCollisions(true)
		Entity:DrawShadow(false)

		local PhysObj = Entity:GetPhysicsObject()

		TransmitScaleInfo(Entity)

		if IsValid(PhysObj) then
			PhysObj:EnableMotion(false)
		end

		return PhysObj
	end

	function ENT:SetSize(Size)
		if not Size then return false end

		local Scale = Size / self.XCFScaleData.OriginalSize

		return ResizeEntity(self, Scale)
	end

	function ENT:SetScale(Scale)
		if not Scale then return false end

		return ResizeEntity(self, Scale)
	end
end

