TOOL.Name = "XCF Menu"
TOOL.Category = "Construction"

if CLIENT then
	TOOL.BuildCPanel = function(Panel)
		local BasePanel = XCF.InitMenuReloadableBase(Panel, "xcf_reload_main_menu", "CreateMainMenu")
		Panel:AddItem(BasePanel)
	end
end

function TOOL:LeftClick(Trace)
	if CLIENT then return true end
	if Trace.HitSky then return false end

	local Player = self:GetOwner()
	local SpawnClass = XCF.GetDataVar("SpawnClass", "ToolGun", Player)
	if not SpawnClass or SpawnClass == "" then return false end

	local Entity = Trace.Entity

	local Position = Trace.HitPos + Trace.HitNormal * 128
	local Angles   = Trace.HitNormal:Angle():Up():Angle()
	local Success, Result = XCF.SpawnEntity(SpawnClass, Player, Position, Angles, DataVarKVs)

	if Success then
		local PhysObj = Result:GetPhysicsObject()
		if Result.XCF_PostMenuSpawn then
			Result:XCF_PostMenuSpawn(SpawnClass, Player, Position, Angles, DataVarKVs)
		end

		Result:SetSpawnEffect(true)

		if IsValid(PhysObj) then
			PhysObj:EnableMotion(false)
		end
	else
		print(Player, "Error", "Couldn't create entity" .. Result)
	end

	return true
end

function TOOL:RightClick(_)
	return true
end

function TOOL:Reload(_)
	return true
end

function TOOL:Think()
	-- print("thinking")
end

function TOOL:Deploy()
	-- print("deploying")
end

function TOOL:Holster()
	-- print("holstering")
end

function TOOL:DrawHud()
	-- print("drawing hud")
end

function TOOL:DrawTOOLScreen(_, _)
	-- print("drawing world")
end