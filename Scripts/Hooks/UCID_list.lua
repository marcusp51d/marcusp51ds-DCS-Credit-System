local ConnectLogger = {}

local folderName = "mission1Scores"  -- define this to your folder name
local documentsPath = os.getenv("USERPROFILE") .. "\\Documents"
local filePath = documentsPath .. "\\" .. folderName .. "\\UCID_storage.lua"
local player_ucids = {}



function saveScore(scores, filePath)
    local file = io.open(filePath, "w")
    if not file then
        error("Failed to open file at "..filePath)
    end
    file:write("GLOBAL_UCIDS = {\n")
    for name, value in pairs(scores) do
        if type(name) == "string" and name:match("^%a[%w_]*$") then
            file:write("  "..name.." = "..string.format("%q", tostring(value))..",\n")  -- quote values as strings
        else
            file:write("  ["..string.format("%q", tostring(name)).."] = "..string.format("%q", tostring(value))..",\n")
        end
    end
    file:write("}\n")
    file:close()
end

ConnectLogger.onPlayerConnect = function(id)
    if not DCS.isServer() then
        return
    end
    if id == 0 then
        return
    end
    local player = net.get_player_info(id)
    if player and player.name then
        local ucid = player.ucid
        local name = player.name
        player_ucids[name] = ucid
        saveScore(player_ucids, filePath)  
    end
end

DCS.setUserCallbacks(ConnectLogger)
net.log("Loaded: PlayerConnectLogger.lua")
