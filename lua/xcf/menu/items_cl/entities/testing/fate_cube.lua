local function CreateFateCubeMenu(MenuPanel)
	MenuPanel:AddLabel("Cube that changes state randomly when its wire input is triggered.\nInteracts with linked boxes.")

	-- Persistence testing
	MenuPanel:AddButton("Save To File"):XCFDebug("SaveToFile").DoClick = function()
		print("Saving data vars to file...")
		XCF.SaveDataVarsToFile("test", "FateCube")
	end
	MenuPanel:AddButton("Load From File"):XCFDebug("LoadFromFile").DoClick = function()
		print("Loading data vars from file...")
		XCF.LoadDataVarsFromFile("test", "FateCube")
	end

	local Base = MenuPanel:AddCollapsible("Settings")
	Base:AddPresetsBar("FateCube")
	Base:AddModelPreview("models/hunter/blocks/cube075x075x075.mdl"):XCFDebug("Model")
	XCF.CreatePanelsFromDataVars(Base, "FateCube")
end

XCF.AddMenuItem(1, "Fate Cube", "icon16/bricks.png", CreateFateCubeMenu, "Testing")