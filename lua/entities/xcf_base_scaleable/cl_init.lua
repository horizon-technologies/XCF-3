-- TODO: Only network scale updates once the model is networked? Probably can be networked separately.

DEFINE_BASECLASS("base_wire_entity") -- Use wiremod's base entity for easy wiremod integration

include("shared.lua") -- Includes and runs shared file on the client

local ModelData = XCF.ModelData

do -- Networking related
	local WaitingForScaleInfo = {}

	--- Requests the scale info of an entity from the server, if we haven't already
	local function RequestEntityScaleInfo(Entity)
		if WaitingForScaleInfo[Entity] then return end
		WaitingForScaleInfo[Entity] = true

		net.Start("XCF_Scalable_Entity")
		net.WriteUInt(Entity:EntIndex(), MAX_EDICT_BITS)
		net.SendToServer()

		Entity:CallOnRemove("XCF_Scalable_Entity", function()
			WaitingForScaleInfo[Entity] = nil
		end)
	end

	-- TODO: Can we just skip to RenderScene or is this needed
	--- Waits for an entity to bet networked to the client, then runs a callback
	local function WaitForEntity(EntIndex, Then)
		local Entity = ents.GetByIndex(EntIndex)
		if IsValid(Entity) then Then(Entity) return end

		hook.Add("NetworkEntityCreated", "XCF_WaitingForEntity" .. EntIndex, function(Ent)
			if Ent:EntIndex() ~= EntIndex then return end

			hook.Remove("NetworkEntityCreated", "XCF_WaitingForEntity" .. EntIndex)
			Then(Ent)
		end)
	end

	-- Given an update, sync the client's copy of the entity with the server
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
			end)
		end)
	end)

	-- When a scalable entity is created, request its scale info
	hook.Add("NetworkEntityCreated", "Scalable Entity Full Update", function(Entity)
		if not Entity.XCFIsScalable then return end

		if not WaitingForScaleInfo[Entity] then
			RequestEntityScaleInfo(Entity)
		end
	end)
end

-- TODO: Is this needed
function ENT:Initialize()
	BaseClass.Initialize(self)

	self.Initialized = true
end

function ENT:Draw()
	if LocalPlayer():InVehicle() then self:DrawModel() return end
	self:DoNormalDraw()
end

-- TODO: Is this needed
function ENT:CalcAbsolutePosition() -- Faking sync
	local PhysObj  = self:GetPhysicsObject()
	local Position = self:GetPos()
	local Angles   = self:GetAngles()

	if IsValid(PhysObj) then
		PhysObj:Sleep()
	end

	return Position, Angles
end

-- TODO: Is this needed
function ENT:Think(...)
	if not self.Initialized then
		self:Initialize()
	end

	return BaseClass.Think(self, ...)
end

do -- Size and scale setter methods
	--- Sets the scale of the entity on the client
	function ENT:ResizeEntity(Scale)
		local Data = self.XCFScaleData
		Data.Size = Data.OriginalSize * Scale
		Data.Scale = Scale

		local Mesh = ModelData.GetModelMesh(Data.ModelPath, Scale)

		self.Matrix = Matrix()
		self.Matrix:SetScale(Scale)

		self:EnableMatrix("RenderMultiply", self.Matrix)
		self:PhysicsInitMultiConvex(Mesh)
		self:EnableCustomCollisions(true)
		self:SetRenderBounds(self:GetCollisionBounds())
		self:DrawShadow(false)

		local PhysObj = self:GetPhysicsObject()

		if IsValid(PhysObj) then
			PhysObj:EnableMotion(false)
			PhysObj:Sleep()
		end

		return PhysObj
	end
end