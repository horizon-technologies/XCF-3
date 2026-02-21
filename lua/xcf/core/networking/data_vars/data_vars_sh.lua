local XCF = XCF

do -- Macros for defining data variables and their types
	XCF.DataVarTypes = XCF.DataVarTypes or {} -- Maps type names to type definitions
	XCF.DataVars = XCF.DataVars or {} -- Maps variable names to variable definitions
	XCF.DataVarIDsToNames = XCF.DataVarIDsToNames or {} -- Maps variable UUIDs to their names for reverse lookup on receive
	XCF.DataVarGroups = XCF.DataVarGroups or {} -- Maps group names to lists of variable names

	local TypeCounter = 0
	function XCF.DefineDataVarType(Name, ReadFunc, WriteFunc, Options)
		XCF.DataVarTypes[Name] = {
			UUID = TypeCounter,
			Read = ReadFunc,
			Write = WriteFunc,
			Options = Options,
		}
		TypeCounter = TypeCounter + 1
		return XCF.DataVarTypes[Name]
	end

	--- Defines data variable on the client
	local VarCounter = 0
	function XCF.DefineDataVar(Name, Group, Type, Default, Options)
		local ExistingDataVar = XCF.DataVars[Name]

		local NewDataVar = {
			UUID = VarCounter,
			Group = Group,
			Type = Type,
			Default = Default,
			Options = Options,
			Values = ExistingDataVar and ExistingDataVar.Values or {} -- Preserve existing values if redefining the variable,
		}

		XCF.DataVars[Name] = NewDataVar

		XCF.DataVarIDsToNames[VarCounter] = Name
		XCF.DataVarGroups[Group] = XCF.DataVarGroups[Group] or {}
		XCF.DataVarGroups[Group][Name] = true

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
	end

	--- Synchronizes server data with the other realm
	--- Called from server: Sends to the specific player if specified, or all players if nil
	--- Called from client: Player argument does nothing
	function XCF.SetServerData(Key, Value, TargetPlayer)
		local DataVar = XCF.DataVars[Key]
		if DataVar.Values[ServerKey] ~= Value then
			DataVar.Values[ServerKey] = Value
			if SERVER then SendDataVar(DataVar, Value, true, TargetPlayer)
			else SendDataVar(DataVar, Value, true) end
		end
	end

	--- Synchronizes client data with the other realm
	--- Called from server: Sends to the specific player if specified, or all players if nil
	--- Called from client: Player argument does nothing
	function XCF.SetClientData(Key, Value, TargetPlayer)
		local DataVar = XCF.DataVars[Key]

		-- Called from client: use local player
		-- Called from server: use player argument or all players if nil
		local PlayersToSync = CLIENT and {LocalPlayer()} or (TargetPlayer and {TargetPlayer} or player.GetAll())

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
		local Key = XCF.DataVarIDsToNames[ID]
		if not Key then return end

		local DataVar = XCF.DataVars[Key]
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
		hook.Run("XCF_OnDataVarChanged", Key, Value) -- Notify any listeners that the variable has changed
	end)

	if SERVER then
		-- Cleanup values when a player leaves to avoid stale data
		hook.Add("PlayerDisconnected", "XCF_CleanupDataVars", function(ply)
			for _, dv in pairs(XCF.DataVars) do
				dv.Values[ply] = nil
			end
		end)

		-- When a player loads in, send them all the server data so they have the correct values
		hook.Add("XCF_OnLoadPlayer", "XCF_FullServerDataSync", function(ply)
			if not IsValid(ply) then return end

			for _, DataVar in pairs(XCF.DataVars) do
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

		return XCF.GetServerData("ServerDataAllowAdmin") and Player:IsAdmin()
	end

	--- Returns the value of a client data variable for a specific player (or local player if on client)
	--- If not set, returns the default value for the variable from its definition
	function XCF.GetClientData(Key, Player, IgnoreDefaults)
		if CLIENT then Player = LocalPlayer() end
		local DataVar = XCF.DataVars[Key]
		if not DataVar then return end
		return DataVar.Values[Player] or (IgnoreDefaults and nil or DataVar.Default)
	end

	--- Returns the value of a server data variable
	--- If not set, returns the default value for the variable from its definition
	function XCF.GetServerData(Key, _, IgnoreDefaults)
		local DataVar = XCF.DataVars[Key]
		if not DataVar then return end
		return DataVar.Values[ServerKey] or (IgnoreDefaults and nil or DataVar.Default)
	end

	--- Helper that assumes server realm on the server or the local player on the client
	function XCF.GetSharedData(Key, IgnoreDefaults)
		if SERVER then return XCF.GetServerData(Key, nil, IgnoreDefaults)
		else return XCF.GetClientData(Key, nil, IgnoreDefaults) end
	end

	--- Helper that assumes server realm on the server or the local player on the client
	function XCF.SetSharedData(Key, Value)
		if SERVER then XCF.SetServerData(Key, Value)
		else XCF.SetClientData(Key, Value) end
	end
end

do -- Handling persistence across sessions through file storage (for presets / server settings)
	local BasePath = "xcf_data_vars/"

	-- STILL WIP

	--- Load data vars from a file into the local player / server
	function XCF.LoadDataVarsFromFile(SubPath, Group)
		local Path = BasePath .. SubPath
		if not file.Exists(Path, "DATA") then return end

		local Data = util.JSONToTable(file.Read(Path, "DATA"))
		if not Data then return end

		for Name, _ in pairs(XCF.DataVarGroups[Group] or {}) do
			if Data[Name] ~= nil then
				XCF.SetSharedData(Name, Data[Name])
			end
		end
	end

	--- Save data vars to a file from the local player / server.
	function XCF.SaveDataVarsToFile(SubPath, Group)
		local Path = BasePath .. SubPath
		local Data = {}

		-- Implicitly avoids saving any variables that aren't defined in the group (key = nil)
		for Name, _ in pairs(XCF.DataVarGroups[Group] or {}) do
			local DataVar = XCF.DataVars[Name]
			if DataVar then Data[Name] = XCF.GetSharedData(Name, true) end
		end

		-- print(util.TableToJSON(Data, true))

		file.Write(Path, util.TableToJSON(Data, true))
	end
end

-- TODO: Add verification for security reasons
do -- Defining default data variables and types
	-- Basic types
	XCF.DefineDataVarType("Bool",        net.ReadBool,        net.WriteBool)
	XCF.DefineDataVarType("String",      net.ReadString,      net.WriteString)
	XCF.DefineDataVarType("Float",       net.ReadFloat,       net.WriteFloat)
	XCF.DefineDataVarType("Double",      net.ReadDouble,      net.WriteDouble)
	XCF.DefineDataVarType("Color",       net.ReadColor,       net.WriteColor)
	XCF.DefineDataVarType("Angle",       net.ReadAngle,       net.WriteAngle)
	XCF.DefineDataVarType("Vector",      net.ReadVector,      net.WriteVector)
	XCF.DefineDataVarType("Normal",      net.ReadNormal,      net.WriteNormal)
	XCF.DefineDataVarType("Entity",      net.ReadEntity,      net.WriteEntity)
	XCF.DefineDataVarType("Player",      net.ReadPlayer,      net.WritePlayer)
	XCF.DefineDataVarType("Table",       net.ReadTable,       net.WriteTable)
	XCF.DefineDataVarType("Data",        net.ReadData,        net.WriteData)
	XCF.DefineDataVarType("Bit",         net.ReadBit,         net.WriteBit)

	-- Signed integers (1 to 32 bits)
	for i = 1, 32 do
		XCF.DefineDataVarType("Int" .. i, function() return net.ReadInt(i) end, function(v) net.WriteInt(v, i) end, {})
	end

	-- Unsigned integers (1 to 32 bits)
	for i = 1, 32 do
		XCF.DefineDataVarType("UInt" .. i, function() return net.ReadUInt(i) end, function(v) net.WriteUInt(v, i) end, {})
	end

	----------------------------------------------------------

	-- Test variable
	XCF.DefineDataVar("TestVar", "TestGroup", XCF.DataVarTypes.String)

	XCF.DefineDataVar("ServerDataAllowAdmin", "ServerSettings", XCF.DataVarTypes.Bool, false)
end