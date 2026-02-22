local function CreateMenu(MenuPanel)
	XCF.SetClientData("SpawnClass", "ToolGun", "xcf_testent")

	MenuPanel:AddLabel("Cube that changes state randomly when its wire input is triggered.\nInteracts with linked boxes.")

	local Base = MenuPanel:AddCollapsible("Settings")
	Base:AddPresetsBar("Baseplate")
	Base:AddModelPreview("models/hunter/blocks/cube075x075x075.mdl"):XCFDebug("Model")
	XCF.CreatePanelsFromDataVars(Base, "Baseplate")
end

XCF.AddMenuItem(1, "Baseplates", "icon16/shape_square.png", CreateMenu, "Integral")