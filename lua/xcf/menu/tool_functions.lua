function XCF.RegisterToolFunctions(Tool)
	function Tool:LeftClick(Trace)
		local Ent = Trace.Entity
		if not IsValid(Ent) then return false end
		if Ent:IsPlayer() or Ent:IsNPC() or Ent:IsNextBot() then return false end
		if CLIENT then return true end
		print("left click hit", Ent)
		return true
	end

	function Tool:RightClick(Trace)
		local Ent = Trace.Entity
		if not IsValid(Ent) then return false end
		if Ent:IsPlayer() or Ent:IsNPC() or Ent:IsNextBot() then return false end
		if CLIENT then return true end
		print("right click hit", Ent)
		return true
	end

	function Tool:Reload(Trace)
		local Ent = Trace.Entity
		if not IsValid(Ent) then return false end
		if Ent:IsPlayer() or Ent:IsNPC() or Ent:IsNextBot() then return false end
		if CLIENT then return true end
		print("reload hit", Ent)
		return true
	end

	function Tool:Think()
		-- print("thinking")
	end

	function Tool:Deploy()
		-- print("deploying")
	end

	function Tool:Holster()
		-- print("holstering")
	end

	function Tool:DrawHud()
		-- print("drawing hud")
	end

	function Tool:DrawToolScreen(width, height)
		-- print("drawing world")
	end
end