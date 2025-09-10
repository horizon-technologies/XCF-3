local PANEL     = {}
local XCF       = XCF

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

-- Default Elements
function PANEL:AddLabel(Text)
	local Panel = self:AddPanel("DLabel")
	Panel:SetAutoStretchVertical(true)
	Panel:SetText(Text or "Label")
	Panel:SetFont("XCF_Label")
	Panel:SetWrap(true)
	Panel:SetDark(true)

	return Panel
end

function PANEL:AddTitle(Text)
	local Panel = self:AddPanel("DLabel")
	Panel:SetText(Text or "Title")
	Panel:SetFont("XCF_Title")
	Panel:SetDark(true)

	return Panel
end

function PANEL:AddButton(Text, OnClick)
	local Panel = self:AddPanel("DButton")
	Panel:SetText(Text or "Button")
	Panel:SetFont("XCF_Control")
	if OnClick then
		Panel.DoClick = OnClick
	end

	return Panel
end

function PANEL:AddCheckbox(Text, OnChange)
	local Panel = self:AddPanel("DCheckBoxLabel")
	Panel:SetText(Text or "Checkbox")
	Panel:SetFont("XCF_Control")
	if OnChange then
		Panel.OnChange = OnChange
	end

	return Panel
end

-- Core elements
function PANEL:AddMenuReload(Command)
	local Reload = self:AddButton("Reload Menu")
	local ReloadDesc = language.GetPhrase("You can type %s in console."):format(Command)
	Reload:SetTooltip(ReloadDesc)

	function Reload:DoClickInternal()
		RunConsoleCommand(Command)
	end

	return Reload
end

-- Must be after methods are attached to the PANEL table.
derma.DefineControl("XCF_Panel", "", PANEL, "Panel")