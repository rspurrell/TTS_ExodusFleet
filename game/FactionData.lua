local ShipData = require("game.ShipData")

local FactionData = T{
    ["B-Leaguers"] = {
        playerBoard = "1fd3ec",
        commandShips = T{
            [ShipData.COMMAND_MINING] = ShipData[ShipData.COMMAND_MINING],
            [ShipData.COMMAND_TRANSPORT] = ShipData[ShipData.COMMAND_TRANSPORT]
        }
    },
    ["Cedarim"] = {
        playerBoard = "6539aa",
        commandShips = T{
            [ShipData.COMMAND_PURCHASE] = ShipData[ShipData.COMMAND_PURCHASE],
            [ShipData.COMMAND_SPACE] = ShipData[ShipData.COMMAND_SPACE]
        }
    },
    ["Karpians"] = {
        playerBoard = "e70f4f",
        commandShips = T{
            [ShipData.COMMAND_PLANNING] = ShipData[ShipData.COMMAND_PLANNING],
            [ShipData.COMMAND_TRADE] = ShipData[ShipData.COMMAND_TRADE]
        }
    },
    ["Paumerites"] = {
        playerBoard = "dad8ee",
        commandShips = T{
            [ShipData.COMMAND_CONSTRUCTION] = ShipData[ShipData.COMMAND_CONSTRUCTION],
            [ShipData.COMMAND_EXPLORATION] = ShipData[ShipData.COMMAND_EXPLORATION]
        }
    },
    ["Wetrockers"] = {
        playerBoard = "a244b3",
        commandShips = T{
            [ShipData.COMMAND_INVESTMENT] = ShipData[ShipData.COMMAND_INVESTMENT],
            [ShipData.COMMAND_MERCHANT] = ShipData[ShipData.COMMAND_MERCHANT]
        }
    }
}
return FactionData