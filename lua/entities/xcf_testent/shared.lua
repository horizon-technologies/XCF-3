-- shared.lua --
DEFINE_BASECLASS("xcf_base_scaleable")

ENT.PrintName      = "XCF scalable test entity"
ENT.WireDebugName  = "XCF scalable test entity"

XCF.DefineDataVar("Volatility", "FateCube", "Float", 0, {Min = 0, Max = 1})
XCF.DefineDataVar("State", "FateCube", "UInt8", 0, {Min = 0, Max = 10})
XCF.DefineDataVar("Size", "FateCube", "Vector", Vector(1, 1, 1), {Min = Vector(0.1, 0.1, 0.1), Max = Vector(2, 2, 2)})
XCF.DefineDataVar("Material", "FateCube", "String", "phoenix_storms/grey_chrome", {MaxLength = 100})
XCF.DefineDataVar("MakeNoise", "FateCube", "Bool", false, {})