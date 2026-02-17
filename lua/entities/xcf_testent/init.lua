-- init.lua --

-- Send shared and cl_init to the client
AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")

include("shared.lua") -- This runs shared.lua on the server

-- This code runs whenever the entity is created.
function ENT:Initialize()
	self:SetModel("models/props_c17/oildrum001_explosive.mdl")

	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)

	local phys = self:GetPhysicsObject()

	-- This will make the entity fall instead of being stuck in the air when spawned.
	if ( IsValid( phys ) ) then
		phys:Wake()
	end

	-- This is required to allow the entity to be gibbed.
	self:PrecacheGibs()
end

-- Explode when damaged!
function ENT:OnTakeDamage(_)
	if self.HasExploded then
		return -- Stop the code here if the entity already exploded.
	end

	local newEffectData = EffectData() -- Creates a new EffectData to use in util.Effect.
	newEffectData:SetOrigin(self:GetPos())
	newEffectData:SetMagnitude(100)
	newEffectData:SetScale(1)

	-- Make the explosion effect!
	util.Effect("Explosion", newEffectData)

	-- Makes the entity split apart. (The vector adds force to the gibs upwards)
	self:GibBreakServer(Vector(0, 0, 10))

	-- Setting this to true prevents the entity from exploding again.
	self.HasExploded = true

	self:Remove()
end

function ENT:OnRemove()
	-- Deal explosion damage.
	-- (The last two variables are custom and can be changed at the top)
	util.BlastDamage( self, self, self:GetPos(), self.ExplosionRadius, self.ExplosionDamage )
end