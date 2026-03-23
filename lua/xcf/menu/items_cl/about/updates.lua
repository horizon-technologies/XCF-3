-- TODO: deal with running out of github API calls

local function DrawGitCommit(Menu, Commit)
	local Base = Menu:AddCollapsible("Latest Commit", false)
	Base:AddLabel(Commit.title)
	Base:AddLabel("Message: " .. Commit.body)
	Base:AddLabel("Author: " .. Commit.author)
	Base:AddLabel("Date: " .. os.date("%Y-%m-%d %H:%M:%S", Commit.date))
	Base:AddButton("View on GitHub", function() gui.OpenURL(Commit.url) end)
end

local function DrawGitStatus(Menu, Version, MostRecentCommit)
	local Base = Menu:AddCollapsible("[" .. Version.path .. "] - " .. Version.realm .. "", true, Version.realm == "Server" and "icon16/Server.png" or "icon16/computer.png")
	local Outdated = Version.date < MostRecentCommit.date
	Base:AddLabel("Status: " .. (Outdated and "Outdated" or "Up to Date")):SetColor(Outdated and Color(255, 100, 100) or Color(100, 255, 100))
	Base:AddLabel("Branch: " .. Version.head)
	Base:AddLabel("Commit: " .. Version.code)

	Base:SetTooltip("Click to copy version info to clipboard")
	function Base:OnMousePressed(Enum)
		if Enum ~= MOUSE_LEFT then return end
		SetClipboardText(Version.code)
	end

	DrawGitCommit(Base, MostRecentCommit)
end

local function CreateMenu(Menu)
	DrawGitStatus(Menu, XCF.ClientVersion, XCF.MostRecentCommit)
	DrawGitStatus(Menu, XCF.ServerVersion, XCF.MostRecentCommit)
end

XCF.AddMenuItem(2, "Updates", "icon16/newspaper.png", CreateMenu, "About")