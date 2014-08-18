PLUGIN.Title = "Welcome"
PLUGIN.Description = ""
PLUGIN.Author = "DefaultPlayer"
PLUGIN.Version = "1.0"

local vTimeOfDay = function() return Rust.EnvironmentControlCenter.Singleton:GetTime() end

local function showWelcome(netuser)
	local timeOrig = tonumber(vTimeOfDay())
	local timeDesc = "?"
	
	-- not sure if..
	if(timeOrig >= 5 and timeOrig <= 12) then
		timeDesc = "Утро"
	elseif (timeOrig >= 12 and timeOrig <= 18) then
		timeDesc = "День"
	elseif(timeOrig >= 18 and timeOrig <= 20) then
		timeDesc = "Вечер"
	elseif(timeOrig >= 20 or (timeOrig >= 0 and timeOrig <= 5)) then
		timeDesc = "Ночь"
	end
		
	local getTime = math.floor(timeOrig) + (timeOrig % 1) * 0.59
	local mult = 10^2
	local roundTime = math.floor(getTime * mult + 0.5) / mult
	rust.SendChatToUser(netuser, "[Dobrota]", "[color #FF006E]*****")
	rust.SendChatToUser(netuser, "[Dobrota]", "Добро пожаловать на PvE-PvP [color #FFD800]ДоброСервер[/color]!")
	rust.SendChatToUser(netuser, "[Dobrota]", "Текущее время: [color #00FF21]"..string.format("%05.2f", tostring(roundTime)):gsub("%.",":",1)..", "..timeDesc.."[/color]. Кол-во игроков [color #00FF21]"..tostring(#rust.GetAllNetUsers()).."[/color].")
	rust.SendChatToUser(netuser, "[Dobrota]", "Группа и информация о сервере [color #FF4B2B]www.dobrorust.ru[/color].")
	rust.SendChatToUser(netuser, "[Dobrota]", "Поддержи сервер - голосуй и получай [color #B6FF00]награды[/color]! Подробности [color #FF4B2B]/vote[/color].")
	-- rust.SendChatToUser(netuser, "[Dobrota]", "[color #FF006E]*****")
end

function PLUGIN:OnUserConnect(netuser)
	timer.Once(6, function() showWelcome(netuser) end)
end