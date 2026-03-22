-- TODO: Localize globals?

--[[
Call Order:
	XCF.SpawnEntity: Entry point for spawning an entity <- (Duplicator / Tool gun spawn)
	EntTable.Spawn: Internal Class specific spawn function. Don't use this.
	XCF_PreSpawn: Called before the entity is spawned.
	XCF.UpdateEntityData: Entry point for updating an entity's data variables. <- (Tool gun update)
	Entity.Update: Internal function that actually updates the entity's data variables. Don't use this.
	XCF_PostUpdateEntityData: Called after the entity's data variables have been updated.
	XCF_PostSpawn: Called after the entity is spawned and updated with the initial data variables.
	OnDuplicated: Called on any entity after it has been created by the duplicator and before any bone/entity modifiers have been applied. <- (Duplicator only)
	PostEntityPaste: Called after the duplicator pastes the entity, after the bone/entity modifiers have been applied to the entity. <- (Duplicator only)
	XCF_PostMenuSpawn: Called after all the above, if created with the toolgun <- (Tool gun only)
	---

Notable variables:
	XCF_LiveData: The current live data of the entity, updated whenever the entity is spawned or updated. Initialized by the toolgun on spawn, or by the duplicator when pasting.
		Certain datavar types like linked entities will have unsafe/garbage data until PostEntityPaste is called. Do not use them before then.	
	XCF_DupeData: A copy of the live data at the time of duplication. PostEntityPaste updates it immediately before copying. It's really just for flushing data, don't use it.
]]--

XCF.EntityTables = XCF.EntityTables or {}

local empty_table = {}

-- Public entry point
function XCF.SpawnEntity(Class, Player, Pos, Angle, DataVarKVs, FromDupe, NoUndo)
	local EntityTable = XCF.EntityTables[Class]
	if not EntityTable then return false, Class .. " is not a registered XCF entity class." end
	if not EntityTable.Spawn then return false, Class .. " does not have a spawn function." end

	local Entity = EntityTable.Spawn(Player, Pos, Angle, DataVarKVs, FromDupe)

	if not IsValid(Entity) then return false, "The spawn function for " .. Class .. " failed to return a valid entity." end

	Entity:CPPISetOwner(Player)
	Entity:SetPlayer(Player)

	Entity.Owner = Player

	if not NoUndo then
		undo.Create(Entity.Name or Class)
		undo.AddEntity(Entity)
		undo.SetPlayer(Player)
		undo.Finish()
	end

	return true, Entity
end

-- Public entry point
function XCF.UpdateEntityData(Entity, DataVarKVs)
	if not IsValid(Entity) then return false, "Can't update invalid entities." end
	if not isfunction(Entity.Update) then return false, "This entity does not support updating." end

	local Result, Message = Entity:Update(DataVarKVs)

	if Result then
		if Entity.UpdateOverlay then Entity:UpdateOverlay(true) end
	else
		Message = "Couldn't update entity: " .. (Message or "No reason provided.")
	end

	return Result, Message
end

function XCF.SetupENT(ENT)
	local Class  = string.Split(ENT.Folder, "/"); Class = Class[#Class]
	ENT.XCF_Class = Class
end

--- Detours an entity's method, allowing you to run code after the original method
--- This lets autoregister work on top of existing definitions
local function HijackAfter(MethodName, DetourFunc)
	local Old = ENT[MethodName]
	local Base = ENT.BaseClass and ENT.BaseClass[MethodName]

	ENT[MethodName] = function(self, ...)
		if Old then Old(self, ...) end
		if Base then Base(self, ...) end
		DetourFunc(self, ...)
	end
end

function XCF.AutoRegister(ENT, Class)
	if CLIENT then return end -- TODO: Maybe this is wrong?

	local Class = ENT.XCF_Class

	function ENT:Update(DataVarKVs)
		XCF.SaveEntity(self)

		-- Update the live data with the new values
		for DataVarName, Value in pairs(DataVarKVs) do
			self.XCF_LiveData[DataVarName] = Value
		end

		if self.XCF_PostUpdateEntityData then self:XCF_PostUpdateEntityData() end
		XCF.RestoreEntity(self)
	end

	HijackAfter("OnRemove", function(self)
		WireLib.Remove(self)
	end)

	HijackAfter("PreEntityCopy", function(self)
		self.XCF_DupeData = table.Copy(self.XCF_LiveData)
		for _, DataVarName in ipairs(XCF.DataVarScopesOrdered[Class] or empty_table) do
			local DataVar = XCF.DataVarsByScopeAndName[Class] and XCF.DataVarsByScopeAndName[Class][DataVarName]
			if DataVar and DataVar.Type.PreCopy then
				local Sanitized = DataVar.Type.PreCopy(self, DataVar, self.XCF_DupeData[DataVarName])
				self.XCF_DupeData[DataVarName] = Sanitized
			end
		end
	end)

	HijackAfter("OnDuplicated", function(self, EntTable)
		if OnDuplicated then OnDuplicated(self, EntTable) end
		self.BaseClass.OnDuplicated(self, EntTable)
	end)

	HijackAfter("PostEntityPaste", function(self, _, _, CreatedEntities)
		for _, DataVarName in ipairs(XCF.DataVarScopesOrdered[Class] or empty_table) do
			local DataVar = XCF.DataVarsByScopeAndName[Class] and XCF.DataVarsByScopeAndName[Class][DataVarName]
			if DataVar and DataVar.Type.PostPaste then
				local Sanitized = DataVar.Type.PostPaste(self, DataVar, self.XCF_LiveData[DataVarName], CreatedEntities)
				self.XCF_LiveData[DataVarName] = Sanitized
			end
		end
	end)

	local EntTable = XCF.EntityTables[Class] or {}
	XCF.EntityTables[Class] = EntTable

	-- Entity specific spawn function
	function EntTable.Spawn(Player, Pos, Angle, DataVarKVs, FromDupe)
		local New = ents.Create(Class)
		if not IsValid(New) then return end

		New:SetPos(Pos)
		New:SetAngles(Angle)
		if New.XCF_PreSpawn then
			New:XCF_PreSpawn(Player, Pos, Angle, DataVarKVs, FromDupe)
		end

		New:Spawn()
		Player:AddCount("_" .. Class, New)
		Player:AddCleanup(Class, New)

		New.XCF_LiveData = {}

		XCF.UpdateEntityData(New, DataVarKVs)
		if New.XCF_PostSpawn then
			New:XCF_PostSpawn(Player, Pos, Angle, DataVarKVs, FromDupe)
		end

		return New
	end

	-- Duplicator entry point
	local function SpawnFunction(Player, Pos, Angle, DataVarKVs)
		-- Collect the extra arguments passed in by duplicator into a KV format
		local _, Entity = XCF.SpawnEntity(Class, Player, Pos, Angle, DataVarKVs, true)
		return Entity
	end

	duplicator.RegisterEntityClass(Class, SpawnFunction, "Pos", "Angle", "XCF_DupeData")
end