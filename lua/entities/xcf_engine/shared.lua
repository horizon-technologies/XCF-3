DEFINE_BASECLASS("xcf_base_scaleable")
XCF.SetupENT(ENT)

ENT.PrintName      = "XCF engine"
ENT.WireDebugName  = "XCF engine"

ENT.XCF_Menu_Model = "models/engines/v12s.mdl"
ENT.XCF_Menu_Description = "Provides power to move contraptions"

XCF.DefineDataVar("Type", ENT.XCF_Class, "EnumeratedString", "Ground", {Choices = {"Flat", "Electric", "Turbine", "Single", "Inline", "Rotary", "Radial", "V-Type" }})