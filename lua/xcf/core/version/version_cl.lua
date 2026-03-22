local XCF = XCF

net.Receive("XCF_VersionInfo", function()
    XCF.MostRecentCommit = util.JSONToTable(net.ReadString())
    XCF.ServerVersion = util.JSONToTable(net.ReadString())
end)

-- Only runs for this client
hook.Add("XCF_OnLoadPlayer", "XCF_VersionInfo", function(_)
    XCF.ClientVersion = XCF.CheckLocalVersion()
end)