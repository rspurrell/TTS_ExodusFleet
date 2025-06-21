local Utils = {}

local resourceIDs = require("game.ResourceData").ResourceIDs

Utils.clamp = function(val, min, max)
    return math.max(min, math.min(val, max))
end

Utils.clampRightAngle = function(angle)
    return math.floor((angle / 90) + 0.5) * 90
end

Utils.indexOf = function(array, value)
    for i, v in ipairs(array) do
        if v == value then
            return i
        end
    end
    return nil
end

Utils.createButton = function(objId, params)
    local obj = getObjectFromGUID(objId)
    if not obj or not params or not params.click_function then
        print("ERROR: Invalid parameters for Utils.createButton. click_function is required.")
        return false
    end

    if not obj.createButton(params) then
        print("ERROR: Failed to create button for object " .. objId)
        return false
    end
    return true
end

Utils.editButton = function(objId, btnName, params)
    local obj = getObjectFromGUID(objId)
    if not obj or not btnName or not params then
        print("ERROR: Invalid object or parameters for Utils.editButton")
        return false
    end

    local btns = obj.getButtons()
    if not btns then
        print("ERROR: No buttons found for object " .. objId)
        return false
    end
    for i, btn in ipairs(btns) do
        if btn.click_function == btnName then
            params.index = btn.index
            break
        end
    end

    if not params.index then
        print("ERROR: Button " .. btnName .. " not found for object " .. objId)
        return false
    end

    if not obj.editButton(params) then
        print("ERROR: Failed to edit button " .. btnName .. " for object " .. objId)
        return false
    end
    return true
end

Utils.removeButton = function(objId, btnName)
    local obj = getObjectFromGUID(objId)
    if not obj or not btnName then
        print("ERROR: Invalid object or parameters for Utils.removeButton")
        return false
    end

    local index = nil
    local btns = obj.getButtons()
    if not btns then
        print("ERROR: No buttons found for object " .. objId)
        return false
    end
    for i, btn in ipairs(btns) do
        if btn.click_function == btnName then
            index = btn.index
            break
        end
    end

    if not index then
        print("ERROR: Button " .. btnName .. " not found for object " .. objId)
        return false
    end

    if not obj.removeButton(index) then
        print("ERROR: Failed to remove button " .. btnName .. " for object " .. objId)
        return false
    end
    return true
end

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

Utils.spawnStartingResources = function(pos, forward)
    local y = pos.y + 2  -- standard board height

    local left = {
        x = -forward.z,
        y = 0,
        z = forward.x
    }

    -- Calculate position top left of player board
    local resPos = {
        x = pos.x + forward.x * 9 + left.x * 9,
        y = y,
        z = pos.z + forward.z * 9 + left.z * 9
    }

    local spacing = 0.4
    -- Fuel ×2
    for i = 0, 1 do
        Utils.spawnResource(resourceIDs.Fuel, {
            resPos.x + forward.x * i * spacing,
            y,
            resPos.z + forward.z * i * spacing
        })
    end

    -- Biomass
    Utils.spawnResource(resourceIDs.Biomass, {
        resPos.x + forward.x * 2 * spacing,
        y,
        resPos.z + forward.z * 2 * spacing
    })

    -- Water
    Utils.spawnResource(resourceIDs.Water, {
        resPos.x + forward.x * 3 * spacing,
        y,
        resPos.z + forward.z * 3 * spacing
    })

    -- Metal
    Utils.spawnResource(resourceIDs.Metal, {
        resPos.x + forward.x * 4 * spacing,
        y,
        resPos.z + forward.z * 4 * spacing
    })
end

return Utils