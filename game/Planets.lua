local Planets = {}

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
            log(waiting)
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
    local currentCard = currentSlot.getObjects()[1]
    if currentCard then
        currentCard.flip()
        currentCard.setPositionSmooth(discardSlot.getPosition(), false, true)
    end

    -- Move Next → Current
    local nextCard = nextSlot.getObjects()[1]
    if nextCard then
        nextCard.setPositionSmooth(currentSlot.getPosition(), false, true)
    end

    -- Move Third → Next
    local thirdCard = thirdSlot.getObjects()[1]
    if thirdCard then
        thirdCard.setPositionSmooth(nextSlot.getPosition(), false, true)
    end

    if fast then
        advancing = false
    else
        Wait.time(function()
            advancing = false
        end, 1) -- Wait for the cards to move before allowing another advance

        broadcastToAll("Planets have advanced", {0.8, 0.9, 1})
    end

    -- Draw from deck zone → Third
    local deckObjects = deckZone.getObjects()
    for _, obj in ipairs(deckObjects) do
        if obj.tag == "Deck" then
            obj = obj.takeObject({
                position = deckZone.getPosition()
            })
        end
        if obj.tag == "Card" then
            obj.flip()
            obj.setPositionSmooth(thirdSlot.getPosition(), false, true)
        end
        return
    end
    print("No cards left in planet deck.")
end

return Planets