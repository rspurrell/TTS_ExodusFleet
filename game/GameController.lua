local Utils = require("lib.Utils")
local Resources = require("game.ResourceData")
local BtnConfig = require("game.Config").ButtonConfig
local FactionData = require("game.FactionData")
local Planets = require("game.Planets")
local PhaseManager = require("game.PhaseManager")
local RoundManager = require("game.RoundManager")
local Ships = require("game.Ships")
local Explorers = require("game.Explorers")
local CardAbilities = require("game.CardAbilities")

local centralBoardId = "c20ddb"  -- GUID for the central board
local seatedColors = T{}
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
        claimedFactions = claimedFactionsByColor,
        phaseData = PhaseManager.save(),
        resourcesData = Resources.save(),
        shipData = Ships.save(),
    })
end

function init(savedData)
    local data = JSON.decode(savedData)
    PhaseManager.onSelecting = delegate_onSelectingPhase
    PhaseManager.onSelected = delegate_onSelectedPhase
    PhaseManager.onPostPhase = delegate_onPostPhase
    CardAbilities.register()

    if data then
        log("Loading game state...")
        claimedFactionsByColor = data.claimedFactions
        RoundManager.init(data.roundData)
        PhaseManager.init(data.phaseData)
        Ships.init(data.shipData)
        Resources.init(data.resourcesData)
        if not RoundManager.isGameFinished() then
        createButtons()
            CardAbilities.restore()
        end
    else
        log("Initializing for a new game...")
        createPreGameButtons()
        RoundManager.init()
        Ships.init()
        Resources.init()
    end
    Planets.init()
    updateSeatedColors()
end

function startGame()
    if #seatedColors < RoundManager.minPlayers() then
        broadcastToAll("At least " .. RoundManager.minPlayers() .. " players must be seated to start the game.", {1, 0, 0})
        return
    end

    if debug then
        debugStart()
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
    local centralBoard = getObjectFromGUID(centralBoardId)
    local cbPos = centralBoard.getPosition()
    local cbNormBounds = centralBoard.getBoundsNormalized()
    Ships.start({
        x = cbPos.x - cbNormBounds.size.x / 2,  -- Starting on the left side of the board
        y = 0.95,
        z = cbPos.z - cbNormBounds.size.z / 2  -- Starting on the bottom side of the board
    },{
        x = 1,
        y = 0,
        z = 0
    }, cbNormBounds.size.x, RoundManager.getPlayerCount())

    local firstPlayer = RoundManager.assignFirstPlayer(seatedColors)
    broadcastToAll((firstPlayer.steam_name or "test") .. " (" .. firstPlayer.color .. ") is the first player!", {1, 1, 0})

    -- Cleanup unclaimed faction assets
    Ships.removeUnclaimedFactions()
    broadcastToAll("Unused boards, command ships, and explorers have been removed.", {0.6, 0.9, 1})

    removePreGameButtons()
    createButtons()
end

function debugStart()
    -- For testing purposes, we can start the game with fewer players
    log("Debug mode: Starting game with " .. #seatedColors .. " players.")
    log("Seated colors: " .. table.concat(seatedColors, ", "))
    for _, color in pairs(seatedColors) do
        if not claimedFactionsByColor[color] then
            claimedFactionsByColor[color] = Ships.selectRandomCommand(color)
        end
    end
    log("Claimed factions by color:")
    log(claimedFactionsByColor)
end

function cleanUp()
    -- Remove all buttons
    Utils.removeButton(centralBoardId, "advancePlanets")
    Utils.removeButton(RoundManager.fleetAdmiralCardId(), "advanceFleetAdmiral")
    removePhaseButtons(RoundManager.admiralColor())
end

function createButtons()
    Utils.createButton(centralBoardId, BtnConfig.advancePlanets)
    if PhaseManager.isPhaseActive() then
        Utils.createButton(RoundManager.fleetAdmiralCardId(), BtnConfig.advanceFleetAdmiral)
    elseif RoundManager.admiralColor() then
        createPhaseSelectionButtons(RoundManager.admiralColor())
    end
end

function createPreGameButtons()
    Utils.createButton(centralBoardId, BtnConfig.startGame)
    Utils.createButton(centralBoardId, BtnConfig.selectRandomCommandShip)
    for faction, data in pairs(FactionData) do
        for guid, ship in pairs(data.commandShips) do
            local cfg = BtnConfig.selectCommandShip
            cfg.tooltip = "Choose " .. ship.name .. " for The " .. faction
            Utils.createButton(guid, cfg)
        end
    end
end

function createPhaseSelectionButtons(playerColor)
    local faction = claimedFactionsByColor[playerColor]
    if not faction then
        broadcastToColor("No faction board found for your color.", playerColor, {1, 0.4, 0.4})
        return
    end

    local board = getObjectFromGUID(faction.PlayerBoardId)
    if not board then
        broadcastToColor("Player board for " .. faction .. " not found.", playerColor, {1, 0.4, 0.4})
        return
    end

    -- Remove existing phase buttons
    removePhaseButtons(playerColor)

    local phases = PhaseManager.getPhases()
    local prevPhase = PhaseManager.getPreviousPhase()
    local btn = BtnConfig.SelectPhase
    local btnPos = btn.position
    local btnXOffset = 0.805
    local btnIndex = 0

    for i, phaseName in ipairs(phases) do
        if phaseName ~= prevPhase then
            btn.label = phaseName
            btn.click_function = "selectPhase_" .. phaseName
            btn.position = {
                btnPos[1] + btnIndex * btnXOffset,
                btnPos[2],
                btnPos[3]
            }
            btn.tooltip = "Choose the " .. phaseName .. " phase"
            board.createButton(btn)
        end
        btnIndex = btnIndex + 1
    end
    btn.position[1] = btnPos[1] -- Reset to original position for next admiral
end

function removePhaseButtons(playerColor)
    local faction = claimedFactionsByColor[playerColor]
    if not faction then
        broadcastToColor("No faction board found for your color.", playerColor, {1, 0.4, 0.4})
        return
    end

    local board = getObjectFromGUID(faction.PlayerBoardId)
    if not board then
        broadcastToColor("Player board for " .. faction .. " not found.", playerColor, {1, 0.4, 0.4})
        return
    end

    local btns = board.getButtons()
    if btns then
        for _, btn in ipairs(btns) do
            if string.find(btn.click_function, "selectPhase_") then
                board.removeButton(btn.index)
            end
        end
    end
end

function removePreGameButtons()
    Utils.removeButton(centralBoardId, "startGame")
    Utils.removeButton(centralBoardId, "selectRandomCommandShip")
end

function advanceFleetAdmiral(_, playerColor)
    if (RoundManager.isGameFinished()) then
        return
    end

    local admiralColor = RoundManager.admiralColor()
    if not debug and admiralColor and playerColor ~= admiralColor then
        broadcastToColor("Only the Fleet Admiral (" .. admiralColor .. ") may pass.", playerColor, {1, 0.4, 0.4})
        return
    end

    -- ensure we have removed any previous phase buttons
    removePhaseButtons(RoundManager.admiralColor())

    -- Remove the advance Fleet Admiral button
    Utils.removeButton(RoundManager.fleetAdmiralCardId(), "advanceFleetAdmiral")

local postPhaseFunctions = {
    miners = function()
        Planets.advance()
            printToAll("Updating planets after Miners phase.")
    end,
    builders = function()
        Ships.advanceFactionShips(RoundManager.getPlayerCount())
        printToAll("Updating faction ships on auction.")
    end
}

    PhaseManager.resolvePostPhaseEffects(postPhaseFunctions)

    local result = RoundManager.advanceFleetAdmiral(seatedColors)
    if result.success then
        if result.isMidGame then
            Ships.advanceNeutralShips()
            printToAll("Updating neutral ships on auction.")
        end
        createPhaseSelectionButtons(result.color)
    end
    if (RoundManager.isGameFinished()) then
        cleanUp()
    end
end

function advancePlanets()
    Planets.advance()
end

function selectCommandShip(obj, playerColor)
    if claimedFactionsByColor[playerColor] then
        broadcastToColor("You have already selected a command ship and faction.", playerColor, {1, 0.4, 0.4})
        return
    end
    local selectedFactionData = Ships.selectCommand(obj, playerColor)
    claimedFactionsByColor[playerColor] = selectedFactionData
    Resources.createPlayerResourceZone(playerColor)
end

function selectRandomCommandShip(obj, playerColor)
    if claimedFactionsByColor[playerColor] then
        broadcastToColor("You have already selected a command ship and faction.", playerColor, {1, 0.4, 0.4})
        return
    end
    local selectedFactionData = Ships.selectRandomCommand(playerColor)
    claimedFactionsByColor[playerColor] = selectedFactionData
    Resources.createPlayerResourceZone(playerColor)
end

function delegate_onSelectingPhase(playerColor, phaseName)
    local admiralColor = RoundManager.admiralColor()
    if not debug and admiralColor and playerColor ~= admiralColor then
        broadcastToColor("Only the Fleet Admiral (" .. admiralColor .. ") may select the phase.", playerColor, {1, 0.4, 0.4})
        return false
    end
    return true
    end

function delegate_onSelectedPhase(playerColor, phaseName)
    local admiralColor = RoundManager.admiralColor()
        -- Remove phase buttons now that phase is locked
        removePhaseButtons(admiralColor)

    local phaseFunctions = {
        income = function()
            local success, fleetData = Ships.getFleetData()
            if not success then
                log("Failed to get fleet data for income phase.")
                return false
            end

            for playerColor, fleetData in pairs(fleetData) do
                local totalXU = 0

                for _, shipInfo in ipairs(fleetData) do
                    if shipInfo.data.xu then
                        totalXU = totalXU + shipInfo.data.xu
                    end
                end

                local isAdmiral = playerColor == admiralColor
                if isAdmiral then
                    totalXU = totalXU + Resources.AdmiralBonus()
                end

                if totalXU > 0 then
                    printToAll("Dealing " .. totalXU .. " XU to " .. (Player[playerColor].steam_name or playerColor) .. (isAdmiral and " (Admiral)" or ""), playerColor)
                    Resources.dealXUToPlayer(playerColor, totalXU)
                elseif totalXU < 0 then
                    -- Handle negative XU if needed
                    printToAll("Player " .. (Player[playerColor].steam_name or playerColor) .. " has negative XU: " .. totalXU, playerColor)
                end
            end
            return true
        end
    }

    if not PhaseManager.resolvePhaseEffects(phaseName, phaseFunctions) then
        return false
    end

        -- Create the advance Fleet Admiral button
    Utils.createButton(RoundManager.fleetAdmiralCardId(), BtnConfig.advanceFleetAdmiral)

    return true
end

function delegate_onPostPhase(success, phaseName, playerColor)
    if not success then
        -- restore the phase buttons to the admiral if the phase failed
        createPhaseSelectionButtons(RoundManager.admiralColor())
        return
    end
end

function selectPhase_Income(_, playerColor)
    PhaseManager.selectPhase(playerColor, PhaseManager.getPhases()[1])
end

function selectPhase_Miners(_, playerColor)
    PhaseManager.selectPhase(playerColor, PhaseManager.getPhases()[2])
end

function selectPhase_Transporters(_, playerColor)
    PhaseManager.selectPhase(playerColor, PhaseManager.getPhases()[3])
end

function selectPhase_Builders(_, playerColor)
    PhaseManager.selectPhase(playerColor, PhaseManager.getPhases()[4])
end

function selectPhase_Explorers(_, playerColor)
    PhaseManager.selectPhase(playerColor, PhaseManager.getPhases()[5])
end

function updateSeatedColors()
    seatedColors = T(getSeatedPlayers())

    if (debug) then
        seatedColors = T{"Purple", "Blue", "Green"}
    end

    broadcastToAll(#seatedColors .. " player(s) currently seated.", {0.7, 0.9, 1})

    if RoundManager.currentRound() == 0 then
        updatePlayerBoardStates(#seatedColors)
    end
end

function updatePlayerBoardStates(playerCount)
    local state = Utils.clamp(playerCount, 2, 5) - 1  -- convert 2–5 players to state 1–4
    for faction, data in pairs(FactionData) do
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

function onObjectLeaveContainer(container, obj)
    if obj.type == "Card" and container.hasTag(Ships.ShipTag())
    or obj.type == "Block" and container.hasTag(Resources.ResourceTag()) then
        -- This is a ship card being removed from a ship deck
        -- or resource block being removed from a resource bag.
        -- Copy container tags to the withdrawn object
        obj.setTags(container.getTags())
    end
end

function onObjectSpawn(obj)
    if obj.type == "Card" and obj.hasTag(Explorers.ExplorerTag()) then
        CardAbilities.initCard(obj)
    end
end

function onObjectNumberTyped(obj, playerColor, number)
    if obj.type == "Infinite" and obj.hasTag(Resources.ResourceTag()) then
        return Resources.spawnResourcesAtZone(obj, playerColor, number)
    end
    return false
end

function onObjectEnterZone(zone, obj)
    if obj.type ~= "Card"
    or (not obj.hasTag(Ships.ShipTag())
        and not obj.hasTag(Explorers.ExplorerTag())
    ) then
        return
    end

    if zone.type == "Hand"
    and obj.type == "Card"
    and obj.hasTag(Explorers.ExplorerTag()) then
        CardAbilities.initCard(obj)
        return
    end

    if zone.hasTag(Ships.FleetTag()) then
        Wait.time(function()
            -- Align the ship's storage squares to the grid
            Ships.applyOffsetPosition(obj)
        end, 0.1)
        return
    end

    if zone.hasTag(Ships.AuctionTag())
    and (Ships.IsFactionAuctionZoneSnappingEnabled()
        and zone.hasTag(Ships.FactionTag())
        and obj.hasTag(Ships.FactionTag())
        or
        Ships.IsNeutralAuctionZoneSnappingEnabled()
        and zone.hasTag(Ships.NeutralTag())
        and obj.hasTag(Ships.NeutralTag())
    ) then
        -- align card to the auction zone
        obj.setPositionSmooth({
            x = zone.getPosition().x,
            y = zone.getPosition().y + 0.1,  -- slightly above the zone
            z = zone.getPosition().z
        }, false, true)
    end
end