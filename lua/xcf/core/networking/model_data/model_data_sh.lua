--- Note: Mesh refers to https://wiki.facepunch.com/gmod/Structures/MeshVertex
local XCF       = XCF
XCF.ModelData = XCF.ModelData or {}
local ModelData = XCF.ModelData
local isstring  = isstring
local IsUseless = IsUselessModel

--- Returns a scaled copy of a mesh
local function CopyScaledMesh(Mesh, Scale)
	local Result = {}

	for I, Hull in ipairs(Mesh) do
		local Current = {}

		for J, Vertex in ipairs(Hull) do
			Current[J] = Vertex * Scale
		end

		Result[I] = Current
	end

	return Result
end

--- Returns the mesh of a physics object in the format PhysicsInitMultiConvex expects
function ModelData.GetMultiConvex(PhysObj)
	local Mesh = PhysObj:GetMeshConvexes()

	for I, Hull in ipairs(Mesh) do
		for J, Vertex in ipairs(Hull) do
			Mesh[I][J] = Vertex.pos
		end
	end

	return Mesh
end

-------------------------------------------------------------------

--- Returns the path of a model, or nil if the model is invalid
function ModelData.GetModelPath(Model)
	if not isstring(Model) then return end
	if IsUseless(Model) then return end

	return Model:Trim():lower()
end

--- Returns the mesh of a model after scaling
function ModelData.GetModelMesh(Model, Scale)
	local Data = ModelData.GetModelData(Model)

	if not Data then return end
	if not Scale then return Data.Mesh end

	return CopyScaledMesh(Data.Mesh, Scale)
end

--- Returns the volume of a model after scaling
function ModelData.GetModelVolume(Model, Scale)
	local Data = ModelData.GetModelData(Model)

	if not Data then return end
	if not Scale then return Data.Volume end

	return Data.Volume * math.abs(Scale.x * Scale.y * Scale.z)
end

--- Returns the center of a model after scaling
function ModelData.GetModelCenter(Model, Scale)
	local Data = ModelData.GetModelData(Model)

	if not Data then return end
	if not Scale then return Data.Center end

	return Data.Center * Scale
end

--- Returns the size of a model after scaling
function ModelData.GetModelSize(Model, Scale)
	local Data = ModelData.GetModelData(Model)

	if not Data then return end
	if not Scale then return Data.Size end

	return Data.Size * Scale
end

--- Returns the scale of an entity
--- TODO: Unused?
function ModelData.GetEntityScale(Entity)
	if Entity.XCFIsScalable and Entity.GetScale then
		local Scale = Entity:GetScale()
		return Scale
	end

	return Entity:GetModelScale()
end