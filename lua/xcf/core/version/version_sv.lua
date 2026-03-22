local XCF = XCF

do -- Retrieve most recent commit and current server commit and network to all clients
    util.AddNetworkString("XCF_VersionInfo")
    hook.Add("Initialize", "XCF_VersionCheck", function()
        XCF.GetLatestCommit("horizon-technologies", "XCF-3", "main", function(commit)
            XCF.MostRecentCommit = commit
        end)

        XCF.ServerVersion = XCF.CheckLocalVersion()

        hook.Add("XCF_OnLoadPlayer", "XCF_SendVersionInfo", function(ply)
            net.Start("XCF_VersionInfo")
            net.WriteString(util.TableToJSON(XCF.MostRecentCommit or {}))
            net.WriteString(util.TableToJSON(XCF.ServerVersion or {}))
            net.Send(ply)
        end)

        hook.Remove("Initialize", "XCF_VersionCheck")
    end)
end