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
	local BasePanel = vgui.Create("XCF_Panel", Panel)

	-- Contains the reload button
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
	local Tree = Menu:AddPanel("DTree")
	Tree:SetSize(300, 400)

	local Clearable = Menu:AddPanel("XCF_Panel")

	local function DefaultAction(Panel)
		Panel:AddLabel("This is the default action. Select a node to see more options.")
	end

	TreeData = {
		{
			Name = "About", Icon = "icon16/information.png",
			Children = {
				{Name = "Updates", Icon = "icon16/newspaper.png"},
				{Name = "Contact", Icon = "icon16/feed.png"},
				{Name = "Wiki", Icon = "icon16/book_open.png"},
			}
		},
		{
			Name = "Tools", Icon = "icon16/wrench.png",
			Children = {
				{Name = "Clientside Settings", Icon = "icon16/user.png"},
				{Name = "Serverside Settings", Icon = "icon16/server.png"},
				{Name = "Scanner", Icon = "icon16/magnifier.png"},
				{Name = "Battle Log", Icon = "icon16/chart_bar.png"},
			}
		},
		{
			Name = "Entities", Icon = "icon16/brick.png",
			Children = {
				{
					Name = "Weapons", Icon = "icon16/bomb.png", Children = {
						{Name = "Guns", Icon = "icon16/gun.png"},
						{Name = "Missiles", Icon = "icon16/wand.png"},
					}
				},
				{
					Name = "Mobility", Icon = "icon16/lorry.png", Children = {
						{Name = "Engines", Icon = "icon16/car.png"},
						{Name = "Gearboxes", Icon = "icon16/cog.png"},
					}
				},
				{
					Name = "Core", Icon = "icon16/heart.png", Children = {
						{Name = "Baseplates", Icon = "icon16/shape_square.png"},
						{Name = "Turrets", Icon = "icon16/shape_align_center.png"},
						{Name = "Crew", Icon = "icon16/user_female.png"},
						{Name = "Controllers", Icon = "icon16/computer.png"}
					}
				},
				{
					Name = "Peripherals", Icon = "icon16/drive.png", Children = {
						{Name = "Sensors", Icon = "icon16/transmit.png"},
						{Name = "Guidance", Icon = "icon16/joystick.png"},
						{Name = "Refill", Icon = "icon16/arrow_refresh.png"},
					},
				},
			}
		}
	}

	-- ExpandRecurse expands instantly, so this is less jarring.
	-- TODO: Maybe BFS looks better than DFS?
	local function ExpandRecurseSmooth(Node, Expand)
		Node:SetExpanded(Expand)
		for _, Child in pairs(Node:GetChildNodes()) do
			ExpandRecurseSmooth(Child, Expand)
		end
	end

	-- Handles what happens when a node is selected
	function Tree:UpdateTree(Old, New)
		if Old == New then return end

		ExpandRecurseSmooth(New, true)

		-- Collapse every other ancestor node
		for _, Node in pairs(Tree.Children) do
			if Node ~= New.Ancestor then
				ExpandRecurseSmooth(Node, false)
			end
		end

		local NodeData = New.NodeData or {}

		-- Clear the temporary menu panel and load the menu
		Clearable:ClearChildren()
		Clearable:AddTitle(NodeData.Name)

		if NodeData.Action then NodeData.Action(Clearable)
		else DefaultAction(Clearable) end

		Clearable:InvalidateLayout(true)
		Clearable:SizeToChildren(true, true)
	end

	function Tree:OnNodeSelected(Node)
		if self.Selected == Node then return end

		self:UpdateTree(self.Selected, Node)

		self.Selected = Node
	end

	-- Recursive function to add nodes and their children
	function AddNodeWithChildren(DTree, ParentNode, NodeData)
		local Node = ParentNode:AddNode(NodeData.Name, NodeData.Icon)
		Node.NodeData = NodeData

		-- An ancestor is any node added directly to the tree
		if ParentNode == DTree then
			Node.Ancestor = Node
			DTree.Children = DTree.Children or {}
			table.insert(DTree.Children, Node)
		end

		Node.Ancestor = Node.Ancestor or ParentNode.Ancestor

		-- Recursively add children
		if NodeData.Children then
			for _, ChildData in ipairs(NodeData.Children) do
				AddNodeWithChildren(DTree, Node, ChildData)
			end
		end
		return Node
	end

	-- Add all top-level nodes
	for _, NodeData in ipairs(TreeData) do
		AddNodeWithChildren(Tree, Tree, NodeData):ExpandRecurse(true)
	end
end

-- Pop out menu tab example
concommand.Add("open_frame", function()
	local Width, Height = ScrW(), ScrH()
	local DFrame = vgui.Create("DFrame")
	DFrame:SetPos(Width * 0.25, Height * 0.25)
	DFrame:SetSize(Width * 0.5, Height * 0.5)
	DFrame:Center()
	DFrame:SetTitle("XCF Menu Popout")
	DFrame:SetSizable(true)
	DFrame:MakePopup() -- Makes your mouse be able to move around.

	local DScrollPanel = vgui.Create("DScrollPanel", DFrame)
	DScrollPanel:Dock(FILL)

	local BasePanel = XCF.InitMenuReloadableBase(DScrollPanel, "Popout", "xcf_reload_popout_menu", "CreateMainMenu")
	BasePanel:Dock(TOP)
	BasePanel:DockMargin(10, 30, 10, 10)
end)