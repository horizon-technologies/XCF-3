do -- Networked notifications
	-- Maps encoded notification types to information
	if CLIENT then
		local LastNotificationSoundTime = 0
		net.Receive("XCF_Notify", function()
			local IsOK = net.ReadBool()
			local Msg  = net.ReadString()
			local Type = IsOK and NOTIFY_GENERIC or NOTIFY_ERROR

			local Now = SysTime()
			local DeltaTime = Now - LastNotificationSoundTime

			if not IsOK and DeltaTime > 0.2 then -- Rate limit sounds. Helps with lots of sudden errors not killing your ears
				surface.PlaySound("buttons/button10.wav")
				LastNotificationSoundTime = Now
			end

			Msg = "[XCF] " .. Msg
			notification.AddLegacy(Msg, Type, 7)
		end)
	end

	if SERVER then
		do -- Networked notifications
			util.AddNetworkString("XCF_Notify")

			function XCF.SendNotify(Player, Success, Message)
				net.Start("XCF_Notify")
				net.WriteBool(Success)
				net.WriteString(Message or "")
				net.Send(Player)
			end
		end
	end
end