PLUGIN.Title = "Item Modifier"
PLUGIN.Description = ""
PLUGIN.Author = "DefaultPlayer"
PLUGIN.Version = "1.0"

typesystem.LoadEnum( cs.gettype( "ItemDataBlock+TransientMode, Assembly-CSharp" ), "TransientMode" )

function PLUGIN:OnDatablocksLoaded()
    local t = {{"Arrow", 30},{"Small Medkit", 10} } -- uses mod
    local t2 = {{"Hunting Bow",6,7},{"HandCannon",18,21}} -- dmg mod
    local t3 = {} -- clip mod (reload bug, no profit)
    local t4 = {{"Uber Hatchet", TransientMode.Untransferable}, {"Uber Hunting Bow", TransientMode.Untransferable},
        {"Invisible Boots", TransientMode.Untransferable}, {"Invisible Helmet", TransientMode.Untransferable}, {"Invisible Pants", TransientMode.Untransferable},
        {"Invisible Vest", TransientMode.Untransferable}}
    for i = 1, #t do
        local data = rust.GetDatablockByName(t[i][1])
        if(data) then data._maxUses = t[i][2] end
    end

    for i = 1, #t2 do
        local data = rust.GetDatablockByName(t2[i][1])
        if(data) then data.damageMin = t2[i][2]; data.damageMax = t2[i][3];  end
    end

    for i = 1, #t3 do
        local data = rust.GetDatablockByName(t3[i][1])
        if(data) then data.maxClipAmmo = t3[i][2] end
    end

    for i = 1, #t4 do
        local data = rust.GetDatablockByName(t4[i][1])
        if(data) then data.transientMode = t4[i][2] end
    end
end