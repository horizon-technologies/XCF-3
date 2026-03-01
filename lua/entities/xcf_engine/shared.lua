DEFINE_BASECLASS("xcf_base_scaleable")

ENT.PrintName      = "XCF engine"
ENT.WireDebugName  = "XCF engine"
ENT.Spawnable = false

ENT.XCF_Class = "xcf_engine"
ENT.XCF_Menu_Model = "models/engines/v8s.mdl"
ENT.XCF_Menu_Description = "Provides power to move contraptions"

XCF.DefineDataVar("Type", ENT.XCF_Class, "EnumeratedString", "Ground", {Choices = {"Flat", "Electric", "Turbine", "Single", "Inline", "Rotary", "Radial", "V-Type" }})