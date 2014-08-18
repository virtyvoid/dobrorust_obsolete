PLUGIN.Title = "Time Commands"
PLUGIN.Version = "2.0"
PLUGIN.Description = "Adds the commands to make it day or night and to freeze or unfreeze time."
PLUGIN.Author = "Ross / DefaultPlayer" --{ http://forum.rustoxide.com/resources/authors/ross.98/ }--

-------------------------------------{Credit: rexas}-----------------------------------------
--local vTimeScale = util.GetStaticPropertyGetter( Rust.EnvironmentControlCenter, "timeScale" )
--local vTimeOfDay = util.GetStaticPropertyGetter( Rust.EnvironmentControlCenter, "timeOfDay" )
local vTimeOfDay = function() return Rust.EnvironmentControlCenter.Singleton:GetTime() end
---------------------------------------------------------------------------------------------

function PLUGIN:Init()
	local exclMk = "!"
	local errorAns = " "
	oxmin_Plugin = plugins.Find("oxmin")
    if not oxmin_Plugin or not oxmin then
        errorAns = "but without flags. Requires Oxmin"
		exclMk = " "
    end
	if oxmin_Plugin or oxmin then		
		self.FLAG_TIME = oxmin.AddFlag( "time" )
	end
	local b, res = config.Read( "timecmds" )
	self.Config = res or {}
	if (not b) then
		self:LoadDefaultConfig()
		if (res) then config.Save( "timecmds" ) end
	end
	self:AddChatCommand( "day",  self.cmdDay )
	self:AddChatCommand( "night",  self.cmdNight )
	-- self:AddChatCommand( "freeze",  self.cmdFreeze )
	-- self:AddChatCommand( "unfreeze",  self.cmdUnFreeze )
	self:AddChatCommand("time", self.cmdTime)
	-- self:AddChatCommand("timescale", self.cmdTimeScale)
	print( self.Title .. " v" .. self.Version .. " loaded" .. exclMk .. errorAns )
end

function PLUGIN:LoadDefaultConfig()
 self.Config.day = "10"
 self.Config.night = "23"
end

function PLUGIN:cmdDay( netuser, args )
    if ((netuser:CanAdmin()) or (oxmin_Plugin:HasFlag( netuser, self.FLAG_TIME, false ))) then 
		local getTime = self.Config.day
		rust.RunServerCommand( "env.time " .. getTime )
		rust.Notice(netuser, "Time set to day!") -- Edit the notice message here.
	else	
        rust.Notice( netuser, "You do not have permission to use this command!" )
	end
end

function PLUGIN:cmdNight( netuser, args )
    if ((netuser:CanAdmin()) or (oxmin_Plugin:HasFlag( netuser, self.FLAG_TIME, false ))) then
		local getTime = self.Config.night
		rust.RunServerCommand( "env.time " .. getTime )
		rust.Notice(netuser, "Time set to night!") -- Edit the notice message here.
	else
        rust.Notice( netuser, "You do not have permission to use this command!" )
	end
end

--[[function PLUGIN:cmdFreeze( netuser, args )
    if ((netuser:CanAdmin()) or (oxmin_Plugin:HasFlag( netuser, self.FLAG_TIME, false ))) then
		local cmdFreeze = "env.timescale 0"
		rust.RunServerCommand(cmdFreeze)
		rust.Notice(netuser, "Time has been frozen!") -- Edit the notice message here.
	else
        rust.Notice( netuser, "You do not have permission to use this command!" )
	end
end

function PLUGIN:cmdUnFreeze( netuser, args )
    if ((netuser:CanAdmin()) or (oxmin_Plugin:HasFlag( netuser, self.FLAG_TIME, false ))) then
		local cmdUnFreeze = "env.timescale 0.006666667"
		rust.RunServerCommand(cmdUnFreeze)
		rust.Notice(netuser, "Time has been unfrozen!") -- Edit the notice message here.
	else
        rust.Notice( netuser, "You do not have permission to use this command!" )
	end
end]]

function PLUGIN:cmdTime( netuser, cmd, args )
    if (not args[1]) then
		local getTime = tonumber(vTimeOfDay())
		getTime = math.floor(getTime) + (getTime % 1) * 0.59
		local mult = 10^2
		local roundTime = math.floor(getTime * mult + 0.5) / mult
		rust.Notice( netuser, "Текущее время: " .. string.format("%05.2f", tostring(roundTime)):gsub("%.",":",1) )
	end    
    if (args[1]) then
		if ((netuser:CanAdmin()) or (oxmin_Plugin:HasFlag( netuser, self.FLAG_TIME, false ))) then
			local inTime = tostring( args[1] )
			rust.RunServerCommand("env.time " .. inTime )
			rust.Notice( netuser, "Time changed to: " .. inTime )
		else
			rust.Notice( netuser, "You do not have permission to use this command!" )
		end
    end    
end

--[[function PLUGIN:cmdTimeScale( netuser, cmd, args )
    if (not args[1]) then
		local timeScale = tostring(vTimeScale())
		rust.Notice( netuser, "Current timescale is: " .. timeScale )
	end
	if (args[1] == "default") then
		if ((netuser:CanAdmin()) or (oxmin_Plugin:HasFlag( netuser, self.FLAG_TIME, false ))) then
			local inTimeScale = "0.006666667"
			rust.RunServerCommand("env.timescale " .. inTimeScale )
			rust.Notice( netuser, "Timescale changed to: " .. inTimeScale )
		else
			rust.Notice( netuser, "You do not have permission to use this command!" )
		end
    end  
    if (args[1]) then
		if ((netuser:CanAdmin()) or (oxmin_Plugin:HasFlag( netuser, self.FLAG_TIME, false ))) then
			local inTimeScale = tostring( args[1] )
			rust.RunServerCommand("env.timescale " .. inTimeScale )
			rust.Notice( netuser, "Timescale changed to: " .. inTimeScale )
		else
			rust.Notice( netuser, "You do not have permission to use this command!" )
		end
    end    
end]]

function PLUGIN:SendHelpText( netuser )
	local msgTime = " "
	local msgTime2 = " "
	local msgTimeScale = " "
	local msgTimeScale2 = " "
    if ((netuser:CanAdmin()) or (oxmin_Plugin:HasFlag( netuser, self.FLAG_TIME, false ))) then
        rust.SendChatToUser( netuser, "Use /day to make it day." )
        rust.SendChatToUser( netuser, "Use /night to make it night." )
		--rust.SendChatToUser( netuser, "Use /freeze to freeze the progression of time." )
		--rust.SendChatToUser( netuser, "Use /unfreeze to start the progression of time again." )
		msgTime = " \"number\" "
		msgTime2 = " or change "
    end	
	rust.SendChatToUser( netuser, "Use /time" .. msgTime .. "to display" .. msgTime2 .. "the current time." )
	--rust.SendChatToUser( netuser, "Use /timescale" .. msgTime .. "to display" .. msgTime2 .. "the current timescale." )
end
