TOOL.Name = "XCF Menu"
TOOL.Category = "Construction"
TOOL.Command	 = nil
TOOL.ConfigName = ""

function InitMenuBase(Panel)
	local Menu = vgui.Create("XCF_Panel")
	Menu.Panel = Panel
	Panel:AddItem(Menu)
	return Menu
end

function CreateMainMenu(Panel)
	local Menu = InitMenuBase(Panel)

	-- Add test elements
	Menu:AddTitle("XCF Menu")
	Menu:AddLabel("This is a label.")
	Menu:AddButton("This is a button.", function() print("Button clicked!") end)
	Menu:AddLabel("More text to show how wrapping works. This label should wrap if the panel is too narrow.")
end

TOOL.BuildCPanel = CreateMainMenu