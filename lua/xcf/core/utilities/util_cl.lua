local XCF = XCF

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

--- Initializes an ACF menu base panel on the provided panel.
--- @param Panel any The panel to add the base panel to
--- @param UniqueID string A unique ID for this menu (see above)
--- @param Command string The command to run to reload the menu
--- @param CreateMenu string The name of the function to call to create the menu (on the XCF table)
function XCF.InitMenuReloadableBase(Panel, UniqueID, Command, CreateMenu)
	-- Contains the reload button
	local BasePanel = vgui.Create("XCF_Panel", Panel)
	BasePanel:AddMenuReload(Command)

	-- Actual menu exists inside this panel
	local MenuPanel = BasePanel:AddPanel("XCF_Panel")

	-- Add the console command to reload the menu
	concommand.Add(Command, function()
		MenuPanel:ClearChildren()
		XCF[CreateMenu](MenuPanel)
	end)

	-- Create the menu for the first time
	XCF[CreateMenu](MenuPanel)

	return BasePanel
end

--- Creates the main menu for XCF given an existing XCF_Panel
function XCF.CreateMainMenu(Menu)
	-- Add test elements
	Menu:AddTitle("XCF Menu")
	Menu:AddLabel("This is as label.")
	Menu:AddButton("This is a button.", function() print("Button clicked!") end)
	Menu:AddLabel("More text to show how wrapping works. This label should wrap if the panel is too narrow.")
	local Image = Menu:AddPanel("DImage")
	Image:SetImage("gm_construct/flatsign")
	Image:SetHeight(300)
	local Image2 = Menu:AddPanel("DImage")
	Image2:SetImage("gm_construct/flatsign")
	Image2:SetHeight(300)
	local Image3 = Menu:AddPanel("DImage")
	Image3:SetImage("gm_construct/flatsign")
	Image3:SetHeight(300)
end

print("redefine", XCF.CreateMainMenu)

-- Pop out menu tab example
concommand.Add( "open_frame", function()
	local Width, Height = ScrW(), ScrH()
	local DFrame = vgui.Create("DFrame")
	DFrame:SetPos(Width * 0.25, Height * 0.25)
	DFrame:SetSize(Width * 0.5, Height * 0.5)
	DFrame:Center()
	DFrame:SetTitle("XCF Menu Popout")
	DFrame:SetSizable(true)
	DFrame:MakePopup() -- Makes your mouse be able to move around.

	local DScrollPanel = vgui.Create( "DScrollPanel", DFrame )
	DScrollPanel:Dock( FILL )

	local BasePanel = XCF.InitMenuReloadableBase(DScrollPanel, "Popout", "xcf_reload_popout_menu", "CreateMainMenu")
	BasePanel:Dock(TOP)
	BasePanel:DockMargin(10, 30, 10, 10)
end )