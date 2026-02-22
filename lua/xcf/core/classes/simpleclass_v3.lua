-- API Notes =================================================================================
-- You should only need to use DefineClass
-- Base/Super/Parent class all refer to the same thing here.

-- A class is created in this order:
--    Stage 1: The class table (holds ID, Parent, Children, OnInit) is initialized when DefineClass is called
--    Stage 2: The class metatable (makes inheritance and instantiation work) is initialized when the parent class initializes (see: InitializeClass)
--    Stage 3: The class table is indexed into Classes
--    Stage 5: The class table's OnInit method is ran
--    Stage 6: The children of this class are initialized (Stage 1-6) recursively

-- Internal Notes ============================================================================
-- A class has initialized <-> Classes[ID] = ClassTable
-- A class is waiting on its parent to initialize <-> Queued[BaseID][ID] = ClassTable

local Classes = {} --- A mapping from a class' ID to its table
local Queued = {} -- A mapping from a class' ID to a (mapping from its children's IDs to their tables)

--- Initializes a class by adding its metatable and running callbacks/hooks.
--- Recursively initializes children waiting on this class
--- This is called when a class and its parent are both initialized
--- @param ID string The ID of the class
--- @param NewClass table The class table of the class
--- @param BaseClass table The class table of the base class
local function InitializeClass(ID, NewClass, BaseClass)
	local ClassMeta = {
		__index = BaseClass, -- If I don't have it, check my super (inheritance)
		__tostring = function(self) return "Class (" .. self.ID .. ")" end,

		-- Instantiation
		__call = function(self, ...)
			local obj = setmetatable({}, {
				__index = self, -- Instances should use their class' static methods/variables if they dont have them set
				__tostring = function(instance) return "Instance of Class(" .. instance.ID .. ")" end, -- Avoid ambiguity/shadowing of self and the instance
			})
			if self.__new then self.__new(obj, ...) end -- Constructor if applicable
			return obj
		end
	}
	setmetatable(NewClass, ClassMeta)

	-- Index and Initialize ourselves
	Classes[ID] = NewClass
	if BaseClass then BaseClass.Children[ID] = NewClass end -- Register ourselves as a child of our parent
	NewClass.Parent = BaseClass

	if NewClass.OnInit then NewClass:OnInit(BaseClass) end

	-- Initialize children waiting on us, the parent, to initialize
	if Queued[ID] then
		for WaitingID, WaitingClass in pairs(Queued[ID]) do
			InitializeClass(WaitingID, WaitingClass, NewClass)
			NewClass.Children[WaitingID] = WaitingClass
		end
		Queued[ID] = nil
	end
end

--- Defines and returns a class' table, which you can define methods on.
--- @param ID string The ID of the class
--- @param BaseID string? The ID of the parent class
--- @param OnInit function? Ran when both the class and its parent are initialized. New and base class tables are passed as args.
--- @return NewClass table The table of the new class
function DefineClass(ID, BaseID, OnInit)
	local BaseClass = Classes[BaseID]
	local NewClass = {
		ID = ID,
		Parent = nil,
		Children = {},
		OnInit = OnInit
	}

	-- If we have a parent and they don't exist
	if BaseID and not BaseClass then
		Queued[BaseID] = Queued[BaseID] or {}
		Queued[BaseID][ID] = NewClass
		return NewClass
	end

	-- Otherwise initialize
	InitializeClass(ID, NewClass, BaseClass)
	return NewClass
end

--- Returns a class' table from its ID
function GetClass(ID)
	return Classes[ID]
end

--- Returns a class' metatable from its ID
function GetClassMeta(ID)
	local Class = GetClass(ID)
	return getmetatable(Class)
end

-- Example test code
-- local Snake = DefineClass("Snake", "Reptile")
-- local Frog = DefineClass("Frog", "Reptile")
-- local Reptile = DefineClass("Reptile", "Animal")

-- local Dog = DefineClass("Dog", "Mammal", function(Class, BaseClass)
-- 	function Class:MakeNoise()
-- 		print("Woof")
-- 	end
-- end)

-- local Cat = DefineClass("Cat", "Mammal")
-- local Mammal = DefineClass("Mammal", "Animal", function(Class, BaseClass)
-- 	function Class:MakeNoise()
-- 		print("Roar")
-- 	end
-- end)

-- local Animal = DefineClass("Animal", nil, function(Class, BaseClass)
-- 	function Class:MakeNoise()
-- 		print("Animal Noise")
-- 	end
-- end)

-- local MyDog = Dog()
-- MyDog:MakeNoise()
-- print(MyDog)
