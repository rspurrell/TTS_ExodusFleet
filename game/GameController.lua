local Utils = require("lib.Utils")
local btnConfig = require("game.ResourceData").ButtonConfig
local factionData = require("game.FactionData")
local Planets = require("game.Planets")
local RoundManager = require("game.RoundManager")
local Ships = require("game.Ships")

local centralBoardId = "c20ddb"  -- GUID for the central board
local playerCount = 0
local seatedColors = {}
local colorOrder = {"Purple", "Blue", "Green", "Red", "Orange"}

function init()
    Utils.createButton(centralBoardId, btnConfig.startGame)
    addSelectCommandShip()
    updatePlayerCount()

    RoundManager.init()
    Planets.init()
end

function startGame()
    if #seatedColors == 0 or #seatedColors == 1 then
        broadcastToAll("Cannot begin: At least 2 players are required.", {1, 0, 0})
        return
    end

    broadcastToAll("Starting a " .. #seatedColors .. " player game!", {0.6, 1, 0.6})

    Planets.start()
    Utils.createButton(centralBoardId, btnConfig.advancePlanets)
    Utils.createButton(centralBoardId, btnConfig.advanceRound)

    Utils.removeButton(centralBoardId, "startGame")

    RoundManager.start()
end

function advanceRound()
    RoundManager.nextRound(playerCount)
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
    Ships.selectCommand(obj, playerColor)
end

function updatePlayerCount()
    local count = 0
    seatedColors = {}
    for _, color in ipairs(colorOrder) do
        if Player[color].seated then
            count = count + 1
            seatedColors[count] = color
        end
    end
    playerCount = count
    broadcastToAll(playerCount .. " player(s) currently seated.", {0.7, 0.9, 1})
end

-- Event Handlers
function onPlayerChangeColor(color)
    updatePlayerCount()
end