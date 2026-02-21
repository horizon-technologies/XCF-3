local function CreateFateCubeMenu(MenuPanel)
	MenuPanel:AddLabel("Cube that changes state randomly when its wire input is triggered.\nInteracts with linked boxes.")
	MenuPanel:AddButton("Test Button", function() print("Button Clicked") end)
	MenuPanel:AddCheckbox("Test Checkbox", function(_, Val) print("Checkbox Changed:", Val) end)

	local Base = MenuPanel:AddCollapsible("Settings")
	Base:AddPresetsBar()
	Base:AddModelPreview("models/hunter/blocks/cube075x075x075.mdl"):XCFDebug("Model")
	Base:AddSlider("Volatility", 0, 1, 2):XCFDebug("Volatility"):BindToDataVar("Volatility", "SetValue", "GetValue", "OnValueChanged")
	Base:AddNumberWang("State", 0, 10):XCFDebug("State"):BindToDataVar("State", "SetValue", "GetValue", "OnValueChanged")
	Base:AddVec3Slider("Scale"):XCFDebug("Scale")
	Base:AddTextEntry("Material"):XCFDebug("Material"):BindToDataVar("Material", "SetValue", "GetValue", "OnValueChange")
end

XCF.AddMenuItem(1, "Fate Cube", "icon16/bricks.png", CreateFateCubeMenu, "Testing")