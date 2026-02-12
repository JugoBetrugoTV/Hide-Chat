local addonName, ns = ...

local btn         -- toggle button
local minimapBtn  -- minimap button

---------------------------------------------------------------------------
-- WHISPER BLINK ANIMATION
---------------------------------------------------------------------------
local blinkTicker = nil
local blinkState  = false

function ns.StartBlink()
    if blinkTicker then return end -- already blinking
    ns._hasWhisper = true
    blinkState = false
    blinkTicker = C_Timer.NewTicker(0.5, function()
        if not btn then return end
        blinkState = not blinkState
        if blinkState then
            btn.bg:SetColorTexture(0.8, 0.5, 0.0, 0.90)     -- orange flash
            btn.overlay:SetColorTexture(1.0, 0.6, 0.0, 1)
        else
            ns.UpdateButton()   -- restore normal state colour
        end
    end)
end

function ns.StopBlink()
    ns._hasWhisper = false
    if blinkTicker then
        blinkTicker:Cancel()
        blinkTicker = nil
    end
    blinkState = false
    ns.UpdateButton()
end

---------------------------------------------------------------------------
-- TOGGLE BUTTON
---------------------------------------------------------------------------
function ns.InitButton()
    if btn then return end

    btn = CreateFrame("Button", "HideChatToggleButton", UIParent)
    btn:SetSize(30, 30)
    btn:SetFrameStrata("HIGH")
    btn:SetClampedToScreen(true)

    -- Dark background
    local bg = btn:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0.12, 0.12, 0.12, 0.85)
    btn.bg = bg

    -- Hover highlight
    local highlight = btn:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetAllPoints()
    highlight:SetColorTexture(1, 1, 1, 0.10)

    -- Chat icon label (text-based, works on all WoW versions)
    local label = btn:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    label:SetPoint("CENTER", 0, 0)
    label:SetText("HC")
    label:SetTextColor(1, 1, 1)
    btn.label = label

    -- State colour dot
    local overlay = btn:CreateTexture(nil, "ARTWORK", nil, 1)
    overlay:SetSize(8, 8)
    overlay:SetPoint("BOTTOMRIGHT", -3, 3)
    btn.overlay = overlay

    ---------- position ---------------------------------------------------
    local pos = HideChatDB.buttonPos
    if pos then
        btn:ClearAllPoints()
        btn:SetPoint(pos.point, UIParent, pos.relPoint, pos.x, pos.y)
    else
        btn:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", 4, 165)
    end

    ---------- dragging ---------------------------------------------------
    btn:SetMovable(true)
    btn:EnableMouse(true)
    btn:RegisterForDrag("LeftButton")
    btn:RegisterForClicks("AnyUp")

    btn:SetScript("OnDragStart", function(self)
        if not HideChatDB.lockButton then self:StartMoving() end
    end)
    btn:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local point, _, relPoint, x, y = self:GetPoint()
        HideChatDB.buttonPos = { point = point, relPoint = relPoint, x = x, y = y }
    end)

    ---------- clicks -----------------------------------------------------
    btn:SetScript("OnClick", function(_, button)
        if button == "RightButton" then
            if ns.ToggleConfig then ns.ToggleConfig() end
        else
            HideChat_Toggle()
        end
    end)

    ---------- tooltip ----------------------------------------------------
    btn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine("HideChat", 0, 1, 0)
        GameTooltip:AddLine(" ")
        if ns.isHidden then
            GameTooltip:AddLine("Status: Hidden", 0.9, 0.2, 0.2)
        else
            GameTooltip:AddLine("Status: Visible", 0.2, 0.9, 0.2)
        end
        if ns._hasWhisper then
            GameTooltip:AddLine("New whisper!", 1.0, 0.6, 0.0)
        end
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("Left-click: Toggle chat", 1, 1, 1)
        GameTooltip:AddLine("Right-click: Settings", 1, 1, 1)
        if not HideChatDB.lockButton then
            GameTooltip:AddLine("Drag: Move button", 0.5, 0.5, 0.5)
        end
        GameTooltip:Show()
    end)
    btn:SetScript("OnLeave", function() GameTooltip:Hide() end)

    ---------- visibility -------------------------------------------------
    if not HideChatDB.showButton then btn:Hide() end
    ns.UpdateButton()

    ---------- minimap button ---------------------------------------------
    ns.InitMinimapButton()
end

---------------------------------------------------------------------------
-- Refresh toggle button visuals
---------------------------------------------------------------------------
function ns.UpdateButton()
    if not btn then return end

    if HideChatDB.showButton then btn:Show() else btn:Hide(); return end

    -- Skip colour update while blink is active (blink sets its own)
    if blinkState then return end

    if ns.isHidden then
        btn.bg:SetColorTexture(0.45, 0.08, 0.08, 0.85)
        btn.overlay:SetColorTexture(0.9, 0.2, 0.2, 1)
        btn.label:SetTextColor(0.7, 0.7, 0.7)
    else
        btn.bg:SetColorTexture(0.08, 0.30, 0.08, 0.85)
        btn.overlay:SetColorTexture(0.2, 0.9, 0.2, 1)
        btn.label:SetTextColor(1, 1, 1)
    end
end

function ns.ResetButtonPos()
    if not btn then return end
    HideChatDB.buttonPos = nil
    btn:ClearAllPoints()
    btn:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", 4, 165)
end

---------------------------------------------------------------------------
-- MINIMAP BUTTON
---------------------------------------------------------------------------
local function UpdateMinimapPosition()
    if not minimapBtn then return end
    local angle = math.rad(HideChatDB.minimapPos or 220)
    local radius = 80
    minimapBtn:ClearAllPoints()
    minimapBtn:SetPoint("CENTER", Minimap, "CENTER",
        math.cos(angle) * radius,
        math.sin(angle) * radius)
end

function ns.InitMinimapButton()
    if minimapBtn then return end

    minimapBtn = CreateFrame("Button", "HideChatMinimapButton", Minimap)
    minimapBtn:SetSize(32, 32)
    minimapBtn:SetFrameStrata("MEDIUM")
    minimapBtn:SetFrameLevel(8)

    -- Background circle
    local bg = minimapBtn:CreateTexture(nil, "BACKGROUND")
    bg:SetSize(24, 24)
    bg:SetPoint("CENTER")
    bg:SetColorTexture(0, 0, 0, 0.6)

    -- Icon label (text-based, works on all WoW versions)
    local label = minimapBtn:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    label:SetPoint("CENTER", 0, 0)
    label:SetText("HC")
    label:SetTextColor(1, 1, 1)
    minimapBtn.label = label

    -- Standard minimap border ring
    local border = minimapBtn:CreateTexture(nil, "OVERLAY")
    border:SetSize(54, 54)
    border:SetPoint("CENTER")
    border:SetTexture(136430)  -- MiniMap-TrackingBorder file data ID

    -- Hover highlight
    local hl = minimapBtn:CreateTexture(nil, "HIGHLIGHT")
    hl:SetSize(24, 24)
    hl:SetPoint("CENTER")
    hl:SetColorTexture(1, 1, 1, 0.15)

    ---------- position ---------------------------------------------------
    UpdateMinimapPosition()

    ---------- dragging ---------------------------------------------------
    minimapBtn:RegisterForDrag("LeftButton")
    minimapBtn:RegisterForClicks("AnyUp")
    minimapBtn:SetScript("OnDragStart", function(self)
        self._dragging = true
    end)
    minimapBtn:SetScript("OnDragStop", function(self)
        self._dragging = false
    end)
    minimapBtn:SetScript("OnUpdate", function(self)
        if not self._dragging then return end
        local mx, my = Minimap:GetCenter()
        local cx, cy = GetCursorPosition()
        local scale  = UIParent:GetEffectiveScale()
        cx, cy = cx / scale, cy / scale
        local angle = math.deg(math.atan2(cy - my, cx - mx))
        HideChatDB.minimapPos = angle
        UpdateMinimapPosition()
    end)

    ---------- clicks -----------------------------------------------------
    minimapBtn:SetScript("OnClick", function(_, button)
        if button == "RightButton" then
            if ns.ToggleConfig then ns.ToggleConfig() end
        else
            HideChat_Toggle()
        end
    end)

    ---------- tooltip ----------------------------------------------------
    minimapBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:AddLine("HideChat", 0, 1, 0)
        GameTooltip:AddLine(" ")
        if ns.isHidden then
            GameTooltip:AddLine("Status: Hidden", 0.9, 0.2, 0.2)
        else
            GameTooltip:AddLine("Status: Visible", 0.2, 0.9, 0.2)
        end
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("Left-click: Toggle", 1, 1, 1)
        GameTooltip:AddLine("Right-click: Settings", 1, 1, 1)
        GameTooltip:AddLine("Drag: Reposition", 0.5, 0.5, 0.5)
        GameTooltip:Show()
    end)
    minimapBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

    ---------- visibility -------------------------------------------------
    ns.UpdateMinimap()
end

function ns.UpdateMinimap()
    if not minimapBtn then return end
    if HideChatDB.showMinimap then
        minimapBtn:Show()
        UpdateMinimapPosition()
    else
        minimapBtn:Hide()
    end
end
