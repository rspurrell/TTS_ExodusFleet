local Utils = {}

Utils.startsWith = function(str, test)
    return str:sub(1, #test) == test
end

Utils.endsWith = function(str, test)
    return test == "" or str:sub(-#test) == test
end

Utils.clamp = function(val, min, max)
    return math.max(min, math.min(val, max))
end

Utils.clampRightAngle = function(angle)
    return math.floor((angle / 90) + 0.5) * 90
end

Utils.randomTableKey = function(tbl)
    local keys = {}
    for k in pairs(tbl) do
        table.insert(keys, k)
    end
    if #keys == 0 then
        return nil
    end
    return keys[math.random(#keys)]
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
        print("WARN: No buttons found for object " .. objId)
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

Utils.createZones = function(origin, zoneSize, direction, distance, numZones, name, tags)
    local totalWidth = math.abs(zoneSize.x * direction.x + zoneSize.z * direction.z) * numZones
    if (totalWidth > distance) then
        print("ERROR: Total width of zones exceeds specified distance.")
        return {}
    end

    local spacing = (numZones < 1) and 0 or (distance - totalWidth) / (numZones - 1)
    local halfWidth = zoneSize.x / 2
    local halfDepth = zoneSize.z / 2

    local zones = {}
    for i = 0, numZones - 1 do
        local zone = spawnObject({
            type = "ScriptingTrigger",
            position = {
                origin.x + halfWidth + i * (zoneSize.x + spacing) * direction.x,
                origin.y,
                origin.z - halfDepth + i * (zoneSize.z + spacing) * direction.z
            },
            scale = {zoneSize.x, zoneSize.y, zoneSize.z},
            rotation = {0, 0, 0},
            snap_to_grid = false,
            sound = false
        })

        zone.setName((name or "zone") .. "_" .. i)
        zone.setTags(tags or {})
        zone.interactable = false
        table.insert(zones, zone)
    end
    return zones
end

Utils.getCardFromZone = function(zone, dest, flip)
    local zPos = zone.getPosition()
    local objects = zone.getObjects()
    for _, obj in ipairs(objects) do
        if obj.tag == "Deck" then
            local aboveDeck = zPos.y + 0.2 + obj.getBoundsNormalized().size.y / 2
            obj = obj.takeObject({
                position = {
                    zPos.x,
                    aboveDeck,
                    zPos.z
                }
            })
        end
        if obj.tag == "Card" then
            if flip then
                obj.flip()
            end
            if dest then
                obj.setPositionSmooth(dest, false, true)
            end
            return obj
        end
    end
    return nil
end

Utils.justifyZones = function(zones, step, callback, delay)
    step = step or 1 -- Default step is 1
    if step ~= 1 and step ~= -1 then
        log("Invalid step value. Must be 1 or -1.")
        return nil
    end

    if not zones or #zones == 0 then
        log("No zones provided for compression.")
        return nil
    end

    local targetIndex = 1 -- current valid zone index
    local i = 1
    if step == -1 then
        targetIndex = #zones -- start from the last zone
        i = #zones -- start from the last zone
    end

    local objectsMoved = false
    while i >= 1 and i <= #zones do
        local zone = zones[i]
        local objects = zone.getObjects()
        if (#objects > 0 and targetIndex == i) then -- current zone has objects and is the target zone
            targetIndex = i + step -- step target index
        elseif (#objects > 0) then
            objectsMoved = true
            for _, obj in ipairs(objects) do
                local dest = zones[targetIndex].getPosition()
                obj.setPositionSmooth(dest, false, true)
                targetIndex = targetIndex + step  -- next available zone
            end
        end
        i = i + step
    end

    local filledZoneCount = targetIndex - 1
    if filledZoneCount == 0 or not objectsMoved then
        delay = 0
    end

    if callback then
        Wait.time(function()
            callback(filledZoneCount)
        end, delay or 0.25) -- slight delay to ensure all objects are moved before callback
    end
    return filledZoneCount
end

return Utils