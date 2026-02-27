do
	local Offset = Vector(0, 0, 256)

	--- Shared implementation of UTIL_DropToFloor (roughly).
	--- @param Entity any The entity to try dropping to the floor
	function XCF.DropToFloor(Entity)
		Entity:SetGroundEntity(NULL)

		local EntPos = Entity:GetPos()
		local EntCollisionGroup = Entity:GetCollisionGroup()
		local TraceCollisionGroup = EntCollisionGroup == COLLISION_GROUP_PUSHAWAY and COLLISION_GROUP_NONE or EntCollisionGroup
		local Trace = util.TraceEntity({
			start = EntPos,
			endpos = EntPos - Offset,
			collisiongroup = TraceCollisionGroup,
			filter = Entity,
		}, Entity)

		if Trace.AllSolid then return -1 end
		if Trace.Fraction == 1 then return 0 end

		Entity:SetPos(Trace.HitPos)
		Entity:SetGroundEntity(Trace.Entity)

		return 1
	end
end

do -- Baseplate lua seat generation
	local ModelToPlayerStart = {
		["models/chairs_playerstart/jeeppose.mdl"] = "playerstart_chairs_jeep",
		["models/chairs_playerstart/airboatpose.mdl"] = "playerstart_chairs_airboat",
		["models/chairs_playerstart/sitposealt.mdl"] = "playerstart_chairs_seated",
		["models/chairs_playerstart/podpose.mdl"] = "playerstart_chairs_podpose",
		["models/chairs_playerstart/sitpose.mdl"] = "playerstart_chairs_seated_alt",
		["models/chairs_playerstart/standingpose.mdl"] = "playerstart_chairs_standing",
		["models/chairs_playerstart/pronepose.mdl"] = "playerstart_chairs_prone"
	}

	--- Creates and returns a lua seat after parenting it to the given entity.
	--- Returns nil if the seat couldn't be created for some reason.
	function XCF.GenerateLuaSeat(Entity, Player, Pos, Angle, Model)
		if not Player:CheckLimit("vehicles") then return end

		local Pod = ents.Create("prop_vehicle_prisoner_pod")
		Player:AddCount("vehicles", Pod)
		if IsValid(Pod) and IsValid(Player) then
			Pod:SetAngles(Angle)
			Pod:SetModel(Model)
			Pod:SetPos(Pos)
			Pod:Spawn()
			Pod:SetParent(Entity)

			-- MARCH: Fixes player-start animations
			-- I don't like how this works but it's the best way I can think of right now
			local PlayerStartName = ModelToPlayerStart[Model]
			if PlayerStartName then
				local PlayerStartInfo = list.GetForEdit("Vehicles")[PlayerStartName]
				if PlayerStartInfo then
					Pod:SetVehicleClass(PlayerStartName)
					if PlayerStartInfo.Members then
						table.Merge(Pod, PlayerStartInfo.Members)
					end
				end
			end

			Pod.Owner = Player
			Pod:CPPISetOwner(Player)

			return Pod
		else
			return nil
		end
	end

	timer.Simple(1, function()
		if WireLib then
			if not XCF.WirelibDetour_GetClosestRealVehicle then
				XCF.WirelibDetour_GetClosestRealVehicle = WireLib.GetClosestRealVehicle
			end
			local XCF_WirelibDetour_GetClosestRealVehicle = XCF.WirelibDetour_GetClosestRealVehicle
			function WireLib.GetClosestRealVehicle(Vehicle, Position, Notify)
				if IsValid(Vehicle) and Vehicle.XCF and Vehicle.XCF_GetSeatProxy then
					local Pod = Vehicle:XCF_GetSeatProxy()
					if IsValid(Pod) then return Pod end
				end

				return XCF_WirelibDetour_GetClosestRealVehicle(Vehicle, Position, Notify)
			end
		end

		if SF then
			local tool = weapons.GetStored("gmod_tool").Tool.starfall_component
			if not XCF.Starfall_DetourComponentRightClick then
				XCF.Starfall_DetourComponentRightClick = tool.RightClick
			end

			local XCF_Starfall_DetourComponentRightClick = XCF.Starfall_DetourComponentRightClick

			function tool:RightClick(trace)
				if not trace.HitPos or not (trace.Entity and trace.Entity:IsValid()) or trace.Entity:IsPlayer() then return false end
				if CLIENT then return true end

				local ent = trace.Entity
				if self:GetStage() == 1 and self.Component:GetClass() == "starfall_hud" and ent.XCF and ent.XCF_GetSeatProxy then
					self.Component:LinkVehicle(ent:XCF_GetSeatProxy())
					self:SetStage(0)
					SF.AddNotify(self:GetOwner(), "Linked to vehicle successfully.", "GENERIC" , 4, "DRIP2")
					return true
				end

				return XCF_Starfall_DetourComponentRightClick(self, trace)
			end
		end
	end)

	--- Configures a lua seat after it has been created.
	--- Whenever the seat is created, this should be called after.
	--- @param Entity any The entity to attach the seat to
	--- @param Pod any The seat to configure
	--- @param Player any The owner of the seat
	function XCF.ConfigureLuaSeat(Entity, Pod, Player)
		-- Just to be safe...
		Pod.Owner = Player
		Pod:CPPISetOwner(Player)

		Pod:SetKeyValue("vehiclescript", "scripts/vehicles/prisoner_pod.txt")    	-- I don't know what this does, but for good measure...
		Pod:SetKeyValue("limitview", 0)                                            -- Let the player look around

		Pod.Vehicle = Entity
		Pod.XCF = Pod.XCF or {}
		Pod.XCF.LuaGeneratedSeat = true

		if not IsValid(Pod) then return end

		Pod:SetParent(Entity)

		Pod:SetNoDraw(true)
		Pod:SetNotSolid(true)
		-- MARCH: In Advanced Duplicator 2, pasting runs v.PostEntityPaste (if it exists), and then afterwards will call
		-- v:SetNotSolid(v.SolidMod). For whatever reason, that is false when the seat gets duped. So this just tricks
		-- the duplicator to make it not-solid. source: advdupe2/lua/advdupe2/sv_clipboard.lua
		Pod.SolidMod = true

		Pod.XCF_InvisibleToBallistics = true
		Pod.XCF_InvisibleToTrace = true

		Entity.Pod = Pod
	end
end