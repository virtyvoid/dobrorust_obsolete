PLUGIN.Title = "Votifier"
PLUGIN.Description = "Награждает за голосования на трекерах"
PLUGIN.Author = "Tedro. Mod+Fix by DefaultPlayer"
PLUGIN.Version = "1.0"

local conf = {}
local reward = {}
local user = {}
local rewardfile

function PLUGIN:Init()
    local b, res = config.Read( "votifier" )
    conf = res or {}
    if not b then
        self:Configuration()
        if res then
            config.Save( "votifier" )
        end
    end

    local b, re = config.Read( "votifier_reward" )
    reward = re or {}
    if not b then
        self:Rewards()
        if re then
            config.Save( "votifier_reward" )
        end
    end

    rewardfile = util.GetDatafile( "votifier" )
    local txt = rewardfile:GetText()
    if txt ~= "" then
        user = json.decode( txt )
    else
        user = {}
    end

    self:AddChatCommand("vote", self.Vote)
    self:AddChatCommand("voted", self.Voted)
    api.Bind(self, "getVoteBalanceFor")
    api.Bind(self, "updateVoteBalanceFor")
end

function PLUGIN:Configuration()
    conf.rusttracker = true
    conf.rusttracker_id = 0
    conf.toprustservers = true
    conf.toprustservers_id = "server/0"
    conf.toprustservers_key = "paste_here_your_key"
    conf.chatname = "Server"
end

function PLUGIN:Rewards()
    reward = {}
end

function PLUGIN:Save()
    rewardfile:SetText( json.encode( user ) )
    rewardfile:Save()
end

function PLUGIN:OnUserConnect( netuser )
    if netuser then
        local uid = rust.GetUserID( netuser )
        if not user[uid] then
            user[uid] = 0
            self:Save()
        end
    end
end

function PLUGIN:Voted( netuser, cmd, args )
    local steamuid = tonumber( rust.GetUserID( netuser ) )
    local uid = rust.GetUserID( netuser )
    local inv = rust.GetInventory( netuser )

    if args[1] == "list" then
        rust.SendChatToUser( netuser, conf.chatname, "Доступны следующие награды:" )
        for i = 1, #reward do
            rust.SendChatToUser( netuser, conf.chatname, "[color #00FF00]/voted[/color] [color #FFFF00]" .. reward[i].name .. "[/color], стоимостью " .. reward[i].cost .. " " .. self:TrueVote( reward[i].cost ) .. " ([color #00FF00]/voted " .. reward[i].name .. " list[/color] покажет список вещей награды)" )
        end
        return
    end

    if args[1] then
        local rew = self:FindReward( args[1] )
        if rew then
            if args[2] == "list" then
                rust.SendChatToUser( netuser, conf.chatname, "Список вещей награды \"" .. rew.name .. "\", стоимостью " .. rew.cost .. " " .. self:TrueVote( rew.cost ) .. ":" )
                for i = 1, #rew.item do
                    if rew.item[i][2] then
                        rust.SendChatToUser( netuser, conf.chatname, rew.item[i][2] .. " x " .. rew.item[i][1] )
                    else
                        rust.SendChatToUser( netuser, conf.chatname, "1 x " .. rew.item[i][1] )
                    end
                end
            elseif not args[2] then
                if user[uid] >= rew.cost then
                    for i = 1, #rew.item do
                        if rew.item[i][2] then
                            inv:AddItemAmount( rust.GetDatablockByName( rew.item[i][1] ), tonumber( rew.item[i][2] ) )
                            rust.InventoryNotice( netuser, tostring( rew.item[i][2] ) .. " x " .. rew.item[i][1] )
                        else
                            inv:AddItemAmount( rust.GetDatablockByName( rew.item[i][1] ), 1 )
                            rust.InventoryNotice( netuser, "1 x " .. rew.item[i][1] )
                        end
                    end
                    rust.SendChatToUser( netuser, conf.chatname, "Вы успешно получили награду \"[color #00FF00]" .. rew.name .. "[/color]\"."  )
                    rust.InventoryNotice( netuser, "-" .. rew.cost .. " " .. self:TrueVote( rew.cost ) )
                    user[uid] = user[uid] - rew.cost
                    self:Save()
                else
                    rust.Notice( netuser, "У Вас не хватает голосов для получения награды!" )
                end
            else
                rust.Notice( netuser, "/voted " .. rew.name .. " list покажет список вещей награды" )
            end
        else
            rust.Notice( netuser, "Такой награды не найдено!" )
        end
    end

    if not args[1] then
        webrequest.Send( "http://rust-tracker.ru/api/?id=" .. conf.rusttracker_id .. "&uid=" .. steamuid, function( code, content )
            if code == 200 then
                if tostring( content ) == "0" then
                    rust.SendChatToUser( netuser, conf.chatname, "Для начала проголосуйте здесь: [color #20FF00]http://dobrorust.ru/vote" )
                end
                if tostring( content ) == "2" then
                    rust.SendChatToUser( netuser, conf.chatname, "За сегодняшнее голосование Вам уже засчитан голос!" )
                end
                if tostring( content ) == "1" then
                    rust.InventoryNotice( netuser, "+1 голос" )
                    user[uid] = user[uid] + 1
                    self:Save()
                    rust.SendChatToUser( netuser, conf.chatname, "Вам засчитан голос за голосование! Спасибо!" )
                    rust.SendChatToUser( netuser, conf.chatname, "Вы можете получить награду уже сейчас! А можете накопить голоса." )
                    rust.SendChatToUser( netuser, conf.chatname, "Вы так же можете менять бумагу (Paper) на голоса." )
                    rust.SendChatToUser( netuser, conf.chatname, "Список наград и стоимость можно узнать по команде [color #00FF00]/voted list" )
                end
            else
                rust.Notice( netuser, "Неполадки с трекером Rust-Tracker.ru! Попробуйте ещё раз" )
            end
        end )

        --[[webrequest.Send( "http://api.toprustservers.com/api/put?plugin=voter&key=" .. conf.toprustservers_key .. "&uid=" .. steamuid, function( code, content )
            if code == 200 then
                if tostring( content ) == "invalid_api" then
                    rust.Notice( netuser, conf.chatname, "Неправильный ключ для получения голосов с трекера TopRustServers.com! Сообщите администратору сервера!" )
                elseif tostring( content ) == "1" then
                    rust.InventoryNotice( netuser, "+1 голос" )
                    user[uid] = user[uid] + 1
                    self:Save()
                    rust.SendChatToUser( netuser, conf.chatname, "Вам засчитан голос за голосование на зарубежном трекере!" )
                else
                    rust.SendChatToUser( netuser, conf.chatname, "Вы ещё не голосовали или Вам уже засчитан голос за зарубежный трекер!" )
                end
            else
                rust.Notice( netuser, "Неполадки с трекером TopRustServers.com! Попробуйте ещё раз" )
            end
        end ) ]]
    end
end

function PLUGIN:FindReward( name )
    for i = 1, #reward do
        local rew = reward[i]
        if name == reward[i].name then
            return rew
        end
    end
end

function PLUGIN:TrueVote( vote )
    local setone = { 1, 21, 31, 41, 51, 61, 71, 81, 91 }
    local settwo = { 2, 3, 4, 22, 23, 24, 32, 33, 34, 42, 43, 44, 52, 53, 54, 62, 63, 64, 72, 73, 74, 82, 83, 84, 92, 93, 94 }
    if(vote > 100) then vote = vote - math.floor(vote / 100)*100 end
    for i = 1, #setone do
        if vote == setone[i] then
            return "голос"
        end
    end
    for i = 1, #settwo do
        if vote == settwo[i] then
            return "голоса"
        end
    end
    return "голосов"
end

function PLUGIN:Vote( netuser, cmd, args )
    local uid = rust.GetUserID( netuser )
    if(args[1] and args[1] == "paper") then
        local inv = rust.GetInventory( netuser )
        if (not inv) then return end
        local paperAmount = 0
        local foundPapers = {}
        for i = 0, inv.slotCount-1 do
            local b, item = inv:GetItem( i )
            if(b and item.datablock.name == "Paper") then
                table.insert(foundPapers, {item, item.uses})
                paperAmount = paperAmount + item.uses
                -- print("Found paper of "..item.uses.."u in slot "..i)
            end
        end
        local voteCount = math.floor(paperAmount / 100)
        local paperNeeded = voteCount * 100
        if(voteCount <= 0) then
            rust.SendChatToUser( netuser, conf.chatname, "У Вас недостаточно бумаги для обмена на голоса.")
            foundPapers = nil
            return
        end
        for i = 1, #foundPapers do
            if paperNeeded <= 0 then break end
            if(foundPapers[i][2] > paperNeeded) then
               -- print("Reducing "..foundPapers[i][1].uses.." by "..paperNeeded.." = "..foundPapers[i][1].uses - paperNeeded)
                local tmp = paperNeeded
                paperNeeded = paperNeeded - (foundPapers[i][1].uses - paperNeeded)
                foundPapers[i][1]:SetUses(foundPapers[i][1].uses - tmp)
            else if(foundPapers[i][2] <= paperNeeded) then
               -- print("Removing "..foundPapers[i][1].uses)
                paperNeeded = paperNeeded - foundPapers[i][1].uses
                inv:RemoveItem(foundPapers[i][1])
            else
                print("THEFUCK!!!!")
                return
            end
            end
         end
        foundPapers = nil
        rust.InventoryNotice( netuser, "+"..voteCount.. " " ..self:TrueVote( voteCount ) )
        self:updateVoteBalanceFor(netuser, user[uid] + voteCount)
        rust.SendChatToUser( netuser, conf.chatname, "Вы сдали макулатуру на [color #FFFF00]"..voteCount.." " ..self:TrueVote( voteCount ).."[/color]! Приносите еще :)" )
        print("PaperRecycler: "..netuser.displayName.." received "..voteCount.." votes!")
        return
    end
    rust.NoticeIcon( netuser, "На Вашем счету " .. user[uid] .. " " .. self:TrueVote( user[uid] ) .. ".", "$", 5 )
    if conf.rusttracker then
        rust.SendChatToUser( netuser, conf.chatname, "Вы можете проголосовать за наш сервер здесь: [color #20FF00]http://dobrorust.ru/vote")
    end
    if conf.toprustservers then
        rust.SendChatToUser( netuser, conf.chatname, "Вы можете проголосовать за наш сервер здесь: http://toprustservers.com/" .. conf.toprustservers_id )
    end
    rust.SendChatToUser( netuser, conf.chatname, "[color #00FF00]/voted[/color] проверит и зачислит голоса, а [color #00FF00]/voted list[/color] покажет список наград." )
    rust.SendChatToUser( netuser, conf.chatname, "[color #FF6644]ВАЖНО: Перед получением награды - проверьте свободные слоты инвентаря!" )
    rust.SendChatToUser( netuser, conf.chatname, "********" )
    rust.SendChatToUser( netuser, conf.chatname, "[color #FFEF3F] Спец. предложение! Обмен бумаги(Paper) на голоса по курсу 100 к 1!" )
    rust.SendChatToUser( netuser, conf.chatname, "[color #FFEF3F] Введите [color #00FF00]/vote paper[/color] [color #FFEF3F]для автоматического обмена!" )
end

function PLUGIN:SendHelpText( netuser )
    rust.SendChatToUser( netuser, "Oxide", "[color #00FF00]/vote[/color] покажет ссылки на сервера для голосования и Ваш баланс голосов." )
    rust.SendChatToUser( netuser, "Oxide", "[color #00FF00]/voted[/color] проверит и зачислит голоса, а [color #00FF00]/voted list[/color] покажет список наград." )
end

function PLUGIN:getVoteBalanceFor(netuser)
    return user[rust.GetUserID( netuser )]
end

function PLUGIN:updateVoteBalanceFor(netuser, newvalue)
    user[rust.GetUserID( netuser )] = newvalue
    self:Save()
end