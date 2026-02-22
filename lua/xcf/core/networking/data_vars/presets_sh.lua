XCF.PresetsByGroupAndName = XCF.PresetsByGroupAndName or {} -- Maps Group -> Name -> Preset

local BasePath = "xcf/presets/" -- Base path preset folders/files are located at

--- Creates a preset with the given information
--- @param PresetName string The name of the preset. Must be unique within the PresetGroup.
--- @param PresetGroup string The group of the preset. Presets are organized by group, and presets in the same group share the same set of data variables.
--- @param DataVarGroup string The data variable group that this preset is associated with.
--- @param SaveUnset boolean Whether to save unset data variables using their default. Not specifying allows you to only apply changes to what you want.
function XCF.AddPreset(PresetName, PresetGroup, DataVarGroup, SaveUnset)
	local NewPreset = {
		Name = PresetName,
		PresetGroup = PresetGroup,
		DataVarGroup = DataVarGroup,
		Data = {},
	}

	for VarName, _ in pairs(XCF.DataVarsByGroupAndName[DataVarGroup] or {}) do
		local Value = XCF.GetRealmData(VarName, DataVarGroup, not SaveUnset)
		if Value ~= nil then
			NewPreset.Data[DataVarGroup] = NewPreset.Data[DataVarGroup] or {}
			NewPreset.Data[DataVarGroup][VarName] = Value
		end
	end

	XCF.PresetsByGroupAndName[PresetGroup] = XCF.PresetsByGroupAndName[PresetGroup] or {}
	XCF.PresetsByGroupAndName[PresetGroup][PresetName] = NewPreset

	return NewPreset
end

--- Removes a preset by name and group. Also deletes the preset file from disk if it exists.
function XCF.RemovePreset(Name, Group)
	if XCF.PresetsByGroupAndName[Group][Name] then
		local Path = BasePath .. Name .. ".txt"
		if file.Exists(Path, "DATA") then file.Delete(Path) end

		XCF.PresetsByGroupAndName[Group][Name] = nil
		if table.IsEmpty(XCF.PresetsByGroupAndName[Group]) then XCF.PresetsByGroupAndName[Group] = nil end
		return true
	end

	return false
end

--- Sets all the data variables to values listed in the preset.
function XCF.ApplyPreset(Name, Group)
	local Preset = XCF.PresetsByGroupAndName[Group][Name]
	if not Preset then return end

	for Group, GroupTable in pairs(Preset.Data) do
		for VarName, Value in pairs(GroupTable) do
			XCF.SetRealmData(VarName, Group, Value)
		end
	end
end

--- Saves a preset to disk. Presets are stored in garrysmod/data/xcf/presets/.
--- Used by the preset menu when saving a preset
function XCF.SavePreset(Name, Group)
	local Preset = XCF.PresetsByGroupAndName[Group][Name]
	if not Preset then return end

	local SubPath = BasePath .. "/" .. Group .. "/"
	if not file.Exists(SubPath, "DATA") then file.CreateDir(SubPath) end

	local FullPath = SubPath .. Name .. ".txt"

	local SaveData = {
		Name = Preset.Name,
		PresetGroup = Preset.PresetGroup,
		DataVarGroup = Preset.DataVarGroup,
		Data = Preset.Data
	}

	file.Write(FullPath, util.TableToJSON(SaveData, true))
end

--- Loads all presets for a specific group from disk.
--- Used by the preset menu to populate the list of presets.
function XCF.LoadPresetsForGroup(Group)
	local GroupPath = BasePath .. Group .. "/"
	if not file.Exists(GroupPath, "DATA") then return end

	local Files = file.Find(GroupPath .. "*.txt", "DATA")

	for _, FileName in ipairs(Files) do
		local JSON = file.Read(GroupPath .. FileName, "DATA")
		local Loaded = util.JSONToTable(JSON)
		if Loaded and Loaded.Name and Loaded.PresetGroup then
			XCF.AddPreset(Loaded.Name, Loaded.PresetGroup, Loaded.DataVarGroup, true, Loaded.Data)
		end
	end
end