-- shared.lua --

AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_anim"


-- The name that appears in the spawnmenu.
ENT.PrintName   = "XCF Explosive Barrel"

ENT.Information = "Shoot to explode."

ENT.Author      = "You!"


ENT.Spawnable = true

-- The category the entity is located in within the spawnmenu.
ENT.Category = "Other"


-- These are custom entity variables, feel free to change them!
ENT.ExplosionDamage = 100
ENT.ExplosionRadius = 250

-- This custom variable prevents the entity from infinitely exploding.
ENT.HasExploded = false