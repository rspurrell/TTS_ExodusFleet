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

return Utils