DEFINE_BASECLASS("base_wire_entity") -- Use wiremod's base entity for easy wiremod integration

ENT.PrintName      = "XCF base scalable entity"
ENT.WireDebugName  = "XCF base scalable entity"

ENT.Spawnable = true
ENT.Category = "Other"
ENT.Author = "XCF Team"

ENT.XCFIsScalable = true
ENT.XCFScaleData = { ModelPath = "", Scale = Vector(1, 1, 1), Size = Vector(1, 1, 1), OriginalSize = Vector(1, 1, 1) }

local ModelData = XCF.ModelData

function ENT:GetSize()
	return self.Size
end

function ENT:GetScale()
	return self.Scale
end

function ENT:GetModelPath()
	return self.XCFScaleData.ModelPath
end

function ENT:GetOriginalSize()
	return self.XCFScaleData.OriginalSize
end

function ENT:SetScaledModel(Model)
	self.XCFScaleData.ModelPath = Model
	self.XCFScaleData.OriginalSize = ModelData.GetModelSize(Model)

	self:SetModel(Model)
end