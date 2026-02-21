local XCF = XCF
XCF.DebugStorePanels = XCF.DebugStorePanels or {}

local PanelMeta = FindMetaTable("Panel")

function PanelMeta:XCFDebug(Name)
	XCF.DebugStorePanels[Name] = self
	return self
end

function PanelMeta:DefineOnChanged(hookName, callback)
	local oldFunc = self[hookName]
	self[hookName] = function(pnl, ...)
		oldFunc(pnl, ...)
		callback(pnl, ...)
	end
end

function PanelMeta:DefineSetter(setterName, callback)
	local oldFunc = self[setterName]
	self[setterName] = function(pnl, ...)
		oldFunc(pnl, ...)
		callback(pnl, ...)
	end
end

function PanelMeta:BindToDataVar(Key, setterName, getterName, changeHookName)
	local suppress = false -- Need to prevent infinite loops when both panel and DataVar update each other

	-- Panel -> DataVar (user changes)
	if changeHookName then
		self:DefineOnChanged(changeHookName, function(pnl)
			if suppress then return end
			local value = pnl[getterName](pnl)
			XCF.SetClientData(Key, value)
		end)
	end

	-- Setter -> DataVar (programmatic changes)
	self:DefineSetter(setterName, function(pnl, ...)
		if suppress then return end
		local value = pnl[getterName](pnl)
		XCF.SetClientData(Key, value)
	end)

	-- DataVar -> Panel (network updates)
	hook.Add("XCF_OnDataVarChanged", "XCF_Bind_" .. tostring(self) .. "_" .. Key, function(changedKey, value)
		if changedKey ~= Key then return end
		if not IsValid(self) then return end

		suppress = true
		self[setterName](self, value)
		suppress = false
	end)

	-- Initialize with current / default value (usnet values remain unset)
	local initial = CLIENT and XCF.GetClientData(Key) or XCF.GetServerData(Key)
	if initial ~= nil then
		suppress = true
		self[setterName](self, initial)
		suppress = false
	end
end

-- hook.Add("XCF_OnDataVarChanged", "DebugPrintTestVar", function(Key, Value)
-- 	print(Key .. " changed to:", Value)
-- end)

-- function PanelMeta:BindToDataVar(Name, FromPanel, FromNetwork) end