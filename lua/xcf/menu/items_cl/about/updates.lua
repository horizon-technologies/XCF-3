local function DrawGitStatus(Menu, Result)
    local Base = Menu:AddCollapsible("[" .. Result.path .. "] - " .. Result.realm .. "", true, Result.realm == "Server" and "icon16/Server.png" or "icon16/computer.png")
    Base:AddLabel("Branch: " .. Result.head)
    Base:AddLabel("Commit: " .. Result.code)
end

local function CreateMenu(Menu)
    DrawGitStatus(Menu, XCF.ClientVersion)
    DrawGitStatus(Menu, XCF.ServerVersion)
end

XCF.AddMenuItem(2, "Updates", "icon16/newspaper.png", CreateMenu, "About")