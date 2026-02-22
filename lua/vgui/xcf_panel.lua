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

function PANEL:AddButton(Text)
	local Panel = self:AddPanel("DButton")
	Panel:SetText(Text or "Button")
	Panel:SetFont("XCF_Control")
	Panel:SetDark(true)

	return Panel
end

function PANEL:AddCheckbox(Text)
	local Panel = self:AddPanel("DCheckBoxLabel")
	Panel:SetText(Text or "Checkbox")
	Panel:SetFont("XCF_Control")
	Panel:SetDark(true)

	function Panel:BindToDataVar(DataVar)
		self:BindToDataVarAdv(DataVar, "SetChecked", "GetChecked", "OnChange")
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
	Panel:SetDark(true)

	Panel.Label:SetFont("XCF_Control")

	function Panel:BindToDataVar(DataVar)
		self:BindToDataVarAdv(DataVar, "SetValue", "GetValue", "OnValueChanged")
	end

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

	function Wang:BindToDataVar(DataVar)
		Wang:BindToDataVarAdv(DataVar, "SetValue", "GetValue", "OnValueChanged")
	end

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

function PANEL:AddTextEntry(LabelText)
	local Base = self:AddPanel("XCF_Panel")

	local Label = Base:AddLabel(LabelText)
	local Entry = Base:AddPanel("DTextEntry")

	Label:Dock(LEFT)

	function Entry:BindToDataVar(DataVar)
		self:BindToDataVarAdv(DataVar, "SetText", "GetText", "OnTextChanged")
	end

	return Entry, Base, Label
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

	Base.varX = Base:AddSlider(Title .. " X", 0, 2, 2)
	Base.varY = Base:AddSlider(Title .. " Y", 0, 2, 2)
	Base.varZ = Base:AddSlider(Title .. " Z", 0, 2, 2)

	-- TODO: Refactor this and other panel binds to reduce code duplication?

	-- Binds three sliders to a vector DataVar
	function Base:BindToDataVar(DataVar)
		local suppress = false

		local function GetValue()
			return Vector(self.varX:GetValue(), self.varY:GetValue(), self.varZ:GetValue())
		end

		local function SetValue(vec)
			suppress = true
			self.varX:SetValue(vec.x)
			self.varY:SetValue(vec.y)
			self.varZ:SetValue(vec.z)
			suppress = false
		end

		local function PushToDataVar()
			if suppress then return end
			XCF.SetClientData(DataVar, GetValue())
		end

		-- When any one slider changes, push the new vector to the DataVar
		self.varX:XCFDefineOnChanged("OnValueChanged", PushToDataVar)
		self.varY:XCFDefineOnChanged("OnValueChanged", PushToDataVar)
		self.varZ:XCFDefineOnChanged("OnValueChanged", PushToDataVar)

		self.varX:XCFDefineSetter("SetValue", PushToDataVar)
		self.varY:XCFDefineSetter("SetValue", PushToDataVar)
		self.varZ:XCFDefineSetter("SetValue", PushToDataVar)

		-- When the datavar changes, update all sliders.
		local HookID = "XCF_Bind_" .. tostring(self) .. "_" .. DataVar
		hook.Add("XCF_OnDataVarChanged", HookID, function(changedKey, value)
			if changedKey ~= DataVar then return end
			if not IsValid(self) then hook.Remove("XCF_OnDataVarChanged", HookID) return end

			suppress = true
			SetValue(value)
			suppress = false
		end)

		-- Initialize with current/default value
		local initial = CLIENT and XCF.GetClientData(DataVar) or XCF.GetServerData(DataVar)
		if initial then
			SetValue(initial)
		end
	end

	return Base
end

-- TODO: Add graph element

-- Must be after methods are attached to the PANEL table.
derma.DefineControl("XCF_Panel", "", PANEL, "Panel")