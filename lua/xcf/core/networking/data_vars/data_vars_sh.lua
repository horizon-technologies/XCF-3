local XCF = XCF

XCF.DataVarTypes = XCF.DataVarTypes or {} -- Maps type names to type definitions
XCF.DataVars = XCF.DataVars or {} -- Maps variable names to variable definitions
XCF.DataVarIDsToNames = XCF.DataVarIDsToNames or {} -- Maps variable UUIDs to their names for reverse lookup on receive
XCF.DataVarGroups = XCF.DataGroups or {} -- Maps group names to lists of variable names

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
function XCF.DefineDataVar(Name, Group, Type, Options)
	XCF.DataVars[Name] = {
		UUID = VarCounter,
		Group = Group,
		Type = Type,
		Options = Options,
		Values = {},
	}
	XCF.DataVarIDsToNames[VarCounter] = Name

	XCF.DataVarGroups[Group] = XCF.DataVarGroups[Group] or {}
	XCF.DataVarGroups[Group][Name] = true

	VarCounter = VarCounter + 1
	return XCF.DataVars[Name]
end

--- Returns whether a client is allowed to set a server datavars
function XCF.CanSetServerData(Player)
	if not IsValid(Player) then return true end -- No player, probably the server
	if Player:IsSuperAdmin() then return true end

	return XCF.GetServerBool("ServerDataAllowAdmin") and Player:IsAdmin()
end

-- Determine if we're on a listen server once a player joins
-- TODO: This may cause race conditions in the future if we send client data to a player when they spawn?
XCF.IsListenServer = XCF.IsListenServer or false
if SERVER then
	hook.Add("PlayerInitialSpawn", "XCF_DetectHost", function(ply)
		if ply:IsListenServerHost() then
			XCF.IsListenServer = true
			hook.Remove("PlayerInitialSpawn", "XCF_DetectHost")
		end
	end)
else
	hook.Add("InitPostEntity", "XCF_DetectHostClient", function()
		if LocalPlayer():IsListenServerHost() then
			XCF.IsListenServer = true
			hook.Remove("InitPostEntity", "XCF_DetectHostClient")
		end
	end)
end
print("XCF: Listen server mode is " .. tostring(XCF.IsListenServer))

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

--- Load data vars from a file. Used for persistent data on client/server and presets on client
-- function XCF.LoadDataVarsFromFile(Path, TargetPlayer, Filter) end

--- Save data vars to a file. Used for persistent data on client/server and presets on client
-- function XCF.SaveDataVarsToFile(Path, TargetPlayer, Filter) end

----------------------------------------------------------

-- Basic types
XCF.DefineDataVarType("Bool",        net.ReadBool,        net.WriteBool)
XCF.DefineDataVarType("String",      net.ReadString,      net.WriteString)
XCF.DefineDataVarType("Float",       net.ReadFloat,       net.WriteFloat)
XCF.DefineDataVarType("Double",      net.ReadDouble,      net.WriteDouble)

-- Signed integers
XCF.DefineDataVarType("Int8",        function() return net.ReadInt(8)  end,  function(v) net.WriteInt(v, 8)  end)
XCF.DefineDataVarType("Int16",       function() return net.ReadInt(16) end,  function(v) net.WriteInt(v, 16) end)
XCF.DefineDataVarType("Int32",       function() return net.ReadInt(32) end,  function(v) net.WriteInt(v, 32) end)

-- Unsigned integers
XCF.DefineDataVarType("UInt8",       function() return net.ReadUInt(8)  end, function(v) net.WriteUInt(v, 8)  end)
XCF.DefineDataVarType("UInt16",      function() return net.ReadUInt(16) end, function(v) net.WriteUInt(v, 16) end)
XCF.DefineDataVarType("UInt32",      function() return net.ReadUInt(32) end, function(v) net.WriteUInt(v, 32) end)

-- Others
XCF.DefineDataVarType("Color",       net.ReadColor,       net.WriteColor)
XCF.DefineDataVarType("Angle",       net.ReadAngle,       net.WriteAngle)
XCF.DefineDataVarType("Vector",      net.ReadVector,      net.WriteVector)
XCF.DefineDataVarType("Normal",      net.ReadNormal,      net.WriteNormal)
XCF.DefineDataVarType("Entity",      net.ReadEntity,      net.WriteEntity)
XCF.DefineDataVarType("Player",      net.ReadPlayer,      net.WritePlayer)
XCF.DefineDataVarType("Table",       net.ReadTable,       net.WriteTable)
XCF.DefineDataVarType("Data",        net.ReadData,        net.WriteData)
XCF.DefineDataVarType("Bit",         net.ReadBit,         net.WriteBit)

----------------------------------------------------------

-- Test variable
XCF.DefineDataVar("TestVar", "TestGroup", XCF.DataVarTypes.String)

XCF.DefineDataVar("Volatility", "FateCube", XCF.DataVarTypes.Float)
XCF.DefineDataVar("State", "FateCube", XCF.DataVarTypes.UInt8)
XCF.DefineDataVar("Size", "FateCube", XCF.DataVarTypes.Vector)
XCF.DefineDataVar("Material", "FateCube", XCF.DataVarTypes.String)