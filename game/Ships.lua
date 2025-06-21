local Ships = {}

local factionData = require("game.FactionData")
local Utils = require("lib.Utils")

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

local claimedFactions = {}
local shipZones = {}  -- Maps player color to ship scripting trigger zone

Ships.ShipTag = function()
    return TAG_SHIP
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

    -- Tag all cards in each ship deck
    for tag, deckGUID in pairs(shipDecks) do
        local deck = getObjectFromGUID(deckGUID)
        if deck and deck.type == "Deck" then
            deck.setTags({TAG_SHIP, tag})
        end
    end
end

Ships.selectCommand = function(obj, playerColor)
    -- Get hand transform and forward vector
    local handTransform = Player[playerColor].getHandTransform()
    if not handTransform then
        broadcastToColor("Error: Sit at an eligible player position", playerColor, {1,0,0})
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

    broadcastToAll(Player[playerColor].steam_name .. " selected " ..
        selectedShipEntry.name .. " (" .. selectedFaction .. ").", {0.5, 1, 0.5})

    Utils.dealXUToPlayer(playerColor, selectedShipEntry.xu)
    Utils.spawnStartingResources(hPos, hForward)

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
        y = 1,
        z = hand.position.z + hand.forward.z * 15.2
    }

    local rot = {0, hand.rotation.y, 0}

    local zone = spawnObject({
        type = "ScriptingTrigger",
        position = pos,
        rotation = rot,
        scale = {23, 1, 8},  -- adjustable size
        sound = false,
        snap_to_grid = false
    })

    zone.setName("ShipZone_" .. color)
    zone.setVar("zoneColor", color)
    zone.addTag(TAG_SHIP)
    zone.interactable = false
    shipZones[color] = zone
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