local Utils = require("lib.Utils")
local factionData = require("game.FactionData")
local Planets = require("game.Planets")
local RoundManager = require("game.RoundManager")
local Ships = require("game.Ships")

local playerCount = 0

function init()
    initCommandShipSelect()
    initPlanetAdvance()
    initRoundAdvance()
    RoundManager.init()
    Planets.init()
end

function initRoundAdvance()
    local centralBoard = getObjectFromGUID("c20ddb")
    if centralBoard then
        centralBoard.createButton({
            label = "Advance Round »",
            click_function = "advanceRound",
            function_owner = Global,
            position = {1.99, 0.01, 0.155},
            rotation = {0, 0, 0},
            width = 2100,
            height = 1000,
            scale = { 0.1, 1, 0.1 },
            font_size = 250,
            color = {0.329, 0, 0.769},
            font_color = {1, 1, 1},
            tooltip = "Advance the round marker and check for scoring."
        })
    else
        print("ERROR: Central board not found.")
    end
end

function advanceRound()
    RoundManager.nextRound(playerCount)
end

function initPlanetAdvance()
    local centralBoard = getObjectFromGUID("c20ddb")
    if centralBoard then
        centralBoard.createButton({
            label = "Advance Planets »",
            click_function = "advancePlanets",
            function_owner = Global,
            position = {1.99, 0.01, -0.55},
            rotation = {0, 0, 0},
            width = 2100,
            height = 1000,
            scale = { 0.1, 1, 0.1 },
            font_size = 250,
            color = {0.176, 0.412, 0.176},
            font_color = {1, 1, 1},
            tooltip = "Advance all planet cards"
        })
    else
        print("ERROR: Central board not found.")
    end
end

function advancePlanets()
    Planets.advance()
end

function initCommandShipSelect()
    for faction, data in pairs(factionData) do
        for guid, ship in pairs(data.commandShips) do
            local obj = getObjectFromGUID(guid)
            if obj then
                obj.createButton({
                    label = "☑",
                    click_function = "selectCommandShip",
                    function_owner = Global,
                    position = {-0.91, 0.3, -0.90},  -- near upper-left corner
                    width = 100,
                    height = 120,
                    font_size = 75,
                    tooltip = "Choose " .. ship.name .. " for The " .. faction
                })
            else
                print("WARNING: Command ship with GUID " .. guid .. " not found.")
            end
        end
    end
end

function selectCommandShip(obj, playerColor)
    Ships.selectCommand(obj, playerColor)
end