local XCF = XCF

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

--- Fetch latest commit for a given repo and branch
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

            callback(true, commit)
        end,
        failed = function(err)
            print("HTTP failed:", err)
            callback(false)
        end
    })
end