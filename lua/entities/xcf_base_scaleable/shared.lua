DEFINE_BASECLASS("base_wire_entity") -- Use wiremod's base entity for easy wiremod integration

ENT.PrintName      = "XCF base scalable entity"
ENT.WireDebugName  = "XCF base scalable entity"

ENT.Spawnable = false
ENT.Category = "Other"
ENT.Author = "XCF Team"

ENT.IsXCFEntity = true
ENT.XCFIsScalable = true
ENT.XCFScaleData = { ModelPath = "", Scale = Vector(1, 1, 1), Size = Vector(1, 1, 1), OriginalSize = Vector(1, 1, 1) }

local ModelData = XCF.ModelData

-- Various getters
function ENT:GetSize() return self.XCFScaleData.Size end

function ENT:GetScale() return self.XCFScaleData.Scale end

function ENT:GetModelPath() return self.XCFScaleData.ModelPath end

function ENT:GetOriginalSize() return self.XCFScaleData.OriginalSize end

--- Resizes an entity given a scale vector
function ENT:SetScale(Scale)
	if not Scale then return false end

	return self:ResizeEntity(Scale)
end

--- Resizes an entity given a size vector
function ENT:SetSize(Size)
	if not Size then return false end

	local Scale = Size / self.XCFScaleData.OriginalSize

	return self:ResizeEntity(Scale)
end

--- Initializes the entity's scale data given a model path
function ENT:SetScaledModel(Model)
	self.XCFScaleData.ModelPath = Model
	self.XCFScaleData.OriginalSize = ModelData.GetModelSize(Model)

	self:SetModel(Model)
end