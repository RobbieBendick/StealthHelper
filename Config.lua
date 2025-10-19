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
            testMode = false,
            dynamicSizing = false,
            timerText = {
                fontSize = 10,
                anchor = "BOTTOM",
                xOffset = 2,
                yOffset = -8,
                hidden = false,
                hideSecondary = false,
                avoidOverlap = true,
            },
        },
    }
};

local MIN_CONTAINER_WIDTH = 50
local MAX_CONTAINER_WIDTH = 200
local MIN_CONTAINER_HEIGHT = 48
local MAX_CONTAINER_HEIGHT = 200
local SECONDARY_ICON_SIZE_MULTIPLIER = 0.5
local PRIMARY_ICON_SIZE_MULTIPLIER = 0.7
local MAX_DOT_COUNT = 3
local TITLE_BAR_HEIGHT = 8

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
        
        if self.resizeHandle and self.resizeHandle.isResizing then
            if width < MIN_CONTAINER_WIDTH then
                self._isAdjustingSize = true
                self:SetWidth(MIN_CONTAINER_WIDTH)
                self._isAdjustingSize = false
            elseif width > MAX_CONTAINER_WIDTH then
                self._isAdjustingSize = true
                self:SetWidth(MAX_CONTAINER_WIDTH)
                self._isAdjustingSize = false
            end
            
            if height < MIN_CONTAINER_HEIGHT then
                self._isAdjustingSize = true
                self:SetHeight(MIN_CONTAINER_HEIGHT)
                self._isAdjustingSize = false
            elseif height > MAX_CONTAINER_HEIGHT then
                self._isAdjustingSize = true
                self:SetHeight(MAX_CONTAINER_HEIGHT)
                self._isAdjustingSize = false
            end
        end
    end)
    frame.titleBar = CreateFrame("Frame", "StealthHelperTitleBar", frame)
    frame.titleBar:SetSize(self.db.profile.parentFrame.dimensions.width, TITLE_BAR_HEIGHT)
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

    frame.dotIcons = {}
    frame.dotTimers = {}
    
    for i = 1, MAX_DOT_COUNT do
        frame.dotIcons[i] = frame:CreateTexture(nil, "ARTWORK")
        frame.dotIcons[i]:SetSize(32, 32) -- initial size, will be updated
        frame.dotIcons[i]:SetPoint("CENTER", frame, "CENTER", 0, 0) -- initial position, will be updated
        
        frame.dotTimers[i] = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        frame.dotTimers[i]:SetTextColor(1, 1, 1, 1) -- white text
        
        -- hide all icons and timers initially
        frame.dotIcons[i]:Hide()
        frame.dotTimers[i]:Hide()
    end

    frame.resizeHandle = CreateFrame("Button", nil, frame)
    frame.resizeHandle:SetSize(16, 16)
    frame.resizeHandle:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
    frame.resizeHandle:SetFrameStrata("MEDIUM")
    
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
        if button == "LeftButton" and not SH.db.profile.parentFrame.locked then
            self.isResizing = true
            self:GetParent():StartSizing("BOTTOMRIGHT")
            self:SetScript("OnUpdate", function()
                if self.isResizing then
                    local frame = self:GetParent()
                    frame.titleBar:SetWidth(frame:GetWidth())
                    SH:UpdateIconLayout(frame)
                end
            end)
        end
    end)
    
    frame.resizeHandle:SetScript("OnMouseUp", function(self, button)
        if button == "LeftButton" and self.isResizing then
            self:GetParent():StopMovingOrSizing()
            self.isResizing = false
            self:SetScript("OnUpdate", nil)
            SH:UpdateFrameLayout(self:GetParent())
            SH:UpdateTimerTextVisibility(self:GetParent())
        end
    end)
    
    frame.resizeHandle:SetScript("OnLeave", function(self)
        if self.isResizing then
            self:GetParent():StopMovingOrSizing()
            self.isResizing = false
            self:SetScript("OnUpdate", nil)
            SH:UpdateFrameLayout(self:GetParent())
            SH:UpdateTimerTextVisibility(self:GetParent())
        end
        self.bg:SetColorTexture(0.2, 0.2, 0.2, 0)
    end)
    
    frame.resizeHandle:SetScript("OnEnter", function(self)
        if not SH.db.profile.parentFrame.locked then
            self.bg:SetColorTexture(0.4, 0.4, 0.4, 0.5)
        end
    end)
    
    self:UpdateFrameLockState(frame)
    self:UpdateFrameVisibility(frame)
    self:UpdateTitlebarVisibility(frame)
    self:UpdateBackgroundVisibility(frame)
    self:UpdateDotCount(frame)
    self:UpdateIconLayout(frame)
    
    frame.titleBar:SetWidth(frame:GetWidth())
    
    return frame
end

function SH:RegisterOptions()
    local version = GetAddOnMetadata(self.name, "Version") or "Unknown"
    local author = GetAddOnMetadata(self.name, "Author") or "Mageiden"

    local options = {
        name = "StealthHelper",
        type = "group",
        args = {
            info = {
                order = 1,
                type = "description",
                name = "|cffffd700Version|r " .. version .. "\n|cffffd700Author|r " .. author,
            },
            frame = {
                name = "Frame Settings",
                type = "group",
                order = 2,
                args = {
                    testMode = {
                        name = function() return self.db.profile.parentFrame.testMode and "Disable Test Mode" or "Enable Test Mode" end,
                        desc = "Toggle test mode to preview DoT timers with sample data",
                        type = "execute",
                        order = 1,
                        func = function()
                            self:ToggleTestMode()
                        end,
                        width = "full",
                    },
                    lock = {
                        name = "Lock Frame",
                        desc = "Locks the frame and hides the titlebar and background.",
                        type = "toggle",
                        order = 2,
                        get = function() return self.db.profile.parentFrame.locked end,
                        set = function(info, value)
                            self.db.profile.parentFrame.locked = value
                            self.db.profile.parentFrame.hideTitlebar = value
                            self.db.profile.parentFrame.hideBackground = value
                            self:UpdateFrameLockState(self.timerFrame)
                            self:UpdateTitlebarVisibility(self.timerFrame)
                            self:UpdateBackgroundVisibility(self.timerFrame)
                        end,
                    },
                    hide = {
                        name = "Hide Frame",
                        type = "toggle",
                        order = 3,
                        get = function() return self.db.profile.parentFrame.hidden end,
                        set = function(info, value)
                            self.db.profile.parentFrame.hidden = value
                            self:UpdateFrameVisibility(self.timerFrame)
                        end,
                    },
                    dotCount = {
                        name = "DoT Count",
                        type = "select",
                        order = 4,
                        values = {
                            [1] = "1 DoT",
                            [2] = "2 DoTs",
                            [3] = "3 DoTs",
                        },
                        get = function() return self.db.profile.parentFrame.dotCount end,
                        set = function(info, value)
                            self.db.profile.parentFrame.dotCount = value
                            self:UpdateDotCount(self.timerFrame)
                            self:UpdateIconLayout(self.timerFrame)
                        end,
                    },
                    dynamicSizing = {
                        name = "Dynamic Sizing",
                        desc = "Automatically adjust icon layout based on the number of active DoTs. When disabled, the icon layout will always be the same as the configured DoT count.",
                        type = "toggle",
                        order = 5,
                        get = function() return self.db.profile.parentFrame.dynamicSizing end,
                        set = function(info, value)
                            self.db.profile.parentFrame.dynamicSizing = value
                            self:UpdateIconLayout(self.timerFrame)
                        end,
                    },
                    timerText = {
                        name = "Timer Text",
                        type = "group",
                        inline = true,
                        order = 6,
                        args = {
                            hidden = {
                                name = "Hide Timer Texts",
                                type = "toggle",
                                order = 1,
                                get = function() return self.db.profile.parentFrame.timerText.hidden end,
                                set = function(info, value)
                                    self.db.profile.parentFrame.timerText.hidden = value
                                    self:UpdateTimerTextVisibility(self.timerFrame)
                                end,
                            },
                            hideSecondary = {
                                name = "Hide Secondary Timer Texts",
                                desc = "Hide timer texts for secondary DoT icons (icons 2 and 3), keeping only the primary timer text visible.",
                                type = "toggle",
                                order = 2,
                                get = function() return self.db.profile.parentFrame.timerText.hideSecondary end,
                                set = function(info, value)
                                    self.db.profile.parentFrame.timerText.hideSecondary = value
                                    self:UpdateTimerTextVisibility(self.timerFrame)
                                end,
                            },
                            avoidOverlap = {
                                name = "Avoid Overlap",
                                desc = "Automatically hide secondary timer texts when the frame is too small to display them without overlapping.",
                                type = "toggle",
                                order = 3,
                                get = function() return self.db.profile.parentFrame.timerText.avoidOverlap end,
                                set = function(info, value)
                                    self.db.profile.parentFrame.timerText.avoidOverlap = value
                                    self:UpdateTimerTextVisibility(self.timerFrame)
                                end,
                            },
                            fontSize = {
                                name = "Font Size",
                                type = "range",
                                order = 4,
                                min = 6,
                                max = 20,
                                step = 1,
                                get = function() return self.db.profile.parentFrame.timerText.fontSize end,
                                set = function(info, value)
                                    self.db.profile.parentFrame.timerText.fontSize = value
                                    self:UpdateTimerTextSettings(self.timerFrame)
                                end,
                            },
                            anchor = {
                                name = "Anchor Point",
                                type = "select",
                                order = 5,
                                values = {
                                    ["CENTER"] = "Center",
                                    ["LEFT"] = "Left",
                                    ["RIGHT"] = "Right",
                                    ["TOP"] = "Top",
                                    ["BOTTOM"] = "Bottom",
                                    ["TOPLEFT"] = "Top Left",
                                    ["TOPRIGHT"] = "Top Right",
                                    ["BOTTOMLEFT"] = "Bottom Left",
                                    ["BOTTOMRIGHT"] = "Bottom Right",
                                },
                                get = function() return self.db.profile.parentFrame.timerText.anchor end,
                                set = function(info, value)
                                    self.db.profile.parentFrame.timerText.anchor = value
                                    self:UpdateTimerTextSettings(self.timerFrame)
                                end,
                            },
                            xOffset = {
                                name = "X Offset",
                                type = "range",
                                order = 6,
                                min = -50,
                                max = 50,
                                step = 1,
                                get = function() return self.db.profile.parentFrame.timerText.xOffset end,
                                set = function(info, value)
                                    self.db.profile.parentFrame.timerText.xOffset = value
                                    self:UpdateTimerTextSettings(self.timerFrame)
                                end,
                            },
                            yOffset = {
                                name = "Y Offset",
                                type = "range",
                                order = 7,
                                min = -50,
                                max = 50,
                                step = 1,
                                get = function() return self.db.profile.parentFrame.timerText.yOffset end,
                                set = function(info, value)
                                    self.db.profile.parentFrame.timerText.yOffset = value
                                    self:UpdateTimerTextSettings(self.timerFrame)
                                end,
                            },
                        },
                    },
                    position = {
                        name = "Position",
                        type = "group",
                        inline = true,
                        order = 7,
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
                        order = 8,
                        args = {
                            width = {
                                name = "Width",
                                type = "range",
                                order = 1,
                                min = MIN_CONTAINER_WIDTH,
                                max = MAX_CONTAINER_WIDTH,
                                step = 1,
                                get = function() return self.db.profile.parentFrame.dimensions.width end,
                                set = function(info, value)
                                    if self.db.profile.parentFrame.dimensions.width ~= value then
                                        self.db.profile.parentFrame.dimensions.width = value
                                        if self.timerFrame then
                                            self.timerFrame:SetWidth(value)
                                            self.timerFrame.titleBar:SetWidth(value)
                                            self:UpdateIconLayout(self.timerFrame)
                                        end
                                    end
                                end,
                            },
                            height = {
                                name = "Height",
                                type = "range",
                                order = 2,
                                min = MIN_CONTAINER_HEIGHT,
                                max = MAX_CONTAINER_HEIGHT,
                                step = 1,
                                get = function() return self.db.profile.parentFrame.dimensions.height end,
                                set = function(info, value)
                                    if self.db.profile.parentFrame.dimensions.height ~= value then
                                        self.db.profile.parentFrame.dimensions.height = value
                                        if self.timerFrame then
                                            self.timerFrame:SetHeight(value)
                                            self:UpdateIconLayout(self.timerFrame)
                                        end
                                    end
                                end,
                            },
                        },
                    },
                    reset = {
                        name = "Reset to Default",
                        type = "execute",
                        order = 9,
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


function SH:ShowPrimaryIcon(spellTexture, timeUntilTick)
    if not self.timerFrame or not self.timerFrame.dotIcons then return end
    if spellTexture then
        self.timerFrame.dotIcons[1]:SetTexture(spellTexture)
        self.timerFrame.dotIcons[1]:Show()
    end
    if timeUntilTick then
        local clampedTime = math.max(0, timeUntilTick)
        if clampedTime > 0 then
            self.timerFrame.dotTimers[1]:SetText(string.format("%.1fs", clampedTime))
            self.timerFrame.dotTimers[1]:Show()
        else
            self.timerFrame.dotTimers[1]:Hide()
        end
    end
end

function SH:HideIcon(index)
    if not self.timerFrame or not self.timerFrame.dotTimers or not self.timerFrame.dotIcons then return end
    self.timerFrame.dotTimers[index]:Hide()
    self.timerFrame.dotIcons[index]:Hide()
end

function SH:HideIcons()
    if not self.timerFrame then return end

    for i = 1, MAX_DOT_COUNT do
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
            
            -- Check if DoT has expired based on duration
            if dot.duration and elapsed >= dot.duration then
                -- DoT has expired, remove it
                dots[spellId] = nil
                if next(dots) == nil then
                    self.activeDots[destGUID] = nil
                end
            else
                -- DoT is still active, calculate next tick
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
    end

    if #upcoming == 0 then
        -- hide all icons and timers when no DoTs are active
        self:HideIcons()
        
        -- if we're in test mode and no DoTs are active, disable test mode
        if self.db.profile.parentFrame.testMode then
            self.db.profile.parentFrame.testMode = false
            if self.testTicker then
                self.testTicker:Cancel()
                self.testTicker = nil
            end
            self.activeDots = {}
            AceConfigRegistry:NotifyChange(self.name)
            self:Print("No active test DoTs remaining, stopping test mode.")
        end
        return
    end

    table.sort(upcoming, function(a, b) return a.nextTick < b.nextTick end)

    local primary = upcoming[1]
    local primaryTime = primary.nextTick - now
    if primaryTime <= 0 then
        -- hide all icons and timers when DoTs have expired
        self:HideIcons()
        return
    end

    local timerFrame = _G["StealthHelper_TimerFrame"]
    if timerFrame then
        timerFrame:Show()
    end

    -- get the number of DoTs to display
    local dotCount = self.db.profile.parentFrame.dotCount
    local maxDisplay = (dotCount == 0) and MAX_DOT_COUNT or dotCount

    -- filter out expired DoTs and only show active ones
    local activeDots = {}
    for i = 1, #upcoming do
        local dot = upcoming[i]
        local timeUntilTick = dot.nextTick - now
        if timeUntilTick > 0 then
            table.insert(activeDots, dot)
        end
    end
    
    -- first, hide all icons and timers
    for i = 1, MAX_DOT_COUNT do
        if self.timerFrame.dotIcons and self.timerFrame.dotIcons[i] then
            self.timerFrame.dotIcons[i]:Hide()
        end
        if self.timerFrame.dotTimers and self.timerFrame.dotTimers[i] then
            self.timerFrame.dotTimers[i]:Hide()
        end
    end
    
    -- then show only the active DoTs with dynamic layout
    local activeCount = math.min(#activeDots, maxDisplay)
    for i = 1, maxDisplay do
        if activeDots[i] then
            local dot = activeDots[i]
            local timeUntilTick = dot.nextTick - now
            
            -- show icon and timer
            if self.timerFrame.dotIcons and self.timerFrame.dotIcons[i] and dot.spellIcon then
                self.timerFrame.dotIcons[i]:SetTexture(dot.spellIcon)
                self.timerFrame.dotIcons[i]:Show()
            end
            if self.timerFrame.dotTimers and self.timerFrame.dotTimers[i] then
                self.timerFrame.dotTimers[i]:SetText(string.format("%.1fs", timeUntilTick))
                self.timerFrame.dotTimers[i]:Show()
            end
        end
    end
    
    -- update icon layout based on dynamic sizing setting
    if self.db.profile.parentFrame.dynamicSizing then
        self:UpdateIconLayoutDynamic(self.timerFrame, activeCount)
    else
        self:UpdateIconLayout(self.timerFrame)
    end
    
    -- apply timer text visibility settings
    self:UpdateTimerTextVisibility(self.timerFrame)
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

    -- always disable test mode on startup/reload
    self.db.profile.parentFrame.testMode = false
end

function SH:ToggleOptions()
    if Settings and Settings.OpenToCategory then
        Settings.OpenToCategory(addon.name)
    else
        InterfaceOptionsFrame_OpenToCategory(addon.name)
        InterfaceOptionsFrame_OpenToCategory(addon.name)
    end
end

function SH:UpdateTimerTextSettings(frame)
    if not frame or not frame.dotTimers then return end
    
    local fontSize = self.db.profile.parentFrame.timerText.fontSize
    local anchor = self.db.profile.parentFrame.timerText.anchor
    local xOffset = self.db.profile.parentFrame.timerText.xOffset
    local yOffset = self.db.profile.parentFrame.timerText.yOffset
    
    for i = 1, MAX_DOT_COUNT do
        if frame.dotTimers[i] then
            frame.dotTimers[i]:SetFont("Fonts\\FRIZQT__.TTF", fontSize, "OUTLINE")
            
            local iconSize = frame.dotIcons[i]:GetWidth()
            local halfSize = iconSize / 2
            
            local finalXOffset = xOffset
            local finalYOffset = yOffset
            
            if anchor == "LEFT" then
                finalXOffset = xOffset - halfSize
            elseif anchor == "RIGHT" then
                finalXOffset = xOffset + halfSize
            elseif anchor == "TOP" then
                finalYOffset = yOffset + halfSize
            elseif anchor == "BOTTOM" then
                finalYOffset = yOffset - halfSize
            elseif anchor == "TOPLEFT" then
                finalXOffset = xOffset - halfSize
                finalYOffset = yOffset + halfSize
            elseif anchor == "TOPRIGHT" then
                finalXOffset = xOffset + halfSize
                finalYOffset = yOffset + halfSize
            elseif anchor == "BOTTOMLEFT" then
                finalXOffset = xOffset - halfSize
                finalYOffset = yOffset - halfSize
            elseif anchor == "BOTTOMRIGHT" then
                finalXOffset = xOffset + halfSize
                finalYOffset = yOffset - halfSize
            end
            
            frame.dotTimers[i]:SetPoint("CENTER", frame.dotIcons[i], "CENTER", finalXOffset, finalYOffset)
        end
    end
    self:UpdateTimerTextVisibility(frame)
end

function SH:UpdateTimerTextVisibility(frame)
    if not frame or not frame.dotTimers then return end
    
    local hidden = self.db.profile.parentFrame.timerText.hidden
    local hideSecondary = self.db.profile.parentFrame.timerText.hideSecondary
    local avoidOverlap = self.db.profile.parentFrame.timerText.avoidOverlap
    local dotCount = self.db.profile.parentFrame.dotCount
    local maxDisplay = (dotCount == 0) and MAX_DOT_COUNT or dotCount
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
    local activeCount = math.min(#upcoming, maxDisplay)
    
    -- check if frame is too small for timer texts
    local frameWidth = frame:GetWidth()
    local frameHeight = frame:GetHeight()
    local isFrameTooSmall = avoidOverlap and activeCount > 2 and (frameWidth < 90 or frameHeight < 60)
    
    for i = 1, MAX_DOT_COUNT do
        if frame.dotTimers[i] then
            -- check if the corresponding icon is visible first
            local iconVisible = frame.dotIcons[i] and frame.dotIcons[i]:IsVisible()
            
            -- first check if this icon should be displayed based on DoT count
            if i > maxDisplay then
                -- hide timer text for icons beyond the current DoT count
                frame.dotTimers[i]:Hide()
            elseif hidden then
                -- hide all timer texts
                frame.dotTimers[i]:Hide()
            elseif not iconVisible then
                -- hide timer text if the corresponding icon is not visible
                frame.dotTimers[i]:Hide()
            elseif isFrameTooSmall then
                -- hide timer texts when frame is too small
                if i == 1 and not hideSecondary then
                    -- keep primary timer text if not hiding secondary
                    frame.dotTimers[i]:Show()
                else
                    -- hide all other timer texts when frame is small
                    frame.dotTimers[i]:Hide()
                end
            elseif hideSecondary and i > 1 then
                -- hide only secondary timer texts (icons 2 and 3)
                frame.dotTimers[i]:Hide()
            else
                -- show timer text
                frame.dotTimers[i]:Show()
            end
        end
    end
end

function SH:UpdateIconLayout(frame)
    -- try to use dynamic layout if we have active DoTs and dynamic sizing is enabled
    if self.db.profile.parentFrame.dynamicSizing and self.activeDots and frame and frame.dotIcons then
        local totalActiveCount = 0
        for destGUID, dots in pairs(self.activeDots) do
            for spellId, dot in pairs(dots) do
                totalActiveCount = totalActiveCount + 1
            end
        end
        
        if totalActiveCount > 0 then
            -- respect the user's dotCount setting for dynamic sizing
            local dotCount = self.db.profile.parentFrame.dotCount
            local maxDisplay = (dotCount == 0) and MAX_DOT_COUNT or dotCount
            local activeCount = math.min(totalActiveCount, maxDisplay)
            self:UpdateIconLayoutDynamic(frame, activeCount)
            return
        end
    end
    
    -- fallback to configured layout if no active DoTs
    if not frame or not frame.dotIcons then return end
    
    local containerWidth = frame:GetWidth()
    local containerHeight = frame:GetHeight()
    local dotCount = self.db.profile.parentFrame.dotCount
    local maxDisplay = (dotCount == 0) and MAX_DOT_COUNT or dotCount
    
    -- calculate available space (account for titlebar and padding)
    local padding = 4 -- Padding from frame edges
    local availableHeight = containerHeight - TITLE_BAR_HEIGHT - (padding * 2)
    local availableWidth = containerWidth - (padding * 2)
    
    -- calculate base icon sizes
    local basePrimarySize = math.min(availableWidth, availableHeight) * PRIMARY_ICON_SIZE_MULTIPLIER
    local baseSecondarySize = basePrimarySize * SECONDARY_ICON_SIZE_MULTIPLIER
    
    -- position and size icons
    if maxDisplay == 1 then
        -- single icon centered - use available space
        local iconSize = math.min(availableWidth, availableHeight) * 0.8
        frame.dotIcons[1]:SetSize(iconSize, iconSize)
        frame.dotIcons[1]:SetPoint("CENTER", frame, "CENTER", 0, -TITLE_BAR_HEIGHT / 2)
    else
        -- multiple icons - calculate if they fit, scale down if needed
        local spacing = 5
        local totalWidthNeeded = basePrimarySize + spacing + (baseSecondarySize + spacing) * (maxDisplay - 1)
        
        -- scale down if icons don't fit in available width
        local scaleFactor = 1
        if totalWidthNeeded > availableWidth then
            scaleFactor = availableWidth / totalWidthNeeded
        end
        
        -- apply scaling
        local primarySize = basePrimarySize * scaleFactor
        local secondarySize = baseSecondarySize * scaleFactor
        
        -- recalculate total width with scaled sizes
        local totalWidth = primarySize + spacing + (secondarySize + spacing) * (maxDisplay - 1)
        local startX = -totalWidth / 2
        
        -- primary icon (next tick) - always first and largest
        frame.dotIcons[1]:SetSize(primarySize, primarySize)
        frame.dotIcons[1]:SetPoint("CENTER", frame, "CENTER", startX + primarySize / 2, -TITLE_BAR_HEIGHT / 2)
        
        -- secondary icons (other DoTs) - evenly spaced and smaller
        for i = 2, maxDisplay do
            local xOffset = startX + primarySize + spacing + (secondarySize + spacing) * (i - 2) + secondarySize / 2
            frame.dotIcons[i]:SetSize(secondarySize, secondarySize)
            frame.dotIcons[i]:SetPoint("CENTER", frame, "CENTER", xOffset, -TITLE_BAR_HEIGHT / 2)
        end
    end
    
    -- update timer text positioning after icon layout is set
    self:UpdateTimerTextSettings(frame)
end

function SH:UpdateIconLayoutDynamic(frame, activeCount)
    if not frame or not frame.dotIcons then return end
    
    local containerWidth = frame:GetWidth()
    local containerHeight = frame:GetHeight()
    
    -- calculate available space (account for titlebar and padding)
    local padding = 4 -- Padding from frame edges
    local availableHeight = containerHeight - TITLE_BAR_HEIGHT - (padding * 2)
    local availableWidth = containerWidth - (padding * 2)
    
    -- calculate base icon sizes
    local basePrimarySize = math.min(availableWidth, availableHeight) * PRIMARY_ICON_SIZE_MULTIPLIER
    local baseSecondarySize = basePrimarySize * SECONDARY_ICON_SIZE_MULTIPLIER
    
    -- position and size icons based on actual active count
    if activeCount == 1 then
        -- single icon centered - use available space
        local iconSize = math.min(availableWidth, availableHeight) * 0.8
        frame.dotIcons[1]:SetSize(iconSize, iconSize)
        frame.dotIcons[1]:SetPoint("CENTER", frame, "CENTER", 0, -TITLE_BAR_HEIGHT / 2)
    elseif activeCount == 2 then
        -- two icons - use same sizes as regular layout but closer positioning
        local spacing = 3  -- Keep icons close together
        local totalWidthNeeded = basePrimarySize + spacing + baseSecondarySize
        
        -- scale down if icons don't fit in available width
        local scaleFactor = 1
        if totalWidthNeeded > availableWidth then
            scaleFactor = availableWidth / totalWidthNeeded
        end
        
        -- apply scaling (same as regular layout)
        local primarySize = basePrimarySize * scaleFactor
        local secondarySize = baseSecondarySize * scaleFactor
        
        -- calculate total width needed and center the group
        local totalWidth = primarySize + spacing + secondarySize
        local startX = -totalWidth / 2
        
        -- primary icon (left) - larger
        frame.dotIcons[1]:SetSize(primarySize, primarySize)
        frame.dotIcons[1]:SetPoint("CENTER", frame, "CENTER", startX + primarySize / 2, -TITLE_BAR_HEIGHT / 2)
        
        -- secondary icon (right) - smaller
        frame.dotIcons[2]:SetSize(secondarySize, secondarySize)
        frame.dotIcons[2]:SetPoint("CENTER", frame, "CENTER", startX + primarySize + spacing + secondarySize / 2, -TITLE_BAR_HEIGHT / 2)
    elseif activeCount >= 3 then
        -- three or more icons - use original layout logic
        local spacing = 5
        local totalWidthNeeded = basePrimarySize + spacing + (baseSecondarySize + spacing) * 2
        
        -- scale down if icons don't fit in available width
        local scaleFactor = 1
        if totalWidthNeeded > availableWidth then
            scaleFactor = availableWidth / totalWidthNeeded
        end
        
        -- apply scaling
        local primarySize = basePrimarySize * scaleFactor
        local secondarySize = baseSecondarySize * scaleFactor
        
        -- recalculate total width with scaled sizes
        local totalWidth = primarySize + spacing + (secondarySize + spacing) * 2
        local startX = -totalWidth / 2
        
        -- primary icon (next tick) - always first and largest
        frame.dotIcons[1]:SetSize(primarySize, primarySize)
        frame.dotIcons[1]:SetPoint("CENTER", frame, "CENTER", startX + primarySize / 2, -TITLE_BAR_HEIGHT / 2)
        
        -- secondary icons (other DoTs) - evenly spaced and smaller
        for i = 2, 3 do
            local xOffset = startX + primarySize + spacing + (secondarySize + spacing) * (i - 2) + secondarySize / 2
            frame.dotIcons[i]:SetSize(secondarySize, secondarySize)
            frame.dotIcons[i]:SetPoint("CENTER", frame, "CENTER", xOffset, -TITLE_BAR_HEIGHT / 2)
        end
    end
    
    -- update timer text positioning after icon layout is set
    self:UpdateTimerTextSettings(frame)
end

function SH:UpdateIconLayoutOnly(frame)
    if not frame or not frame.dotIcons then return end
    
    local containerWidth = frame:GetWidth()
    local containerHeight = frame:GetHeight()
    local dotCount = self.db.profile.parentFrame.dotCount
    local maxDisplay = (dotCount == 0) and MAX_DOT_COUNT or dotCount
    
    -- calculate available space (account for titlebar and padding)
    local padding = 4 -- Padding from frame edges
    local availableHeight = containerHeight - TITLE_BAR_HEIGHT - (padding * 2)
    local availableWidth = containerWidth - (padding * 2)
    
    -- calculate base icon sizes
    local basePrimarySize = math.min(availableWidth, availableHeight) * PRIMARY_ICON_SIZE_MULTIPLIER
    local baseSecondarySize = basePrimarySize * SECONDARY_ICON_SIZE_MULTIPLIER
    
    -- position and size icons
    if maxDisplay == 1 then
        -- single icon centered - use available space
        local iconSize = math.min(availableWidth, availableHeight) * 0.8
        frame.dotIcons[1]:SetSize(iconSize, iconSize)
        frame.dotIcons[1]:SetPoint("CENTER", frame, "CENTER", 0, -TITLE_BAR_HEIGHT / 2)
    else
        -- multiple icons - calculate if they fit, scale down if needed
        local spacing = 5
        local totalWidthNeeded = basePrimarySize + spacing + (baseSecondarySize + spacing) * (maxDisplay - 1)
        
        -- scale down if icons don't fit in available width
        local scaleFactor = 1
        if totalWidthNeeded > availableWidth then
            scaleFactor = availableWidth / totalWidthNeeded
        end
        
        -- apply scaling
        local primarySize = basePrimarySize * scaleFactor
        local secondarySize = baseSecondarySize * scaleFactor
        
        -- recalculate total width with scaled sizes
        local totalWidth = primarySize + spacing + (secondarySize + spacing) * (maxDisplay - 1)
        local startX = -totalWidth / 2
        
        -- primary icon (next tick) - always first and largest
        frame.dotIcons[1]:SetSize(primarySize, primarySize)
        frame.dotIcons[1]:SetPoint("CENTER", frame, "CENTER", startX + primarySize/2, -TITLE_BAR_HEIGHT / 2)
        
        -- secondary icons (other DoTs) - evenly spaced and smaller
        for i = 2, maxDisplay do
            local xOffset = startX + primarySize + spacing + (secondarySize + spacing) * (i - 2) + secondarySize/2
            frame.dotIcons[i]:SetSize(secondarySize, secondarySize)
            frame.dotIcons[i]:SetPoint("CENTER", frame, "CENTER", xOffset, -TITLE_BAR_HEIGHT / 2)
        end
    end
    
    -- update timer text positioning after icon layout is set
    self:UpdateTimerTextSettings(frame)
end

function SH:UpdateFrameLayout(frame)
    if not frame then return end
    
    local newWidth = frame:GetWidth()
    local newHeight = frame:GetHeight()
    
    frame.titleBar:SetWidth(newWidth)
    
    self.db.profile.parentFrame.dimensions.width = newWidth
    self.db.profile.parentFrame.dimensions.height = newHeight
    
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
    
    -- hide all icons first
    for i = 1, MAX_DOT_COUNT do
        if frame.dotIcons[i] then
            frame.dotIcons[i]:Hide()
        end
        if frame.dotTimers[i] then
            frame.dotTimers[i]:Hide()
        end
    end
    
    -- show icons and timers based on count
    if dotCount == 0 then
        -- show all icons and timers
        for i = 1, MAX_DOT_COUNT do
            if frame.dotIcons[i] then
                frame.dotIcons[i]:Show()
            end
            if frame.dotTimers[i] then
                frame.dotTimers[i]:Show()
            end
        end
    else
        -- show only the specified number
        for i = 1, dotCount do
            if frame.dotIcons[i] then
                frame.dotIcons[i]:Show()
            end
            if frame.dotTimers[i] then
                frame.dotTimers[i]:Show()
            end
        end
    end
    
    -- update layout after changing DoT count
    self:UpdateIconLayout(frame)
end

function SH:ToggleTestMode()
    self.db.profile.parentFrame.testMode = not self.db.profile.parentFrame.testMode
    
    if self.db.profile.parentFrame.testMode then
        self:StartTestMode()
    else
        self:StopTestMode()
    end
end

function SH:StartTestMode()
    -- create sample test data with realistic durations
    local now = GetTime()
    local testTargetGUID = "test-target-1"
    
    -- Clear existing activeDots and populate with test data
    self.activeDots = {}
    self.activeDots[testTargetGUID] = {
        [172] = { -- Corruption
            caster = "test-player-caster",
            spellName = "Corruption",
            spellId = 172,
            spellIcon = C_Spell.GetSpellTexture(172),
            tickInterval = 3,
            duration = 12,
            appliedAt = now,
        },
        [980] = { -- Curse of Agony
            caster = "test-player-caster",
            spellName = "Curse of Agony",
            spellId = 980,
            spellIcon = C_Spell.GetSpellTexture(980),
            tickInterval = 2,
            duration = 18,
            appliedAt = now,
        },
        [703] = { -- Garrote
            caster = "test-player-caster",
            spellName = "Garrote",
            spellId = 703,
            spellIcon = C_Spell.GetSpellTexture(703),
            tickInterval = 2,
            duration = 10,
            appliedAt = now,
        }
    }
    
    if not self.testTicker then
        self.testTicker = C_Timer.NewTicker(0.1, function() self:UpdateTimer() end)
    end
    
    self:Print("Test mode enabled.")
end

function SH:StopTestMode()
    if self.testTicker then
        self.testTicker:Cancel()
        self.testTicker = nil
    end
    -- clear test data
    self.activeDots = {}
    self:HideIcons()

    self.db.profile.parentFrame.testMode = false
    if self.testTicker then
        self.testTicker:Cancel()
        self.testTicker = nil
    end

    AceConfigRegistry:NotifyChange(self.name)
    
    self:Print("Test mode disabled.")
end


function SH:RegisterStaticPopups()
    StaticPopupDialogs["STEALTHHELPER_RESET_CONFIRM"] = {
        text = "Are you sure you want to reset StealthHelper frame to default settings?",
        button1 = "Yes",
        button2 = "No",
        OnAccept = function()
            self.db.profile.parentFrame.position = {
                point = defaults.profile.parentFrame.position.point,
                relativeTo = defaults.profile.parentFrame.position.relativeTo,
                relativePoint = defaults.profile.parentFrame.position.relativePoint,
                xOffset = defaults.profile.parentFrame.position.xOffset,
                yOffset = defaults.profile.parentFrame.position.yOffset,
            }
            self.db.profile.parentFrame.dimensions = {
                width = defaults.profile.parentFrame.dimensions.width,
                height = defaults.profile.parentFrame.dimensions.height,
            }
            self.db.profile.parentFrame.locked = defaults.profile.parentFrame.locked
            self.db.profile.parentFrame.hidden = defaults.profile.parentFrame.hidden
            self.db.profile.parentFrame.hideTitlebar = defaults.profile.parentFrame.hideTitlebar
            self.db.profile.parentFrame.hideBackground = defaults.profile.parentFrame.hideBackground
            self.db.profile.parentFrame.dotCount = defaults.profile.parentFrame.dotCount
            self.db.profile.parentFrame.testMode = defaults.profile.parentFrame.testMode
            self.db.profile.parentFrame.dynamicSizing = defaults.profile.parentFrame.dynamicSizing
            self.db.profile.parentFrame.timerText = {
                fontSize = defaults.profile.parentFrame.timerText.fontSize,
                anchor = defaults.profile.parentFrame.timerText.anchor,
                xOffset = defaults.profile.parentFrame.timerText.xOffset,
                yOffset = defaults.profile.parentFrame.timerText.yOffset,
                hidden = defaults.profile.parentFrame.timerText.hidden,
                hideSecondary = defaults.profile.parentFrame.timerText.hideSecondary,
                avoidOverlap = defaults.profile.parentFrame.timerText.avoidOverlap,
            }
            if self.timerFrame then
                self.timerFrame:ClearAllPoints()
                self.timerFrame:SetPoint(defaults.profile.parentFrame.position.point, defaults.profile.parentFrame.position.relativeTo, defaults.profile.parentFrame.position.relativePoint, defaults.profile.parentFrame.position.xOffset, defaults.profile.parentFrame.position.yOffset)
                self.timerFrame:SetSize(defaults.profile.parentFrame.dimensions.width, defaults.profile.parentFrame.dimensions.height)
                self:UpdateFrameLayout(self.timerFrame)
                self:UpdateFrameLockState(self.timerFrame)
                self:UpdateFrameVisibility(self.timerFrame)
                self:UpdateTitlebarVisibility(self.timerFrame)
                self:UpdateBackgroundVisibility(self.timerFrame)
                self:UpdateDotCount(self.timerFrame)
                self:UpdateTimerTextSettings(self.timerFrame)
            end
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
    }
end

