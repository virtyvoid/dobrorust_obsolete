PLUGIN.Title = "Temp Door Ownership"
PLUGIN.Description = ""
PLUGIN.Version = "1.0"
PLUGIN.Author = "DefaultPlayer"

local TempDoorAdmin = {} -- steamids
local TempDoorOwners = {} -- {steamid,hash}

function PLUGIN:Init()
	self.oxmin = plugins.Find("oxmin")
 	self:AddChatCommand( "markdoor", self.cmdTemp )
	self:LoadConfig()
 	print("Loaded Temp Door Owning.")
end

function PLUGIN:permCheck(netuser)
	return self.oxmin:HasFlag(netuser, oxmin.strtoflag["cangod"], false)
end

function PLUGIN:cmdTemp(netuser, cmd, args)
		if (netuser:CanAdmin()) or (self:permCheck(netuser)) then
			local steamID = rust.CommunityIDToSteamID(tonumber(rust.GetUserID(netuser)))

			if TempDoorAdmin[steamID] then
					TempDoorAdmin[steamID] = nil
					rust.Notice(netuser, "Door marking disabled.")
			else
					TempDoorAdmin[steamID] = true
					rust.Notice(netuser, "Door marking enabled.")
			end
		else
				rust.Notice( netuser, "You do not have permission to use this command.")
		end
end

function PLUGIN:OnHurt(takedamage, damage)
	if(damage and damage.attacker and damage.attacker.client and damage.attacker.client.netUser) then
		local steamID = rust.CommunityIDToSteamID(  tonumber(rust.GetUserID(damage.attacker.client.netUser)))
		if(not TempDoorAdmin[steamID]) then return end
		local depl = takedamage.GameObject:GetComponent("DeployableObject")
		if(not depl or not takedamage.gameObject.Name == "WoodenDoor(Clone)" or not takedamage.gameObject.Name == "MetalDoor(Clone)") then return end

		local door = takedamage.GameObject:GetComponent("BasicDoor")
		local origPos = typesystem.GetField(Rust.BasicDoor, "originalLocalPosition", bf.private_instance)(door)
		
		-- Просто первое что пришло на ум, главное работает.
		local doorhash = math.floor(bit32.lshift(math.abs(origPos.x)*3,8) + bit32.lshift(math.abs(origPos.y)*2,4) + math.abs(origPos.z)*4)
		
		rust.SendChatToUser(damage.attacker.client.netUser, "This door hash is "..tostring(doorhash))
		for i=1, #self.Config.TempDoors do
			if(self.Config.TempDoors[i]==doorhash) then
				rust.Notice(damage.attacker.client.netUser, "Door UN-marked!")
				table.remove(self.Config.TempDoors, i)
				config.Save("TempDoor")
				return
			end
		end
		table.insert(self.Config.TempDoors,doorhash)
		rust.Notice(damage.attacker.client.netUser, "Door marked as ownable!")
		config.Save("TempDoor")
	end
end

function PLUGIN:CanOpenDoor( netuser, door )
	-- Get n' validate the deployable
	local deployable = door:GetComponent( "DeployableObject" )
	if (not deployable) then return end
	local ldoor = door:GetComponent("BasicDoor")
	if(not ldoor) then return end

	local origPos = typesystem.GetField(Rust.BasicDoor, "originalLocalPosition", bf.private_instance)(ldoor)
	local doorhash = math.floor(bit32.lshift(math.abs(origPos.x)*3,8) + bit32.lshift(math.abs(origPos.y)*2,4) + math.abs(origPos.z)*4)

	local steamID = rust.CommunityIDToSteamID(tonumber(rust.GetUserID(netuser)))

	for i=1, #TempDoorOwners do
		if(TempDoorOwners[i][1] == steamID) then
			if(TempDoorOwners[i][2] == doorhash) then
				return true
			end
			return false
		elseif(TempDoorOwners[i][2] == doorhash and not TempDoorOwners[i][1] == steamID) then
			Rust.Rust.Notice.Popup(netuser.networkPlayer, "✘", "Закрыто. Сейчас эта дверь кем-то занята.", 5)
			return false
		end
	end

	local isTemp
	for i=1, #self.Config.TempDoors do if(self.Config.TempDoors[i]==doorhash) then isTemp=true; break; end end
	if(not isTemp) then return nil end

	table.insert(TempDoorOwners, {steamID, doorhash})
	Rust.Rust.Notice.Popup(netuser.networkPlayer, "✔", "Теперь это ваша дверь на ближайшие 30 минут !", 9)
	timer.Once(1800, function() for i=1, #TempDoorOwners do
		if(TempDoorOwners[i][1] == steamID) then
			table.remove(TempDoorOwners, i);
			if(netuser.networkPlayer.isConnected) then
				Rust.Rust.Notice.Popup(netuser.networkPlayer, "‼", "Время владения общей дверью истекло !", 9)
			end
			break
		end end end)
	return true
end

-----------------------------------
---- Config Management.
-----------------------------------

function PLUGIN:LoadConfig()
	local b, res = config.Read("TempDoor")
	if not res then print("TempDoor config (res) is nil?!") end
	self.Config = res or {}
	if (not b or not self.Config.TempDoors) then
		self:LoadDefaultConfig()
		if (res) then config.Save("TempDoor")
		end
	end
	print("Loaded doors: "..tostring(#self.Config.TempDoors))
end

function PLUGIN:LoadDefaultConfig()
	self.Config.TempDoors = {}
end