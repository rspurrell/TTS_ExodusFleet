local Utils = require("lib.Utils")
local factionData = require("game.FactionData")
local resourceIDs = require("game.ResourceData").ResourceIDs
local Planets = require("game.Planets")
local RoundManager = require("game.RoundManager")

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

function selectCommandShip(obj, player_color)
    -- Get hand transform and forward vector
    local handTransform = Player[player_color].getHandTransform()
    if not handTransform then
        broadcastToColor("Error: Select an eligible hand color", player_color, {1,0,0})
        return
    end

    local selectedGUID = obj.getGUID()
    local selectedFaction = nil
    local selectedShipEntry = nil

    -- Find which faction this command ship belongs to
    for faction, data in pairs(factionData) do
        for guid, ship in pairs(data.commandShips) do
            if guid == selectedGUID then
                selectedFaction = faction
                selectedShipEntry = ship
                break
            end
        end
        if selectedFaction then break end
    end

    if not selectedFaction then
        broadcastToColor("Error: Command ship not found in data table.", player_color, {1,0,0})
        return
    end

    local hForward = handTransform.forward -- get player hand forward vector
    local hPos = handTransform.position  -- get player hand position
    local hRot = handTransform.rotation  -- get player-facing rotation
    local y = hPos.y + 2  -- standard board height

    -- remove select buttons
    obj.clearButtons()

    -- Move selected command ship
    objRot = obj.getRotation()
    obj.setRotationSmooth({0, hRot.y + objRot.y, 0})
    obj.setPositionSmooth({0, 5, 0})
    Wait.time(function()
        obj.setPositionSmooth({hPos.x, y, hPos.z})
    end, 0.5)

    -- Move matching explorer card
    local explorerGUID = selectedShipEntry.explorerCard
    local explorer = getObjectFromGUID(explorerGUID)
    if explorer then
        explorer.deal(1, player_color)
    end

    -- Offset 7.1 units forward from hand zone
    local offsetPos = {
        hPos.x + hForward.x * 7.1,
        y,
        hPos.z + hForward.z * 7.1
    }

    -- Move player board
    local boardGUID = factionData[selectedFaction].playerBoard
    local board = getObjectFromGUID(boardGUID)
    if board then
        bRot = board.getRotation()
        board.setRotationSmooth({0, hRot.y + bRot.y, 0})
        board.setPositionSmooth(offsetPos)
        board.interactable = false
    end

    -- Remove the unchosen command ship and explorer card
    for guid, ship in pairs(factionData[selectedFaction].commandShips) do
        if guid ~= selectedGUID then
            local otherShip = getObjectFromGUID(guid)
            if otherShip then otherShip.destruct() end

            local otherExplorer = getObjectFromGUID(ship.explorerCard)
            if otherExplorer then otherExplorer.destruct() end
        end
    end

    broadcastToAll(Player[player_color].steam_name .. " selected " ..
        selectedShipEntry.name .. " (" .. selectedFaction .. ").", {0.5, 1, 0.5})

    Utils.dealXUToPlayer(player_color, selectedShipEntry.xu)
    spawnStartingResources(hPos, hForward)
end

function spawnStartingResources(pos, forward)
    local y = pos.y + 2  -- standard board height

    local left = {
        x = -forward.z,
        y = 0,
        z = forward.x
    }

    -- Calculate position top left of player board
    local resPos = {
        x = pos.x + forward.x * 9 + left.x * 9,
        y = y,
        z = pos.z + forward.z * 9 + left.z * 9
    }

    local spacing = 0.4
    -- Fuel ×2
    for i = 0, 1 do
        Utils.spawnResource(resourceIDs.Fuel, {
            resPos.x + forward.x * i * spacing,
            y,
            resPos.z + forward.z * i * spacing
        })
    end

    -- Biomass
    Utils.spawnResource(resourceIDs.Biomass, {
        resPos.x + forward.x * 2 * spacing,
        y,
        resPos.z + forward.z * 2 * spacing
    })

    -- Water
    Utils.spawnResource(resourceIDs.Water, {
        resPos.x + forward.x * 3 * spacing,
        y,
        resPos.z + forward.z * 3 * spacing
    })

    -- Metal
    Utils.spawnResource(resourceIDs.Metal, {
        resPos.x + forward.x * 4 * spacing,
        y,
        resPos.z + forward.z * 4 * spacing
    })
end