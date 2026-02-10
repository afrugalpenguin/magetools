local MT = MageTools

MT.TELEPORTS = {
    -- Alliance
    { spellID = 3561,  name = "Stormwind",    faction = "Alliance" },
    { spellID = 3562,  name = "Ironforge",    faction = "Alliance" },
    { spellID = 3565,  name = "Darnassus",    faction = "Alliance" },
    { spellID = 32271, name = "Exodar",       faction = "Alliance" },
    -- Horde
    { spellID = 3567,  name = "Orgrimmar",    faction = "Horde" },
    { spellID = 3563,  name = "Undercity",    faction = "Horde" },
    { spellID = 3566,  name = "Thunder Bluff", faction = "Horde" },
    { spellID = 32272, name = "Silvermoon",   faction = "Horde" },
    -- Neutral
    { spellID = 35715, name = "Shattrath",    faction = "Neutral" },
}

MT.PORTALS = {
    -- Alliance
    { spellID = 10059, name = "Stormwind",    faction = "Alliance" },
    { spellID = 11416, name = "Ironforge",    faction = "Alliance" },
    { spellID = 11419, name = "Darnassus",    faction = "Alliance" },
    { spellID = 32266, name = "Exodar",       faction = "Alliance" },
    -- Horde
    { spellID = 11417, name = "Orgrimmar",    faction = "Horde" },
    { spellID = 11418, name = "Undercity",    faction = "Horde" },
    { spellID = 11420, name = "Thunder Bluff", faction = "Horde" },
    { spellID = 32267, name = "Silvermoon",   faction = "Horde" },
    -- Neutral
    { spellID = 33691, name = "Shattrath",    faction = "Neutral" },
}

-- Conjured food item IDs (all ranks, highest first)
MT.CONJURED_FOOD = {
    22895, -- Conjured Cinnamon Roll (Rank 8)
    22019, -- Conjured Croissant (Rank 7)
    8075,  -- Conjured Sourdough (Rank 6)
    1487,  -- Conjured Pumpernickel (Rank 5)
    1114,  -- Conjured Rye (Rank 4)
    1113,  -- Conjured Bread (Rank 3)
    5349,  -- Conjured Muffin (Rank 2)
}

-- Conjured water item IDs (all ranks, highest first)
MT.CONJURED_WATER = {
    30703, -- Conjured Mountain Spring Water (Rank 9)
    22018, -- Conjured Glacier Water (Rank 8)
    8079,  -- Conjured Crystal Water (Rank 7)
    8078,  -- Conjured Sparkling Water (Rank 6)
    8077,  -- Conjured Mineral Water (Rank 5)
    3772,  -- Conjured Spring Water (Rank 4)
    2136,  -- Conjured Purified Water (Rank 3)
    2288,  -- Conjured Fresh Water (Rank 2)
    5350,  -- Conjured Water (Rank 1)
}

-- Mana gem item IDs (highest first)
MT.MANA_GEMS = {
    22044, -- Mana Emerald
    8008,  -- Mana Ruby
    8007,  -- Mana Citrine
    5513,  -- Mana Jade
    5514,  -- Mana Agate
}

-- Conjure spell IDs (highest rank)
MT.CONJURE_FOOD_SPELL = 33717  -- Conjure Food Rank 8
MT.CONJURE_WATER_SPELL = 27090 -- Conjure Water Rank 9
MT.CONJURE_GEM_SPELL = 27101   -- Conjure Mana Emerald

-- Build a lookup set of all conjured item IDs for fast bag scanning
MT.CONJURED_ITEM_SET = {}
for _, id in ipairs(MT.CONJURED_FOOD) do MT.CONJURED_ITEM_SET[id] = "food" end
for _, id in ipairs(MT.CONJURED_WATER) do MT.CONJURED_ITEM_SET[id] = "water" end
for _, id in ipairs(MT.MANA_GEMS) do MT.CONJURED_ITEM_SET[id] = "gem" end
