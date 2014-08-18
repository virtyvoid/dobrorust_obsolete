PLUGIN.Title = "PvP Arena 2"
PLUGIN.Description = ""
PLUGIN.Author = "DefaultPlayer"
PLUGIN.Version = "2.0"

---
local deathMsg = { "пришил", "замочил", "угандошил", "надрал зад", "начистил табло", "намылил шею", "чпокнул", "закатал в асфальт", "навалял", "сделал бо-бо", "выписал путёвку в ад", "отделал" }
local tableUsersInPvP = {}
local tableDeadUsers = {}
---
---
local CZone = {}
local CZone_mt = { __index = CZone }
function CZone:newZone(xPolys, zPolys)

	-- find xMin,xMax/zMin,zMax
	local xMin, xMax = 2147483648, -2147483648
	local zMin, zMax = 2147483648, -2147483648
	for i = 1, #xPolys do
		xMin = math.min(xMin, xPolys[i])
		xMax = math.max(xMax, xPolys[i])
		--
		zMin = math.min(zMin, zPolys[i])
		zMax = math.max(zMax, zPolys[i])
	end

	return setmetatable({
		xPoly = xPolys,
		zPoly = zPolys,
		minX = xMin,
		maxX = xMax,
		minZ = zMin,
		maxZ = zMax,
		settings = { name = "Unnamed", dmgmul = 1.0, invuldeploy = false, invulstruct = false, invulexplosive = false, noannounce = false, pve = false, nodecay = false },
		enabled = true,
		respawnsite = { 0, 0, 0 },
		description = nil
	}, CZone_mt)
end

function CZone:restore(zoneTable)
	return getmetatable(zone) and zoneTable or setmetatable(zoneTable, CZone_mt)
end

function CZone:getCenterDistance(x, z)
	local centerX = (self.minX + self.maxX) / 2
	local centerZ = (self.minZ + self.maxZ) / 2
	return math.sqrt(math.pow(centerX - x, 2) + math.pow(centerZ - z, 2))
end

function CZone:isInZone(x, z)
	assert(#self.xPoly == #self.zPoly, "Omfg")
	local result = false
	local polySides = #self.xPoly
	local j = polySides

	for i = 1, polySides do

		if ((self.zPoly[i] < z and self.zPoly[j] >= z or self.zPoly[j] < z and self.zPoly[i] >= z) and (self.xPoly[i] <= x or self.xPoly[j] <= x)) then
			if (self.xPoly[i] + (z - self.zPoly[i]) / (self.zPoly[j] - self.zPoly[i]) * (self.xPoly[j] - self.xPoly[i]) < x) then
				result = not result
			end
		end
		j = i
	end
	return result
end

function CZone:getMinX() return self.minX end
function CZone:getMaxX() return self.maxX end
function CZone:getMinZ() return self.minZ end
function CZone:getMaxZ() return self.maxZ end
--
function CZone:getPolysX() return self.xPoly end
function CZone:getPolysZ() return self.zPoly end
--
function CZone:getName() return self.settings.name end
function CZone:setName(newName) self.settings.name = newName end
--
function CZone:getSettings() return self.settings end
function CZone:getSetting(key) return self.settings[key] end
function CZone:setSetting(key, value)
	if (type(value) == "string") then
		if (value == "true") then
			value = true
		elseif (value == "false") then
			value = false
		end
	end
	self.settings[key] = value
end
--
function CZone:isEnabled() return self.enabled end
function CZone:setEnabled(flag) self.enabled = flag end
--
function CZone:setRespawnSite(x, y, z) self.respawnsite = { x, y, z } end
function CZone:getRespawnSite() return self.respawnsite end



------
--
local function teleportTo(netUser, vecTbl)
	local vec = new(UnityEngine.Vector3)
	vec.x = vecTbl[1]
	vec.y = vecTbl[2] + 2
	vec.z = vecTbl[3]
	rust.ServerManagement():TeleportPlayer(netUser.playerClient.netPlayer, vec)
	Rust.Rust.Notice.Popup(netUser.networkPlayer, "ツ", "Вы перемещены обратно к PvP-зоне.", 6)
	-- Hint: idMain ?
	--[[timer.Once(1.5, function() 
	
	local body = netUser.playerClient.controllable:GetComponent("HumanBodyTakeDamage")
	local takedamage = netUser.playerClient.controllable:GetComponent("TakeDamage")
	
	end)]]
end

--
---------
-- Essens.
---------
function PLUGIN:OnServerInitialized()
	rust.RunServerCommand("server.pvp true")
	print("PvP Arena 2 - enabled global PvP.")
end

function PLUGIN:Init()
	print("PvP Arena 2 init.")
	self.oxmin = plugins.Find("oxmin")
	self:AddChatCommand("pvp", self.cmdTimer)
	self:AddChatCommand("pvppoint", self.cmdAddPoint)
	self:AddChatCommand("pvpsave", self.cmdSave)
	self:AddChatCommand("pvpflush", self.cmdFlush)
	self:AddChatCommand("pvplist", self.cmdList)
	self:AddChatCommand("pvpdel", self.cmdDel)
	self:AddChatCommand("pvpload", self.cmdLoad)
	self:AddChatCommand("pvpstore", self.cmdStore)
	self:AddChatCommand("pvpreload", self.cmdReload)
	self:AddChatCommand("pvpset", self.cmdSet)
	self:AddChatCommand("pvpteleport", self.cmdTeleport)
	self:AddChatCommand("pvpenable", self.cmdEnable)
	self:AddChatCommand("pvpdisable", self.cmdDisable)
	self:AddChatCommand("pvpdesc", self.cmdDescribe)
	self:LoadConfig()
	typesystem.LoadEnum(Rust.DamageTypeFlags, "DamageType")
	self.THETIMER = timer.Repeat(1.33, function() self:timerTick() end)
	self.REMINDER = timer.Repeat(180, function() self:remindPvP() end)
end

function PLUGIN:Unload()
	print("PvP Arena 2 - UNLOAD")
	if (self.THETIMER) then
		self.THETIMER:Destroy()
		self.THETIMER = nil
		tableUsersInPvP = {}
		tableDeadUsers = {}
	end
	if(self.REMINDER) then
	self.REMINDER:Destroy()
	self.REMINDER = nil
	end
end

function PLUGIN:permCheck(netuser)
	return self.oxmin:HasFlag(netuser, oxmin.strtoflag["cangod"], false)
end
---------
---------
---- Management.
----------------------------------

function PLUGIN:remindPvP()
	local users = rust.GetAllNetUsers()
	for i=0, #users do
		local user = users[i]
		if(user) then
			local steamid = rust.CommunityIDToSteamID(tonumber(rust.GetUserID(user)))
			local zone = tableUsersInPvP[steamid]
			if(zone) then zone = zone["zone"] end
			if(zone and zone:isEnabled() and not zone:getSetting("pve")) then
				Rust.Rust.Notice.Popup(user.networkPlayer, "☠", "Напоминаем: Вы в PvP зоне " .. zone:getName() .. "!", 5.50)
				rust.SendChatToUser(user, "[PvP]", "Напоминаем: [color #FF8A3D]Вы в PvP зоне[/color] [color #EAC300]" .. zone:getName() .. "[/color]!")
			end
		end
	end
end

function PLUGIN:timerTick()
	local users = rust.GetAllNetUsers()
	if (not users or not self.Config or not self.Config.AreasObj) then return end
	for i = 1, #users do
		if (users[i]) then
			local user = users[i]
			local x, z = user.playerClient.lastKnownPosition.x, user.playerClient.lastKnownPosition.z
			--
			for zoneIdx = 1, #self.Config.AreasObj do
				self:managePvPStatus(user, self.Config.AreasObj[zoneIdx], self.Config.AreasObj[zoneIdx]:isInZone(x, z), zoneIdx)
			end
		end
	end
end

function PLUGIN:managePvPStatus(netuser, zoneObj, isInPvP, zoneid)
	local steamid = rust.CommunityIDToSteamID(tonumber(rust.GetUserID(netuser)))
	local zoneName = zoneObj:getName()
	if (isInPvP) then
		if (not tableUsersInPvP[steamid] and zoneObj:isEnabled()) then
			tableUsersInPvP[steamid] = { id = zoneid, settings = zoneObj:getSettings(), zone = zoneObj }

			if(zoneObj.description) then
				Rust.Rust.Notice.Popup(netuser.networkPlayer, "✌", tostring(zoneObj.description), 8.88)
				return
			end

			if (zoneObj:getSetting("noannounce")) then
				return
			end

			if(zoneObj:getSetting("pve")) then
				Rust.Rust.Notice.Popup(netuser.networkPlayer, "✌", "Вы зашли в зону \"" .. zoneName .. "\".", 5.50)
				rust.SendChatToUser(netuser, "[Zone]", "Вы зашли в зону \"" .. zoneName .. "\".")
				return
			end


			Rust.Rust.Notice.Popup(netuser.networkPlayer, "☠", "Внимание! Вы зашли в PvP зону " .. zoneName .. "!", 5.50)
			rust.SendChatToUser(netuser, "[PvP]", "Вы зашли в PvP зону [color #EAC300]" .. zoneName .. "[/color]!")
			rust.SendChatToUser(netuser, "[PvP]", "[color #FF8A3D]В PvP зонах разрешен урон по игрокам.")
			if (zoneObj:getSetting("dmgmul") ~= 1.0) then
				rust.SendChatToUser(netuser, "[PvP]", "В этой зоне урон отличается на " .. string.format("%i", (zoneObj:getSetting("dmgmul") * 100) - 100) .. "%!")
			end
			if (zoneObj:getSetting("invulexplosive")) then
				rust.SendChatToUser(netuser, "[PvP]", "В этой зоне урон от взрывчатки отсутствует!")
			end

		elseif (tableUsersInPvP[steamid] and not zoneObj:isEnabled()) then
			tableUsersInPvP[steamid] = nil
			Rust.Rust.Notice.Popup(netuser.networkPlayer, "☮", "Внимание! Зона " .. zoneName .. " отключена!", 5.50)
		end
	elseif (not isInPvP) then
		if (tableUsersInPvP[steamid] and tableUsersInPvP[steamid]["id"] == zoneid) then
			tableUsersInPvP[steamid] = nil
			if ( zoneObj:getSetting("noannounce")) then
				return
			end

			if(zoneObj:getSetting("pve")) then
				Rust.Rust.Notice.Popup(netuser.networkPlayer, "✌", "Вы вышли из зоны \"" .. zoneName .. "\".", 5.50)
				rust.SendChatToUser(netuser, "[Zone]", "Вы вышли из зоны \"" .. zoneName .. "\".")
				return
			end

			Rust.Rust.Notice.Popup(netuser.networkPlayer, "☮", "Внимание! Вы вышли из PvP зоны " .. zoneName .. "!", 5.50)
			rust.SendChatToUser(netuser, "[PvP]", "Вы покинули PvP зону " .. zoneName .. "!")
		end
	end
end

----------------------------------
---- Hook handlers.
----------------------------------

function PLUGIN:OnSpawnPlayer(playerclient, usecamp, avatar)
	if (not playerclient or not playerclient.netPlayer) then return end
	local steamid = rust.CommunityIDToSteamID(tonumber(rust.GetUserID(rust.NetUserFromNetPlayer(playerclient.netPlayer))))
	if (usecamp) then tableDeadUsers[steamid] = nil return end
	local site = tableDeadUsers[steamid]
	if (site and (site[1] + site[2] + site[3]) == 0) then
		site = nil
	end
	tableDeadUsers[steamid] = nil
	if (site) then
		timer.Once(2, function() teleportTo(rust.NetUserFromNetPlayer(playerclient.netPlayer), site) end)
	else
	end
end

function PLUGIN:OnUserDisconnect(networkplayer)
	local netuser = networkplayer:GetLocalData()
	if (not netuser or netuser:GetType().Name ~= "NetUser") then
		return
	end
	local steamid = rust.CommunityIDToSteamID(tonumber(rust.GetUserID(netuser)))
	if (tableDeadUsers[steamid]) then
		tableDeadUsers[steamid] = nil
	end
	if (tableUsersInPvP[steamid]) then
		tableUsersInPvP[steamid] = nil
		print("Arena: Popped out " .. netuser.displayName .. " from PvP Zone.")
	end
end

function PLUGIN:OnKilled(takedamage, damage)
	local victim = takedamage:GetComponent("HumanController")
	if (not victim or not victim.networkViewOwner) then
		return
	end
	
	if(damage.attacker and damage.victim and (damage.attacker.client == damage.victim.client)) then
		rust.BroadcastChat("[Некролог]", " [color #6E5BFF]"..damage.attacker.client.netUser.displayName .. "[/color] убился :(")
		return
	end
	
	local netUserVictim = rust.NetUserFromNetPlayer(victim.networkViewOwner)
	local steamid = rust.CommunityIDToSteamID(tonumber(rust.GetUserID(netUserVictim)))
	if (tableUsersInPvP[steamid]) then
		local respVec = tableUsersInPvP[steamid]["zone"]:getRespawnSite()
		if((respVec[1] + respVec[2] + respVec[3]) ~= 0) then
			tableDeadUsers[steamid] = respVec
		end
	-- else
	end

	if (not damage.attacker or not damage.attacker.client or not damage.attacker.client.netUser
			or damage.attacker.client == damage.victim.client or damage.attacker.userID == damage.victim.userID) then
		return
	end
	--[[local takedamageAtk = damage.attacker.client.controllable:GetComponent("TakeDamage")
	rust.BroadcastChat("[PvP]", "☠ [color #6E5BFF]"..damage.attacker.client.netUser.displayName .. "[/color](".. string.format("%i",takedamageAtk.health) .."HP) " .. deathMsg[math.random(1, #deathMsg)] .. " [color #FF6A00]" .. damage.victim.client.netUser.displayName 
										.. "[/color]("..string.format("%i",takedamage.health - damage.amount).. "HP).")]]
	rust.BroadcastChat("[PvP]", "☠ [color #6E5BFF]"..damage.attacker.client.netUser.displayName .. "[/color] " .. deathMsg[math.random(1, #deathMsg)] .. " [color #FF6A00]" .. damage.victim.client.netUser.displayName .. "[/color].")
	print("PvPArena: " .. damage.attacker.client.netUser.displayName .. " killed " .. damage.victim.client.netUser.displayName .. ".")
end

function PLUGIN:ModifyDamage(takedamage, damage)

	if (tostring(damage.status) == tostring(LifeStatus.IsDead)) then
		return damage
	end

	local objDepl = takedamage:GetComponent("DeployableObject")
	local objStruct = takedamage:GetComponent("StructureComponent")
	if (objDepl or objStruct) then
		local obj = objDepl or objStruct
		local x, z = obj.transform.position.x, obj.transform.position.z
		local zone
		for zoneIdx = 1, #self.Config.AreasObj do
			if (self.Config.AreasObj[zoneIdx]:isInZone(x, z)) then
				zone = self.Config.AreasObj[zoneIdx]
				break
			end
		end
		if (zone) then
			if (objDepl and zone:getSetting("invuldeploy") or objStruct and zone:getSetting("invulstruct") or
					tostring(damage.damageTypes) == tostring(DamageType.damage_explosion) and zone:getSetting("invulexplosive")
					or (zone:getSetting("nodecay") and tostring(damage.attacker):find("EnvDecay"))) then
				damage.amount = 0
				damage.status = LifeStatus.IsAlive
			elseif (not tostring(damage.attacker):find("EnvDecay")) then -- do not modify decay dmg.
				damage.amount = damage.amount * zone:getSetting("dmgmul")
				if (takedamage.health - damage.amount < 0) then
					damage.status = LifeStatus.WasKilled -- negative hp fix.
				end
			end
			return damage
		end
	end

	-- from now: always skip environment damages (poison, rad, starve, bleed).
	if (tostring(damage.damageTypes) == "0: 0") then
		return damage
	end

	local victim = takedamage:GetComponent("HumanController")
	if (not victim or not victim.networkViewOwner or not damage.victim or not damage.victim.client or not
	damage.attacker or not damage.attacker.client or not damage.attacker.client.netUser
			or damage.attacker.client == damage.victim.client or damage.attacker.userID == damage.victim.userID) then
		return damage
	end

	local netUserVictim = rust.NetUserFromNetPlayer(victim.networkViewOwner)
	local netUserPlayer = damage.attacker.client.netUser
	----
	local steamidVictim = rust.CommunityIDToSteamID(tonumber(rust.GetUserID(netUserVictim)))
	local steamidPlayer = rust.CommunityIDToSteamID(tonumber(rust.GetUserID(netUserPlayer)))
	----
	-- both in pvp area, allow dmg.
	if (tableUsersInPvP[steamidPlayer] and tableUsersInPvP[steamidVictim] and tableUsersInPvP[steamidPlayer]["id"] == tableUsersInPvP[steamidVictim]["id"] and not tableUsersInPvP[steamidPlayer]["settings"]["pve"]) then
		damage.amount = damage.amount * tableUsersInPvP[steamidPlayer]["settings"]["dmgmul"]

		if (takedamage.health - damage.amount < 0 or tostring(damage.status) == tostring(LifeStatus.WasKilled)) then -- negative hp fix / harmless handling
			damage.status = LifeStatus.WasKilled
		end
		return damage
	end

	-- bad conditions, no dmg.
	damage.amount = 0
	damage.status = LifeStatus.IsAlive
	-- damage.damageTypes = DamageType.damage_melee
	return damage
end


----------------------------------
----------------------------------
---- Command handlers.
----------------------------------


function PLUGIN:cmdTimer(netuser, cmd, args)
	if not self:permCheck(netuser) then return end
	if (self.THETIMER) then
		self.THETIMER:Destroy()
		self.THETIMER = nil
		tableUsersInPvP = {}
		tableDeadUsers = {}
		rust.SendChatToUser(netuser, "PvP Stopped");
	else
		tableUsersInPvP = {}
		tableDeadUsers = {}
		self.THETIMER = timer.Repeat(1.33, function() self:timerTick() end)
		rust.SendChatToUser(netuser, "PvP Started");
	end
end

function PLUGIN:cmdReload(netuser, cmd, args)
	if not self:permCheck(netuser) then return end
	if (self.THETIMER) then
		self.THETIMER:Destroy()
		self.THETIMER = nil
	end
	tableUsersInPvP = {}
	tableDeadUsers = {}
	self.Config = {}
	rust.SendChatToUser(netuser, "PvP Stopped, reloading..");
	cs.reloadplugin("pvparena2")
	rust.SendChatToUser(netuser, "Reloaded!");
	-- rust.RunServerCommand("oxide.reload pvparena")
end

function PLUGIN:cmdSave(netuser, cmd, args)
	if not self:permCheck(netuser) then return end
	if not args[1] then return end
	if (#self.Config.PendingPoints[1] >= 3) then
		local newZoneObj = CZone:newZone(self.Config.PendingPoints[1], self.Config.PendingPoints[2])
		newZoneObj:setName(args[1])
		rust.SendChatToUser(netuser, "New Zone added!");
		table.insert(self.Config.AreasObj, newZoneObj)
		self.Config.PendingPoints = { {}, {} }
		return
	else
		rust.SendChatToUser(netuser, "Zone is incomplete (" .. tostring(#self.Config.PendingPoints[1]) .. " < 3).")
	end
end

function PLUGIN:cmdStore(netuser, cmd, args)
	if not self:permCheck(netuser) then return end
	local saveTo = args[1] or "PvPArena2"
	config.Save(saveTo)
	rust.SendChatToUser(netuser, "All saved to " .. saveTo .. ".")
end

function PLUGIN:cmdLoad(netuser, cmd, args)
	if not self:permCheck(netuser) then return end
	local readFrom = args[1] or "PvPArena2"
	local a, b = config.Read(readFrom)
	if (not a or not b) then rust.SendChatToUser(netuser, "Config load from " .. readFrom .. " failed.") return end
	for idx = 1, #b.AreasObj do
		b.AreasObj[idx] = CZone:restore(b.AreasObj[idx])
	end
	self.Config = b
	rust.SendChatToUser(netuser, "Config loaded from " .. readFrom .. ".")
end

function PLUGIN:cmdFlush(netuser, cmd, args)
	if not self:permCheck(netuser) then return end
	self.Config.PendingPoints = { {}, {} }
	rust.SendChatToUser(netuser, "Pending zone flushed.")
end

function PLUGIN:cmdList(netuser, cmd, args)
	if not self:permCheck(netuser) then return end
	local x, z = netuser.playerClient.lastKnownPosition.x, netuser.playerClient.lastKnownPosition.z
	rust.SendChatToUser(netuser, " === PvP Zones === ")
	for zoneIdx = 1, #self.Config.AreasObj do
		local status = (function() if (not self.Config.AreasObj[zoneIdx]:isEnabled()) then return "[✘] " else return "" end end)()
		rust.SendChatToUser(netuser, status .. "Idx " .. tostring(zoneIdx) .. ", Name: " .. self.Config.AreasObj[zoneIdx]:getName() .. ", Dist: " .. string.format("%i", self.Config.AreasObj[zoneIdx]:getCenterDistance(x, z)))
		rust.SendChatToUser(netuser, "˙˙˙˙˙: " .. (function() local buf = ""; for k, v in pairs(self.Config.AreasObj[zoneIdx]:getSettings()) do buf = buf .. tostring(k) .. "=" .. tostring(v) .. ", " end return buf:sub(1, #buf - 2) end)())
	end
	rust.SendChatToUser(netuser, "=== End ===");
end

function PLUGIN:cmdDel(netuser, cmd, args)
	if not self:permCheck(netuser) then return end
	if not args[1] then return end
	if tonumber(args[1]) > #self.Config.AreasObj then rust.SendChatToUser(netuser, "Invalid Index.") return end
	local zName = self.Config.AreasObj[tonumber(args[1])]:getName()
	table.remove(self.Config.AreasObj, tonumber(args[1]))
	for k, v in pairs(tableUsersInPvP) do
		if (v and v["id"] == tonumber(args[1])) then
			tableUsersInPvP[k] = nil
			print("PvPArena: Evacuated player from removed zone.")
		end
	end
	rust.SendChatToUser(netuser, "Zone #" .. args[1] .. " (" .. zName .. ") deleted.")
end

function PLUGIN:cmdSet(netuser, cmd, args)
	if not self:permCheck(netuser) then return end
	if not args[1] or not args[2] or not args[3] then Rust.Rust.Notice.Popup(netuser.networkPlayer, "!", "Syntax: /pvpset ID KEY VALUE", 3) return end
	if tonumber(args[1]) > #self.Config.AreasObj then rust.SendChatToUser(netuser, "Invalid Index.") return end
	local zone = self.Config.AreasObj[tonumber(args[1])]
	if (zone:getSetting(args[2]) == nil) then Rust.Rust.Notice.Popup(netuser.networkPlayer, "!", "Illegal Key.", 3) return end
	args[2] = args[2]:lower()
	args[3] = args[3]:lower()
	zone:setSetting(args[2], args[3])
	Rust.Rust.Notice.Popup(netuser.networkPlayer, "✔", "Key " .. args[2] .. " set to " .. args[3] .. " on zone #" .. args[1] .. ".", 5)
end

function PLUGIN:cmdTeleport(netuser, cmd, args)
	if not self:permCheck(netuser) then return end
	if not args[1] then Rust.Rust.Notice.Popup(netuser.networkPlayer, "!", "Syntax: /pvpteleport ID", 3) return end
	if tonumber(args[1]) > #self.Config.AreasObj then rust.SendChatToUser(netuser, "Invalid Index.") return end
	local zone = self.Config.AreasObj[tonumber(args[1])]
	local coords = netuser.playerClient.lastKnownPosition
	zone:setRespawnSite(coords.x, coords.y, coords.z)
	Rust.Rust.Notice.Popup(netuser.networkPlayer, "✔", "Current pos set on zone #" .. args[1] .. ".", 5)
end

function PLUGIN:cmdEnable(netuser, cmd, args)
	if not self:permCheck(netuser) then return end
	if not args[1] then Rust.Rust.Notice.Popup(netuser.networkPlayer, "!", "Syntax: /pvpenable ID", 3) return end
	if tonumber(args[1]) > #self.Config.AreasObj then rust.SendChatToUser(netuser, "Invalid Index.") return end
	local zone = self.Config.AreasObj[tonumber(args[1])]
	zone:setEnabled(true)
	Rust.Rust.Notice.Popup(netuser.networkPlayer, "✔", "Enabled zone #" .. args[1] .. ".", 5)
end

function PLUGIN:cmdDisable(netuser, cmd, args)
	if not self:permCheck(netuser) then return end
	if not args[1] then Rust.Rust.Notice.Popup(netuser.networkPlayer, "!", "Syntax: /pvpdisable ID", 3) return end
	if tonumber(args[1]) > #self.Config.AreasObj then rust.SendChatToUser(netuser, "Invalid Index.") return end
	local zone = self.Config.AreasObj[tonumber(args[1])]
	zone:setEnabled(false)
	Rust.Rust.Notice.Popup(netuser.networkPlayer, "✘", "Disabled zone #" .. args[1] .. ".", 5)
end

function PLUGIN:cmdDescribe(netuser, cmd, args)
	if not self:permCheck(netuser) then return end
	if not args[1] or not args[2] then Rust.Rust.Notice.Popup(netuser.networkPlayer, "!", "Syntax: /pvpdescribe ID \"TEXT\"", 3) return end
	if tonumber(args[1]) > #self.Config.AreasObj then rust.SendChatToUser(netuser, "Invalid Index.") return end
	local zone = self.Config.AreasObj[tonumber(args[1])]
	if (args[2] == "null")
	then
		zone.description = nil
		Rust.Rust.Notice.Popup(netuser.networkPlayer, "✘", "Zone #" .. args[1] .. " became normal (PvP).", 5)
		zone:setSetting("pve", false)
		zone:setSetting("noannounce", false)
		return
	end
	zone.description = args[2]
	zone:setSetting("pve", true)
	zone:setSetting("noannounce", true)
	Rust.Rust.Notice.Popup(netuser.networkPlayer, "✔", "Turned zone #" .. args[1] .. " into description-zone (PvE).", 5)
end

function PLUGIN:cmdAddPoint(netuser, cmd, args)
	if not self:permCheck(netuser) then return end
	if (#self.Config.PendingPoints == 0) then self.Config.PendingPoints = { {}, {} } end

	local x, z = netuser.playerClient.lastKnownPosition.x, netuser.playerClient.lastKnownPosition.z
	table.insert(self.Config.PendingPoints[1], x)
	table.insert(self.Config.PendingPoints[2], z)
	rust.SendChatToUser(netuser, "Point " .. tostring(#self.Config.PendingPoints[1]) .. " Added.")
end

-----------------------------------
---- Config Management.
-----------------------------------

function PLUGIN:LoadConfig()
	local b, res = config.Read("PvPArena2")
	if not res then print("Arena config (res) is nil?!") end
	if (res and res.AreasObj) then
		for idx = 1, #res.AreasObj do
			res.AreasObj[idx] = CZone:restore(res.AreasObj[idx])
		end
	end
	self.Config = res or {}
	if (not b) then
		self:LoadDefaultConfig()
		if (res) then config.Save("PvPArena2")
		end
	end
end

function PLUGIN:LoadDefaultConfig()
	print("Arena2 loaded with default configuration!")
	self.Config.PendingPoints = { {}, {} }
	self.Config.AreasObj = {}
end