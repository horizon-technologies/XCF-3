TOOL.Name = "XCF Menu"
TOOL.Category = "Construction"
TOOL.Command	 = nil
TOOL.ConfigName = ""

if CLIENT then
	TOOL.BuildCPanel = function(Panel)
		XCF.InitMenuBaseForm(Panel, "xcf_reload_menu", XCF.CreateMainMenu)
	end
end