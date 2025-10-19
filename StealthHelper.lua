local _, addon = ...
local SH = _G.LibStub("AceAddon-3.0"):GetAddon(addon.name)

SH.activeDots = {}

function SH:COMBAT_LOG_EVENT_UNFILTERED()
    local _, event, _, sourceGUID, sourceName, _, _, destGUID, destName, _, _, spellId, spellName, _, auraType = CombatLogGetCurrentEventInfo()
    
    if (event == "SPELL_AURA_APPLIED" or event == "SPELL_AURA_REFRESH") and auraType == "DEBUFF" then
        self:EnsureTicker()
        local tickInterval = self.dotTickIntervals[spellId]
        local duration, icon
        for i = 1, 40 do
            local debuffName, debuffRank, debuffIcon, debuffCount, debuffType, debuffDuration, debuffExpirationTime, debuffSource, debuffIsStealable, debuffShouldConsolidate, debuffSpellId = UnitDebuff(destName, i)
            if not debuffName then break end
            if debuffSpellId == spellId then
                duration = debuffDuration
                icon = debuffIcon
                break
            end
        end
        
        if duration and tickInterval then
            self.activeDots[destGUID] = self.activeDots[destGUID] or {}
            self.activeDots[destGUID][spellId] = {
                caster = sourceGUID,
                spellName = spellName,
                spellId = spellId,
                spellIcon = icon or C_Spell.GetSpellTexture(spellId),
                tickInterval = tickInterval,
                duration = duration,
                appliedAt = GetTime(),
            }

            print(string.format("[DoT Applied] %s on %s: %ds duration, ticks every %ds",
                spellName, destName or "?", duration, tickInterval))
        end
    elseif event == "SPELL_AURA_REMOVED" and self.activeDots[destGUID] then
        if self.activeDots[destGUID][spellId] then
            self.activeDots[destGUID][spellId] = nil
        end
        if next(self.activeDots[destGUID]) == nil then
            self.activeDots[destGUID] = nil
        end
        self:StopTickerIfEmpty()
    end
end

function SH:EnsureTicker()
    if not self.timerTicker then
        self.timerTicker = C_Timer.NewTicker(0.1, function() self:UpdateTimer() end)
    end
end

function SH:StopTickerIfEmpty()
    if not self.timerTicker then return end

    for _, dots in pairs(self.activeDots) do
        if next(dots) then
            -- still active DoTs, don’t stop
            return
        end
    end

    -- no DoTs found, stop ticker
    self.timerTicker:Cancel()
    self.timerTicker = nil
end

function SH:OnEnable()
    self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
end

function SH:OnDisable()
    self:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
end
