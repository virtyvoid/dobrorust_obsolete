PLUGIN.Title = "StartKit"
PLUGIN.Description = ""
PLUGIN.Author = "DefaultPlayer"
PLUGIN.Version = "1.0"

-- Вокруг столько готового дерьма, что утыкано хламом и написано всё через жопу. Сделал свой велик, но простой и безотказный.

local kitdatafile
local kitdata
local pref = rust.InventorySlotPreference( InventorySlotKind.Default, false, InventorySlotKindFlags.Belt )

local kitcontent = {{"Metal Door", 2}, {"Wood Planks", 100}, {"Small Medkit", 10}, {"Hunting Bow", 1}, {"Arrow", 20},{"Pick Axe", 1}, {"Hatchet", 1}, {"Bed", 1},
    {"Cloth Boots", 1}, {"Cloth Helmet", 1}, {"Cloth Pants", 1}, {"Cloth Vest", 1}, {"Small Rations", 10}, {"Large Wood Storage", 2} }

function PLUGIN:Init()
    kitdatafile = util.GetDatafile( "startkitdata" )
    local txt = kitdatafile:GetText()
    if txt ~= "" then
        kitdata = json.decode( txt )
    else
        kitdata = {}
    end
    self:AddChatCommand("kit", self.Kit)
end

function PLUGIN:Save()
    kitdatafile:SetText( json.encode( kitdata ) )
    kitdatafile:Save()
end

function PLUGIN:OnUserConnect( netuser )
    if netuser then
        local uid = rust.GetUserID( netuser )
        if not kitdata[uid] then
            timer.Once( 20, function()
                if(netuser and netuser.connected) then
                rust.SendChatToUser( netuser, "[Dobrota]", "Вы еще не получали стартовый набор. [color #FFFF00]/kit[/color] что бы узнать как это сделать!" ) end
            end )
        end
    end
end

function PLUGIN:Kit( netuser, cmd, args )
    local uid = rust.GetUserID( netuser )
    if kitdata[uid] then
        rust.SendChatToUser( netuser, "[Dobrota]", "Вы уже получали стартовый набор. Сделать это можно только 1 раз." )
        return
    end
    if(not args[1] or args[1] ~= "start") then
        rust.SendChatToUser( netuser, "[Dobrota]", "Вы можете только однократно получить стартовый набор." )
        rust.SendChatToUser( netuser, "[Dobrota]", "С помощью команды [color #FFFF00]/kit start[/color] вы можете получить его в удобный момент." )
        return
    end
    -- получаем
    kitdata[uid]={["name"]=netuser.displayName, ["date"]=System.DateTime.UtcNow:AddHours(4):ToString("dd/M/yyyy HH:mm:ss") }
    self:Save()
    local inv = rust.GetInventory( netuser )
    for i=1, #kitcontent do
        inv:AddItemAmount( rust.GetDatablockByName( kitcontent[i][1] ), tonumber( kitcontent[i][2] ) )
        rust.InventoryNotice( netuser, tostring( kitcontent[i][2] ) .. " x " .. kitcontent[i][1] )
    end
    rust.SendChatToUser( netuser, "[Dobrota]", "Поздравляем! Вы получили свой стартовый набор!" )
    rust.SendChatToUser( netuser, "[Dobrota]", "Желаем Вам приятной игры!" )
end