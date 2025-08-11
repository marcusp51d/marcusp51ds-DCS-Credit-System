-- VERSION: 2.7
local folderName = "mission1Scores"
local save_interval = 15 --seconds
debugger_logging = false

base_score = 50
kill_player_score = 50

local function chatlog(text)
    if debugger_logging == true then
        local new = MESSAGE:New(text, 15)
        new:ToAll()
    end
end

_SETTINGS:SetPlayerMenuOff()

local function log(text)
    env.info("scoring "..text)
end

local function chat(text)
    local new = MESSAGE:New(text, 15)
    new:ToAll()
end

chat("started")
log("script started")

playerstatus = {}

vehicle_kill_values = {
    ["unit name"] = 5
}

local documentsPath = os.getenv("USERPROFILE") .. "\\Documents"
local filePath = documentsPath .. "/" .. folderName .. "/credSave.lua"
local priceFilePath = documentsPath .. "/" .. folderName .. "/weaponCosts1991.lua"
local tempFile = documentsPath .. "/" .. folderName .. "/UCID_storage.lua"
dofile(filePath)
dofile(priceFilePath)
local currentPrices = _G.sale_weapons
local current_credits = _G.scores

temp_ucid = {}

function update_temp_ucid()
    dofile(tempFile)
    temp_ucid = _G.GLOBAL_UCIDS
end
update_temp_ucid()


function get_temp_UCID(name_entry)
    if temp_ucid[name_entry] then
        return temp_ucid[name_entry]
    else
        update_temp_ucid()
        return temp_ucid[name_entry]
    end
end

function displayLoadoutCost(triggerUnit)
    chatlog("attempting to display loadout costs")
    if not triggerUnit or triggerUnit:IsDead() then
        return
    end

    local UnitName = triggerUnit:GetName()
    local PlayerClient = CLIENT:FindByName(UnitName)
    if not PlayerClient then return end
    local PlayerName = triggerUnit:GetPlayerName()
    local PlayerUCID = get_player_info(PlayerName)
    if not PlayerUCID then return end

    local playerCreds = current_credits[PlayerUCID][1]
    local weapons = triggerUnit:GetAmmo()
    local attempts = 0
    while weapons == nil and attempts < 10 do
        weapons = triggerUnit:GetAmmo()
        attempts = attempts + 1
    end
    if weapons == nil then
        log("Could not get weapons for unit: " .. UnitName)
        return
    end

    local chatMsg = "you currently have "..tostring(playerCreds).." credits\n\n"
    local totalCost = 0
    chatlog("loadout for "..PlayerUCID)
    for _, weapon in pairs(weapons) do
        if weapon.desc and weapon.desc.displayName then
            local weaponName = weapon.desc.displayName
            local weaponCount = weapon.count
            local weapon_cost = 0
            if currentPrices[weaponName] then
                weapon_cost = currentPrices[weaponName]*weaponCount
            end
            totalCost = totalCost + weapon_cost
            chatMsg = chatMsg..tostring(weaponCount).." "..weaponName.." will cost "..tostring(weapon_cost).."\n"
        end
    end
    if playerstatus[PlayerUCID] == true then
        chatlog("player is on ground")
        if playerCreds >= totalCost then
            chatMsg = chatMsg.."\nin total it will cost ".. tostring(totalCost).." credits\nyou CAN afford these weapons and will be CHARGED when you take off"
            local new = MESSAGE:New(chatMsg, 35)
            new:ToClient(PlayerClient)
        else
            chatMsg = chatMsg.."\nin total it will cost ".. tostring(totalCost).." credits\nyou CAN NOT afford these weapons and will be DESPAWNED if you attempt to take off"
            local new = MESSAGE:New(chatMsg, 35)
            new:ToClient(PlayerClient)
        end
    else
        chatlog("player is not on ground")
        local new = MESSAGE:New(chatMsg, 35)
        new:ToClient(PlayerClient)
    end
end

function displayCredits(triggerUnit)
    if not triggerUnit or triggerUnit:IsDead() then
        return
    end
    local UnitName = triggerUnit:GetName()
    local PlayerClient = CLIENT:FindByName(UnitName)
    if not PlayerClient then return end
    local PlayerName = triggerUnit:GetPlayerName()
    local PlayerUCID = get_temp_UCID(PlayerName)
    if not PlayerUCID then return end

    local new = MESSAGE:New("you currently have "..tostring(current_credits[PlayerUCID][1]).." credits", 20)
    new:ToClient(PlayerClient)
end

local creditMenus = {}

function CreatePlayerMenu(PlayerUnit)
    local PlayerGroup = PlayerUnit:GetGroup()
    local GroupName = PlayerGroup:GetName()

    if creditMenus[GroupName] then
        creditMenus[GroupName]:Remove()
    end

    creditMenus[GroupName] = MENU_GROUP:New(PlayerGroup, "Credit System")
    MENU_GROUP_COMMAND:New(PlayerGroup, "Current loadout cost", creditMenus[GroupName], displayLoadoutCost, PlayerUnit)
    MENU_GROUP_COMMAND:New(PlayerGroup, "Credit balance", creditMenus[GroupName], displayCredits, PlayerUnit)
end

function saveScore(scores)
    local file = io.open(filePath, "w")
    file:write("scores = {\n")
    for name, value in pairs(scores) do
        name = tostring(name)
        file:write('["'..name..'"] = {'..tostring(value[1])..', "'..tostring(value[2])..'"},\n')
    end
    file:write("}\n")
    file:close()
end


PlayerEnterUnitHandler = EVENTHANDLER:New()
function PlayerEnterUnitHandler:OnEventPlayerEnterAircraft(EventData)
    SCHEDULER:New(nil, function()
    if EventData.IniUnit then
        local PlayerUnit = EventData.IniUnit
        local UnitName = PlayerUnit:GetName()
        local PlayerClient = CLIENT:FindByName(UnitName)
        if not PlayerClient then return end
        local PlayerName = PlayerUnit:GetPlayerName()
        local PlayerUCID = get_temp_UCID(PlayerName)

        if not PlayerUCID then
            log("Could not get UCID for " .. tostring(PlayerClient:GetName()))
            return
        end

        local totalCost = 0
        playerstatus[PlayerUCID] = true
        CreatePlayerMenu(PlayerUnit)

        if not current_credits[PlayerUCID] then
            current_credits[PlayerUCID] = {25, PlayerName}
        else
            current_credits[PlayerUCID] = {current_credits[PlayerUCID][1], PlayerName}
        end

        local new = MESSAGE:New("welcome "..PlayerName.." this server uses a credit system for advanced weapons,\ncheck breifing for prices and commands\n!!!YOU WILL BE CHARGED AT TAKE-OFF CHECK YOUR LOADOUT IN THE COMS MENU!!!", 40)
        new:ToClient(PlayerClient)

        PlayerUnit:HandleEvent(EVENTS.Takeoff)
        function  PlayerUnit:OnEventTakeoff(EventData)
            if EventData.IniUnit then
                local playerCreds = current_credits[PlayerUCID][1]
                local weapons = PlayerUnit:GetAmmo()
                local attempts = 0
                while weapons == nil and attempts < 10 do
                    weapons = PlayerUnit:GetAmmo()
                    attempts = attempts + 1
                end
                if weapons == nil then
                    log("Could not get weapons for unit on takeoff: " .. UnitName)
                    return
                end
                local chatMsg = "you currently have "..tostring(playerCreds).." credits\n\n"
                totalCost = 0
                for _, weapon in pairs(weapons) do
                    if weapon.desc and weapon.desc.displayName then
                        local weaponName = weapon.desc.displayName
                        local weaponCount = weapon.count
                        local weapon_cost = 0
                        if currentPrices[weaponName] then
                            weapon_cost = currentPrices[weaponName]*weaponCount
                        end
                        totalCost = totalCost + weapon_cost
                        chatMsg = chatMsg..tostring(weaponCount).." "..weaponName.." will cost "..tostring(weapon_cost).."\n"
                    end
                end

                if playerCreds >= totalCost then
                    chatMsg = chatMsg.."\nin total it will cost ".. tostring(totalCost).." credits\nyou CAN afford these weapons and will be CHARGED"
                    local new = MESSAGE:New(chatMsg, 35)
                    new:ToClient(PlayerClient)
                else
                    chatMsg = chatMsg.."\nin total it will cost ".. tostring(totalCost).." credits\nyou CAN NOT afford these weapons. You will die now."
                    local new = MESSAGE:New(chatMsg, 35)
                    new:ToClient(PlayerClient)
                end

                if playerstatus[PlayerUCID] == true then
                    playerstatus[PlayerUCID] = false
                    if current_credits[PlayerUCID][1] < totalCost then
                        local new = MESSAGE:New("You could not afford these weapons", 10)
                        new:ToClient(PlayerClient)
                        PlayerUnit:Explode(25, 1)
                    elseif current_credits[PlayerUCID][1] >= totalCost then
                        current_credits[PlayerUCID][1] = current_credits[PlayerUCID][1] - totalCost
                        local new = MESSAGE:New("weapons have been purchased for "..tostring(totalCost).." credits you are left with "..tostring(current_credits[PlayerUCID][1]).." credits\nall weapons that you return with will be refunded, have a safe flight!", 10)
                        new:ToClient(PlayerClient)
                        totalCost = 0
                    end
                end
            end
        end

        PlayerUnit:HandleEvent(EVENTS.Land)
        function PlayerUnit:OnEventLand(EventData)
            if playerstatus[PlayerUCID] == false then
                playerstatus[PlayerUCID] = true
                local weapons = PlayerUnit:GetAmmo()
                local attempts = 0
                while weapons == nil and attempts < 10 do
                    weapons = PlayerUnit:GetAmmo()
                    attempts = attempts + 1

                end
                if weapons == nil then
                    log("Could not get weapons on landing for unit: " .. UnitName)
                    return
                end
                local chatmsg = "you landed with:\n"
                totalCost = 0
                for _, weapon in pairs(weapons) do
                    if weapon.desc and weapon.desc.displayName then
                        local weaponName = weapon.desc.displayName
                        local weaponCount = weapon.count
                        local weapon_cost = 0       
                        if currentPrices[weaponName] then
                            weapon_cost = currentPrices[weaponName]*weaponCount
                        end
                        totalCost = totalCost + weapon_cost
                        chatmsg = chatmsg..tostring(weaponCount).." "..weaponName.." value "..tostring(weapon_cost).."\n"
                    end
                end
                chatmsg = chatmsg..tostring(totalCost).." credits have been refunded"
                local new = MESSAGE:New(chatmsg, 35)
                new:ToClient(PlayerClient)
                current_credits[PlayerUCID][1] = current_credits[PlayerUCID][1] + totalCost
            end
        end
    end
end, {}, 3)
end

KillHandler = EVENTHANDLER:New()

function KillHandler:OnEventKill(EventData)
    chatlog("unit killed")
    local killer = EventData.IniPlayerName

    if killer and EventData.IniUnit and EventData.TgtTypeName then

        PlayerUCID = get_temp_UCID(killer)
        if not current_credits[PlayerUCID][1] then
            current_credits[PlayerUCID][1] = 25
        end

        if EventData.TgtPlayerName then
            current_credits[PlayerUCID][1] = current_credits[PlayerUCID][1] + kill_player_score
            chatlog(killer.." killed a player! +"..kill_player_score.." credits")
        else
            current_credits[PlayerUCID][1] = current_credits[PlayerUCID][1] + base_score
            chatlog(killer.." killed an AI! +"..base_score.." credits")
        end
        
    end
end

KillHandler:HandleEvent(EVENTS.Kill)

function linker()
    chatlog("linker")
    
    saveScore(current_credits)
end

PlayerEnterUnitHandler:HandleEvent(EVENTS.PlayerEnterAircraft)
SCHEDULER:New(nil, linker, {}, save_interval, save_interval)
