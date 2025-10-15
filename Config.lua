local _, addon = ...
local SH = _G.LibStub("AceAddon-3.0"):NewAddon("StealthHelper", "AceConsole-3.0", "AceEvent-3.0")
addon.name = "StealthHelper"
SH.name = "StealthHelper"
local defaults = {
    profile = {
        parentFramePosition = {
            point = "CENTER",
            relativeTo = UIParent,
            relativePoint = "CENTER",
            xOffset = 0,
            yOffset = 160,
        }
    }
};

function SH:CreateTimerFrame()
    local frame = CreateFrame("Frame", "StealthHelperFrame", UIParent)
    frame:SetSize(80, 48)
    frame:SetPoint(self.db.profile.parentFramePosition.point, self.db.profile.parentFramePosition.relativeTo, self.db.profile.parentFramePosition.relativePoint, self.db.profile.parentFramePosition.xOffset, self.db.profile.parentFramePosition.yOffset)
    frame:SetFrameStrata("MEDIUM")
    
    -- Background
    frame.bg = frame:CreateTexture(nil, "BACKGROUND")
    frame.bg:SetAllPoints(true)
    frame.bg:SetColorTexture(0, 0, 0, 0.5) -- dark transparent

    -- Movable and draggable
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetClampedToScreen(true)
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", function(self)
        local point, relativeTo, relativePoint, xOffset, yOffset = self:GetPoint()
        self:StopMovingOrSizing()
        SH.db.profile.parentFramePosition = {
            point = point,
            relativeTo = relativeTo and relativeTo:GetName() or "UIParent",
            relativePoint = relativePoint,
            xOffset = xOffset,
            yOffset = yOffset,
        }
    end)

    local titleBarHeight = 10
    frame.titleBar = CreateFrame("Frame", "StealthHelperTitleBar", frame)
    frame.titleBar:SetSize(80, titleBarHeight)
    frame.titleBar:SetPoint("TOP", frame, "TOP", 0, 0)
    frame.titleBar.text = frame.titleBar:CreateFontString(nil, "OVERLAY", "GameFontNormalTiny")
    frame.titleBar.text:SetPoint("CENTER", frame.titleBar, "CENTER", 0, 0)
    frame.titleBar.text:SetText("SH")
    frame.titleBar.text:SetTextColor(1, 1, 1, 1) -- white color
    frame.titleBar.text:SetJustifyH("CENTER")

    frame.titleBg = frame.titleBar:CreateTexture(nil, "BACKGROUND")
    frame.titleBg:SetAllPoints()
    
    frame.titleBg:SetColorTexture(0.2, 0.2, 0.2, 1)
    frame.titleBg:SetGradient("VERTICAL", 
        {r = 0.5, g = 0.1, b = 0.5, a = 1},  -- purple
        {r = 0.1, g = 0.1, b = 1, a = 1}  -- dark blue
    )

    -- Primary icon
    frame.primaryIcon = frame:CreateTexture(nil, "ARTWORK")
    frame.primaryIcon:SetSize(36, 36)
    frame.primaryIcon:SetPoint("LEFT", frame.titleBar, "LEFT", 6, -4) -- shifted down to make room for title

    frame.primaryTimer = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    frame.primaryTimer:SetPoint("BOTTOM", frame.primaryIcon, "BOTTOM", -6, -5)

    -- Secondary icon
    frame.secondaryIcon = frame:CreateTexture(nil, "ARTWORK")
    frame.secondaryIcon:SetSize(28, 28)
    frame.secondaryIcon:SetPoint("RIGHT", frame.titleBar, "RIGHT", -6, -5)

    frame.secondaryTimer = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    frame.secondaryTimer:SetPoint("BOTTOM", frame.secondaryIcon, "BOTTOM", 0, -8)

    return frame
end


function SH:ShowPrimaryIcon(spellTexture, timeUntilTick)
    if not self.timerFrame then return end
    self.timerFrame.primaryIcon:SetTexture(spellTexture or "Interface\\Icons\\INV_Misc_QuestionMark")
    self.timerFrame.primaryTimer:SetText(string.format("%.1fs", timeUntilTick or 0))
    self.timerFrame.primaryIcon:Show()
    self.timerFrame.primaryTimer:Show()
end

function SH:ShowSecondaryIcon(spellTexture, timeUntilTick)
    if not self.timerFrame then return end
    self.timerFrame.secondaryIcon:SetTexture(spellTexture or "Interface\\Icons\\INV_Misc_QuestionMark")
    self.timerFrame.secondaryTimer:SetText(string.format("%.1fs", timeUntilTick or 0))
    self.timerFrame.secondaryIcon:Show()
    self.timerFrame.secondaryTimer:Show()
end

function SH:HideIcons()
    if not self.timerFrame then return end
    self.timerFrame.primaryIcon:Hide()
    self.timerFrame.primaryTimer:Hide()
    self.timerFrame.secondaryIcon:Hide()
    self.timerFrame.secondaryTimer:Hide()
    self.timerFrame:Hide()
end

function SH:UpdateTimer()
    local now = GetTime()
    local upcoming = {}

    for destGUID, dots in pairs(self.activeDots) do
        for spellId, dot in pairs(dots) do
            local elapsed = now - dot.appliedAt
            local ticksElapsed = math.floor(elapsed / dot.tickInterval)
            local nextTick = dot.appliedAt + (ticksElapsed + 1) * dot.tickInterval
            table.insert(upcoming, { spellId = spellId, nextTick = nextTick })
        end
    end

    if #upcoming == 0 then
        self:HideAllIcons()
        return
    end

    table.sort(upcoming, function(a, b) return a.nextTick < b.nextTick end)

    local primary = upcoming[1]
    local primaryTime = primary.nextTick - now
    if primaryTime <= 0 then
        self:HideAllIcons()
        return
    end

    local timerFrame = _G["StealthHelper_TimerFrame"]

    if timerFrame then
        timerFrame:Show()
    end

    self:ShowPrimaryIcon(primary.spellId, primaryTime)

    if #upcoming > 1 then
        local secondary = upcoming[2]
        local secondaryTime = secondary.nextTick - now
        self:ShowSecondaryIcon(secondary.spellId, secondaryTime)
    else
        self:HideSecondaryIcon()
    end
end

function SH:OnInitialize()
	self.db = LibStub("AceDB-3.0"):New(self.name.."DB", defaults, true);
    self.timerFrame = self:CreateTimerFrame()

    SLASH_STEALTHHELPER1 = "/sh";
    SLASH_STEALTHHELPER2 = "/stealthhelper";
    SLASH_STEALTHHELPER3 = "/stealth";

    SlashCmdList["STEALTHHELPER"] = function(msg)
        print('ello')
    end
end

