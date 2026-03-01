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

--- Initializes an XCF menu base panel on the provided panel.
--- @param Panel any The panel to add the base panel to
--- @param Command string The command to run to reload the menu
--- @param CreateMenu string The name of the function to call to create the menu (on the XCF table)
function XCF.InitMenuReloadableBase(Panel, Command, CreateMenu)
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

XCF.MainMenuLookup = XCF.MainMenuLookup or {}
--- Adds a menu item to the main menu lookup.
function XCF.AddMenuItem(Order, Name, Icon, Action, Parent)
	XCF.MainMenuLookup[Name] = {
		Order = Order,
		Name = Name,
		Icon = Icon,
		Action = Action,
		Parent = Parent,
		Children = {},
	}
end

--- Creates the main menu for XCF given an existing XCF_Panel
function XCF.CreateMainMenu(Menu)
	-- Add test elements
	local Tree = Menu:AddPanel("DTree")
	Tree:SetSize(300, 400)

	local Clearable = Menu:AddPanel("XCF_Panel")

	-- Build a forest from the flat lookup table (to deal with hot loading)
	local Lookup = table.Copy(XCF.MainMenuLookup)
	for _, node in pairs(Lookup) do
		if Lookup[node.Parent] then
			table.insert(Lookup[node.Parent].Children, node)
			table.sort(Lookup[node.Parent].Children, function(a, b) return a.Order < b.Order end)
		end
	end

	local function DefaultAction(Panel)
		Panel:AddLabel("This menu has not been implemented yet.")
	end

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
	for _, NodeData in ipairs(Lookup.Base.Children) do
		AddNodeWithChildren(Tree, Tree, NodeData):ExpandRecurse(true)
	end

	return Tree
end

--- Returns a function that creates a menu for the specified entity class
--- Make sure a data var scope for the EntityClass has been created before calling this.
function XCF.EntityMenuCallback(EntityClass)
	local ClassData = baseclass.Get( EntityClass )
	return function(MenuPanel)
		XCF.SetDataVar("SpawnClass", "ToolGun", EntityClass)

		MenuPanel:AddLabel(ClassData.XCF_Menu_Description or "No description available.")

		local Base = MenuPanel:AddCollapsible("Settings")
		Base:AddPresetsBar(EntityClass)
		Base:AddModelPreview(ClassData.XCF_Menu_Model or "models/hunter/blocks/cube025x025x025.mdl")
		XCF.CreatePanelsFromDataVars(Base, EntityClass)
	end
end

-- Pop out menu tab example
concommand.Add("xcf_menu_console", function()
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

	local BasePanel = XCF.InitMenuReloadableBase(DScrollPanel, "xcf_reload_popout_menu", "CreateMainMenu")
	BasePanel:Dock(TOP)
	BasePanel:DockMargin(10, 30, 10, 10)
end)