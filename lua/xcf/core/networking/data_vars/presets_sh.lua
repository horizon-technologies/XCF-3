XCF.PresetsByGroupAndName = XCF.PresetsByGroupAndName or {} -- Maps Group -> Name -> Preset

local BasePath = "xcf/presets/"

--- Creates a preset with the given information
--- @param PresetName string
--- @param PresetGroup string
--- @param DataVarGroup string
--- @param SaveUnset boolean
function XCF.AddPreset(PresetName, PresetGroup, DataVarGroup, SaveUnset)
	local NewPreset = {
		Name = PresetName,
		PresetGroup = PresetGroup,
		DataVarGroup = DataVarGroup,
		Data = {},
	}

	for VarName, _ in pairs(XCF.DataVarsByGroupAndName[DataVarGroup] or {}) do
		local Value = XCF.GetSharedData(VarName, DataVarGroup, not SaveUnset)
		if Value ~= nil then
			NewPreset.Data[DataVarGroup] = NewPreset.Data[DataVarGroup] or {}
			NewPreset.Data[DataVarGroup][VarName] = Value
		end
	end

	XCF.PresetsByGroupAndName[PresetGroup] = XCF.PresetsByGroupAndName[PresetGroup] or {}
	XCF.PresetsByGroupAndName[PresetGroup][PresetName] = NewPreset

	return NewPreset
end

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

function XCF.ApplyPreset(Name, Group)
	local Preset = XCF.PresetsByGroupAndName[Group][Name]
	if not Preset then return end

	for Group, GroupTable in pairs(Preset.Data) do
		for VarName, Value in pairs(GroupTable) do
			XCF.SetSharedData(VarName, Group, Value)
		end
	end
end

-- function XCF.SavePreset(Name, Group)
-- 	local Preset = XCF.PresetsByGroupAndName[Group][Name]
-- 	if not Preset then return end

-- 	XCF.EnsureFileAndDirectoryExists(BasePath, Name .. ".txt")

-- 	file.Write(
-- 		BasePath .. Name .. ".txt",
-- 		util.TableToJSON(Preset.Data, true)
-- 	)
-- end