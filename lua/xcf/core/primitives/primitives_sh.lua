local DefineClass = XCF.DefineClass

DefineClass("Primitive3D", nil, function(Class)
	function Class:initialize()
		self.children = {}
		self.visible = true
		self.physical = true

		self:ClearMesh()
	end

	------------------- Mesh creation functions ----------------------------

	function Class:ClearMesh()
		self.vertices = {} -- List of vertices
		self.triangleIDs = {} -- List of triplets of vertex IDs
		self.convexIDs = {} -- List of tuples (>=4 vertices) of vertex IDs
		self.triangles = {} -- In the format BuildFromTriangles expects
		self.convexes = {} -- In the format PhysicsInitMultiConvex expects
	end

	function Class:PushVertex(X, Y, Z)
		local vertex = Vector(X, Y, Z)
		table.insert(self.vertices, vertex)
		return #self.vertices -- Return the index of the new vertex
	end

	function Class:PushTriangle(I1, I2, I3)
		table.insert(self.triangleIDs, {I1, I2, I3})
	end

	function Class:PushFace(...)
		local f = { ... }
		local a, b, c = f[1], f[2]

		for i = 3, #f do
			c = f[i]
			self:PushTriangle( a, b, c )
			b = c
		end
	end

	function Class:PushConvex(...)
		local vertexIDs = {...}
		table.insert(self.convexIDs, vertexIDs)
	end

	------------------- Mesh transformation functions ----------------------------

	-- Dock to absolute position
	function Class:Dock(pos, ang)
		self.pos = pos
		self.ang = ang
		self.dir = self.ang:Forward()
	end

	-- Dock child relative to parent
	function Class:DockRelSimple(Parent, RelPos, RelAng)
		Parent:AddPrimitive(self)

		local pos, ang = LocalToWorld(RelPos, RelAng, Parent.pos, Parent.ang)
		self:Dock(pos, ang)
	end

	-- Dock child relative to parent and itself
	function Class:DockRelAdv(Parent, RelAng3, RelPos1, RelAng1, RelPos2, RelAng2)
		Parent:AddPrimitive(self)

		local _, Ang1 = LocalToWorld(Vector(), RelAng1, Vector(), Parent.ang)
		local Pos1, Ang2 = LocalToWorld(RelPos1, RelAng2, Vector(), Ang1)
		local Pos2, _ = LocalToWorld(RelPos2, RelAng3, Vector(), Ang2)
		self:Dock(Parent.pos + Pos1 - Pos2, Ang2)
	end

	function Class:AddPrimitive(primitive)
		table.insert(self.children, primitive)
	end

	----------------------- Mesh generation functions ----------------------------

	function Class:ComputeMeshSkeleton() end -- Placeholder

	local function ComputeUV(p, normal)
		local ax = math.abs(normal.x)
		local ay = math.abs(normal.y)
		local az = math.abs(normal.z)

		local scale = 0.02 -- texture scale

		if az >= ax and az >= ay then
			return p.x * scale, p.y * scale
		elseif ax >= ay then
			return p.y * scale, p.z * scale
		else
			return p.x * scale, p.z * scale
		end
	end

	function Class:ComputeMeshOriented()
		self:ComputeMeshSkeleton()

		for _, Triangle in ipairs(self.triangleIDs) do
			local v1, v2, v3 = self.vertices[Triangle[1]], self.vertices[Triangle[2]], self.vertices[Triangle[3]]
			local wv1, _ = LocalToWorld(v1, Angle(), self.pos, self.ang)
			local wv2, _ = LocalToWorld(v2, Angle(), self.pos, self.ang)
			local wv3, _ = LocalToWorld(v3, Angle(), self.pos, self.ang)

			local edge1 = wv2 - wv1
			local edge2 = wv3 - wv1
			local normal = edge2:Cross(edge1):GetNormalized()

			local u1, v1 = ComputeUV(wv1, normal)
			local u2, v2 = ComputeUV(wv2, normal)
			local u3, v3 = ComputeUV(wv3, normal)

			table.insert(self.triangles, {pos = wv1, normal = normal, u = u1, v = v1})
			table.insert(self.triangles, {pos = wv2, normal = normal, u = u2, v = v2})
			table.insert(self.triangles, {pos = wv3, normal = normal, u = u3, v = v3})
		end

		for _, Convex in ipairs(self.convexIDs) do
			local wConvex = {}
			for _, vertexID in ipairs(Convex) do
				local v = self.vertices[vertexID]
				local wv, _ = LocalToWorld(v, Angle(), self.pos, self.ang)
				table.insert(wConvex, wv)
			end
			table.insert(self.convexes, wConvex)
		end
	end

	function Class:CompileChildren()
		self:ClearMesh()
		for _, child in ipairs(self.children) do
			child:ComputeMeshOriented()
			for _, tri in ipairs(child.triangles) do table.insert(self.triangles, tri) end
			for _, convex in ipairs(child.convexes) do table.insert(self.convexes, convex) end
		end
	end
end)

DefineClass("Cube", "Primitive3D", function(Class, BaseClass)
	function Class:initialize(options)
		BaseClass.initialize(self, options)
		self.length = options.length or 1
		self.width = options.width or 1
		self.height = options.height or 1
	end

	function Class:GetVolume()
		return self.length * self.width * self.height
	end

	function Class:GetSurfaceArea()
		return (self.length * self.width) * 2 + (self.width * self.height) * 2 + (self.length * self.height) * 2
	end

	function Class:ComputeMeshSkeleton()
		local hl, hw, hh = self.length / 2, self.width / 2, self.height / 2

		local c1 = self:PushVertex(-hl, -hw, -hh)
		local c2 = self:PushVertex(-hl, -hw,  hh)
		local c3 = self:PushVertex(-hl,  hw, -hh)
		local c4 = self:PushVertex(-hl,  hw,  hh)
		local c5 = self:PushVertex( hl, -hw, -hh)
		local c6 = self:PushVertex( hl, -hw,  hh)
		local c7 = self:PushVertex( hl,  hw, -hh)
		local c8 = self:PushVertex( hl,  hw,  hh)

		self:PushFace(c1, c3, c4, c2) -- -X
		self:PushFace(c5, c6, c8, c7) -- +X
		self:PushFace(c1, c2, c6, c5) -- -Y
		self:PushFace(c3, c7, c8, c4) -- +Y
		self:PushFace(c1, c5, c7, c3) -- -Z
		self:PushFace(c2, c4, c8, c6) -- +Z

		self:PushConvex(c1, c2, c3, c4, c5, c6, c7, c8)
	end
end)


DefineClass("Cylinder", "Primitive3D", function(Class, BaseClass)
	function Class:initialize(options)
		BaseClass.initialize(self, options)

		self.radius = options.radius or 1
		self.height = options.height or 1
		self.fidelity = options.fidelity or 10
	end

	function Class:GetVolume()
		return math.pi * math.pow(self.radius, 2) * self.height
	end

	function Class:GetSurfaceArea()
		return 2 * math.pi * self.radius * (self.radius + self.height)
	end

	function Class:ComputeMeshSkeleton()
		self:ClearMesh()
		local r = self.radius
		local hh = self.height / 2
		local step = math.rad(360 / self.fidelity)

		local top = {}
		local bottom = {}
		local all = {}

		for i = 0, self.fidelity - 1 do
			local ang = i * step
			local x = r * math.cos(ang)
			local y = r * math.sin(ang)

			local i1 = self:PushVertex(x, y, hh)
			local i2 = self:PushVertex(x, y, -hh)
			table.insert(top, i1)
			table.insert(bottom, i2)
			table.insert(all, i1)
			table.insert(all, i2)
		end

		self:PushFace(unpack(table.Reverse(top))) -- Top cap
		self:PushFace(unpack(bottom)) -- Bottom cap

		-- Side walls
		for i = 1, self.fidelity do
			local n = (i % self.fidelity) + 1 -- next vertex, wrapping around
			self:PushFace(top[i], top[n], bottom[n], bottom[i])
		end

		self:PushConvex(unpack(all))
	end
end)

DefineClass("HollowCylinder", "Primitive3D", function(Class, BaseClass)
	function Class:initialize(options)
		BaseClass.initialize(self, options)

		self.radius1 = options.radius1 or 1
		self.radius2 = options.radius2 or 1
		self.height = options.height or 1
		self.fidelity = options.fidelity or 10
	end

	function Class:GetVolume()
		local outter = math.pi * math.pow(self.radius1, 2) * self.height
		local inner = math.pi * math.pow(self.radius2, 2) * self.height
		return outter - inner
	end

	function Class:GetSurfaceArea()
		local R = self.radius2
		local r = self.radius1
		local h = self.height

		local outer = 2 * math.pi * R * h
		local inner = 2 * math.pi * r * h
		local caps = 2 * math.pi * (R * R - r * r)

		return outer + inner + caps
	end

	function Class:ComputeMeshSkeleton()
		local r1 = self.radius1
		local r2 = self.radius2
		local hh = self.height / 2
		local step = math.rad(360 / self.fidelity)

		local outerTop = {}
		local outerBottom = {}
		local innerTop = {}
		local innerBottom = {}

		for i = 0, self.fidelity - 1 do
			local ang = i * step
			local cos = math.cos(ang)
			local sin = math.sin(ang)

			local i1 = self:PushVertex(r1 * cos, r1 * sin, hh)
			local i2 = self:PushVertex(r1 * cos, r1 * sin, -hh)
			local i3 = self:PushVertex(r2 * cos, r2 * sin, hh)
			local i4 = self:PushVertex(r2 * cos, r2 * sin, -hh)

			table.insert(outerTop, i1)
			table.insert(outerBottom, i2)
			table.insert(innerTop, i3)
			table.insert(innerBottom, i4)

			self:PushConvex(i1, i2, i3, i4)
		end

		for i = 1, self.fidelity do
			local n = (i % self.fidelity) + 1 -- next vertex, wrapping around
			self:PushFace(outerTop[i], outerTop[n], outerBottom[n], outerBottom[i]) -- Outer wall
			self:PushFace(innerTop[n], innerTop[i], innerBottom[i], innerBottom[n]) -- Inner wall (reverse winding)
			self:PushFace(outerTop[i], innerTop[i], innerTop[n], outerTop[n]) -- Top ring
			self:PushFace(outerBottom[n], innerBottom[n], innerBottom[i], outerBottom[i]) -- Bottom ring
		end
	end
end)

-- local Base = XCF.GetClass("Primitive3D")()
-- Base:Dock(Vector(), Angle())

-- local Shaft = XCF.GetClass("Cylinder")({radius=6, height=36})
-- Shaft:DockRelSimple(Base, Vector(0,0,0), Angle(90,0,0))

-- for i = 1,4 do
-- 	local Piston = XCF.GetClass("Cube")({length=36,width=6,height=12})
-- 	Piston:DockRelAdv(Base, Angle(), Vector(0,0,6), Angle(0,0,45+90*i), Vector(0,0,-5), Angle(0,0,0))
-- end

-- Shaft:ComputeMeshSkeleton()
-- Shaft:ComputeMeshOriented()
-- -- PrintTable(Shaft.triangles)