local XCF = XCF

net.Receive("XCF_VersionInfo", function()
    XCF.ServerExtensions = util.JSONToTable(net.ReadString())
end)