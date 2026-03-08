DEFINE_BASECLASS("base_wire_entity")

ENT.PrintName      = "XCF base procedurable entity"
ENT.WireDebugName  = "XCF base procedurable entity"
ENT.PluralName = "XCF base procedurable entities"

ENT.Spawnable = true
ENT.Category = "Other"
ENT.Author = "XCF Team"

ENT.IsXCFEntity = true
ENT.XCFIsProcedural = true

local Base = XCF.GetClass("Primitive3D")()
Base:Dock(Vector(), Angle())

local Shaft = XCF.GetClass("Cylinder")({radius=6, height=36})
Shaft:DockRelSimple(Base, Vector(0,0,0), Angle(90,0,0))

for i = 1,4 do
	local Piston = XCF.GetClass("Cube")({length=36,width=6,height=12})
	Piston:DockRelAdv(Base, Angle(), Vector(0,0,6), Angle(0,0,45+90*i), Vector(0,0,-5), Angle(0,0,0))
end

Base:CompileChildren()

function ENT:Initialize()
	-- Initializing the multi-convex physics mesh
	self:SetModel( "models/combine_helicopter/helicopter_bomb01.mdl" )
	local res = self:PhysicsInitMultiConvex(Base.convexes)
	print("init", res)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	self:EnableCustomCollisions(true)
	self:DrawShadow(false)

	local PhysObj = self:GetPhysicsObject()
	if IsValid(PhysObj) then
		PhysObj:EnableMotion(false)
		PhysObj:Sleep()
	end
end

if CLIENT then
	local NewMat = Material("hunter/myplastic")
	local NewMesh = Mesh(NewMat)
	NewMesh:BuildFromTriangles(Base.triangles)

	function ENT:GetRenderMesh()
		return {Mesh = NewMesh, Material = NewMat}
	end

	function ENT:Draw()
		self:DrawModel()
	end
end