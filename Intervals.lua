
local _, addon = ...;
local ArenaMarker = LibStub("AceAddon-3.0"):GetAddon(addon.name);


-- SpellID  ->  Dot Tick Interval
local dotTickIntervals = {
    [172]   = 3,  -- Corruption
    [980]   = 2,  -- Curse of Agony (ramps, but base tick = 2s)
    [703]   = 2,  -- Garrote
    [1943]  = 2,  -- Rupture
    [1822]  = 2,  -- Rake
    [1079]  = 2,  -- Rip
    [589]   = 3,  -- Shadow Word: Pain
    [34914] = 3,  -- Vampiric Touch
    [8921]  = 3,  -- Moonfire
    [348]   = 3,  -- Immolate
    [1978]  = 3,  -- Serpent Sting
    [12654] = 2,  -- Ignite (from Fire crits)
    [133]   = 2,  -- Fireball (built-in DoT component)
    [2818]  = 3,  -- Deadly Poison (base ID, applies multiple ranks)
    [24640] = 4,  -- Scorpid Poison (hunter pet ability)
}