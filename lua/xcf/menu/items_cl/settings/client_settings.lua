local function CreateMenu(MenuPanel)
	MenuPanel:AddLabel("Client side settings (only affect what you see).")

	local Base = MenuPanel:AddCollapsible("Settings")
	Base:AddPresetsBar("ClientSettings")
	XCF.CreatePanelsFromDataVars(Base, "ClientSettings")
end

XCF.AddMenuItem(1, "Clientside Settings", "icon16/user.png", CreateMenu, "Settings")