local PhaseManager = {}

local PHASE_INCOME = "Income"
local PHASE_MINERS = "Miners"
local PHASE_TRANSPORTERS = "Transporters"
local PHASE_BUILDERS = "Builders"
local PHASE_EXPLORERS = "Explorers"

local phases = {PHASE_INCOME, PHASE_MINERS, PHASE_TRANSPORTERS, PHASE_BUILDERS, PHASE_EXPLORERS}
local prevPhase = nil

PhaseManager.getPhases = function()
    return phases
end

-- Get the last chosen phase (used for enforcing no-repeat rule)
PhaseManager.getPreviousPhase = function()
    return prevPhase
end

-- Validate if a phase choice is allowed
local function isPhaseAllowed(phaseName)
    if not phaseName then return false end

    -- Check if phaseName is one of the valid phases
    local isValidPhase = false
    for _, phase in ipairs(phases) do
        if phase == phaseName then
            isValidPhase = true
            break
        end
    end
    if not isValidPhase then
        print("PhaseManager: Invalid phase name: " .. tostring(phaseName))
        return false
    end

    -- Cannot select the same phase as the previous player
    return phaseName ~= prevPhase
end

PhaseManager.selectPhase = function(playerColor, phaseName)
    if not isPhaseAllowed(phaseName) then
        print("Phase  '" .. phaseName .. "' not allowed.")
        return false
    end

    prevPhase = phaseName
    broadcastToAll((Player[playerColor].steam_name or playerColor) .. " selected " .. phaseName .. ".", playerColor)
    return true
end

PhaseManager.resolvePhaseEffects = function(phaseName)
    if phaseName == PHASE_INCOME then
        -- TODO: Trigger Income phase logic
        broadcastToAll(PHASE_INCOME .. " Phase: Players collect XU based on their fleet income.", {0.9, 1, 0.9})
    elseif phaseName == PHASE_MINERS then
        -- TODO: Trigger Miners phase logic
        broadcastToAll(PHASE_MINERS .." Phase: Mining ships produce resources. ", {0.9, 0.9, 1})
    elseif phaseName == PHASE_TRANSPORTERS then
        -- TODO: Trigger Transporters phase logic
        broadcastToAll(PHASE_TRANSPORTERS .. " Phase: Players move resources between ships and warehouse.", {0.9, 0.9, 1})
    elseif phaseName == PHASE_BUILDERS then
        -- TODO: Trigger Builders phase logic
        broadcastToAll(PHASE_BUILDERS .. " Phase: Players may construct ships.", {1, 0.8, 0.8})
    elseif phaseName == PHASE_EXPLORERS then
        -- TODO: Trigger Explorers phase logic
        broadcastToAll(PHASE_EXPLORERS .. " Phase: Players draw explorer cards.", {1, 0.9, 0.6})
    else
        print("PhaseManager: Unknown phase effect for '" .. tostring(phaseName) .. "'")
    end
end

PhaseManager.resolvePostPhaseEffects = function(postPhaseFunctions)
    if not prevPhase then
        print("PhaseManager: No previous phase to resolve post-phase effects.")
        return
    end
    log("PhaseManager: Resolving post-phase effects for " .. prevPhase)
    if prevPhase == PHASE_MINERS then
        if postPhaseFunctions and postPhaseFunctions.miners then
            postPhaseFunctions.miners()
        else
            print("PhaseManager: No post-phase function defined for " .. PHASE_MINERS)
        end
    elseif prevPhase == PHASE_BUILDERS then
        if postPhaseFunctions and postPhaseFunctions.builders then
            postPhaseFunctions.builders()
        else
            print("PhaseManager: No post-phase function defined for " .. PHASE_BUILDERS)
        end
    end
end

PhaseManager.init = function(data)
    prevPhase = data and data.prevPhase or nil
end

-- Save/Load support
PhaseManager.save = function()
    return {
        prevPhase = prevPhase
    }
end

return PhaseManager