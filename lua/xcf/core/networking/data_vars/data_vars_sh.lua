local XCF = XCF

do -- Macros for defining data variables and their types
	XCF.DataVarTypesByName = XCF.DataVarTypesByName or {} -- Maps name -> type definition

	local TypeCounter = 1
	function XCF.DefineDataVarType(Name, ReadFunc, WriteFunc, Options)
		local NewDataVarType = {
			Name = Name,
			UUID = TypeCounter,
			Read = ReadFunc,
			Write = WriteFunc,
			Options = Options or {},
		}
		TypeCounter = TypeCounter + 1
		XCF.DataVarTypesByName[Name] = NewDataVarType
		return NewDataVarType
	end

	XCF.DataVars = XCF.DataVars or {} -- Maps UUID -> variable definition
	XCF.DataVarsByScopeAndName = XCF.DataVarsByScopeAndName or {} -- Maps scope -> name -> variable definition
	XCF.DataVarScopesOrdered = XCF.DataVarScopesOrdered or {} -- Maps scope -> ordered list of variable names (for menu generation)

	--- Defines data variable on the client
	local VarCounter = 1
	function XCF.DefineDataVar(Name, Scope, Type, Default, Options)
		local ExistingDataVar = XCF.DataVarsByScopeAndName[Scope] and XCF.DataVarsByScopeAndName[Scope][Name]

		local NewDataVar = {
			Name = Name,
			Scope = Scope,
			UUID = VarCounter,
			Type = XCF.DataVarTypesByName[Type],
			Default = Default,
			Options = Options or {},
			Values = ExistingDataVar and ExistingDataVar.Values or {},
		}

		-- Only change UUID / Order if this is a new variable.
		if not ExistingDataVar then
			-- Add to ordered list of scopes
			XCF.DataVarScopesOrdered[Scope] = XCF.DataVarScopesOrdered[Scope] or {}
			table.insert(XCF.DataVarScopesOrdered[Scope], Name)
			XCF.DataVars[VarCounter] = NewDataVar
			VarCounter = VarCounter + 1
		end

		XCF.DataVarsByScopeAndName[Scope] = XCF.DataVarsByScopeAndName[Scope] or {}
		XCF.DataVarsByScopeAndName[Scope][Name] = NewDataVar

		return NewDataVar
	end
end

do -- Managing data variable synchronization and networking
	local XCF_DATA_VAR_LIMIT_EXPONENT = 8 -- Maximum number of data vars allowed as an exponent of 2
	local XCF_DATA_VAR_MAX_MESSAGE_SIZE = 128 -- Maximum size of a data var message in bytes

	if SERVER then util.AddNetworkString("XCF_DV_NET") end

	-- TODO: Add queue for rate limitting per variable (and forcing option)

	local function StartWriteDataVar(DataVar, Value, SyncServer)
		net.Start("XCF_DV_NET")
		net.WriteUInt(DataVar.UUID, XCF_DATA_VAR_LIMIT_EXPONENT)
		net.WriteBool(SyncServer) -- Whether we are synchronizing server data or client data
		DataVar.Type.Write(Value)
	end

	--- Synchronizes a data variable change across the network
	--- Called from server:
	---		XCF.SetDataVar(Name, Scope, Value) -> Same as "Server" case (default)
	--- 	XCF.SetDataVar(Name, Scope, Value, "Server") -> Updates a server variable and broadcasts to all clients
	---		XCF.SetDataVar(Name, Scope, Value, Player) -> Updates a client variable for a specific player and sends to that player
	--- Called from client:
	---		XCF.SetDataVar(Name, Scope, Value) -> Same as LocalPlayer() case (default)
	--- 	XCF.SetDataVar(Name, Scope, Value, LocalPlayer()) -> Updates a client variable and sends to the server, but you must use the local player
	--- 	XCF.SetDataVar(Name, Scope, Value, "Server") -> Updates a client variable for the local player and sends to the server
	function XCF.SetDataVar(Name, Scope, Value, ToSync)
		ToSync = ToSync or (CLIENT and LocalPlayer()) or "Server" -- default values

		-- Only do stuff if something changes
		local DataVar = XCF.DataVarsByScopeAndName[Scope][Name]
		if DataVar.Values[ToSync] ~= Value then
			DataVar.Values[ToSync] = Value

			local SyncServer = ToSync == "Server"
			StartWriteDataVar(DataVar, Value, SyncServer)

			if CLIENT and SyncServer and not XCF.CanSetServerData(LocalPlayer()) then return end -- Don't allow unauthorized clients to send server data

			if SERVER then
				if SyncServer then net.Broadcast() -- Broadcast server change to all clients
				else net.Send(ToSync) end -- Send specific client change to that client
			else
				if SyncServer then net.SendToServer() -- Send server change to server
				else net.SendToServer() end -- Send client change to server
			end

			-- print("Sent data var", XCF.DataVarIDsToNames[DataVar.UUID], "with value", Value)
			hook.Run("XCF_OnDataVarChanged", DataVar.Name, DataVar.Scope, Value) -- Notify our realm before we send
		end
	end

	-- Handle incoming data var updates
	net.Receive("XCF_DV_NET", function(len, ply)
		if len > (XCF_DATA_VAR_MAX_MESSAGE_SIZE * 8) then return end

		local ID = net.ReadUInt(XCF_DATA_VAR_LIMIT_EXPONENT)
		local DataVar = XCF.DataVars[ID]
		if not DataVar then return end

		local SyncServerRealm = net.ReadBool()
		local Value = DataVar.Type.Read()

		-- Unauthorized clients cannot set the server's view of the data
		if SERVER and SyncServerRealm and not XCF.CanSetServerData(ply) then return end

		if SERVER then
			if SyncServerRealm then DataVar.Values.Server = Value
			else DataVar.Values[ply] = Value end
		else
			if SyncServerRealm then DataVar.Values.Server = Value
			else DataVar.Values[LocalPlayer()] = Value end
		end
		hook.Run("XCF_OnDataVarChanged", DataVar.Name, DataVar.Scope, Value) -- Notify any listeners that the variable has changed
	end)

	if SERVER then
		-- Cleanup values when a player leaves to avoid stale data
		hook.Add("PlayerDisconnected", "XCF_CleanupDataVars", function(ply)
			for _, dv in ipairs(XCF.DataVars) do
				dv.Values[ply] = nil
			end
		end)

		-- When a player loads in, send them all the server data so they have the correct values
		hook.Add("XCF_OnLoadPlayer", "XCF_FullServerDataSync", function(ply)
			if not IsValid(ply) then return end

			for _, DataVar in ipairs(XCF.DataVars) do
				local value = DataVar.Values.Server
				if value ~= nil then
					StartWriteDataVar(DataVar, value, true)
					net.Send(ply)
				end
			end
		end)
	end

	--- Returns whether a client is allowed to set a server datavars
	function XCF.CanSetServerData(Player)
		if not IsValid(Player) then return true end -- No player, probably the server
		if Player:IsSuperAdmin() then return true end

		return XCF.GetRealmData("ServerDataAllowAdmin", nil, true) and Player:IsAdmin()
	end

	--- Gets the value of a data variable for the given Player/"Server"
	function XCF.GetDataVar(Name, Scope, Player, IgnoreUnset)
		local DataVar = XCF.DataVarsByScopeAndName[Scope][Name]
		if not DataVar then return end

		local Value = DataVar.Values[Player or (CLIENT and LocalPlayer()) or "Server"]
		if not Value and DataVar.Default ~= nil then return DataVar.Default end
		return Value or (not IgnoreUnset and DataVar.Default)
	end

	--- Sets all data variables at once using a nested table format: Data[Scope][Name] = Value.
	function XCF.SetDataVars(Data, Player)
		for scope, _ in pairs(XCF.DataVarsByScopeAndName) do
			for name, _ in pairs(XCF.DataVarsByScopeAndName[scope] or {}) do
				if Data[scope] and Data[scope][name] ~= nil then XCF.SetDataVar(name, scope, Data[scope][name], Player) end
			end
		end
	end

	--- Gets all data variables at once in a nested table format: Data[Scope][Name] = Value.
	function XCF.GetDataVars(Scope, Player, IgnoreUnset)
		local Result = {}
		for scope, _ in pairs(XCF.DataVarsByScopeAndName) do
			if Scope and scope ~= Scope then continue end
			for name, _ in pairs(XCF.DataVarsByScopeAndName[scope] or {}) do
				Result[scope] = Result[scope] or {}
				Result[scope][name] = XCF.GetDataVar(name, scope, Player, IgnoreUnset)
			end
		end
		return Result
	end
end

do -- Automatic Menu Generation
	function XCF.CreatePanelFromDataVar(Menu, DataVar)
		if not DataVar.Type.Options.CreatePanel then return end
		local Panel = DataVar.Type.Options.CreatePanel(Menu, DataVar)
		-- print(Panel, DataVar.Name, DataVar.Scope)
		if Panel.BindToDataVar then Panel:BindToDataVar(DataVar.Name, DataVar.Scope) end
		if DataVar.Options.Tooltip then Panel:SetTooltip(DataVar.Options.Tooltip) end
		return Panel
	end

	function XCF.CreatePanelsFromDataVars(Menu, Scope)
		local Panels = {}
		for _, Name in ipairs(XCF.DataVarScopesOrdered[Scope] or {}) do
			local DataVar = XCF.DataVarsByScopeAndName[Scope][Name]
			if DataVar then
				Panels[Name] = XCF.CreatePanelFromDataVar(Menu, DataVar)
			end
		end
		return Panels
	end
end

do -- Defining default data variables and types
	local CreateSliderMenu = function(Menu, DataVar)
		return Menu:AddSlider(DataVar.Name, DataVar.Options.Min, DataVar.Options.Max, 2)
	end

	local CreateWangMenu = function(Menu, DataVar)
		return Menu:AddNumberWang(DataVar.Name, DataVar.Options.Min, DataVar.Options.Max, 2)
	end

	-- Basic types
	XCF.DefineDataVarType("Bool", net.ReadBool, net.WriteBool, {
		CreatePanel = function(Menu, DataVar) return Menu:AddCheckbox(DataVar.Name) end,
	})

	XCF.DefineDataVarType("String", net.ReadString, net.WriteString, {
		CreatePanel = function(Menu, DataVar) return Menu:AddTextEntry(DataVar.Name) end,
	})

	XCF.DefineDataVarType("Float", net.ReadFloat, net.WriteFloat, {
		CreatePanel = CreateSliderMenu,
	})

	XCF.DefineDataVarType("Double", net.ReadDouble, net.WriteDouble, {
		CreatePanel = CreateSliderMenu,
	})

	XCF.DefineDataVarType("Color", net.ReadColor, net.WriteColor, {})
	XCF.DefineDataVarType("Angle", net.ReadAngle, net.WriteAngle, {})

	XCF.DefineDataVarType("Vector", net.ReadVector, net.WriteVector, {
		CreatePanel = function(Menu, DataVar) return Menu:AddVec3Slider(DataVar.Name, DataVar.Options.Min, DataVar.Options.Max, 2) end,
	})

	XCF.DefineDataVarType("Normal", net.ReadNormal, net.WriteNormal, {})
	XCF.DefineDataVarType("Entity", net.ReadEntity, net.WriteEntity, {})
	XCF.DefineDataVarType("Player", net.ReadPlayer, net.WritePlayer, {})
	XCF.DefineDataVarType("Table", net.ReadTable, net.WriteTable, {})
	XCF.DefineDataVarType("Data", net.ReadData, net.WriteData, {})
	XCF.DefineDataVarType("Bit", net.ReadBit, net.WriteBit, {})

	-- Signed integers (1 to 32 bits)
	for i = 1, 32 do
		XCF.DefineDataVarType("Int" .. i, function() return net.ReadInt(i) end, function(v) net.WriteInt(v, i) end, {
			CreatePanel = CreateWangMenu,
		})
	end

	-- Unsigned integers (1 to 32 bits)
	for i = 1, 32 do
		XCF.DefineDataVarType("UInt" .. i, function() return net.ReadUInt(i) end, function(v) net.WriteUInt(v, i) end, {
			CreatePanel = CreateWangMenu,
		})
	end

	----------------------------------------------------------

	-- Test variable
	XCF.DefineDataVar("TestVar", "TestScope", "String", "TestValue")

	XCF.DefineDataVar("ServerDataAllowAdmin", "ServerSettings", "Bool", false)

	XCF.DefineDataVar("SpawnClass", "ToolGun", "String", "xcf_testent")
end