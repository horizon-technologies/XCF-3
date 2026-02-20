DEFINE_BASECLASS("base_wire_entity") -- Use wiremod's base entity for easy wiremod integration

include("shared.lua") -- Includes and runs shared file on the client

local ModelData = XCF.ModelData
local Standby = {}

local function RequestEntityScaleInfo(Entity)
	if Standby[Entity] then return end
	Standby[Entity] = true

	net.Start("XCF_Scalable_Entity")
	net.WriteUInt(Entity:EntIndex(), MAX_EDICT_BITS)
	net.SendToServer()

	Entity:CallOnRemove("XCF_Scalable_Entity", function()
		Standby[Entity] = nil
	end)
end

-- TODO: how much of this is needed
function ENT:Initialize()
	BaseClass.Initialize(self)

	self.Initialized = true
end

function ENT:CalcAbsolutePosition() -- Faking sync
	local PhysObj  = self:GetPhysicsObject()
	local Position = self:GetPos()
	local Angles   = self:GetAngles()

	if IsValid(PhysObj) then
		PhysObj:Sleep()
	end

	return Position, Angles
end

function ENT:Think(...)
	if not self.Initialized then
		self:Initialize()
	end

	return BaseClass.Think(self, ...)
end

do -- Size and scale setter methods
	local function ResizeEntity(Entity, Scale)
		local Data = Entity.XCFScaleData
		Data.Size = Data.OriginalSize * Scale
		Data.Scale = Scale

		local Mesh = ModelData.GetModelMesh(Data.ModelPath, Scale)

		Entity.Matrix = Matrix()
		Entity.Matrix:SetScale(Scale)

		Entity:EnableMatrix("RenderMultiply", Entity.Matrix)
		Entity:PhysicsInitMultiConvex(Mesh)
		Entity:EnableCustomCollisions(true)
		Entity:SetRenderBounds(Entity:GetCollisionBounds())
		Entity:DrawShadow(false)

		local PhysObj = Entity:GetPhysicsObject()

		if IsValid(PhysObj) then
			PhysObj:EnableMotion(false)
			PhysObj:Sleep()
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

-- TODO: Can we just skip to RenderScene or is this needed
local function WaitForEntity(EntIndex, Then)
	local Entity = ents.GetByIndex(EntIndex)
	if IsValid(Entity) then Then(Entity) return end

	hook.Add("NetworkEntityCreated", "XCF_WaitingForEntity" .. EntIndex, function(Ent)
		if Ent:EntIndex() ~= EntIndex then return end

		hook.Remove("NetworkEntityCreated", "XCF_WaitingForEntity" .. EntIndex)
		Then(Ent)
	end)
end

net.Receive("XCF_Scalable_Entity", function()
	local EntIndex = net.ReadUInt(MAX_EDICT_BITS)
	local Scale = Vector(net.ReadFloat(), net.ReadFloat(), net.ReadFloat())
	local Path  = net.ReadString()

	WaitForEntity(EntIndex, function(Entity)
		hook.Add("RenderScene", "XCF_RunThisASAP" .. EntIndex, function()
			hook.Remove("RenderScene", "XCF_RunThisASAP" .. EntIndex)
			if not IsValid(Entity) then return end
			if not Entity.XCFIsScalable then return end

			Entity:SetScaledModel(Path)
			Entity:SetScale(Scale)
			print(EntIndex, Scale, Path)
		end)
	end)
end)

do
	hook.Add("NetworkEntityCreated", "Scalable Entity Full Update", function(Entity)
		if not Entity.XCFIsScalable then return end

		-- Instantly requesting XCFScaleData and Scale
		if not Standby[Entity] then
			RequestEntityScaleInfo(Entity)
		end
	end)
end