TOOL.Name = "XCF Menu"
TOOL.Category = "Construction"

-- Build defaults for the preset system.
local ConVarsDefault = TOOL:BuildConVarList()

-- Please note that this function is defined with a dot (.), not a colon (:)!!!
-- This is important! You will not be able to access "self" in this function.
function TOOL.BuildCPanel( CPanel )

	CPanel:AddControl( "Header", { Description = "#tool.ballsocket.help" } )

	CPanel:AddControl( "ComboBox", { MenuButton = 1, Folder = "ballsocket", Options = { [ "#preset.default" ] = ConVarsDefault }, CVars = table.GetKeys( ConVarsDefault ) } )

	CPanel:AddControl( "Slider", { Label = "#tool.forcelimit", Command = "ballsocket_forcelimit", Type = "Float", Min = 0, Max = 50000, Help = true } )

	CPanel:AddControl( "CheckBox", { Label = "#tool.nocollide", Command = "ballsocket_nocollide", Help = true } )

end