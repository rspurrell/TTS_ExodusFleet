local COMMAND_MINING = "88d07b"
local COMMAND_TRANSPORT = "8bc2f6"
local COMMAND_PURCHASE = "0e1fea"
local COMMAND_SPACE = "9e9470"
local COMMAND_PLANNING = "74064d"
local COMMAND_TRADE = "1a55aa"
local COMMAND_CONSTRUCTION = "d4d180"
local COMMAND_EXPLORATION = "cb6087"
local COMMAND_INVESTMENT = "7aa10a"
local COMMAND_MERCHANT = "fe5d2c"

local ShipData = {
    -- Command Ships
    [COMMAND_MINING] = {
        explorerCard = "05cf48",
        faction = "B-Leaguers",
        name = "Mining Command",
        xu = 8,
    },
    [COMMAND_TRANSPORT] = {
        explorerCard = "5c24e1",
        faction = "B-Leaguers",
        name = "Transport Command",
        xu = 8,
    },
    [COMMAND_PURCHASE] = {
        explorerCard = "6cc899",
        faction = "Cedarim",
        name = "Purchase Command",
        xu = 9,
    },
    [COMMAND_SPACE] = {
        explorerCard = "b6e19e",
        faction = "Cedarim",
        name = "Space Command",
        xu = 8,
    },
    [COMMAND_PLANNING] = {
        explorerCard = "7e196c",
        faction = "Karpians",
        name = "Planning Command",
        xu = 7,
    },
    [COMMAND_TRADE] = {
        explorerCard = "e299cc",
        faction = "Karpians",
        name = "Trade Command",
        xu = 8,
    },
    [COMMAND_CONSTRUCTION] = {
        explorerCard = "1dcf83",
        faction = "Paumerites",
        name = "Construction Command",
        xu = 8,
    },
    [COMMAND_EXPLORATION] = {
        explorerCard = "9d2bb9",
        faction = "Paumerites",
        name = "Exploration Command",
        xu = 9,
    },
    [COMMAND_INVESTMENT] = {
        explorerCard = "dcc291",
        faction = "Wetrockers",
        name = "Investment Command",
        xu = 12,
    },
    [COMMAND_MERCHANT] = {
        explorerCard = "2193dd",
        faction = "Wetrockers",
        name = "Merchant Command",
        xu = 8,
    },

    -- Starting Ships
    ["e963d6"] = {
        faction = "B-Leaguers",
        name = "Black Market",
        xu = 1,
    },
    ["b89f3c"] = {
        faction = "B-Leaguers",
        name = "Market Ship",
        xu = 1,
    },
    ["f383da"] = {
        faction = "Cedarim",
        name = "Mini-Recycler",
        xu = 1,
    },
    ["86c841"] = {
        faction = "Cedarim",
        name = "Haulage Ship",
        xu = -1,
    },
    ["457bc1"] = {
        faction = "Karpians",
        name = "Mini-Explorer",
        xu = 0,
    },
    ["f47d3b"] = {
        faction = "Karpians",
        name = "Merchant Ship",
        xu = 1,
    },
    ["93c350"] = {
        faction = "Paumerites",
        name = "Power Plant",
        xu = 1,
    },
    ["364af4"] = {
        faction = "Paumerites",
        name = "Redistribution Center",
        xu = 1,
    },
    ["ae20d7"] = {
        faction = "Wetrockers",
        name = "Wholesaler",
        xu = 1,
    },
    ["63dd5c"] = {
        faction = "Wetrockers",
        name = "Military Builders",
        xu = 0,
    },

    -- Faction Ships

    -- B-Leaguers
    ["a2a835"] = {
        faction = "B-Leaguers",
        name = "Alien Breeders",
        xu = 0
    },
    ["8def45"] = {
        faction = "B-Leaguers",
        name = "Junkyard",
        xu = 1
    },
    ["74de1c"] = {
        faction = "B-Leaguers",
        name = "Military Repair Center",
        xu = 0
    },
    ["7d37d7"] = {
        faction = "B-Leaguers",
        name = "Mini-Transporter",
        xu = 1
    },
    ["379785"] = {
        faction = "B-Leaguers",
        name = "Miners Union",
        xu = 0
    },
    ["977588"] = {
        faction = "B-Leaguers",
        name = "Sewage Processor",
        xu = 1
    },
    ["6ebac5"] = {
        faction = "B-Leaguers",
        name = "Transporters Union",
        xu = 0
    },

    -- Cedarim
    ["57bd2a"] = {
        faction = "Cedarim",
        name = "Asteroid Tour Ship",
        xu = 1
    },
    ["1c7fad"] = {
        faction = "Cedarim",
        name = "Construction Platform",
        xu = 0
    },
    ["49772a"] = {
        faction = "Cedarim",
        name = "Greenhouse",
        xu = 1
    },
    ["b43d82"] = {
        faction = "Cedarim",
        name = "Military Barracks",
        xu = -1
    },
    ["70a362"] = {
        faction = "Cedarim",
        name = "Solar Station",
        xu = 1
    },
    ["ec8ef1"] = {
        faction = "Cedarim",
        name = "Space Magnet",
        xu = 1
    },
    ["a69a80"] = {
        faction = "Cedarim",
        name = "Super-Tanker",
        xu = 1
    },

    -- Karpians
    ["1f51d8"] = {
        faction = "Karpians",
        name = "Biochemical Plant",
        xu = 1
    },
    ["418c76"] = {
        faction = "Karpians",
        name = "Culinary Clinic",
        xu = 1
    },
    ["d334ad"] = {
        faction = "Karpians",
        name = "Game Reserve",
        xu = 1
    },
    ["d1408e"] = {
        faction = "Karpians",
        name = "Hospital",
        xu = -1
    },
    ["89eca8"] = {
        faction = "Karpians",
        name = "Military Laser",
        xu = 1
    },
    ["45ed52"] = {
        faction = "Karpians",
        name = "Recycler",
        xu = 1
    },
    ["29585e"] = {
        faction = "Karpians",
        name = "Safe Storage",
        xu = 1
    },

    -- Paumerites
    ["4c1bac"] = {
        faction = "Paumerites",
        name = "Conference Station",
        xu = 0
    },
    ["c9e57a"] = {
        faction = "Paumerites",
        name = "Eco-Habitat",
        xu = 0
    },
    ["a00358"] = {
        faction = "Paumerites",
        name = "Immigration Control",
        xu = -1
    },
    ["677014"] = {
        faction = "Paumerites",
        name = "Military Technology",
        xu = 0
    },
    ["e8aa46"] = {
        faction = "Paumerites",
        name = "Military Warehouse",
        xu = 1
    },
    ["9892ab"] = {
        faction = "Paumerites",
        name = "Mini-miner",
        xu = 1
    },
    ["e7124c"] = {
        faction = "Paumerites",
        name = "Sanitation Plant",
        xu = 1
    },

    -- Wetrockers
    ["ef51e8"] = {
        faction = "Wetrockers",
        name = "Biomass Farm",
        xu = 1
    },
    ["a974ef"] = {
        faction = "Wetrockers",
        name = "Builders Union",
        xu = 1
    },
    ["6a29fb"] = {
        faction = "Wetrockers",
        name = "Explorers Union",
        xu = 0
    },
    ["0190de"] = {
        faction = "Wetrockers",
        name = "Ice Collector",
        xu = 1
    },
    ["3aed7f"] = {
        faction = "Wetrockers",
        name = "Logistics Center",
        xu = -1
    },
    ["40bc0c"] = {
        faction = "Wetrockers",
        name = "Refugee Camp",
        xu = -1
    },
    ["c1d4fa"] = {
        faction = "Wetrockers",
        name = "Shipyard",
        xu = 1
    },

    -- Neutral Ships
    ["f3f823"] = {
        faction = "Neutral",
        name = "Astronomical Array",
        xu = 1
    },
    ["b9dd43"] = {
        faction = "Neutral",
        name = "Bank",
        xu = 3
    },
    ["25f7f9"] = {
        faction = "Neutral",
        name = "Blockade Runner",
        xu = 2
    },
    ["afaad6"] = {
        faction = "Neutral",
        name = "Casino Ship",
        xu = 3
    },
    ["df70e2"] = {
        faction = "Neutral",
        name = "Church of the New Land",
        xu = 2
    },
    ["a03837"] = {
        faction = "Neutral",
        name = "Cryogenic Storage",
        xu = -1
    },
    ["4e1974"] = {
        faction = "Neutral",
        name = "Fellowship Hall",
        xu = 1
    },
    ["3fe9e1"] = {
        faction = "Neutral",
        name = "Fleet Congress",
        xu = 2
    },
    ["bf4fed"] = {
        faction = "Neutral",
        name = "Interstellar Concordia",
        xu = 2
    },
    ["891a14"] = {
        faction = "Neutral",
        name = "Military Explorer",
        xu = 2
    },
    ["8ef8c2"] = {
        faction = "Neutral",
        name = "Military Gunship",
        xu = 0
    },
    ["aba531"] = {
        faction = "Neutral",
        name = "Military HQ",
        xu = 2
    },
    ["eb7989"] = {
        faction = "Neutral",
        name = "Navigation Vessel",
        xu = 0
    },
    ["d8d17a"] = {
        faction = "Neutral",
        name = "Safe Haven",
        xu = 0
    },
    ["d70378"] = {
        faction = "Neutral",
        name = "Space Hotel",
        xu = 3
    },
    ["00a936"] = {
        faction = "Neutral",
        name = "Storage Hold",
        xu = -1
    },
    ["1b2fae"] = {
        faction = "Neutral",
        name = "Terraformers Guild",
        xu = 1
    },
    ["354430"] = {
        faction = "Neutral",
        name = "Time Capsule",
        xu = -1
    },
    ["de0843"] = {
        faction = "Neutral",
        name = "Undersea Explorers",
        xu = 1
    },
    ["629f74"] = {
        faction = "Neutral",
        name = "Welcome Center",
        xu = 1
    },
    ["c7e52c"] = {
        faction = "Neutral",
        name = "Xenological Center",
        xu = 2
    },
}

ShipData.COMMAND_MINING = COMMAND_MINING
ShipData.COMMAND_TRANSPORT = COMMAND_TRANSPORT
ShipData.COMMAND_PURCHASE = COMMAND_PURCHASE
ShipData.COMMAND_SPACE = COMMAND_SPACE
ShipData.COMMAND_PLANNING = COMMAND_PLANNING
ShipData.COMMAND_TRADE = COMMAND_TRADE
ShipData.COMMAND_CONSTRUCTION = COMMAND_CONSTRUCTION
ShipData.COMMAND_EXPLORATION = COMMAND_EXPLORATION
ShipData.COMMAND_INVESTMENT = COMMAND_INVESTMENT
ShipData.COMMAND_MERCHANT = COMMAND_MERCHANT

return ShipData