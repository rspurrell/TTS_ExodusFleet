local RoundManager = {}

local Utils = require("lib/Utils")

local fleetAdmiralCardId = "5778e4"
local firstPlayerMarkerId = "5640f7"
local roundMarkerId = "3001ac"
local roundMarkerMoveDistance = 2.34  -- Distance to move the round marker each round

local finished = false
local roundLimits = { [2] = 13, [3] = 11, [4] = 8, [5] = 6 }
local midGameScoringRound = { [2] = 8, [3] = 7, [4] = 5, [5] = 4 }

local minPlayers = 2
local initialPlayerCount = 0
local maxRounds = 0
local currentRound = 0
local fleetAdmiralIndex = nil  -- current index in seatedColors
local firstPlayerColor = nil   -- color of the player who started first

RoundManager.currentRound = function()
    return currentRound
end

RoundManager.minPlayers = function()
    return minPlayers
end
RoundManager.isGameFinished = function()
    return finished
end

RoundManager.fleetAdmiralCardId = function()
    return fleetAdmiralCardId
end

function canAdvance(playerCount)
    return playerCount and initialPlayerCount == playerCount
end

RoundManager.init = function(roundData)
    getObjectFromGUID(firstPlayerMarkerId).interactable = false
    getObjectFromGUID(fleetAdmiralCardId).interactable = false
    getObjectFromGUID(roundMarkerId).interactable = false
    if roundData then
        currentRound = roundData.currentRound or currentRound
        initialPlayerCount = roundData.initialPlayerCount or initialPlayerCount
        maxRounds = roundData.maxRounds or maxRounds
        fleetAdmiralIndex = roundData.fleetAdmiralIndex or fleetAdmiralIndex
        firstPlayerColor = roundData.firstPlayerColor or firstPlayerColor
    end
end

RoundManager.save = function()
    return {
        currentRound = currentRound,
        initialPlayerCount = initialPlayerCount,
        maxRounds = maxRounds,
        fleetAdmiralIndex = fleetAdmiralIndex,
        firstPlayerColor = firstPlayerColor
    }
end

RoundManager.start = function(playerCount)
    if playerCount < minPlayers then
        broadcastToAll("At least " .. minPlayers .. " players must be seated to start the round.", {1, 0, 0})
        return false
    end
    maxRounds = roundLimits[playerCount]
    initialPlayerCount = playerCount
    currentRound = 1
    announceRound()
    return true
end

RoundManager.assignFirstPlayer = function(seatedColors)
    local chosenIndex = math.random(1, #seatedColors)
    local chosenColor = seatedColors[chosenIndex]
    local player = Player[chosenColor]

    local pos = player.getHandTransform().position
    local left = player.getHandTransform().right * -1
    local offset = {
        pos.x + left.x * 10,
        pos.y + 2,
        pos.z + left.z * 10
    }
    getObjectFromGUID(firstPlayerMarkerId).setPositionSmooth(offset)

    firstPlayerColor = chosenColor
    fleetAdmiralIndex = Utils.indexOf(seatedColors, chosenColor)
    RoundManager.moveFleetAdmiralToColor(chosenColor)
    return player
end

RoundManager.advanceFleetAdmiral = function(seatedColors)
    if not fleetAdmiralIndex or not canAdvance(#seatedColors) then
        broadcastToAll(initialPlayerCount .. " player(s) must be seated to advance the Fleet Admiral.", {1, 0, 0})
        return false
    end

    if RoundManager.isGameFinished() then
        broadcastToAll("Game finished! Fleet Admiral cannot be advanced.", {1, 0, 0})
        return false
    end

    fleetAdmiralIndex = fleetAdmiralIndex + 1
    if fleetAdmiralIndex > #seatedColors then
        fleetAdmiralIndex = 1
    end

    local nextColor = seatedColors[fleetAdmiralIndex]
    RoundManager.moveFleetAdmiralToColor(nextColor)

    -- Check for return to first player → advance round
    if nextColor == firstPlayerColor then
        broadcastToAll("Fleet Admiral returned to first player", {0.8, 1, 0.8})
        local newRound = RoundManager.nextRound(#seatedColors)
    end
    return true
end

RoundManager.moveFleetAdmiralToColor = function(playerColor)
    local player = Player[playerColor]
    if not player then
        print("ERROR: Player for color " .. playerColor .. " not found.")
        return false
    end

    -- Move the Fleet Admiral card to the next player's play area
    local hand = player.getHandTransform()
    local card = getObjectFromGUID(fleetAdmiralCardId)
    card.setPositionSmooth({
        hand.position.x + hand.right.x * 10,
        hand.position.y + 2,
        hand.position.z + hand.right.z * 10
    }, false)
    card.setRotationSmooth({
        0,
        hand.rotation.y + 180, -- fleet admiral card is rotated 180 degrees
        0
    }, false)
    broadcastToAll((player.steam_name or "test") .. " (" .. playerColor .. ") is now the Fleet Admiral", {0.9, 0.9, 1})
    return true
end

RoundManager.nextRound = function(playerCount)
    if not canAdvance(playerCount) then
        broadcastToAll(initialPlayerCount .. " player(s) must be seated to advance the round.", {1, 0, 0})
        return currentRound
    end

    if currentRound >= maxRounds then
        currentRound = maxRounds
        finished = true
        broadcastToAll("» Game finished! All players calculate final scores. «", {1, 1, 0})
        return currentRound
    end

    if not advanceRoundMarker() then
        print("ERROR: Round marker not found.")
        return currentRound
    end

    currentRound = currentRound + 1

    -- Check for mid-game scoring
    if currentRound == midGameScoringRound[playerCount] then
        broadcastToAll("» All players calculate mid-game scores now! «", {1, 1, 0})
    end

    if currentRound == maxRounds then
        broadcastToAll("» Round " .. currentRound .. ". Last round!", {1, 0.3, 0.3})
        return currentRound
    else
        announceRound()
    end

    return currentRound
end

function advanceRoundMarker()
    local roundMarker = getObjectFromGUID(roundMarkerId)
    if not roundMarker then
        return false
    end

    local pos = roundMarker.getPosition()
    local newPos = {pos.x + roundMarkerMoveDistance, pos.y, pos.z}
    roundMarker.setPositionSmooth(newPos)
    return true
end

function announceRound()
    broadcastToAll("» Round " .. currentRound, {0.6, 1, 0.6})
end

return RoundManager