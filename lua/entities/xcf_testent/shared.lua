-- shared.lua --
DEFINE_BASECLASS("xcf_base_scaleable")

ENT.PrintName      = "XCF scalable test entity"
ENT.WireDebugName  = "XCF scalable test entity"
ENT.Spawnable = true

XCF.DefineDataVar("Volatility", "FateCube", XCF.DataVarTypes.Float, 0)
XCF.DefineDataVar("State", "FateCube", XCF.DataVarTypes.UInt8, 0)
XCF.DefineDataVar("Size", "FateCube", XCF.DataVarTypes.Vector, Vector(1, 1, 1))
XCF.DefineDataVar("Material", "FateCube", XCF.DataVarTypes.String, "phoenix_storms/grey_chrome")