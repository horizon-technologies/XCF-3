local XCF = XCF
local PanelMeta = FindMetaTable("Panel")

XCF.DebugStorePanels = XCF.DebugStorePanels or {}

--- Attaches a panel to the debug store for easy access in the console. Usage: Panel:XCFDebug("MyPanel").
--- The panel can then be accessed via XCF.DebugStorePanels["MyPanel"]
function PanelMeta:XCFDebug(Name)
	XCF.DebugStorePanels[Name] = self
	return self
end

function PanelMeta:XCFHijackBefore(methodName, callback)
	local old = self[methodName]

	self[methodName] = function(pnl, ...)
		callback(pnl, ...)
		return old(pnl, ...)
	end

	return old
end

function PanelMeta:XCFHijackAfter(methodName, callback)
	local old = self[methodName]

	self[methodName] = function(pnl, ...)
		local ret = old(pnl, ...)
		callback(pnl, ...)
		return ret
	end

	return old
end

function PanelMeta:XCFHijackReplace(methodName, callback)
	local old = self[methodName]

	self[methodName] = function(pnl, ...)
		return callback(pnl, old, ...)
	end

	return old
end

--- Binds a panel to a data variable, keeping them in sync in both directions.
--- Whenever the panel's value is changed by the user or programmatically, the data variable will be updated.
--- Whenever the data variable is updated (by the server or client), the panel's value will be updated.
--- @param DataVar string The name of the data variable to bind to
--- @param setterName string The name of the panel's setter function (see XCFDefineSetter)
--- @param getterName string The name of the panel's getter function
--- @param changeName string The name of the panel's OnVAlueChanged-like function to detour (see XCFDefineOnChanged)
function PanelMeta:BindToDataVarAdv(Name, Group, setterName, getterName, changeName)
	local suppress = false -- Need to prevent infinite loops when both panel and DataVar update each other

	-- Panel -> DataVar (user changes)
	local function PushToDataVar(pnl)
		if suppress then return end
		local value = pnl[getterName](pnl)
		XCF.SetClientData(Name, Group, value)
	end

	self:XCFHijackAfter(changeName, PushToDataVar)
	self:XCFHijackAfter(setterName, PushToDataVar)

	-- DataVar -> Panel (network updates)
	local HookID = "XCF_Bind_" .. tostring(self) .. "_" .. Name .. "_" .. Group
	hook.Add("XCF_OnDataVarChanged", HookID, function(name, group, value)
		if name ~= Name or group ~= Group then return end
		if not IsValid(self) then hook.Remove("XCF_OnDataVarChanged", HookID) return end

		suppress = true
		self[setterName](self, value)
		suppress = false
	end)

	-- Initialize with current / default value (unset values remain unset)
	local initial = CLIENT and XCF.GetClientData(Name, Group) or XCF.GetServerData(Name, Group)
	if initial ~= nil then
		suppress = true
		self[setterName](self, initial)
		suppress = false
	end
end

-- hook.Add("XCF_OnDataVarChanged", "DebugPrintTestVar", function(DataVar, Value)
-- 	print(DataVar .. " changed to:", Value)
-- end)