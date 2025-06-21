function table:exclude(exclude)
    -- Exclude values from the table based on the exclude parameter
    local result = T{}
    exclude = T(exclude)
    if self:isArray() and exclude:isArray() then
        -- array exclude
        for i, v in ipairs(self) do
            if not exclude:contains(v) then
                table.insert(result, v)
            end
        end
    elseif exclude:isArray() then
        -- table exclude with array
        for k, v in pairs(self) do
            if not exclude:contains(v) then
                result[k] = v
            end
        end
    else
        -- table exclude by matching value
        for k, v in pairs(self) do
            local v2 = exclude[k]
            if v2 == nil or v ~= v2 then
                result[k] = v
            end
        end
    end
    return result
end

function table:excludeKeys(exclude)
    -- Exclude entries from table based exclude array
    local result = T{}
    exclude = T(exclude)
    if self:isArray() or not exclude:isArray() then
        log("Error: excludeKeys called on an array or with a non-array exclude. Use exclude instead.")
    else
        -- table exclude with array
        for k, v in pairs(self) do
            if not exclude:contains(k) then
                result[k] = v
            end
        end
    end
    return result
end

function table:containsKey(key)
    -- Check if the table contains a specific key
    if self:isArray() then
        log("Error: containsKey called on an array. Use contains instead.")
        return false
    else
        for k, v in pairs(self) do
            if k == key then
                return true
            end
        end
    end
    return false
end

function table:contains(value)
    -- Check if the table or array contains a specific value
    if self:isArray() then
        -- array contains
        for _, v in ipairs(self) do
            if v == value then
                return true
            end
        end
    else
        -- table contains
        for k, v in pairs(self) do
            if v == value then
                return true
            end
        end
    end
    return false
end

function table:filter(predicate)
    -- Filter the table or array based on a predicate function
    local result = T{}
    if self:isArray() then
        -- array filter
        for i, v in ipairs(self) do
            if predicate(v, i) then
                table.insert(result, v)
            end
        end
    else
        -- table filter
        for k, v in pairs(self) do
            if predicate(v, k) then
                result[k] = v
            end
        end
    end
    return result
end

function table:indexOf(value)
    for i, v in ipairs(self) do
        if v == value then
            return i
        end
    end
    return nil
end

function table:isArray()
    return type(self) == "table" and #self > 0
end

function table:keys()
    -- Returns the keys of the table as an array
    local keys = T{}
    if self:isArray() then
        log("Error: keys called on an array. Use ipairs instead.")
    else
        for k, _ in pairs(self) do
            table.insert(keys, k)
        end
    end
    return keys
end

function table:map(mapper, keyer)
    -- Returns a new table with the keys and values transformed by the keyer and mapper functions
    -- mapper should return the new value. [optional] keyer should return the new key
    local result = T{}
    for k, v in pairs(self) do
        local r = mapper(v, k)
        if r then
            if (keyer == nil) then
                table.insert(result, r)
            else
                result[keyer(k, v)] = r
            end
        end
    end
    return result
end

function table:mapMany(selectCollection, mapper, keyer)
    local result = T{}
    for k, v in pairs(self) do
        -- iterate over the collection returned by selectCollection
        local t = selectCollection(v, k)
        -- then add the value returned by mapper
        for k2, v2 in pairs(t) do
            if not mapper then
                -- if no mapper is provided, just add the value
                table.insert(result, v2)
            else
                local r = mapper(v2, k2, v, k)
                if r then
                    if not keyer then
                        table.insert(result, r)
                    else
                        result[keyer(r, v2, k2, v, k)] = r
                    end
                end
            end
        end
    end
    return result
end

function T(t)
    return setmetatable(t, {__index = table})
end