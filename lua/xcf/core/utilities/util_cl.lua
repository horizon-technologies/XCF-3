local XCF = XCF or {}

do -- Custom fonts
	surface.CreateFont("XCF_Title", {
		font = "Roboto",
		size = 18,
		weight = 850,
		antialias = true,
	})

	surface.CreateFont("XCF_Label", {
		font = "Roboto",
		size = 14,
		weight = 650,
		antialias = true,
	})

	surface.CreateFont("XCF_Control", {
		font = "Roboto",
		size = 14,
		weight = 550,
		antialias = true,
	})
end

function XCF.InitMenuBaseForm(Panel, Command, CreateMenu)
	local Menu = vgui.Create("XCF_Panel")
	Panel:AddItem(Menu)

	if Command then
		concommand.Add(Command, function()
			Menu:ClearChildren()
			print("create", CreateMenu)
			CreateMenu(Menu)
		end)
	end
	CreateMenu(Menu)
	return Menu
end

function XCF.CreateMainMenu(Menu)
	local ReloadButton = Menu:AddMenuReload("xcf_reload_menu")

	-- Add test elements
	Menu:AddTitle("XCF Menu")
	Menu:AddLabel("This is as label.")
	Menu:AddButton("This is a button.", function() print("Button clicked!") end)
	Menu:AddLabel("More text to show how wrapping works. This label should wrap if the panel is too narrow.")
end

print("redefine", XCF.CreateMainMenu)