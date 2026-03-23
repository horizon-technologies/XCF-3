local XCF = XCF

do -- Retrieve most recent commit and current server commit and network to all clients
    util.AddNetworkString("XCF_VersionInfo")
    hook.Add("XCF_OnLoadPlayer", "XCF_SendVersionInfo", function(ply)
        net.Start("XCF_VersionInfo")
        net.WriteString(util.TableToJSON(XCF.Extensions or {}))
        net.Send(ply)
    end)
end