-- TODO: Add registration for extensions of XCF
-- TODO: Check local version in a client file and receive the server's version for comparison

local XCF = XCF
local Realm = SERVER and "Server" or "Client"

--- Converts a local time to UTC for comparison
local function LocalToUTC(time)
	return os.time(os.date("!*t", time))
end

--- Returns the path of the addon by figuring out where the file is being run from
local function GetAddonPath()
	local info = debug.getinfo(2, "S")                  -- Get the source of the caller (the file that called this function)
	return string.Split(info.short_src, "/lua/")[1]     -- Extract the path before "/lua/"
end

--- Returns the current git branch name
local function GetGitHead(Path)
	local HeadFile = Path .. "/.git/HEAD"
	if not file.Exists(HeadFile, "GAME") then return end

	local content = file.Read(HeadFile, "GAME")
	if not content then return end

	local _, _, head = content:find("refs/heads/(.+)$")  -- Extract the branch name from the content, e.g. "master" from "ref: refs/heads/master"
	if not head then return end

	return head:Trim()
end

--- Returns the current git commit SHA and date for a given branch
local function GetGitCommit(Path, Head)
	if not Head then return end

	local RefPath = Path .. "/.git/refs/heads/" .. Head

	if not file.Exists(RefPath, "GAME") then return end

	local sha = file.Read(RefPath, "GAME")
	if not sha then return end

	local BranchSha = string.GetFileFromFilename(Head) .. "-" .. sha:Trim():sub(1, 7)
	local Time = file.Time(RefPath, "GAME")
	return BranchSha, Time
end

--- Returns the git owner from the URL of the remote repository
local function GetGitOwner(Path)
	local FetchPath = Path .. "/.git/FETCH_HEAD"
	if not file.Exists(FetchPath, "GAME") then return end

	local Fetch = file.Read(FetchPath, "GAME")
	if not Fetch then return end

	local Start, End = Fetch:find("github.com[/]?[:]?[%w_-]+/") -- Extract the owner name from the URL, e.g. "XCF-3" from "github.com/XCF-3/XCF-3"
	if not Start then return end

	return Fetch:sub(Start + 11, End - 1)
end

function XCF.CheckLocalVersion()
	local Path = GetAddonPath()

	local Result = {
		realm = Realm,
		path  = Path,
		head  = "master",
		code  = "Not Installed",
		date  = 0,
		owner = nil
	}

	-- Default result if no installation found
	if not Path then return Result end

	-- Git installation
	if file.Exists(Path .. "/.git/HEAD", "GAME") then
		local Head = GetGitHead(Path)
		local Code, Date = GetGitCommit(Path, Head)

		Result.head  = Head or "master"
		Result.owner = GetGitOwner(Path)

		if Code and Date then
			Result.code = "Git-" .. Code
			Result.date = LocalToUTC(Date)
		end

		return Result
	end

	-- Workshop install
	local WorkshopPath = "data_static/XCF/XCF-3-version.txt"
	if file.Exists(WorkshopPath, "GAME") then
		local FileData = file.Read(WorkshopPath, "GAME"):Trim()
		local Code = FileData:sub(1, 7)
		local Date = file.Time(WorkshopPath, "GAME")

		Result.code = "Git-master-" .. Code
		Result.date = LocalToUTC(Date)

		return Result
	end

	-- ZIP install
	if file.Exists(Path .. "/LICENSE", "GAME") then
		Result.code = "ZIP-Unknown"
		Result.date = LocalToUTC(file.Time(Path .. "/LICENSE", "GAME"))

		return Result
	end

	return Result
end

--- Convert GitHub date string to epoch
local function GitDateToEpoch(dateStr)
	local year, month, day, hour, min, sec = dateStr:match("(%d+)-(%d+)-(%d+)T(%d+):(%d+):(%d+)")
	return os.time({
		year = tonumber(year),
		month = tonumber(month),
		day = tonumber(day),
		hour = tonumber(hour),
		min = tonumber(min),
		sec = tonumber(sec)
	})
end

--- Get information about the latest commit for a given repo and branch
--- Example usage: lua_run XCF.GetLatestCommit("horizon-technologies", "XCF-3", "main", function(_, commit) PrintTable(commit) end)
function XCF.GetLatestCommit(owner, repo, branch, callback)
	local url = ("https://api.github.com/repos/%s/%s/commits?per_page=1&sha=%s"):format(owner, repo, branch)

	HTTP({
		url = url,
		method = "GET",
		success = function(_, body)
			local data = util.JSONToTable(body)
			if not data or not data[1] then
				callback(false)
				return
			end

			local raw = data[1]

			local commit = {
				short_sha  = raw.sha:sub(1, 7),
				message    = raw.commit.message,
				author     = raw.commit.author.name,
				date       = GitDateToEpoch(raw.commit.author.date),
				url        = raw.html_url
			}

			callback(commit)
		end,
		failed = function(err)
			print("HTTP failed:", err)
		end
	})
end

--- Get information about a specific commit by SHA
--- Example usage: lua_run XCF.GetCommit("horizon-technologies", "XCF-3", "abc1234", function(success, commit) PrintTable(commit) end)
function XCF.GetCommit(owner, repo, sha, callback)
	local url = ("https://api.github.com/repos/%s/%s/commits/%s"):format(owner, repo, sha)

	HTTP({
		url = url,
		method = "GET",
		success = function(_, body)
			local data = util.JSONToTable(body)
			if not data or not data.commit then
				callback(false)
				return
			end

			local commit = {
				short_sha  = data.sha:sub(1, 7),
				message    = data.commit.message,
				author     = data.commit.author.name,
				date       = GitDateToEpoch(data.commit.author.date),
				url        = data.html_url
			}

			callback(commit)
		end,
		failed = function(err)
			print("HTTP failed:", err)
		end
	})
end