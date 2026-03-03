----------------------------------------
-- XCF library
-- @name xcf
-- @class library
-- @libtbl xcf_library
SF.RegisterLibrary("xcf")

return function(instance) -- called per Starfall chip
    local xcf_library = instance.Libraries.xcf
    local ents_methods = instance.Types.Entity.Methods
    local _, unwrap = instance.Types.Entity.Wrap, instance.Types.Entity.Unwrap

    --- Returns the string 'XCF: <echo>'
    -- @shared
    -- @return string The string 'XCF: <echo>'
    function xcf_library.getEcho(echo)
        return "XCF: " .. echo
    end

    --- Returns true if an entity is an XCF entity
    -- @server
    -- @return boolean True if XCF entity, false otherwise
    function ents_methods:isXCFEntity()
        local This = unwrap(self)
        if not IsValid(This) then return false end
        return This.IsXCFEntity == true
    end
end