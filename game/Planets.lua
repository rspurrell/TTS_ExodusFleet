local Planets = {}

local advancing = false
Planets.advance = function()
    if advancing then
        return
    end
    advancing = true

    -- Planet slots
    local currentSlot = getObjectFromGUID("1efe44")
    local nextSlot = getObjectFromGUID("1d6e8b")
    local thirdSlot = getObjectFromGUID("f1ec73")
    local discardSlot = getObjectFromGUID("f365b1")
    local deckZone = getObjectFromGUID("aa9994")

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

    Wait.time(function()
        -- Move Next → Current
        local nextCard = nextSlot.getObjects()[1]
        if nextCard then
            nextCard.setPositionSmooth(currentSlot.getPosition(), false, true)
        end
    end, 0.25)

    Wait.time(function()
        -- Move Third → Next
        local thirdCard = thirdSlot.getObjects()[1]
        if thirdCard then
            thirdCard.setPositionSmooth(nextSlot.getPosition(), false, true)
        end
    end, 0.5)

    Wait.time(function()
        advancing = false
        broadcastToAll("Planets have advanced", {0.8, 0.9, 1})
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
    end, 0.75)
end

return Planets