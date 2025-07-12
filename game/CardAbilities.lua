local CardAbilities = {}

local PhaseManager = require("game.PhaseManager")
local RoundManager = require("game.RoundManager")

-- Registered abilities by card GUID
local abilityRegistry = {
    ["7e196c"] = {
        name = "The Plan",
        type = "Explorer",
        tooltip = "Activate to repeat the previous phase",
        condition = function(card, playerColor)
            return RoundManager.admiralColor() == playerColor and PhaseManager.getPreviousPhase() ~= nil
        end,
        onClick = function(card, playerColor)
            local success, previousPhase = PhaseManager.forcePreviousPhase(playerColor)
            if not success then
                return
            end
            broadcastToAll((Player[playerColor].steam_name or playerColor) .. " used 'The Plan' to repeat the " .. previousPhase .. " phase.", {1, 1, 0.4})
            card.clearButtons()
            Wait.time(function()
                card.destruct()
            end, 5)
        end
    }
}

-- Initialize cards (called from Global on load or when cards enter hand/zone)
CardAbilities.initCard = function(card)
    local ability = abilityRegistry[card.getGUID()]
    if not ability then return end

    if ability.onClick then
        card.createButton({
            label = ability.name,
            click_function = "onAbility_" .. card.getGUID(),
            function_owner = Global,
            position = {0, 0.3, 0.45},
            width = 2000,
            height = 300,
            scale = {0.5, 0.5, 0.5},
            font_size = 180,
            color = {0.9, 0.9, 0.4},
            font_color = {0, 0, 0},
            tooltip = ability.tooltip or "Activate " .. ability.name
        })
    end
end

CardAbilities.restore = function()
    log("Restoring Card Abilities...")
    -- Restore abilities for seated players
    for _, hand in ipairs(Hands.getHands()) do
        for _, obj in ipairs(hand.getObjects()) do
            log(obj)
            if obj and obj.type == "Card" and obj.getGUID then
                local ability = abilityRegistry[obj.getGUID()]
                if ability then
                    CardAbilities.initCard(obj)
                end
            end
        end
    end
end

-- Dynamic click dispatcher (called by Global)
function _G.onAbility_dispatch(guid, playerColor)
    local card = getObjectFromGUID(guid)
    local ability = abilityRegistry[guid]
    if ability and ability.onClick and ability.condition(card, playerColor) then
        ability.onClick(card, playerColor)
    end
end

CardAbilities.register = function()
    -- Generate click_function name dynamically for the button
    for guid, _ in pairs(abilityRegistry) do
        _G["onAbility_" .. guid] = function(obj, playerColor)
            _G.onAbility_dispatch(guid, playerColor)
        end
    end
end

return CardAbilities