-- Track XCF changes on a contraption
do
    -- Maintain a record in the contraption of its current baseplate
    hook.Add("cfw.contraption.created", "XCF_CFW_Indexing", function(contraption)
        contraption.XCF_EntitiesCount = 0
    end)

    hook.Add("cfw.contraption.entityAdded", "XCF_CFW_Indexing", function(contraption, ent)
        local Class = ent:GetClass()

        if Class == "xcf_baseplate" then
            -- I don't think ent == contraption.XCF_Baseplate would *ever* happen,
            -- but at the same time, if XCF_Baseplate == ent, then it's still a valid
            -- scenario since there's still only one baseplate. Maybe this is too paranoid.
            if IsValid(contraption.XCF_Baseplate) and ent ~= contraption.XCF_Baseplate then
                -- Destroy the new one! We can't have more than one on a contraption
                XCF.SendNotify(ent:CPPIGetOwner(), false, "A contraption can only have one XCF baseplate. New baseplate removed.")
                ent:Remove()
                return
            end

            contraption.XCF_Baseplate = ent
        end

        if ent.IsXCFEntity then
            contraption.XCF_EntitiesCount = math.max(0, contraption.XCF_EntitiesCount + 1)
        end
    end)

    hook.Add("cfw.contraption.entityRemoved", "XCF_CFW_Deindexing", function(contraption, ent)
        local Class = ent:GetClass()

        if Class == "xcf_baseplate" then
            contraption.XCF_Baseplate = nil
        end

        if ent.IsXCFEntity then
            contraption.XCF_EntitiesCount = math.max(0, contraption.XCF_EntitiesCount - 1)
        end
    end)
end

-- XCF contraption methods
do
    local CONTRAPTION     = CFW.Classes.Contraption

    function CONTRAPTION:XCF_IsXCFContraption()
        return self.XCF_EntitiesCount > 0
    end
end