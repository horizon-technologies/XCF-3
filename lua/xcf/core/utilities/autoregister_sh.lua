XCF.EntityTables = XCF.EntityTables or {}

-- External entry point
function XCF.SpawnEntity(Class, Player, Pos, Angle, DataVarKVs)
	local EntityTable = XCF.EntityTables[Class]
	if not EntityTable then return false, Class .. " is not a registered XCF entity class." end
	if not EntityTable.Spawn then return false, Class .. " does not have a spawn function." end

	local Entity = EntityTable.Spawn(Player, Pos, Angle, DataVarKVs)

	if not IsValid(Entity) then return false, "The spawn function for " .. Class .. " failed to return a valid entity." end

	Entity:CPPISetOwner(Player)
	Entity:SetPlayer(Player)

	Entity.Owner = Player

	return true, Entity
end

function XCF.AutoRegister(ENT, Class, DataVarScope)
	local EntTable = XCF.EntityTables[Class] or {}
	XCF.EntityTables[Class] = EntTable

	-- Entity specific spawn function
	function EntTable.Spawn(Player, Pos, Angle, DataVarKVs)
		print("EntTable.Spawn", Player, Pos, Angle, DataVarKVs)
		local New = ents.Create(Class)
		if not IsValid(New) then return end

		New:SetPos(Pos)
		New:SetAngles(Angle)
		if New.XCF_PreSpawn then
			New:XCF_PreSpawn(Player, Pos, Angle, DataVarKVs)
		end

		New:Spawn()

		if New.XCF_PostSpawn then
			New:XCF_PostSpawn(Player, Pos, Angle, DataVarKVs)
		end

		return New
	end

	-- Duplicator entry point
	local DataVarKeys = XCF.DataVarScopesOrdered[DataVarScope]
	local function SpawnFunction(Player, Pos, Angle, ...)
		-- Collect the extra arguments passed in by duplicator into a KV format
		local Values = {...}
		local DataVarKVs = {}
		for i, Key in ipairs(DataVarKeys) do DataVarKVs[Key] = Values[i] end

		local _, Entity = XCF.SpawnEntity(Class, Player, Pos, Angle, DataVarKVs)
		return Entity
	end

	duplicator.RegisterEntityClass(Class, SpawnFunction, "Pos", "Angle", unpack(DataVarKeys))
end