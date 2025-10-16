local _, addon = ...
local SH = _G.LibStub("AceAddon-3.0"):GetAddon(addon.name)

-- spell id -> tick interval
SH.dotTickIntervals = {
    -- warlock
    [172]       = 3,    -- Corruption
    [348]       = 3,    -- Immolate
    [980]       = 2,    -- Curse of Agony

    -- rogue
    [703]       = 2,    -- Garrote
    [1943]      = 2,    -- Rupture
    [2823]      = 2,    -- Deadly Poison (spellID varies by rank)

    -- druid
    [1822]      = 2,    -- Rake
    [1079]      = 2,    -- Rip
    [48463]     = 3,    -- Moonfire
    [48468]     = 2,    -- Insect Swarm

    -- priest
    [589]       = 3,    -- Shadow Word: Pain
    [34914]     = 3,    -- Vampiric Touch
    [48160]     = 3,    -- Vampric Touch
    [19278]     = 3,    -- Devouring Plague

    -- mage
    [22959]     = 2,    -- Fireball (Ignite in Wrath is weird, snapshot) 

    -- hunter
    [1978]      = 3,    -- Serpent Sting
    [55749]     = 2,    -- Scorpid Poison (pet ability)

    -- dk
    [55095]     = 3,    -- Blood Plague
    [55078]     = 3,    -- Frost Fever

    -- warrior
    [12721]     = 1,    -- Deep Wounds
    [47465]     = 3,    -- Rend
    [772]       = 3,    -- Rend (spellID varies by rank)
}
