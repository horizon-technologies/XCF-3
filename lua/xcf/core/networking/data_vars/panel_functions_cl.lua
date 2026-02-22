local XCF = XCF
local PanelMeta = FindMetaTable("Panel")

XCF.DebugStorePanels = XCF.DebugStorePanels or {}

--- Attaches a panel to the debug store for easy access in the console. Usage: Panel:XCFDebug("MyPanel").
--- The panel can then be accessed via XCF.DebugStorePanels["MyPanel"]
function PanelMeta:XCFDebug(Name)
	XCF.DebugStorePanels[Name] = self
	return self
end

--- Defines a function that runs when a panel's value is changed by the user.
--- @param changeName string The name of the panel's OnValueChanged-like function to detour (e.g. "OnValueChanged" for DNumSlider, "OnTextChanged" for DTextEntry)
--- @param callback function The function to run when the value is changed. Will be passed the panel and any arguments from the original function.
function PanelMeta:XCFDefineOnChanged(changeName, callback)
	local oldFunc = self[changeName]
	self[changeName] = function(pnl, ...)
		oldFunc(pnl, ...)
		callback(pnl, ...)
	end
end

--- Defines a function that runs when a panel's value is changed programatically (via setter function)
--- @param setterName string The name of the panel's setter function to detour (e.g. "SetValue" for DNumSlider, "SetText" for DTextEntry)
--- @param callback function The function to run when the value is changed. Will be passed the panel and any arguments from the original function.
function PanelMeta:XCFDefineSetter(setterName, callback)
	local oldFunc = self[setterName]
	self[setterName] = function(pnl, ...)
		oldFunc(pnl, ...)
		callback(pnl, ...)
	end
end

--- Binds a panel to a data variable, keeping them in sync in both directions.
--- Whenever the panel's value is changed by the user or programmatically, the data variable will be updated.
--- Whenever the data variable is updated (by the server or client), the panel's value will be updated.
--- @param DataVar string The name of the data variable to bind to
--- @param setterName string The name of the panel's setter function (see XCFDefineSetter)
--- @param getterName string The name of the panel's getter function (see XCFDefineOnChanged)
--- @param changeName string The name of the panel's OnVAlueChanged-like function to detour (see XCFDefineOnChanged)
function PanelMeta:BindToDataVarAdv(DataVar, setterName, getterName, changeName)
	local suppress = false -- Need to prevent infinite loops when both panel and DataVar update each other

	-- Panel -> DataVar (user changes)
	if changeName then
		self:XCFDefineOnChanged(changeName, function(pnl)
			if suppress then return end
			local value = pnl[getterName](pnl)
			XCF.SetClientData(DataVar, value)
		end)
	end

	-- Setter -> DataVar (programmatic changes)
	self:XCFDefineSetter(setterName, function(pnl, ...)
		if suppress then return end
		local value = pnl[getterName](pnl)
		XCF.SetClientData(DataVar, value)
	end)

	-- DataVar -> Panel (network updates)
	local HookID = "XCF_Bind_" .. tostring(self) .. "_" .. DataVar
	hook.Add("XCF_OnDataVarChanged", HookID, function(key, value)
		if key ~= DataVar then return end
		if not IsValid(self) then hook.Remove("XCF_OnDataVarChanged", HookID) return end
		print("DataVar", DataVar, "changed to", value, "updating panel", self)

		suppress = true
		self[setterName](self, value)
		suppress = false
	end)

	-- Initialize with current / default value (usnet values remain unset)
	local initial = CLIENT and XCF.GetClientData(DataVar) or XCF.GetServerData(DataVar)
	if initial ~= nil then
		suppress = true
		self[setterName](self, initial)
		suppress = false
	end
end

-- hook.Add("XCF_OnDataVarChanged", "DebugPrintTestVar", function(DataVar, Value)
-- 	print(DataVar .. " changed to:", Value)
-- end)