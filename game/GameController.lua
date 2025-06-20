local Utils = require("lib.Utils")
local btnConfig = require("game.ResourceData").ButtonConfig
local factionData = require("game.FactionData")
local Planets = require("game.Planets")
local RoundManager = require("game.RoundManager")
local Ships = require("game.Ships")

local centralBoardId = "c20ddb"  -- GUID for the central board
local seatedColors = {}
local colorOrder = {"Purple", "Blue", "Green", "Red", "Orange"}
local claimedFactionsByColor = {}  -- Maps player color → faction data

local debug = false

function onLoad(savedData)
    init(savedData)
end

function onSave()
    if RoundManager.currentRound() == 0 then
        return nil
    end

    return JSON.encode({
        roundData = RoundManager.save(),
        claimedFactions = claimedFactionsByColor
    })
end

function init(savedData)
    local data = JSON.decode(savedData)
    if data then
        log("Loading game state...")
        claimedFactionsByColor = data.claimedFactions
        RoundManager.init(data.roundData)
        createButtons()
    else
        log("Initializing for a new game...")
        Utils.createButton(centralBoardId, btnConfig.startGame)
        addSelectCommandShip()
        RoundManager.init()
    end

    updateSeatedColors()
    Planets.init()
end

function startGame()
    if #seatedColors < RoundManager.minPlayers() then
        broadcastToAll("At least " .. RoundManager.minPlayers() .. " players must be seated to start the game.", {1, 0, 0})
        return
    end

    if debug then
        -- For testing purposes, we can start the game with fewer players
        log("Debug mode: Starting game with " .. #seatedColors .. " players.")
        log("Seated colors: " .. table.concat(seatedColors, ", "))
        log(claimedFactionsByColor)
    end

    -- Check that every seated player has a claimed faction
    for _, color in ipairs(seatedColors) do
        if not claimedFactionsByColor[color] then
            broadcastToAll("All players must claim a faction before starting the game.", color, {1, 0.5, 0.5})
            return
        end
    end

    broadcastToAll("Starting a " .. #seatedColors .. " player game!", {0.6, 1, 0.6})

    if not RoundManager.start(#seatedColors) then
        return
    end

    Planets.start()

    local firstPlayer = RoundManager.assignFirstPlayer(seatedColors)
    broadcastToAll((firstPlayer.steam_name or "test") .. " (" .. firstPlayer.color .. ") is the first player!", {1, 1, 0})

    createButtons()

    -- Cleanup unclaimed faction assets
    Ships.removeUnclaimedFactions()
    broadcastToAll("Unused boards, command ships, and explorers have been removed.", {0.6, 0.9, 1})

    Utils.removeButton(centralBoardId, "startGame")
end

function cleanUp()
    -- Remove all buttons
    Utils.removeButton(centralBoardId, "advancePlanets")
    Utils.removeButton(RoundManager.fleetAdmiralCardId(), "advanceFleetAdmiral")
end

function createButtons()
    Utils.createButton(centralBoardId, btnConfig.advancePlanets)
    Utils.createButton(RoundManager.fleetAdmiralCardId(), btnConfig.advanceFleetAdmiral)
end

function advanceFleetAdmiral()
    if (RoundManager.isGameFinished()) then
        return
    end

    RoundManager.advanceFleetAdmiral(seatedColors)
    if (RoundManager.isGameFinished()) then
        cleanUp()
    end
end

function advancePlanets()
    Planets.advance()
end

function addSelectCommandShip()
    for faction, data in pairs(factionData) do
        for guid, ship in pairs(data.commandShips) do
            local cfg = btnConfig.selectCommandShip
            cfg.tooltip = "Choose " .. ship.name .. " for The " .. faction
            Utils.createButton(guid, cfg)
        end
    end
end

function selectCommandShip(obj, playerColor)
    if claimedFactionsByColor[playerColor] then
        broadcastToColor("You have already selected a command ship and faction.", playerColor, {1, 0.4, 0.4})
        return
    end
    local selectedFactionData = Ships.selectCommand(obj, playerColor)
    claimedFactionsByColor[playerColor] = selectedFactionData
end

function updateSeatedColors()
    local count = 0
    seatedColors = {}
    for _, color in ipairs(colorOrder) do
        if Player[color].seated then
            count = count + 1
            seatedColors[count] = color
        end
    end

    if (debug) then
        seatedColors = {"Purple", "Blue", "Green"}
    end

    broadcastToAll(#seatedColors .. " player(s) currently seated.", {0.7, 0.9, 1})

    if RoundManager.currentRound() == 0 then
        updatePlayerBoardStates(#seatedColors)
    end
end

function updatePlayerBoardStates(playerCount)
    local state = Utils.clamp(playerCount, 2, 5) - 1  -- convert 2–5 players to state 1–4
    for faction, data in pairs(factionData) do
        local board = getObjectFromGUID(data.playerBoard)
        if board then
            local currentState = board.getStateId()
            if currentState ~= state then -- setting to the same state causes error
                board.setState(state)
            end
        end
    end
end

-- Event Handlers
function onPlayerChangeColor(color)
    updateSeatedColors()
end