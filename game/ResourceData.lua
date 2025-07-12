local Resources = {}

local xuDenominations = {10, 5, 3, 1}

local ADMIRAL_BONUS = 3

local xuIDs = {
    ["1"] = "4e7b3a",
    ["3"] = "95a6bf",
    ["5"] = "d6cf0d",
    ["10"] = "c5a1fb"
}

local RESOURCE_SPACING = 0.52  -- spacing between resources cubes. Matches world grid size.

local TAG_RESOURCE = "Resource"
local TAG_TRIBES = "Tribes"
local TAG_BIOMASS = "Biomass"
local TAG_FUEL = "Fuel"
local TAG_METAL = "Metal"
local TAG_WATER = "Water"

local resourceIDs = {
    [TAG_TRIBES] = "35d912",
    [TAG_BIOMASS] = "a08163",
    [TAG_FUEL] = "1d5775",
    [TAG_METAL] = "64535d",
    [TAG_WATER] = "05e02e"
}

local resourceZones = {}

Resources.ResourceTag = function()
    return TAG_RESOURCE
end

Resources.AdmiralBonus = function()
    return ADMIRAL_BONUS
end

Resources.init = function(data)
    log("Initializing Resources module...")
    -- Tag all resource bags
    for tag, bagId in pairs(resourceIDs) do
        local bag = getObjectFromGUID(bagId)
        if bag and bag.type == "Infinite" then
            bag.setTags({TAG_RESOURCE, tag})
        end
    end
    if data then
        log("Restoring resource zones from saved data...")
        for color, zoneGUID in pairs(data) do
            local zone = getObjectFromGUID(zoneGUID)
            if zone then
                resourceZones[color] = zone
            else
                log("WARNING: No resource zone for " .. color .. " was found during load.")
            end
        end
    end
end

Resources.save = function()
    -- Save the state of all resource zones
    local savedZones = {}
    for color, zone in pairs(resourceZones) do
        savedZones[color] = zone.getGUID()
    end
    return savedZones
end

Resources.dealXUToPlayer = function(playerColor, xuAmount)
    for _, denom in ipairs(xuDenominations) do
        while xuAmount >= denom do
            local bag = getObjectFromGUID(xuIDs[tostring(denom)])
            if bag then
                bag.deal(1, playerColor)
            else
                print("WARNING: Currency bag not found for " .. denom .. " XU")
            end
            xuAmount = xuAmount - denom
        end
    end
end

Resources.createPlayerResourceZone = function(color)
    local hand = Player[color].getHandTransform()
    if not hand then
        return
    end

    local pos = {
        x = hand.position.x + hand.forward.x * 9.2,
        y = 1,
        z = hand.position.z + hand.forward.z * 9.2
    }

    local left = hand.right * -1
    local offset = {
        pos.x + left.x * 10.1,
        pos.y,
        pos.z + left.z * 10.1
    }
    local rot = {0, hand.rotation.y, 0}

    local zone = spawnObject({
        type = "ScriptingTrigger",
        position = offset,
        rotation = rot,
        scale = {4, 1, 4},  -- adjustable size
        sound = false,
        snap_to_grid = false
    })

    zone.setName("ResourceZone_" .. color)
    zone.setVar("zoneColor", color)
    zone.addTag(TAG_RESOURCE)
    zone.interactable = false
    resourceZones[color] = zone
end

Resources.spawnResourcesAtZone = function(obj, playerColor, amount)
    local zone = resourceZones[playerColor]
    if not zone then
        return false
    end

    local zPos = zone.getPosition()
    local zRot = zone.getRotation()
    local forward = zone.getTransformForward()
    local left = {
        x = -forward.z,
        y = 0,
        z = forward.x
    }

    local resIdx = 0 -- default index for Biomass
    local resPos = math.abs(forward.x) - math.abs(left.x)
    if obj.hasTag(TAG_TRIBES) then
        resIdx = 3 * resPos
    elseif obj.hasTag(TAG_WATER) then
        resIdx = 2 * resPos
    elseif obj.hasTag(TAG_METAL) then
        resIdx = 1 * resPos
    -- elseif obj.hasTag(TAG_BIOMASS) then
    --     resIdx = 0
    elseif obj.hasTag(TAG_FUEL) then
        resIdx = -1 * resPos
    end

    for i = 1, amount do
        Wait.time(function()
            local newPos = {
                zPos.x + left.x * (i - 4) * RESOURCE_SPACING + left.z * resIdx * RESOURCE_SPACING,
                zPos.y + 0.5,
                zPos.z + left.z * (i - 4) * RESOURCE_SPACING + left.x * resIdx * RESOURCE_SPACING
            }
            obj.takeObject({
                position = newPos,
                rotation = zRot,
                smooth = true,
                snap_to_grid = true
            })
        end, i * 0.1)
    end
    return true
end

Resources.spawnStartingResources = function(color)
    -- Fuel ×2
    Resources.spawnResourcesAtZone(getObjectFromGUID(resourceIDs.Fuel), color, 2)
    -- Biomass
    Resources.spawnResourcesAtZone(getObjectFromGUID(resourceIDs.Biomass), color, 1)
    -- Water
    Resources.spawnResourcesAtZone(getObjectFromGUID(resourceIDs.Water), color, 1)
    -- Metal
    Resources.spawnResourcesAtZone(getObjectFromGUID(resourceIDs.Metal), color, 1)
end

return Resources