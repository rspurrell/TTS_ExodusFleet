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

function init()
    Utils.createButton(centralBoardId, btnConfig.startGame)
    addSelectCommandShip()
    updateSeatedColors()

    RoundManager.init()
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

    Utils.createButton(centralBoardId, btnConfig.advancePlanets)
    Utils.createButton(RoundManager.fleetAdmiralCardId(), btnConfig.advanceFleetAdmiral)

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

function advanceFleetAdmiral()
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
end

-- Event Handlers
function onPlayerChangeColor(color)
    updateSeatedColors()
end