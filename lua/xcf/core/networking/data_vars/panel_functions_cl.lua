local XCF = XCF
local PanelMeta = FindMetaTable("Panel")

XCF.DebugStorePanels = XCF.DebugStorePanels or {}

--- Attaches a panel to the debug store for easy access in the console. Usage: Panel:XCFDebug("MyPanel").
--- The panel can then be accessed via XCF.DebugStorePanels["MyPanel"]
function PanelMeta:XCFDebug(Name)
	XCF.DebugStorePanels[Name] = self
	return self
end

--- Detours a panel's method, allowing you to run code after the original method
function PanelMeta:HijackAfter(methodName, callback)
	local old = self[methodName]

	self[methodName] = function(pnl, ...)
		local ret = old(pnl, ...)
		callback(pnl, ...)
		return ret
	end

	return old
end

--- Binds a panel to a data variable, keeping them in sync in both directions.
--- Whenever the panel's value is changed by the user or programmatically, the data variable will be updated.
--- Whenever the data variable is updated (by the server or client), the panel's value will be updated.
--- @param DataVar string The name of the data variable to bind to
--- @param setterName string The name of the panel's setter function (e.g. SetValue, SetText, SetChecked, etc.)
--- @param getterName string The name of the panel's getter function (e.g. GetValue, GetText, GetChecked, etc.)
--- @param changeName string The name of the panel's OnVAlueChanged-like function to detour (e.g. OnValueChanged, OnTextChanged, OnCheckedChanged, etc.)
function PanelMeta:BindToDataVarAdv(Name, Scope, setterName, getterName, changeName)
	local suppress = false -- Need to prevent infinite loops when both panel and DataVar update each other

	local function SetValue(value)
		suppress = true
		self[setterName](self, value)
		suppress = false
	end

	-- Panel -> DataVar (user changes)
	local function PushToDataVar(pnl)
		if suppress then return end
		local value = pnl[getterName](pnl)
		XCF.SetClientData(Name, Scope, value)
	end

	self:HijackAfter(changeName, PushToDataVar)
	self:HijackAfter(setterName, PushToDataVar)

	-- DataVar -> Panel (network updates)
	local HookID = "XCF_Bind_" .. tostring(self) .. "_" .. Name .. "_" .. Scope
	hook.Add("XCF_OnDataVarChanged", HookID, function(name, scope, value)
		if name ~= Name or scope ~= Scope then return end
		if not IsValid(self) then hook.Remove("XCF_OnDataVarChanged", HookID) return end

		SetValue(value)
	end)

	-- Initialize with current / default value (unset values remain unset)
	local initial = CLIENT and XCF.GetClientData(Name, Scope) or XCF.GetServerData(Name, Scope)
	if initial ~= nil then
		SetValue(initial)
	end
end

-- hook.Add("XCF_OnDataVarChanged", "DebugPrintTestVar", function(DataVar, Value)
-- 	print(DataVar .. " changed to:", Value)
-- end)