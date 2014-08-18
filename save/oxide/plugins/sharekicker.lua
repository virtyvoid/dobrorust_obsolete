PLUGIN.Title = "Shared Kicker"
PLUGIN.Author = "DefaultPlayer"
PLUGIN.Version = "1.0"
PLUGIN.Description = ""

-- Форкнутый VAC-kicker с ф-цией повторного запроса.

function PLUGIN:doCheckShare(netuser)
	-- Check steam api for vac bans
	local url ='http://api.steampowered.com/IPlayerService/IsPlayingSharedGame/v0001/?key=00A279CE334CF0A15A61687D24AC9FDF&appid_playing=252490&format=json&steamid='..rust.GetLongUserID(netuser)
	local r = webrequest.Send(url, function(code, response)
        -- Check HTTP-Statuscodes
        if(code == 401) then
            print(self.Title..": ERROR - Webrequest failed. Invalid steam api key")
            return
        elseif(code == 404 or code == 503) then
            print(self.Title..": ERROR - Webrequest failed. Steam api unavailable")
            return
        elseif(code == 200) then
			local response = json.decode(response).response

			local lenderId = tostring(response.lender_steamid)
            local playerInfo = netuser.displayName..' ('..rust.GetLongUserID(netuser)..')'
			if(lenderId ~= '0') then
                netuser:Kick(NetError.Facepunch_API_Failure, true)
                print(self.Title..': '..playerInfo..' is shared the game (owner '..lenderId..')! Kicked.')
            else
				print(self.Title..': '..playerInfo..' not shared the game.')
            end
        else
            print(self.Title..': ERROR - Webrequest failed. Unknown error ('..code..')')
			timer.Once(15, function() self:doCheckShare(netuser) end )
            return
		end
	end)
	if(not r) then
        print(self.Title..': ERROR - Webrequest failed. Unknown error')
        return
    end
end

function PLUGIN:OnUserConnect(netuser)
    -- Check for valid netuser
	if(not netuser) then
		return
    end
	timer.Once(5, function() self:doCheckShare(netuser) end )
end