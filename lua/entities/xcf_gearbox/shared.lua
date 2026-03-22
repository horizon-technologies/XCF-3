DEFINE_BASECLASS("xcf_base_scaleable")
XCF.SetupENT(ENT)

ENT.PrintName      = "XCF gearbox"
ENT.WireDebugName  = "XCF gearbox"

ENT.XCF_Menu_Model = "models/engines/transaxial_s.mdl"
ENT.XCF_Menu_Description = "Provides power to move contraptions"

XCF.DefineDataVar("Type", ENT.XCF_Class, "EnumeratedString", "Ground", {Choices = {"Manual", "Automatic", "CVT"}})