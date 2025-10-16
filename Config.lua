local _, addon = ...
local SH = _G.LibStub("AceAddon-3.0"):NewAddon("StealthHelper", "AceConsole-3.0", "AceEvent-3.0")
local AceConfigRegistry = LibStub("AceConfigRegistry-3.0")
addon.name = "StealthHelper"
SH.name = "StealthHelper"
local defaults = {
    profile = {
        parentFrame = {
            position = {
            point = "CENTER",
            relativeTo = UIParent,
            relativePoint = "CENTER",
            xOffset = 0,
            yOffset = 160,
            },
            dimensions = {
                width = 80,
                height = 48,
            },
            locked = false,
            hidden = false,
            hideTitlebar = false,
            hideBackground = false,
            dotCount = 2,
        },
    }
};

local MIN_WIDTH = 50
local MAX_WIDTH = 200
local MIN_HEIGHT = 48
local MAX_HEIGHT = 200
local SECONDARY_ICON_SIZE_MULTIPLIER = 0.5
local PRIMARY_ICON_SIZE_MULTIPLIER = 0.7


function SH:CreateTimerFrame()
    local frame = CreateFrame("Frame", "StealthHelperFrame", UIParent)
    frame:SetSize(self.db.profile.parentFrame.dimensions.width, self.db.profile.parentFrame.dimensions.height)
    frame:SetPoint(self.db.profile.parentFrame.position.point, self.db.profile.parentFrame.position.relativeTo, self.db.profile.parentFrame.position.relativePoint, self.db.profile.parentFrame.position.xOffset, self.db.profile.parentFrame.position.yOffset)
    frame:SetFrameStrata("MEDIUM")
    
    frame.bg = frame:CreateTexture(nil, "BACKGROUND")
    frame.bg:SetAllPoints(true)
    frame.bg:SetColorTexture(0, 0, 0, 0.5) -- dark transparent

    frame:SetMovable(true)
    frame:SetResizable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetClampedToScreen(true)
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", function(self)
        local point, relativeTo, relativePoint, xOffset, yOffset = self:GetPoint()
        self:StopMovingOrSizing()
        SH.db.profile.parentFrame.position = {
            point = point,
            relativeTo = relativeTo and relativeTo:GetName() or "UIParent",
            relativePoint = relativePoint,
            xOffset = xOffset,
            yOffset = yOffset,
        }
    end)

    frame:SetScript("OnSizeChanged", function(self, width, height)
        if self._isAdjustingSize then return end
        
        if width < MIN_WIDTH then
            self._isAdjustingSize = true
            self:SetWidth(MIN_WIDTH)
            self._isAdjustingSize = false
        elseif width > MAX_WIDTH then
            self._isAdjustingSize = true
            self:SetWidth(MAX_WIDTH)
            self._isAdjustingSize = false
        end
        
        if height < MIN_HEIGHT then
            self._isAdjustingSize = true
            self:SetHeight(MIN_HEIGHT)
            self._isAdjustingSize = false
        elseif height > MAX_HEIGHT then
            self._isAdjustingSize = true
            self:SetHeight(MAX_HEIGHT)
            self._isAdjustingSize = false
        end
    end)

    local titleBarHeight = 8
    frame.titleBar = CreateFrame("Frame", "StealthHelperTitleBar", frame)
    frame.titleBar:SetSize(self.db.profile.parentFrame.dimensions.width, titleBarHeight)
    frame.titleBar:SetPoint("TOP", frame, "TOP", 0, 0)
    frame.titleBar.text = frame.titleBar:CreateFontString(nil, "OVERLAY", "GameFontNormalTiny")
    frame.titleBar.text:SetPoint("CENTER", frame.titleBar, "CENTER", 0, 0)
    frame.titleBar.text:SetText("SH")
    frame.titleBar.text:SetTextColor(1, 1, 1, 1)
    frame.titleBar.text:SetJustifyH("CENTER")

    frame.titleBg = frame.titleBar:CreateTexture(nil, "BACKGROUND")
    frame.titleBg:SetAllPoints()
    
    frame.titleBg:SetColorTexture(0.2, 0.2, 0.2, 1)
    frame.titleBg:SetGradient("VERTICAL", 
        {r = 0.5, g = 0.1, b = 0.5, a = 1},  -- purple
        {r = 0.1, g = 0.1, b = 1, a = 1}  -- dark blue
    )

    -- Create DoT icon slots
    frame.dotIcons = {}
    frame.dotTimers = {}
    
    -- Create all icons with initial positioning - sizing will be handled dynamically
    for i = 1, 4 do
        frame.dotIcons[i] = frame:CreateTexture(nil, "ARTWORK")
        frame.dotIcons[i]:SetSize(32, 32) -- Initial size, will be updated
        frame.dotIcons[i]:SetPoint("CENTER", frame, "CENTER", 0, 0) -- Initial position, will be updated
        frame.dotIcons[i]:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark") -- placeholder
        
        frame.dotTimers[i] = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        frame.dotTimers[i]:SetPoint("BOTTOM", frame.dotIcons[i], "BOTTOM", 0, -8)
        frame.dotTimers[i]:SetText(string.format("%.1fs", 1.5 - (i * 0.2))) -- placeholder timer text
        frame.dotTimers[i]:SetTextColor(1, 1, 1, 1) -- white text
        
        -- Hide icons 3 and 4 initially
        if i > 2 then
            frame.dotIcons[i]:Hide()
            frame.dotTimers[i]:Hide()
        end
    end


    frame.resizeHandle = CreateFrame("Button", nil, frame)
    frame.resizeHandle:SetSize(16, 16)
    frame.resizeHandle:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
    frame.resizeHandle:SetFrameStrata("HIGH")
    
    frame.resizeHandle.bg = frame.resizeHandle:CreateTexture(nil, "BACKGROUND")
    frame.resizeHandle.bg:SetAllPoints()
    frame.resizeHandle.bg:SetColorTexture(0.2, 0.2, 0.2, 0)
    
    frame.resizeHandle.grip1 = frame.resizeHandle:CreateTexture(nil, "ARTWORK")
    frame.resizeHandle.grip1:SetSize(2, 2)
    frame.resizeHandle.grip1:SetPoint("BOTTOMRIGHT", frame.resizeHandle, "BOTTOMRIGHT", -1, 3)
    frame.resizeHandle.grip1:SetColorTexture(0.8, 0.8, 0.8, 0.6)
    
    frame.resizeHandle.grip2 = frame.resizeHandle:CreateTexture(nil, "ARTWORK")
    frame.resizeHandle.grip2:SetSize(2, 2)
    frame.resizeHandle.grip2:SetPoint("BOTTOMRIGHT", frame.resizeHandle, "BOTTOMRIGHT", -4, 6)
    frame.resizeHandle.grip2:SetColorTexture(0.8, 0.8, 0.8, 0.6)
    
    frame.resizeHandle.grip3 = frame.resizeHandle:CreateTexture(nil, "ARTWORK")
    frame.resizeHandle.grip3:SetSize(2, 2)
    frame.resizeHandle.grip3:SetPoint("BOTTOMRIGHT", frame.resizeHandle, "BOTTOMRIGHT", -7, 8)
    frame.resizeHandle.grip3:SetColorTexture(0.8, 0.8, 0.8, 0.6)

    frame.resizeHandle:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" then
            self:GetParent():StartSizing("BOTTOMRIGHT")
            self.isResizing = true
            self:SetScript("OnUpdate", function()
                if self.isResizing then
                    local frame = self:GetParent()
                    frame.titleBar:SetWidth(frame:GetWidth())
                    SH:UpdateIconLayoutOnly(frame)
                end
            end)
        end
    end)
    
    frame.resizeHandle:SetScript("OnMouseUp", function(self, button)
        if button == "LeftButton" and self.isResizing then
            self:GetParent():StopMovingOrSizing()
            self.isResizing = false
            -- Stop real-time updates
            self:SetScript("OnUpdate", nil)
            SH:UpdateFrameLayout(self:GetParent())
        end
    end)
    
    frame.resizeHandle:SetScript("OnLeave", function(self)
        if self.isResizing then
            self:GetParent():StopMovingOrSizing()
            self.isResizing = false
            self:SetScript("OnUpdate", nil)
            SH:UpdateFrameLayout(self:GetParent())
        end
        self.bg:SetColorTexture(0.2, 0.2, 0.2, 0.8)
        GameTooltip:Hide()
    end)
    
    frame.resizeHandle:SetScript("OnEnter", function(self)
        self.bg:SetColorTexture(0.4, 0.4, 0.4, 0)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText("Drag to resize", 1, 1, 1, 1)
        GameTooltip:Show()
    end)
    
    frame.resizeHandle:SetScript("OnLeave", function(self)
        self.bg:SetColorTexture(0.2, 0.2, 0.2, 0)
        GameTooltip:Hide()
    end)
    
    SH:UpdateFrameLockState(frame)
    SH:UpdateFrameVisibility(frame)
    SH:UpdateTitlebarVisibility(frame)
    SH:UpdateBackgroundVisibility(frame)
    SH:UpdateDotCount(frame)
    SH:UpdateIconLayout(frame)
    
    -- Ensure titlebar width matches frame width on creation
    frame.titleBar:SetWidth(frame:GetWidth())
    
    return frame
end

function SH:ShowPrimaryIcon(spellTexture, timeUntilTick)
    if not self.timerFrame or not self.timerFrame.dotIcons then return end
    self.timerFrame.dotIcons[1]:SetTexture(spellTexture or "Interface\\Icons\\INV_Misc_QuestionMark")
    self.timerFrame.dotTimers[1]:SetText(string.format("%.1fs", timeUntilTick or 0))
    self.timerFrame.dotIcons[1]:Show()
    self.timerFrame.dotTimers[1]:Show()
end

function SH:ShowSecondaryIcon(spellTexture, timeUntilTick)
    if not self.timerFrame or not self.timerFrame.dotIcons then return end
    self.timerFrame.dotIcons[2]:SetTexture(spellTexture or "Interface\\Icons\\INV_Misc_QuestionMark")
    self.timerFrame.dotTimers[2]:SetText(string.format("%.1fs", timeUntilTick or 0))
    self.timerFrame.dotIcons[2]:Show()
    self.timerFrame.dotTimers[2]:Show()
end

function SH:HideIcon(index)
    if not self.timerFrame or not self.timerFrame.dotTimers or not self.timerFrame.dotIcons then return end
    self.timerFrame.dotTimers[index]:Hide()
    self.timerFrame.dotIcons[index]:Hide()
end

function SH:HideIcons()
    if not self.timerFrame then return end

    for i = 1, 4 do
        self:HideIcon(i)
    end
    if self.db.profile.parentFrame.hidden then
    self.timerFrame:Hide()
    end
end

function SH:UpdateTimer()
    local now = GetTime()
    local upcoming = {}

    for destGUID, dots in pairs(self.activeDots) do
        for spellId, dot in pairs(dots) do
            local elapsed = now - dot.appliedAt
            local ticksElapsed = math.floor(elapsed / dot.tickInterval)
            local nextTick = dot.appliedAt + (ticksElapsed + 1) * dot.tickInterval
            table.insert(upcoming, { 
                spellId = spellId, 
                nextTick = nextTick,
                spellIcon = dot.spellIcon,
                spellName = dot.spellName
            })
        end
    end

    if #upcoming == 0 then
        -- Show placeholder timer text when no DoTs are active
        local dotCount = self.db.profile.parentFrame.dotCount
        local maxDisplay = (dotCount == 0) and 4 or dotCount
        
        for i = 1, maxDisplay do
            if self.timerFrame.dotTimers and self.timerFrame.dotTimers[i] then
                self.timerFrame.dotTimers[i]:Show()
            end
        end
        
        -- Hide unused timer slots
        for i = maxDisplay + 1, 4 do
            if self.timerFrame.dotTimers and self.timerFrame.dotTimers[i] then
                self.timerFrame.dotTimers[i]:Hide()
            end
        end
        return
    end

    table.sort(upcoming, function(a, b) return a.nextTick < b.nextTick end)

    local primary = upcoming[1]
    local primaryTime = primary.nextTick - now
    if primaryTime <= 0 then
        -- Show placeholder timer text when DoTs have expired
        local dotCount = self.db.profile.parentFrame.dotCount
        local maxDisplay = (dotCount == 0) and 4 or dotCount
        
        for i = 1, maxDisplay do
            if self.timerFrame.dotTimers and self.timerFrame.dotTimers[i] then
                self.timerFrame.dotTimers[i]:Show()
            end
        end
        
        -- Hide unused timer slots
        for i = maxDisplay + 1, 4 do
            if self.timerFrame.dotTimers and self.timerFrame.dotTimers[i] then
                self.timerFrame.dotTimers[i]:Hide()
            end
        end
        return
    end

    local timerFrame = _G["StealthHelper_TimerFrame"]
    if timerFrame then
        timerFrame:Show()
    end

    -- Get the number of DoTs to display
    local dotCount = self.db.profile.parentFrame.dotCount
    local maxDisplay = (dotCount == 0) and 4 or dotCount

    -- Display DoTs up to the configured count
    for i = 1, maxDisplay do
        if upcoming[i] then
            local dot = upcoming[i]
            local timeUntilTick = dot.nextTick - now
            
            -- Update icon and timer
            if self.timerFrame.dotIcons and self.timerFrame.dotIcons[i] then
                self.timerFrame.dotIcons[i]:SetTexture(dot.spellIcon or "Interface\\Icons\\INV_Misc_QuestionMark")
                self.timerFrame.dotIcons[i]:Show()
            end
            if self.timerFrame.dotTimers and self.timerFrame.dotTimers[i] then
                self.timerFrame.dotTimers[i]:SetText(string.format("%.1fs", timeUntilTick))
                self.timerFrame.dotTimers[i]:Show()
            end
        else
            -- Hide unused slots
            if self.timerFrame.dotIcons and self.timerFrame.dotIcons[i] then
                self.timerFrame.dotIcons[i]:Hide()
            end
            if self.timerFrame.dotTimers and self.timerFrame.dotTimers[i] then
                self.timerFrame.dotTimers[i]:Hide()
            end
        end
    end

    -- Hide any remaining slots beyond maxDisplay
    for i = maxDisplay + 1, 4 do
        if self.timerFrame.dotIcons and self.timerFrame.dotIcons[i] then
            self.timerFrame.dotIcons[i]:Hide()
        end
        if self.timerFrame.dotTimers and self.timerFrame.dotTimers[i] then
            self.timerFrame.dotTimers[i]:Hide()
        end
    end
end

function SH:OnInitialize()
	self.db = LibStub("AceDB-3.0"):New(self.name.."DB", defaults, true)
    self.timerFrame = self:CreateTimerFrame()

    self:RegisterOptions()
    self:RegisterStaticPopups()

    SLASH_STEALTHHELPER1 = "/sh";
    SLASH_STEALTHHELPER2 = "/stealthhelper";
    SLASH_STEALTHHELPER3 = "/stealth";

    SlashCmdList["STEALTHHELPER"] = function(msg)
        self:ToggleOptions()
    end

end

function SH:ToggleOptions()
    if Settings and Settings.OpenToCategory then
        Settings.OpenToCategory(addon.name)
    else
        InterfaceOptionsFrame_OpenToCategory(addon.name)
        InterfaceOptionsFrame_OpenToCategory(addon.name)
    end
end

function SH:UpdateIconLayout(frame)
    if not frame or not frame.dotIcons then return end
    
    local containerWidth = frame:GetWidth()
    local containerHeight = frame:GetHeight()
    local dotCount = self.db.profile.parentFrame.dotCount
    local maxDisplay = (dotCount == 0) and 4 or dotCount
    
    -- Calculate icon sizes - primary is always largest, others are 1/3 size
    local titleBarHeight = 8
    local availableHeight = containerHeight - titleBarHeight
    local primarySize = math.min(containerWidth, availableHeight) * 0.7 -- Primary takes 70% of available space
    local secondarySize = primarySize * SECONDARY_ICON_SIZE_MULTIPLIER -- Secondary icons are smaller than primary
    
    -- Position and size icons
    if maxDisplay == 1 then
        -- Single icon centered
        frame.dotIcons[1]:SetSize(primarySize, primarySize)
        frame.dotIcons[1]:SetPoint("CENTER", frame, "CENTER", 0, 0)
    else
        -- Primary icon (next tick) + secondary icons (other DoTs)
        local spacing = 5
        local totalWidth = primarySize + spacing + (secondarySize + spacing) * (maxDisplay - 1)
        local startX = -totalWidth / 2
        
        -- Primary icon (next tick) - always first and largest
        frame.dotIcons[1]:SetSize(primarySize, primarySize)
        frame.dotIcons[1]:SetPoint("CENTER", frame, "CENTER", startX + primarySize/2, 0)
        
        -- Secondary icons (other DoTs) - evenly spaced and smaller
        for i = 2, maxDisplay do
            local xOffset = startX + primarySize + spacing + (secondarySize + spacing) * (i - 2) + secondarySize/2
            frame.dotIcons[i]:SetSize(secondarySize, secondarySize)
            frame.dotIcons[i]:SetPoint("CENTER", frame, "CENTER", xOffset, 0)
        end
    end
end

function SH:UpdateIconLayoutOnly(frame)
    if not frame or not frame.dotIcons then return end
    
    local containerWidth = frame:GetWidth()
    local containerHeight = frame:GetHeight()
    local dotCount = self.db.profile.parentFrame.dotCount
    local maxDisplay = (dotCount == 0) and 4 or dotCount
    
    -- Calculate icon sizes - primary is always largest, others are 1/3 size
    local titleBarHeight = 8
    local availableHeight = containerHeight - titleBarHeight
    local primarySize = math.min(containerWidth, availableHeight) * PRIMARY_ICON_SIZE_MULTIPLIER -- Primary takes 70% of available space
    local secondarySize = primarySize * SECONDARY_ICON_SIZE_MULTIPLIER -- Secondary icons are smaller than primary
    
    -- Position and size icons
    if maxDisplay == 1 then
        -- Single icon centered
        frame.dotIcons[1]:SetSize(primarySize, primarySize)
        frame.dotIcons[1]:SetPoint("CENTER", frame, "CENTER", 0, 0)
    else
        -- Primary icon (next tick) + secondary icons (other DoTs)
        local spacing = 5
        local totalWidth = primarySize + spacing + (secondarySize + spacing) * (maxDisplay - 1)
        local startX = -totalWidth / 2
        
        -- Primary icon (next tick) - always first and largest
        frame.dotIcons[1]:SetSize(primarySize, primarySize)
        frame.dotIcons[1]:SetPoint("CENTER", frame, "CENTER", startX + primarySize/2, 0)
        
        -- Secondary icons (other DoTs) - evenly spaced and smaller
        for i = 2, maxDisplay do
            local xOffset = startX + primarySize + spacing + (secondarySize + spacing) * (i - 2) + secondarySize/2
            frame.dotIcons[i]:SetSize(secondarySize, secondarySize)
            frame.dotIcons[i]:SetPoint("CENTER", frame, "CENTER", xOffset, 0)
        end
    end
end

function SH:UpdateFrameLayout(frame)
    if not frame then return end
    
    local newWidth = frame:GetWidth()
    local newHeight = frame:GetHeight()
    
    frame.titleBar:SetWidth(newWidth)
    
    self.db.profile.parentFrame.dimensions.width = newWidth
    self.db.profile.parentFrame.dimensions.height = newHeight
    
    -- Update icon layout when frame is resized
    self:UpdateIconLayout(frame)
    
    AceConfigRegistry:NotifyChange(self.name)
end

function SH:UpdateFrameLockState(frame)
    if not frame then return end
    
    if self.db.profile.parentFrame.locked then
        frame:SetMovable(false)
        frame:EnableMouse(false)
        frame:RegisterForDrag()
        frame.resizeHandle:Hide()
    else
        frame:SetMovable(true)
        frame:EnableMouse(true)
        frame:RegisterForDrag("LeftButton")
        frame.resizeHandle:Show()
    end
end

function SH:UpdateFrameVisibility(frame)
    if not frame then return end
    
    if self.db.profile.parentFrame.hidden then
        frame:Hide()
    else
        frame:Show()
    end
end

function SH:UpdateTitlebarVisibility(frame)
    if not frame or not frame.titleBar then return end
    
    if self.db.profile.parentFrame.hideTitlebar then
        frame.titleBar:Hide()
    else
        frame.titleBar:Show()
    end
end

function SH:UpdateBackgroundVisibility(frame)
    if not frame or not frame.bg then return end
    
    if self.db.profile.parentFrame.hideBackground then
        frame.bg:Hide()
    else
        frame.bg:Show()
    end
end

function SH:UpdateDotCount(frame)
    if not frame or not frame.dotIcons then return end
    
    local dotCount = self.db.profile.parentFrame.dotCount
    
    -- Hide all icons first
    for i = 1, 4 do
        if frame.dotIcons[i] then
            frame.dotIcons[i]:Hide()
        end
        if frame.dotTimers[i] then
            frame.dotTimers[i]:Hide()
        end
    end
    
    -- Show icons and timers based on count
    if dotCount == 0 then
        -- Show all icons and timers
        for i = 1, 4 do
            if frame.dotIcons[i] then
                frame.dotIcons[i]:Show()
            end
            if frame.dotTimers[i] then
                frame.dotTimers[i]:Show()
            end
        end
    else
        -- Show only the specified number
        for i = 1, dotCount do
            if frame.dotIcons[i] then
                frame.dotIcons[i]:Show()
            end
            if frame.dotTimers[i] then
                frame.dotTimers[i]:Show()
            end
        end
    end
    
    -- Update layout after changing DoT count
    self:UpdateIconLayout(frame)
end

function SH:RegisterOptions()
    local options = {
        name = "StealthHelper",
        type = "group",
        args = {
            frame = {
                name = "Frame Settings",
                type = "group",
                order = 1,
                args = {
                    lock = {
                        name = "Lock Frame",
                        type = "toggle",
                        order = 1,
                        get = function() return self.db.profile.parentFrame.locked end,
                        set = function(info, value)
                            self.db.profile.parentFrame.locked = value
                            self:UpdateFrameLockState(self.timerFrame)
                        end,
                    },
                    hide = {
                        name = "Hide Frame",
                        type = "toggle",
                        order = 2,
                        get = function() return self.db.profile.parentFrame.hidden end,
                        set = function(info, value)
                            self.db.profile.parentFrame.hidden = value
                            self:UpdateFrameVisibility(self.timerFrame)
                        end,
                    },
                    hideTitlebar = {
                        name = "Hide Titlebar",
                        type = "toggle",
                        order = 3,
                        get = function() return self.db.profile.parentFrame.hideTitlebar end,
                        set = function(info, value)
                            self.db.profile.parentFrame.hideTitlebar = value
                            self:UpdateTitlebarVisibility(self.timerFrame)
                        end,
                    },
                    hideBackground = {
                        name = "Hide Background",
                        type = "toggle",
                        order = 4,
                        get = function() return self.db.profile.parentFrame.hideBackground end,
                        set = function(info, value)
                            self.db.profile.parentFrame.hideBackground = value
                            self:UpdateBackgroundVisibility(self.timerFrame)
                        end,
                    },
                    dotCount = {
                        name = "DoT Count",
                        type = "select",
                        order = 5,
                        values = {
                            [1] = "1 DoT",
                            [2] = "2 DoTs",
                            [3] = "3 DoTs",
                        },
                        get = function() return self.db.profile.parentFrame.dotCount end,
                        set = function(info, value)
                            self.db.profile.parentFrame.dotCount = value
                            self:UpdateDotCount(self.timerFrame)
                        end,
                    },
                    position = {
                        name = "Position",
                        type = "group",
                        inline = true,
                        order = 6,
                        args = {
                            x = {
                                name = "X Offset",
                                type = "range",
                                order = 1,
                                min = -2000,
                                max = 2000,
                                step = 1,
                                get = function() return self.db.profile.parentFrame.position.xOffset end,
                                set = function(info, value)
                                    if self.db.profile.parentFrame.position.xOffset ~= value then
                                        self.db.profile.parentFrame.position.xOffset = value
                                        if self.timerFrame then
                                            self.timerFrame:ClearAllPoints()
                                            self.timerFrame:SetPoint(
                                                self.db.profile.parentFrame.position.point,
                                                self.db.profile.parentFrame.position.relativeTo,
                                                self.db.profile.parentFrame.position.relativePoint,
                                                self.db.profile.parentFrame.position.xOffset,
                                                self.db.profile.parentFrame.position.yOffset
                                            )
                                        end
                                    end
                                end,
                            },
                            y = {
                                name = "Y Offset",
                                type = "range",
                                order = 2,
                                min = -2000,
                                max = 2000,
                                step = 1,
                                get = function() return self.db.profile.parentFrame.position.yOffset end,
                                set = function(info, value)
                                    if self.db.profile.parentFrame.position.yOffset ~= value then
                                        self.db.profile.parentFrame.position.yOffset = value
                                        if self.timerFrame then
                                            self.timerFrame:ClearAllPoints()
                                            self.timerFrame:SetPoint(
                                                self.db.profile.parentFrame.position.point,
                                                self.db.profile.parentFrame.position.relativeTo,
                                                self.db.profile.parentFrame.position.relativePoint,
                                                self.db.profile.parentFrame.position.xOffset,
                                                self.db.profile.parentFrame.position.yOffset
                                            )
                                        end
                                    end
                                end,
                            },
                        },
                    },
                    dimensions = {
                        name = "Dimensions",
                        type = "group",
                        inline = true,
                        order = 7,
                        args = {
                            width = {
                                name = "Width",
                                type = "range",
                                order = 1,
                                min = MIN_WIDTH,
                                max = MAX_WIDTH,
                                step = 1,
                                get = function() return self.db.profile.parentFrame.dimensions.width end,
                                set = function(info, value)
                                    if self.db.profile.parentFrame.dimensions.width ~= value then
                                        self.db.profile.parentFrame.dimensions.width = value
                                        if self.timerFrame then
                                            self.timerFrame:SetWidth(value)
                                            self.timerFrame.titleBar:SetWidth(value)
                                            self.timerFrame.secondaryIcon:SetPoint("RIGHT", self.timerFrame.titleBar, "RIGHT", -6, -5)
                                        end
                                    end
                                end,
                            },
                            height = {
                                name = "Height",
                                type = "range",
                                order = 2,
                                min = MIN_HEIGHT,
                                max = MAX_HEIGHT,
                                step = 1,
                                get = function() return self.db.profile.parentFrame.dimensions.height end,
                                set = function(info, value)
                                    if self.db.profile.parentFrame.dimensions.height ~= value then
                                        self.db.profile.parentFrame.dimensions.height = value
                                        if self.timerFrame then
                                            self.timerFrame:SetHeight(value)
                                        end
                                    end
                                end,
                            },
                        },
                    },
                    reset = {
                        name = "Reset to Default",
                        type = "execute",
                        order = 8,
                        func = function()
                            StaticPopup_Show("STEALTHHELPER_RESET_CONFIRM")
                        end,
                    },
                },
            },
        },
    }
    
    LibStub("AceConfig-3.0"):RegisterOptionsTable(self.name, options)
    LibStub("AceConfigDialog-3.0"):AddToBlizOptions(self.name, "StealthHelper")
end

function SH:RegisterStaticPopups()
    StaticPopupDialogs["STEALTHHELPER_RESET_CONFIRM"] = {
        text = "Are you sure you want to reset StealthHelper frame to default settings?",
        button1 = "Yes",
        button2 = "No",
        OnAccept = function()
            self.db.profile.parentFrame.position = {
                point = "CENTER",
                relativeTo = UIParent,
                relativePoint = "CENTER",
                xOffset = 0,
                yOffset = 160,
            }
            self.db.profile.parentFrame.dimensions = {
                width = 80,
                height = 48,
            }
            self.db.profile.parentFrame.locked = false
            self.db.profile.parentFrame.hidden = false
            self.db.profile.parentFrame.hideTitlebar = false
            self.db.profile.parentFrame.hideBackground = false
            self.db.profile.parentFrame.dotCount = 2
            if self.timerFrame then
                self.timerFrame:ClearAllPoints()
                self.timerFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 160)
                self.timerFrame:SetSize(80, 48)
                self:UpdateFrameLayout(self.timerFrame)
                self:UpdateFrameLockState(self.timerFrame)
                self:UpdateFrameVisibility(self.timerFrame)
                self:UpdateTitlebarVisibility(self.timerFrame)
                self:UpdateDotCount(self.timerFrame)
            end
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
    }
end

