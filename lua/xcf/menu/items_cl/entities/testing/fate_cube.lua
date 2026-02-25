local function CreateMenu(MenuPanel)
	XCF.SetDataVar("SpawnClass", "ToolGun", "xcf_testent", LocalPlayer())

	MenuPanel:AddLabel("Cube that changes state randomly when its wire input is triggered.\nInteracts with linked boxes.")

	local Base = MenuPanel:AddCollapsible("Settings")
	Base:AddPresetsBar("FateCube")
	Base:AddModelPreview("models/hunter/blocks/cube075x075x075.mdl"):XCFDebug("Model")
	XCF.CreatePanelsFromDataVars(Base, "FateCube")
end

XCF.AddMenuItem(1, "Fate Cube", "icon16/bricks.png", CreateMenu, "Testing")