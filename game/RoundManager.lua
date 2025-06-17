local RoundManager = {}

local firstPlayerMarkerId = "5640f7"  -- GUID for the first player marker
local roundMarkerId = "3001ac"
local roundMarkerMoveDistance = 2.34  -- Distance to move the round marker each round

local roundLimits = { [2] = 13, [3] = 11, [4] = 8, [5] = 6 }
local midGameScoringRound = { [2] = 8, [3] = 7, [4] = 5, [5] = 4 }

local initialPlayerCount = 0
local maxRounds = 0
local currentRound = 0
RoundManager.currentRound = function()
    return currentRound
end

RoundManager.init = function()
    local roundMarker = getObjectFromGUID(roundMarkerId)
    roundMarker.interactable = false
end

RoundManager.start = function(playerCount)
    if playerCount == 0 or playerCount == 1 then
        broadcastToAll("At least 2 players must be seated to start the round.", {1, 0, 0})
        return false
    end
    maxRounds = roundLimits[playerCount]
    initialPlayerCount = playerCount
    currentRound = 1
    announceRound()
    return true
end

RoundManager.nextRound = function(playerCount)
    if playerCount == 0 or playerCount == 1 or initialPlayerCount ~= playerCount then
        broadcastToAll(initialPlayerCount .. " player(s) must be seated to advance the round.", {1, 0, 0})
        return false
    end

    if currentRound >= maxRounds then
        currentRound = maxRounds
        broadcastToAll("» Last round! Game is nearing its end. «", {1, 0.3, 0.3})
        return false
    end

    if not advanceRoundMarker() then
        print("ERROR: Round marker not found.")
        return false
    end

    currentRound = currentRound + 1

    -- Check for mid-game scoring
    if currentRound == midGameScoringRound[playerCount] then
        broadcastToAll("» All players calculate mid-game scores now! «", {1, 1, 0})
    end

    if currentRound == maxRounds then
        broadcastToAll("» Round " .. currentRound .. ". Last round!", {0.6, 1, 0.6})
        return currentRound
    else
        announceRound()
    end

    return true
end

function announceRound()
    broadcastToAll("» Round " .. currentRound, {0.6, 1, 0.6})
end

RoundManager.assignFirstPlayer = function(seatedColors)
    local chosenIndex = math.random(1, #seatedColors)
    local chosenColor = seatedColors[chosenIndex]
    local player = Player[chosenColor]
    broadcastToAll(player.steam_name .. " (" .. chosenColor .. ") is the first player!", {1, 1, 0})

    local pos = player.getHandTransform().position
    local left = player.getHandTransform().right * -1
    local firstPlayerMarker = getObjectFromGUID(firstPlayerMarkerId)
    if firstPlayerMarker then
        local offset = {
            pos.x + left.x * 10,
            pos.y + 2,
            pos.z + left.z * 10
        }
        firstPlayerMarker.setPositionSmooth(offset)
        firstPlayerMarker.interactable = false
    end
end

function advanceRoundMarker()
    local roundMarker = getObjectFromGUID(roundMarkerId)  -- Round marker token
    if not roundMarker then
        return false
    end

    local pos = roundMarker.getPosition()
    local newPos = {pos.x + roundMarkerMoveDistance, pos.y, pos.z}
    roundMarker.setPositionSmooth(newPos)
    return true
end

return RoundManager