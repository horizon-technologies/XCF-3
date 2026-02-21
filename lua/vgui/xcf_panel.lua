local PANEL     = {}
-- local XCF       = XCF

DEFINE_BASECLASS("Panel")

-- Core panel methods
function PANEL:Init()
	self.Items = {}
end

function PANEL:ClearChildren()
	for Item in pairs(self.Items) do
		Item:Remove()
	end
end

function PANEL:AddPanel(PanelClass)
	if not PanelClass then return end

	local Panel = vgui.Create(PanelClass, self)

	Panel:Dock(TOP)
	Panel:DockMargin(0, 0, 0, 10)
	Panel:InvalidateParent()
	Panel:InvalidateLayout()

	self:InvalidateLayout()
	self.Items[Panel] = true

	return Panel
end

function PANEL:PerformLayout()
	self:SizeToChildren(true, true)
end

-- Core Elements
function PANEL:AddMenuReload(Command)
	local Reload = self:AddButton("Reload Menu")
	local ReloadDesc = language.GetPhrase("You can type %s in console."):format(Command)
	Reload:SetTooltip(ReloadDesc)

	function Reload:DoClickInternal()
		RunConsoleCommand(Command)
	end

	return Reload
end

-- Default Elements
function PANEL:AddTitle(Text)
	local Panel = self:AddPanel("DLabel")
	Panel:SetText(Text or "Title")
	Panel:SetFont("XCF_Title")
	Panel:SetDark(true)

	return Panel
end

function PANEL:AddLabel(Text)
	local Panel = self:AddPanel("DLabel")
	Panel:SetAutoStretchVertical(true)
	Panel:SetText(Text or "Label")
	Panel:SetFont("XCF_Label")
	Panel:SetWrap(true)
	Panel:SetDark(true)

	return Panel
end

function PANEL:AddHelp(Text)
	local TextColor = self:GetSkin().Colours.Tree.Hover
	local Panel = self:AddLabel(Text)
	Panel:DockMargin(10, 0, 10, 10)
	Panel:SetTextColor(TextColor)
	Panel:InvalidateLayout()

	return Panel
end

function PANEL:AddButton(Text, OnClick)
	local Panel = self:AddPanel("DButton")
	Panel:SetText(Text or "Button")
	Panel:SetFont("XCF_Control")
	Panel:SetDark(true)
	if OnClick then
		Panel.DoClick = OnClick
	end

	return Panel
end

function PANEL:AddCheckbox(Text, OnChange)
	local Panel = self:AddPanel("DCheckBoxLabel")
	Panel:SetText(Text or "Checkbox")
	Panel:SetFont("XCF_Control")
	Panel:SetDark(true)
	if OnChange then
		Panel.OnChange = OnChange
	end

	return Panel
end

function PANEL:AddSlider(Title, Min, Max, Decimals)
	local Panel = self:AddPanel("DNumSlider")
	Panel:DockMargin(0, 0, 0, 5)
	Panel:SetDecimals(Decimals or 0)
	Panel:SetText(Title or "")
	if Min and Max then
		Panel:SetMinMax(Min, Max)
	end
	Panel:SetValue(Min)
	Panel:SetDark(true)

	Panel.Label:SetFont("XCF_Control")

	return Panel
end

function PANEL:AddNumberWang(Label, Min, Max, Decimals)
	local Base = self:AddPanel("XCF_Panel")

	local Wang = Base:Add("DNumberWang")
	Wang:SetDecimals(Decimals or 0)
	Wang:SetMinMax(Min, Max)
	Wang:SetTall(20)
	Wang:Dock(RIGHT)

	local Text = Base:Add("DLabel")
	Text:SetText(Label or "Text")
	Text:SetFont("XCF_Control")
	Text:SetDark(true)
	Text:Dock(TOP)

	return Wang, Text
end

function PANEL:AddComboBox()
	local Panel = self:AddPanel("DComboBox")
	Panel:SetFont("XCF_Control")
	Panel:SetSortItems(false)
	Panel:SetDark(true)
	Panel:SetWrap(true)
	return Panel
end

function PANEL:AddCollapsible(Text, State)
	if State == nil then State = true end

	local Category = self:AddPanel("DCollapsibleCategory")
	Category:SetLabel(Text or "Title")
	Category.Header:SetFont("XCF_Title")
	Category.Header:SetSize(0, 24)

	Category:DoExpansion(State)

	local Base = vgui.Create("XCF_Panel")
	Base:DockMargin(5, 5, 5, 5)

	Category:SetContents(Base)

	return Base, Category
end

function PANEL:AddTextEntry(Placeholder)
	local Panel = self:AddPanel("DTextEntry")
	Panel:SetFont("XCF_Control")
	Panel:SetPlaceholderText(Placeholder)

	return Panel
end

-- Similar to ControlPresets derma panel, but for XCF.
-- Reference: https://github.com/Facepunch/garrysmod/blob/master/garrysmod/gamemodes/sandbox/gamemode/spawnmenu/controls/control_presets.lua
function PANEL:AddPresetsBar()
	local Box = self:Add("DPanel")
	Box:Dock(TOP)
	Box:SetTall(20)
	Box:DockMargin(0, 0, 0, 10)

	local Dropdown = vgui.Create("DComboBox", Box)
	Dropdown:Dock(FILL)

	local RemoveButton = vgui.Create("DImageButton", Box)
	RemoveButton:Dock(RIGHT)
	RemoveButton:SetTooltip("Remove preset")
	RemoveButton:SetImage("icon16/delete.png")
	RemoveButton:SetStretchToFit(false)
	RemoveButton:SetSize(20, 20)
	RemoveButton:DockMargin(0, 0, 0, 0)

	RemoveButton.DoClick = function()
		print("remove")
	end

	local SaveButton = vgui.Create("DImageButton", Box)
	SaveButton:Dock(RIGHT)
	SaveButton:SetTooltip("Save preset")
	SaveButton:SetImage("icon16/add.png")
	SaveButton:SetStretchToFit(false)
	SaveButton:SetSize(20, 20)
	SaveButton:DockMargin(2, 0, 0, 0)

	SaveButton.DoClick = function()
		print("save")
	end
end

-- TODO: Add more options etc.
function PANEL:AddModelPreview(Model, _)
	local ModelPanel    = self:AddPanel("DModelPanel")

	function ModelPanel:UpdateModel(Model)
		self:SetModel(Model)
		local Entity = self:GetEntity()
		if not IsValid(Entity) then return end

		-- local Min, Max = Entity:GetRenderBounds()
		-- local Size = Max - Min
		-- local Distance = Size:Length() * 1.5
		-- self:SetCamPos(Vector(Distance, Distance, Distance))
		-- self:SetLookAt((Min + Max) * 0.5)
	end

	ModelPanel:SetModel(Model)
	ModelPanel:SetSize(200, 200)
	ModelPanel:SetCamPos(Vector(-100, 0, 0))
	ModelPanel:SetLookAt(Vector(0, 0, 0))

	function ModelPanel:PaintOver( w, h )
		surface.SetDrawColor(255, 255, 255, 255)
		surface.DrawOutlinedRect(0, 0, w, h, 5)
	end

	return ModelPanel
end

-- Multi Elements
function PANEL:AddVec3Slider(Title)
	local Base = self:AddPanel("XCF_Panel")

	local X = Base:AddSlider(Title .. " X", 0, 2, 2)
	local Y = Base:AddSlider(Title .. " Y", 0, 2, 2)
	local Z = Base:AddSlider(Title .. " Z", 0, 2, 2)

	return X, Y, Z
end

-- TODO: Add graph element

-- Must be after methods are attached to the PANEL table.
derma.DefineControl("XCF_Panel", "", PANEL, "Panel")