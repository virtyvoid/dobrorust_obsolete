PLUGIN.Title = "Admin Chat"
PLUGIN.Description = ""
PLUGIN.Author = "DefaultPlayer"
PLUGIN.Version = "1.0"


function PLUGIN:OnUserChat( netuser, name, msg )
	if (msg:sub( 1, 1 ) ~= "/") then
		if (netuser:CanAdmin()) then
			if(msg:sub(1,1) == "!") then
				msg = msg:sub(2)
				local _users = rust.GetAllNetUsers()
				for _, _user in pairs( _users ) do
					rust.NoticeIcon(_user, msg, "ϟ", 6)
				end
			end
			rust.BroadcastChat( name, "[color #ffbf00]".. msg )
			return true
		end
	end
end

