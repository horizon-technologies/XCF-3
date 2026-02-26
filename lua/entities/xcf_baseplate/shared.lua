DEFINE_BASECLASS("xcf_base_scaleable")

ENT.PrintName      = "XCF baseplate"
ENT.WireDebugName  = "XCF baseplate"
ENT.Spawnable = false

XCF.DefineDataVar("Type", "xcf_baseplate", "UInt8", 0, {Min = 0, Max = 3})
XCF.DefineDataVar("Size", "xcf_baseplate", "Vector", Vector(36, 36, 0.5), {Min = Vector(36, 36, 0.5), Max = Vector(480, 120, 3)})
XCF.DefineDataVar("DisableAltE", "xcf_baseplate", "Bool", false, {})
XCF.DefineDataVar("LuaSeat", "xcf_baseplate", "StoredEntity", nil, {Hidden = true})