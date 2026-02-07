Config = {}

Config.Debug = false

Config.SlotMachine = {
    model = `ch_prop_casino_slot_06a`,
    coords = vec4(328.82, -912.29, 28.25, -267.96),
    icon = 'fas fa-arrow-down',
    label = 'Play Plinko'
}

Config.MinBet = 10
Config.MaxBet = 50000

-- INCREASED TO 16 ROWS (Standard High Density Plinko)
-- 16 Rows = 17 Slots at the bottom
Config.Rows = 16 

-- Max balls player can drop at once
Config.MaxBallCount = 20 

-- Multipliers for 16 Rows (17 Slots)
Config.Risk = {
    ['low'] = {
        payouts = {16, 9, 2, 1.4, 1.4, 1.2, 1.1, 1, 0.5, 1, 1.1, 1.2, 1.4, 1.4, 2, 9, 16}
    },
    ['medium'] = {
        payouts = {110, 41, 10, 5, 3, 1.5, 1, 0.5, 0.3, 0.5, 1, 1.5, 3, 5, 10, 41, 110}
    },
    ['high'] = {
        payouts = {1000, 130, 26, 9, 4, 2, 0.2, 0.2, 0.2, 0.2, 0.2, 2, 4, 9, 26, 130, 1000}
    }
}

-- Probabilities for 17 Slots
-- Heavily weighted towards the center indices (7, 8, 9, 10, 11)
Config.Probabilities = {
    ['low']    = {1, 2, 5, 10, 20, 40, 60, 100, 150, 100, 60, 40, 20, 10, 5, 2, 1},
    ['medium'] = {1, 1, 2, 5, 10, 20, 60, 120, 200, 120, 60, 20, 10, 5, 2, 1, 1},
    ['high']   = {1, 1, 1, 2, 5, 10, 30, 150, 400, 150, 30, 10, 5, 2, 1, 1, 1}
}