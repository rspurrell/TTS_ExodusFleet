local buttonConfig = {
    ["advancePlanets"] = {
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
        tooltip = "Advance all planet cards",
    },
    ["advanceRound"] = {
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
    },
    ["advanceFleetAdmiral"] = {
        label = "Pass",
        click_function = "advanceFleetAdmiral",
        function_owner = Global,
        position = {0, 0.35, -0.35},
        rotation = {0, 0, 0},
        width = 400,
        height = 300,
        scale = { 0.75, 1, 0.75 },
        font_size = 160,
        tooltip = "Pass the Fleet Admiral position to the next player.",
    },
    ["selectCommandShip"] = {
        label = "☑",
        click_function = "selectCommandShip",
        function_owner = Global,
        position = {-0.91, 0.3, -0.90},  -- near upper-left corner
        width = 100,
        height = 120,
        font_size = 75
    },
    ["selectRandomCommandShip"] = {
        label = "Random\nCommand Ship",
        click_function = "selectRandomCommandShip",
        function_owner = Global,
        position = {0, 0.01, 1.08},
        rotation = {0, 0, 0},
        width = 2100,
        height = 800,
        scale = { 0.1, 1, 0.1 },
        font_size = 250,
        color = {0.8, 0.4, 0}, -- dark orange color
        font_color = {1, 1, 1},
        tooltip = "Select a random command ship",
    },
    ["startGame"] = {
        label = "Start Game",
        click_function = "startGame",
        function_owner = Global,
        position = {-1.55, 0.01, 1.08},
        rotation = {0, 0, 0},
        width = 2100,
        height = 800,
        scale = { 0.1, 1, 0.1 },
        font_size = 250,
        color = {0.176, 0.412, 0.176},
        font_color = {1, 1, 1},
        tooltip = "Start the game and assign the first player",
    },
}

local resourceIDs = {
    Biomass = "a08163",
    Fuel = "1d5775",
    Metal = "64535d",
    Water = "05e02e"
}

local xuDenominations = {10, 5, 3, 1}

local xuIDs = {
    ["1"] = "4e7b3a",
    ["3"] = "95a6bf",
    ["5"] = "d6cf0d",
    ["10"] = "c5a1fb"
}

return {
    ButtonConfig = buttonConfig,
    XuDenominations = xuDenominations,
    XuIDs = xuIDs,
    ResourceIDs = resourceIDs
}