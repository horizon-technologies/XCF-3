-- shared.lua --
DEFINE_BASECLASS("xcf_base_scaleable")

ENT.PrintName      = "XCF scalable test entity"
ENT.WireDebugName  = "XCF scalable test entity"
ENT.Spawnable = true

XCF.DefineDataVar("Volatility", "FateCube", XCF.DataVarTypes.Float, 0, {Min = 0, Max = 1})
XCF.DefineDataVar("State", "FateCube", XCF.DataVarTypes.UInt8, 0, {Min = 0, Max = 10})
XCF.DefineDataVar("Size", "FateCube", XCF.DataVarTypes.Vector, Vector(1, 1, 1), {Min = Vector(0.1, 0.1, 0.1), Max = Vector(2, 2, 2)})
XCF.DefineDataVar("Material", "FateCube", XCF.DataVarTypes.String, "phoenix_storms/grey_chrome", {MaxLength = 100})
XCF.DefineDataVar("MakeNoise", "FateCube", XCF.DataVarTypes.Bool, false, {})