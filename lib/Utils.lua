local Utils = {}

local xuIDs = require("game.ResourceData").XuIDs
local xuDenoms = require("game.ResourceData").XuDenominations
Utils.dealXUToPlayer = function(player_color, xuAmount)
    for _, denom in ipairs(xuDenoms) do
        while xuAmount >= denom do
            local bag = getObjectFromGUID(xuIDs[tostring(denom)])
            if bag then
                bag.deal(1, player_color)
            else
                print("WARNING: Currency bag not found for " .. denom .. " XU")
            end
            xuAmount = xuAmount - denom
        end
    end
end

Utils.spawnResource = function(bagGUID, position, rotation)
    local bag = getObjectFromGUID(bagGUID)
    if not bag then
        print("ERROR: Could not find bag with GUID " .. bagGUID)
        return nil
    end

    return bag.takeObject({
        position       = position,
        rotation       = rotation or {0, 0, 0},
        smooth         = true,
        snap_to_grid   = true
    })
end

return Utils