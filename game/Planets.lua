local Planets = {}

local Utils = require("lib/Utils")

local planetDeckId = "363ed3"
local deckZoneId = "aa9994"
local currentSlotId = "1efe44"
local nextSlotId = "1d6e8b"
local thirdSlotId = "f1ec73"
local discardSlotId = "f365b1"

-- Planet deck and slots
local planetDeck = nil
local deckZone = nil
local currentSlot = nil
local nextSlot = nil
local thirdSlot = nil
local discardSlot = nil

Planets.init = function()
    log("Initializing Planets module...")
    planetDeck = getObjectFromGUID(planetDeckId)
    deckZone = getObjectFromGUID(deckZoneId)
    currentSlot = getObjectFromGUID(currentSlotId)
    nextSlot = getObjectFromGUID(nextSlotId)
    thirdSlot = getObjectFromGUID(thirdSlotId)
    discardSlot = getObjectFromGUID(discardSlotId)
    planetDeck.setPosition(deckZone.getPosition())
end

Planets.start = function()
    planetDeck.randomize()
    Wait.time(function()
        -- Draw 3 cards from deck to slots
        for i = 1, 3 do
            local waiting = 0.25 * i
            Wait.time(function()
                Planets.advance(true)
            end, waiting)
        end
    end, 0.5)
end

local advancing = false
Planets.advance = function(fast)
    if advancing then
        return
    end
    advancing = true

    if not (currentSlot and nextSlot and thirdSlot and discardSlot and deckZone) then
        print("ERROR: One or more planet slots or deck zone are missing.")
        advancing = false
        return
    end

    -- Move Current → Discard
    Utils.getCardFromZone(currentSlot, discardSlot.getPosition(), true)

    -- Move Next → Current
    Utils.getCardFromZone(nextSlot, currentSlot.getPosition(), false)

    -- Move Third → Next
    Utils.getCardFromZone(thirdSlot, nextSlot.getPosition(), false)

    -- Draw from deck zone → Third
    if not Utils.getCardFromZone(deckZone, thirdSlot.getPosition(), true) then
        print("No cards left in planet deck.")
    end

    if fast then
        advancing = false
    else
        Wait.time(function()
            advancing = false
        end, 1) -- Wait for the cards to move before allowing another advance

        broadcastToAll("Planets have advanced", {0.8, 0.9, 1})
    end
end

return Planets