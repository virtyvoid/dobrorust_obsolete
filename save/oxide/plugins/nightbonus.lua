PLUGIN.Title = "Night Bonus"
PLUGIN.Description = ""
PLUGIN.Author = "DefaultPlayer"
PLUGIN.Version = "1.0"

-- Из-за бага в NLua пришлось реализовать всё через жопу. Вертел я на детородном органе Lua, NLua и вообще весь Oxide..
-- Куски кода оставил тут как память о двухдневной битве с этим дерьмом.

local isNight = function() return Rust.EnvironmentControlCenter.Singleton:IsNight() end
local lastState = false
local origSettings = {}

--[[local function makeSingleOf(str)
	local stm = util.GetStaticMethod(System.Single._type, "Parse")
	return stm[0]:Invoke(nil, util.ArrayFromTable( cs.gettype("System.Object"), {str}))
end]]

local function saveOriginalSettings()
	origSettings["craftScale"] = string.format("%.2f", Rust.crafting.timescale)
	origSettings["armorHealth"] = string.format("%.2f", Rust.conditionloss.armorhealthmult)
	origSettings["weaponHealth"] = string.format("%.2f", Rust.conditionloss.damagemultiplier)
	print("Orig:", origSettings["craftScale"], origSettings["armorHealth"], origSettings["weaponHealth"])
	print("NightBonus: Settings preserved.")
end

local function setNightSettings()
	--[[Rust.crafting.timescale = makeSingleOf("0.10") --0.10
	Rust.conditionloss.armorhealthmult = makeSingleOf(0) --0.00
	Rust.conditionloss.damagemultiplier =  makeSingleOf(0) --0.00 ]]
	rust.RunServerCommand("crafting.timescale 0.10")
	rust.RunServerCommand("conditionloss.armorhealthmult 0")
	rust.RunServerCommand("conditionloss.damagemultiplier 0")
	print("NewSets:", origSettings["craftScale"], origSettings["armorHealth"], origSettings["weaponHealth"])
	print("NightBonus: Applied night settings.")
end

local function revertOriginalSettings()
	--[[Rust.crafting.timescale = makeSingleOf(origSettings["craftScale"])
	Rust.conditionloss.armorhealthmult = makeSingleOf(origSettings["armorHealth"])
	Rust.conditionloss.damagemultiplier = makeSingleOf(origSettings["weaponHealth"])]]
	--rust.RunServerCommand("crafting.timescale \""..origSettings["craftScale"].."\"")
	--rust.RunServerCommand("conditionloss.armorhealthmult \""..origSettings["armorHealth"].."\"")
	--rust.RunServerCommand("conditionloss.damagemultiplier \""..origSettings["weaponHealth"].."\"")
	--print("RevertTo:", origSettings["craftScale"], origSettings["armorHealth"], origSettings["weaponHealth"])
	rust.RunServerCommand("crafting.timescale "..origSettings["craftScale"])
	rust.RunServerCommand("conditionloss.armorhealthmult "..origSettings["armorHealth"])
	rust.RunServerCommand("conditionloss.damagemultiplier "..origSettings["weaponHealth"])
	print("Revert:", origSettings["craftScale"], origSettings["armorHealth"], origSettings["weaponHealth"])
	print("NightBonus: Setting reverted back.")
end

local function timeCheck()
	local n = isNight()
	if(n == lastState) then return end
	lastState = n
	if(n) then
		setNightSettings()
	else
		revertOriginalSettings()
	end
end

function PLUGIN:OnServerInitialized()
	saveOriginalSettings()
	self.timer = timer.Repeat(20, function() timeCheck() end)
end

function PLUGIN:Unload()
	if(self.timer) then
		self.timer:Destroy()
		self.timer = nil
	end
	pcall(function() revertOriginalSettings() end)
end