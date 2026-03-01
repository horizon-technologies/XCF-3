DEFINE_BASECLASS("xcf_base_scaleable")

ENT.PrintName      = "XCF baseplate"
ENT.WireDebugName  = "XCF baseplate"
ENT.Spawnable = false

ENT.XCF_Class = "xcf_baseplate"
ENT.XCF_Menu_Model = "models/hunter/blocks/cube075x075x075.mdl"
ENT.XCF_Menu_Description = "Base of all XCF contraptions. Build your vehicle off of this."

XCF.DefineDataVar("Type", ENT.XCF_Class, "EnumeratedString", "Ground", {Choices = {"Aircraft", "Ground", "Recreational"}})
XCF.DefineDataVar("Size", ENT.XCF_Class, "Vector", Vector(144, 72, 1.5), {Min = Vector(36, 36, 0.5), Max = Vector(480, 120, 3)})
XCF.DefineDataVar("DisableAltE", ENT.XCF_Class, "Bool", false, {})
XCF.DefineDataVar("LuaSeat", ENT.XCF_Class, "StoredEntity", nil, {Hidden = true})