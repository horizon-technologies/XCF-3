DEFINE_BASECLASS("xcf_base_scaleable")

ENT.PrintName      = "XCF baseplate"
ENT.WireDebugName  = "XCF baseplate"
ENT.Spawnable = false

XCF.DefineDataVar("Type", "Baseplate", "UInt8", 0, {Min = 0, Max = 3})
XCF.DefineDataVar("Size", "Baseplate", "Vector", Vector(1, 1, 1), {Min = Vector(36, 36, 0.5), Max = Vector(480, 120, 3)})
XCF.DefineDataVar("DisableAltE", "Baseplate", "Bool", false, {})