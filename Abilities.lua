local _, addon = ...
local SH = _G.LibStub("AceAddon-3.0"):GetAddon(addon.name)

SH.spellGroups = {
    -- warlock
    ["Corruption"] = {interval = 3, ranks = {172, 6222, 6223, 7648, 11671, 11672, 25311, 27216}},
    ["Immolate"] = {interval = 3, ranks = {348, 707, 1094, 2941, 11665, 11667, 11668, 25309, 27215}},
    ["Curse of Agony"] = {interval = 2, ranks = {980, 1014, 6217, 11711, 11712, 11713, 27218}},
    
    -- rogue
    ["Garrote"] = {interval = 3, ranks = {703, 8631, 8632, 8633, 11289, 11290, 26839, 26884}},
    ["Rupture"] = {interval = 2, ranks = {1943, 8639, 8640, 11273, 11274, 11275, 26867}},
    -- ["Deadly Poison"] = {interval = 2, ranks = {2823}}, TODO: Add ranks
    
    -- druid
    ["Rake"] = {interval = 3, ranks = {1822, 1823, 1824, 9904, 27003}},
    ["Rip"] = {interval = 2, ranks = {1079, 9492, 9493, 9752, 9894, 9896, 27008}},
    ["Moonfire"] = {interval = 3, ranks = {8921, 8924, 8925, 8926, 8927, 8928, 8929, 9833, 9834, 9835, 26987, 26988}},
    ["Insect Swarm"] = {interval = 2, ranks = {5570, 24974, 24975, 24976, 24977, 27013}},
    
    -- priest
    ["Shadow Word: Pain"] = {interval = 3, ranks = {589, 594, 970, 992, 2767, 10892, 10893, 10894, 25367, 25368}},
    ["Vampiric Touch"] = {interval = 3, ranks = {34914, 34916, 34917}},
    ["Devouring Plague"] = {interval = 3, ranks = {2944, 19276, 19277, 19278, 19279, 19280, 25467}},
    
    -- mage
    ["Fireball"] = {interval = 2, ranks = {133, 143, 145, 3140, 8400, 8401, 8402, 10148, 10149, 10150, 10151, 25306, 27070, 38692}},
    
    -- hunter
    ["Serpent Sting"] = {interval = 3, ranks = {1978, 13549, 13550, 13551, 13552, 13553, 13554, 13555, 25295, 27016}},
    ["Scorpid Poison"] = {interval = 2, ranks = {24640, 24583, 24586, 24587, 27060}},
    
    -- warrior
    ["Deep Wounds"] = {interval = 1, ranks = {12865, 12866, 12867}},
    ["Rend"] = {interval = 3, ranks = {772, 6546, 6547, 6548, 11572, 11573, 11574, 25208}},
}

-- build the spell id -> tick interval lookup table
SH.dotTickIntervals = {}
for spellName, data in pairs(SH.spellGroups) do
    for _, spellId in ipairs(data.ranks) do
        SH.dotTickIntervals[spellId] = data.interval
    end
end