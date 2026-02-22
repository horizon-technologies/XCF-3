local XCF = XCF

-- TODO: Maybe consider using group as a scope to avoid name conflicts?
-- TODO: determine if there are looping issues with the menu

do -- Macros for defining data variables and their types
	XCF.DataVarTypes = XCF.DataVarTypes or {} -- Maps type names to type definitions
	XCF.DataVars = XCF.DataVars or {} -- Maps variable names to variable definitions
	XCF.DataVarIDsToNames = XCF.DataVarIDsToNames or {} -- Maps variable UUIDs to their names for reverse lookup on receive
	XCF.DataVarGroups = XCF.DataVarGroups or {} -- Maps group names to lists of variable names

	local TypeCounter = 0
	function XCF.DefineDataVarType(Name, ReadFunc, WriteFunc, Options)
		XCF.DataVarTypes[Name] = {
			Name = Name,
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
			Name = Name,
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
		-- print("Sent data var", XCF.DataVarIDsToNames[DataVar.UUID], "with value", Value)
		hook.Run("XCF_OnDataVarChanged", DataVar.Name, Value) -- Notify our realm before we send
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
		if not IgnoreDefaults and DataVar.Values[Player] == nil then return DataVar.Default end
		return DataVar.Values[Player]
	end

	--- Returns the value of a server data variable
	--- If not set, returns the default value for the variable from its definition
	function XCF.GetServerData(Key, _, IgnoreDefaults)
		local DataVar = XCF.DataVars[Key]
		if not DataVar then return end
		if not IgnoreDefaults and DataVar.Values[ServerKey] == nil then return DataVar.Default end
		return DataVar.Values[ServerKey]
	end

	--- TODO: Rename these to make their synchronization purpose clearer

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

	-- TODO: May want to ignore defaults and refactor other parts to use this?
	-- Returns the current values of all data variables for a given player (or server if on server)
	function XCF.GetDataVarValues(TargetPlayer)
		local Results = {}
		for Name, DataVar in pairs(XCF.DataVars) do
			Results[Name] = DataVar.Values[TargetPlayer] or DataVar.Default
		end
		return Results
	end
end

-- TODO: Handle automatic persistence and queueing over time. Also have a variable specify if it should be saved on a given realm.
do -- Handling persistence across sessions through file storage (for presets / server settings)
	local BasePath = "xcf/"

	--- Ensures that the specified file and its parent directory exist, creating them if necessary
	function XCF.EnsureFileAndDirectoryExists(BasePath, FileName)
		local DirExists = file.Exists(BasePath, "DATA")
		if not DirExists then
			file.CreateDir(BasePath)
		end

		local FileExists = file.Exists(BasePath .. FileName, "DATA")
		if not FileExists then
			file.Write(BasePath .. FileName, "")
		end
	end

	if SERVER then XCF.EnsureFileAndDirectoryExists(BasePath, "persistence_sv.txt") end
	if CLIENT then XCF.EnsureFileAndDirectoryExists(BasePath, "persistence_cl.txt") end

	--- Load data vars from a file into the local player / server
	--- Only loads variables from the group that are specified in the file
	function XCF.LoadDataVarsFromFile(Name, Group)
		local Path = BasePath .. Name .. ".txt"
		if not file.Exists(Path, "DATA") then return end

		local Data = util.JSONToTable(file.Read(Path, "DATA"))
		if not Data then return end

		for Name, _ in pairs(XCF.DataVarGroups[Group] or {}) do
			if Data[Name] ~= nil then XCF.SetSharedData(Name, Data[Name]) end
		end
	end

	--- Save data vars to a file from the local player / server.
	--- Only saves variables from the group that have been set
	function XCF.SaveDataVarsToFile(Name, Group)
		local Path = BasePath .. Name .. ".txt"
		local Data = {}

		-- Implicitly avoids saving any variables that aren't defined in the group (key = nil)
		for Name, _ in pairs(XCF.DataVarGroups[Group] or {}) do
			local DataVar = XCF.DataVars[Name]
			if DataVar then Data[Name] = XCF.GetSharedData(Name, true) end
		end

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