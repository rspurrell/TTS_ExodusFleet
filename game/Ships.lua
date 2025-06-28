local Ships = {}

local factionData = require("game.FactionData")
local Utils = require("lib.Utils")
local Resources = require("game.ResourceData")

local TAG_SHIP_AUCTION = "ShipAuction"
local TAG_FLEET = "Fleet"
local TAG_SHIP = "Ship"
local TAG_COMMAND = "Command"
local TAG_FACTION = "Faction"
local TAG_STARTING = "Starting"
local TAG_NEUTRAL = "Neutral"

local shipDecks = { -- tags and the deck they are associated with
    [TAG_COMMAND] = "d5770c",  -- Command Ships (original deck, may be empty)
    [TAG_FACTION] = "a8f671",  -- Faction Ships
    [TAG_STARTING] = "cae96a", -- Starting Ships
    [TAG_NEUTRAL] = "2ef965",  -- Neutral Ships
}

local shipOffset = { -- offset corrections for 0.52 grid
    [0] = {
        x = 0.135,
        z = 0.19
    },
    [180] = {
        x = -0.145,
        z = -0.235
    },
    [90] = {
        x = 0.23,
        z = -0.125
    },
    [270] = {
        x = -0.245,
        z = 0.125
    },
}

local neutralAuctionZoneSnappingEnabled = true  -- Enable snapping to grid for neutral auction zones
local factionAuctionZoneSnappingEnabled = true  -- Enable snapping to grid for faction auction zones
local claimedFactions = {}
local shipZones = {}  -- Maps player color to ship scripting trigger zone
local neutralDeckZones = {}  -- Maps deck tag to neutral ship deck zone
local factionDeckZones = {}  -- Maps deck tag to faction ship deck zone

Ships.AuctionTag = function()
    return TAG_SHIP_AUCTION
end

Ships.FactionTag = function()
    return TAG_FACTION
end

Ships.FleetTag = function()
    return TAG_FLEET
end

Ships.NeutralTag = function()
    return TAG_NEUTRAL
end

Ships.ShipTag = function()
    return TAG_SHIP
end

Ships.IsNeutralAuctionZoneSnappingEnabled = function(value)
    return neutralAuctionZoneSnappingEnabled
end

Ships.IsFactionAuctionZoneSnappingEnabled = function(value)
    return factionAuctionZoneSnappingEnabled
end

Ships.init = function()
    log("Initializing Ships module...")
    shipOffset[360] = shipOffset[0]  -- Add 360° rotation to ship offsets

    -- Tag loose Command Ships
    for faction, data in pairs(factionData) do
        for guid, ship in pairs(data.commandShips) do
            getObjectFromGUID(guid).setTags({TAG_SHIP, TAG_COMMAND})
        end
    end

    -- Tag each ship deck
    for tag, deckGUID in pairs(shipDecks) do
        local deck = getObjectFromGUID(deckGUID)
        if deck and deck.type == "Deck" then
            deck.setTags({TAG_SHIP, tag})
        end
    end
end

Ships.start = function(origin, direction, distance, playerCount)
    createShipAuctionZones(origin, direction, distance, playerCount)

    local y = origin.y + 2  -- raise slightly off the table
    local rot = {0, 180, 180} -- rotate horizontal and keep decks face down

    -- Move neutral deck to first zone
    local neutralDeck = getObjectFromGUID(shipDecks[TAG_NEUTRAL])
    local firstNeutralZonePos = neutralDeckZones[1].getPosition()
    neutralDeck.setRotation(rot)
    neutralDeck.setPositionSmooth({firstNeutralZonePos.x, y, firstNeutralZonePos.z})
    Wait.time(function()
        neutralDeck.shuffle()
    end, 0.5)

    -- Move and prepare faction and starting decks
    local factionDeck = getObjectFromGUID(shipDecks[TAG_FACTION])
    local firstFactionZonePos = factionDeckZones[1].getPosition()
    factionDeck.setRotation(rot)
    factionDeck.setPositionSmooth({firstFactionZonePos.x, y, firstFactionZonePos.z})
    Wait.time(function()
        factionDeck.shuffle()
    end, 0.5)

    local startingDeck = getObjectFromGUID(shipDecks[TAG_STARTING])
    startingDeck.setRotation(rot)
    startingDeck.setPositionSmooth({firstFactionZonePos.x, y + 1, firstFactionZonePos.z})
    Wait.time(function()
        startingDeck.shuffle()
    end, 0.5)

    Wait.time(function()
        Ships.advanceNeutralShips()
        Ships.advanceFactionShips(playerCount)
    end, 2)
end

Ships.advanceNeutralShips = function()
    if #neutralDeckZones < 3 then
        print("ERROR: Not enough neutral ship zones created.")
        return
    end

    neutralAuctionZoneSnappingEnabled = false
    advanceAuctionZones(neutralDeckZones, #neutralDeckZones - 2, function()
        log("Re-enabling neutral auction zone snapping.")
        neutralAuctionZoneSnappingEnabled = true
    end)
end

Ships.advanceFactionShips = function(playerCount)
    if #factionDeckZones < 3 then
        print("ERROR: Not enough faction ship zones created.")
        return
    end

    factionAuctionZoneSnappingEnabled = false
    local numToDiscard = (playerCount <= 3) and 1 or 2  -- discard 1 or 2 existing ships based on player count
    local auctionZones = {table.unpack(factionDeckZones, 2, #factionDeckZones - 1)}

     -- left justify existing ships in faction auction zones before advancing
    Utils.justifyZones({table.unpack(factionDeckZones, 2, #factionDeckZones - 1)}, 1, function(existingShipCount)
        if numToDiscard > existingShipCount then
            numToDiscard = existingShipCount  -- don't discard more than available
        end
        local numShipsToDeal = #auctionZones + numToDiscard - existingShipCount  -- always fill faction ship auction zones
        print("Refreshing faction ships on auction. Discarding " .. numToDiscard .. " ship(s).")
        advanceAuctionZones(factionDeckZones, numShipsToDeal, function()
            log("Re-enabling faction auction zone snapping.")
            factionAuctionZoneSnappingEnabled = true
        end)
    end)
end

function advanceAuctionZones(zones, numToDeal, callback)
    if #zones < 3 then
        print("ERROR: Not enough auction zones created.")
        return
    end

    local delay = 0
    local delayStep = 0.25  -- for animation spacing
    for j = 1, numToDeal, 1 do
        Wait.time(function()
            for i = #zones - 1, 1, -1 do
                local source = zones[i]
                local targetPos = zones[i + 1].getPosition()
                Utils.getCardFromZone(source, targetPos, (i == 1) or (i + 1 == #zones))
            end

            if j == numToDeal and callback then
                Wait.time(callback, delayStep)
            end
        end, delay)
        delay = delay + delayStep
    end
end

Ships.selectRandomCommand = function(playerColor)
    local factionName = Utils.randomTableKey(factionData:filter(|_, name| not claimedFactions[name]))
    local shipId = Utils.randomTableKey(factionData[factionName].commandShips)
    return Ships.selectCommand(getObjectFromGUID(shipId), playerColor)
end

Ships.selectCommand = function(obj, playerColor)
    -- Get hand transform and forward vector
    local handTransform = Player[playerColor].getHandTransform()
    if not handTransform then
        broadcastToColor("Error: Sit at an eligible player position", playerColor, {1,0,0})
        return
    end

    if not obj then
        broadcastToAll("Error: Command ship card is null.", {1,0,0})
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
        broadcastToColor("Error: Command ship not found in data table.", playerColor, {1,0,0})
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
        explorer.deal(1, playerColor)
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

    broadcastToAll((Player[playerColor].steam_name or playerColor) .. " selected " ..
        selectedShipEntry.name .. " (" .. selectedFaction .. ").", {0.5, 1, 0.5})

    Resources.dealXUToPlayer(playerColor, selectedShipEntry.xu)
    Resources.createPlayerResourceZone(playerColor)
    Resources.spawnStartingResources(playerColor)

    createPlayerFleetZone(playerColor)

    claimedFactions[selectedFaction] = true
    return {
        CommandShip = selectedShipEntry,
        Faction = selectedFaction,
        PlayerColor = playerColor
    }
end

function createPlayerFleetZone(color)
    local hand = Player[color].getHandTransform()
    if not hand then
        return
    end

    -- Position in front of hand (same logic as with Admiral/Faction boards)
    local pos = {
        x = hand.position.x + hand.forward.x * 15.2,
        y = 0.5,
        z = hand.position.z + hand.forward.z * 15.2
    }

    local rot = {0, hand.rotation.y, 0}

    local zone = spawnObject({
        type = "ScriptingTrigger",
        position = pos,
        rotation = rot,
        scale = {23, 0.25, 8},  -- adjustable size
        sound = false,
        snap_to_grid = false
    })

    zone.setName("FleetZone_" .. color)
    zone.setVar("zoneColor", color)
    zone.setTags({TAG_SHIP, TAG_FLEET})
    zone.interactable = false
    shipZones[color] = zone
end

function createShipAuctionZones(origin, direction, distance, playerCount)
    -- Create zones for the neutral and faction ship decks

    -- Fetch decks
    local neutralDeck = getObjectFromGUID(shipDecks[TAG_NEUTRAL])
    local factionDeck = getObjectFromGUID(shipDecks[TAG_FACTION])

    if not (neutralDeck and factionDeck) then
        print("ERROR: One or more ship decks not found.")
        return
    end

    -- Get deck sizes
    local neutralSize = neutralDeck.getBoundsNormalized().size
    local factionSize = factionDeck.getBoundsNormalized().size

    -- Determine number of zones
    local numNeutralZones = (playerCount <= 3) and 6 or 7
    local numFactionZones = 7

    local zoneYScale = 0.8

    neutralDeckZones = Utils.createZones(origin, {
        x = neutralSize.x,
        y = zoneYScale,
        z = neutralSize.z
    }, direction, distance, numNeutralZones, "NeutralShipZone", {TAG_SHIP_AUCTION, TAG_SHIP, TAG_NEUTRAL})

    local factionOffset = neutralSize.z + 0.5  -- Offset to place faction zones below neutral zones
    factionDeckZones = Utils.createZones({
        x = origin.x,
        y = origin.y,
        z = origin.z - factionOffset
    }, {
        x = factionSize.x,
        y = zoneYScale,
        z = factionSize.z
    }, direction, distance, numFactionZones, "FactionShipZone", {TAG_SHIP_AUCTION, TAG_SHIP, TAG_FACTION})
end

Ships.applyOffsetPosition = function(ship)
    local pos = ship.getPosition()
    local rot = ship.getRotation()
    local clamprot = Utils.clampRightAngle(rot.y)
    local offset = shipOffset[clamprot]
    ship.setPositionSmooth({
        pos.x + offset.x,
        pos.y,
        pos.z + offset.z
    }, false, true)
    ship.setRotationSmooth({
        rot.x,
        clamprot,
        rot.z
    }, false, true)
end

Ships.removeUnclaimedFactions = function()
    for faction, data in pairs(factionData) do
        if not claimedFactions[faction] then
            -- Destroy the player board
            local board = getObjectFromGUID(data.playerBoard)
            if board then
                board.destruct()
            end

            -- Destroy command ships and explorer cards
            for guid, ship in pairs(data.commandShips) do
                local shipObj = getObjectFromGUID(guid)
                if shipObj then
                    shipObj.destruct()
                end

                local explorer = getObjectFromGUID(ship.explorerCard)
                if explorer then
                    explorer.destruct()
                end
            end
        end
    end
end

return Ships