local function CreateMenu(MenuPanel)
	MenuPanel:AddLabel("Server side settings (affects all players).")

	local Base = MenuPanel:AddCollapsible("Settings")
	Base:AddPresetsBar("ServerSettings")
	XCF.CreatePanelsFromDataVars(Base, "ServerSettings")
end

XCF.AddMenuItem(2, "Serverside Settings", "icon16/server.png", CreateMenu, "Settings")