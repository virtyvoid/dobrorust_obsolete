PLUGIN.Title = "Go!"
PLUGIN.Description = ""
PLUGIN.Author = "DefaultPlayer"
PLUGIN.Version = "1.0"

-- Плагинчик для удобной телепортации себя или другого. Сколько же приколов с его помощью было совершено...

local FLAG_GO = nil
local PrevPos = {}

function PLUGIN:Init()
    print("Go! init.")
    FLAG_GO = oxmin:AddFlag("go")
    self:AddChatCommand("go", self.cmdGo)
    self:AddChatCommand("go2", self.cmdGoTwo)
    self:AddChatCommand("goback", self.cmdGoBack)
end

function PLUGIN:cmdGo (netuser, cmd, args)
    if not oxmin_Plugin:HasFlag( netuser, FLAG_GO, false )
    then return false end

    if(#args ~= 3) then
        Rust.Rust.Notice.Popup( netuser.networkPlayer, "☠", "/go dX dY dZ (/go 0 40 0)", 4.0 )
        return false
    end

    local coords = netuser.playerClient.lastKnownPosition
    PrevPos[rust.GetUserID(netuser)]=coords
    coords = netuser.playerClient.lastKnownPosition
    coords.x = coords.x + tonumber(args[1])
    coords.y = coords.y + tonumber(args[2])
    coords.z = coords.z + tonumber(args[3])
    rust.ServerManagement():TeleportPlayer(netuser.playerClient.netPlayer, coords)
    Rust.Rust.Notice.Popup( netuser.networkPlayer, "✈", "Вот и передвинулись :)", 4.0 )
end

function PLUGIN:cmdGoTwo (netuser, cmd, args)
	if (#args ~= 4) then
		rust.Notice( netuser, "Syntax: /go2 \"nick\" dX dY dZ" )
		return
	end
	local b, targetuser = rust.FindNetUsersByName( args[1] )
	if (not b) then
		if (targetuser == 0) then
			rust.Notice( netuser, "No players found with that name!" )
		else
			rust.Notice( netuser, "Multiple players found with that name!" )
		end
		return
	end
	local coords = targetuser.playerClient.lastKnownPosition
	coords.x = coords.x + tonumber(args[2])
    coords.y = coords.y + tonumber(args[3])
    coords.z = coords.z + tonumber(args[4])
	rust.ServerManagement():TeleportPlayer(targetuser.networkPlayer, coords)
	Rust.Rust.Notice.Popup( netuser.networkPlayer, "✈", "Передвинули ".. args[1] .." :)", 4.0 )
		
end


function PLUGIN:cmdGoBack (netuser, cmd, args)
    if not oxmin_Plugin:HasFlag( netuser, FLAG_GO, false )
    then return false end

    if(not PrevPos[rust.GetUserID(netuser)]) then
        Rust.Rust.Notice.Popup( netuser.networkPlayer, "✘", "Предыдущей позиции нет.", 4.0 )
        return false
    end


    local coords = PrevPos[rust.GetUserID(netuser)]
    PrevPos[rust.GetUserID(netuser)]=nil
    rust.ServerManagement():TeleportPlayer(netuser.playerClient.netPlayer, coords)
    Rust.Rust.Notice.Popup( netuser.networkPlayer, "✈", "Вернулись назад.", 4.0 )
end