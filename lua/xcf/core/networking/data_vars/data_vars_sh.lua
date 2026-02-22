local XCF = XCF

-- TODO: Maybe consider using group as a scope to avoid name conflicts?
-- TODO: determine if there are looping issues with the menu

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
	XCF.DataVarsByGroupAndName = XCF.DataVarsByGroupAndName or {} -- Maps group -> name -> variable definition
	XCF.DataVarGroupsOrdered = XCF.DataVarGroupsOrdered or {} -- Maps group -> ordered list of variable names (for menu generation)

	--- Defines data variable on the client
	local VarCounter = 1
	function XCF.DefineDataVar(Name, Group, Type, Default, Options)
		local ExistingDataVar = XCF.DataVarsByGroupAndName[Group] and XCF.DataVarsByGroupAndName[Group][Name]

		local NewDataVar = {
			Name = Name,
			Group = Group,
			UUID = VarCounter,
			Type = Type,
			Default = Default,
			Options = Options or {},
			Values = ExistingDataVar and ExistingDataVar.Values or {} -- Preserve existing values if redefining the variable,
		}

		XCF.DataVars[VarCounter] = NewDataVar
		XCF.DataVarsByGroupAndName[Group] = XCF.DataVarsByGroupAndName[Group] or {}
		XCF.DataVarsByGroupAndName[Group][Name] = NewDataVar

		-- Add to ordered list of groups
		XCF.DataVarGroupsOrdered[Group] = XCF.DataVarGroupsOrdered[Group] or {}
		table.insert(XCF.DataVarGroupsOrdered[Group], Name)

		VarCounter = VarCounter + 1
		return NewDataVar
	end
end

do -- Managing data variable synchronization and networking
	local XCF_DATA_VAR_LIMIT_EXPONENT = 8 -- Maximum number of data vars allowed as an exponent of 2
	local XCF_DATA_VAR_MAX_MESSAGE_SIZE = 128 -- Maximum size of a data var message in bytes

	if SERVER then util.AddNetworkString("XCF_DV_NET") end

	-- TODO: Add queue for rate limitting per variable (and forcing option)
	local ServerKey = "Server"

	-- Internal helper to send a datavar across realms
	local function SendDataVar(DataVar, Value, SyncServerRealm, TargetPlayer)
		net.Start("XCF_DV_NET")
		net.WriteUInt(DataVar.UUID, XCF_DATA_VAR_LIMIT_EXPONENT)
		net.WriteBool(SyncServerRealm)
		DataVar.Type.Write(Value)

		if SERVER then
			if TargetPlayer then net.Send(TargetPlayer)
			else net.Broadcast() end
		else
			net.SendToServer()
		end
		-- print("Sent data var", XCF.DataVarIDsToNames[DataVar.UUID], "with value", Value)
		hook.Run("XCF_OnDataVarChanged", DataVar.Name, DataVar.Group, Value) -- Notify our realm before we send
	end

	--- Synchronizes server data with the other realm
	--- Called from server: Sends to the specific player if specified, or all players if nil
	--- Called from client: Player argument does nothing
	function XCF.SetServerData(Name, Group, Value, TargetPlayer)
		local DataVar = XCF.DataVarsByGroupAndName[Group][Name]
		if DataVar.Values[ServerKey] ~= Value then
			DataVar.Values[ServerKey] = Value
			if SERVER then SendDataVar(DataVar, Value, true, TargetPlayer)
			else SendDataVar(DataVar, Value, true) end
		end
	end

	--- Synchronizes client data with the other realm
	--- Called from server: Sends to the specific player if specified, or all players if nil
	--- Called from client: Player argument does nothing
	function XCF.SetClientData(Name, Group, Value, TargetPlayer)
		local DataVar = XCF.DataVarsByGroupAndName[Group][Name]

		-- Called from client: use local player
		-- Called from server: use player argument or all players if nil
		local PlayersToSync = CLIENT and {LocalPlayer()} or (TargetPlayer and {TargetPlayer} or player.GetAll())
		-- print("SetClientData", Key, Value, TargetPlayer)
		-- PrintTable(PlayersToSync)

		-- Iterate over the player(s) and update their values
		for _, ply in ipairs(PlayersToSync) do
			if DataVar.Values[ply] ~= Value then
				DataVar.Values[ply] = Value
				SendDataVar(DataVar, Value, false, ply)  -- Send update immediately after modification
			end
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
			if SyncServerRealm then DataVar.Values[ServerKey] = Value
			else DataVar.Values[ply] = Value end
		else
			if SyncServerRealm then DataVar.Values[ServerKey] = Value
			else DataVar.Values[LocalPlayer()] = Value end
		end
		hook.Run("XCF_OnDataVarChanged", DataVar.Name, DataVar.Group, Value) -- Notify any listeners that the variable has changed
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
				local value = DataVar.Values["Server"]
				if value ~= nil then
					SendDataVar(DataVar, value, true, ply)
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

	--- Returns the value of a client data variable for a specific player (or local player if on client)
	--- If not set, returns the default value for the variable from its definition
	function XCF.GetClientData(Name, Group, Player, IgnoreDefaults)
		if CLIENT then Player = LocalPlayer() end
		local DataVar = XCF.DataVarsByGroupAndName[Group][Name]
		if not DataVar then return end
		if not IgnoreDefaults and DataVar.Values[Player] == nil then return DataVar.Default end
		return DataVar.Values[Player]
	end

	--- Returns the value of a server data variable
	--- If not set, returns the default value for the variable from its definition
	function XCF.GetServerData(Name, Group, _, IgnoreDefaults)
		local DataVar = XCF.DataVarsByGroupAndName[Group][Name]
		if not DataVar then return end
		if not IgnoreDefaults and DataVar.Values[ServerKey] == nil then return DataVar.Default end
		return DataVar.Values[ServerKey]
	end

	--- Calls GetClientData or GetServerData based on the realm
	function XCF.GetRealmData(Name, Group, IgnoreDefaults)
		if SERVER then return XCF.GetServerData(Name, Group, nil, IgnoreDefaults)
		else return XCF.GetClientData(Name, Group, nil, IgnoreDefaults) end
	end

	--- Calls SetClientData or SetServerData based on the realm
	function XCF.SetRealmData(Name, Group, Value)
		if SERVER then XCF.SetServerData(Name, Group, Value)
		else XCF.SetClientData(Name, Group, Value) end
	end
end

do -- Automatic Menu Generation
	function XCF.CreatePanelFromDataVar(Menu, DataVar)
		if not DataVar.Type.Options.CreatePanel then return end
		local Panel = DataVar.Type.Options.CreatePanel(Menu, DataVar)
		return Panel
	end

	function XCF.CreatePanelsFromDataVars(Menu, Group)
		local Panels = {}
		for _, Name in ipairs(XCF.DataVarGroupsOrdered[Group] or {}) do
			local DataVar = XCF.DataVarsByGroupAndName[Group][Name]
			if DataVar then
				Panels[Name] = XCF.CreatePanelFromDataVar(Menu, DataVar)
			end
		end
		return Panels
	end
end

do -- Defining default data variables and types
	local CreateSliderMenu = function(Menu, DataVar)
		return Menu:AddSlider(DataVar.Name, DataVar.Options.Min, DataVar.Options.Max, 2):BindToDataVar(DataVar.Name, DataVar.Group)
	end

	local CreateWangMenu = function(Menu, DataVar)
		return Menu:AddNumberWang(DataVar.Name, DataVar.Options.Min, DataVar.Options.Max, 2):BindToDataVar(DataVar.Name, DataVar.Group)
	end

	-- Basic types
	XCF.DefineDataVarType("Bool", net.ReadBool, net.WriteBool, {
		CreatePanel = function(Menu, DataVar) return Menu:AddCheckbox(DataVar.Name):BindToDataVar(DataVar.Name, DataVar.Group) end,
	})

	XCF.DefineDataVarType("String", net.ReadString, net.WriteString, {
		CreatePanel = function(Menu, DataVar) return Menu:AddTextEntry(DataVar.Name):BindToDataVar(DataVar.Name, DataVar.Group) end,
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
		CreatePanel = function(Menu, DataVar) return Menu:AddVec3Slider(DataVar.Name, DataVar.Options.Min, DataVar.Options.Max, 2):BindToDataVar(DataVar.Name, DataVar.Group) end,
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
	XCF.DefineDataVar("TestVar", "TestGroup", XCF.DataVarTypesByName.String)

	XCF.DefineDataVar("ServerDataAllowAdmin", "ServerSettings", XCF.DataVarTypesByName.Bool, false)

	XCF.DefineDataVar("SpawnClass", "ToolGun", XCF.DataVarTypesByName.String, "xcf_testent")
end