local addonName, ns = ...

local btn         -- toggle button
local minimapBtn  -- minimap button

---------------------------------------------------------------------------
-- Helper: draw a chat-bubble icon from layered textures
-- Returns table of texture refs for recoloring later
---------------------------------------------------------------------------
local function CreateBubbleIcon(parent, size)
    local s = size or 30
    local parts = {}

    -- Bubble body
    local body = parent:CreateTexture(nil, "ARTWORK")
    body:SetSize(s * 0.60, s * 0.38)
    body:SetPoint("CENTER", parent, "CENTER", 0, s * 0.06)
    parts.body = body

    -- Bubble tail
    local tail = parent:CreateTexture(nil, "ARTWORK")
    tail:SetSize(s * 0.18, s * 0.14)
    tail:SetPoint("TOPLEFT", body, "BOTTOMLEFT", s * 0.08, 1)
    parts.tail = tail

    -- Three dots
    parts.dots = {}
    local dotSize = math.max(2, s * 0.09)
    local spacing = s * 0.16
    for i = -1, 1 do
        local dot = parent:CreateTexture(nil, "ARTWORK", nil, 1)
        dot:SetSize(dotSize, dotSize)
        dot:SetPoint("CENTER", body, "CENTER", i * spacing, 0)
        parts.dots[#parts.dots + 1] = dot
    end

    return parts
end

local function SetBubbleColor(parts, bodyR, bodyG, bodyB, bodyA, dotR, dotG, dotB)
    parts.body:SetColorTexture(bodyR, bodyG, bodyB, bodyA or 0.9)
    parts.tail:SetColorTexture(bodyR, bodyG, bodyB, bodyA or 0.9)
    for _, dot in ipairs(parts.dots) do
        dot:SetColorTexture(dotR or 0.12, dotG or 0.12, dotB or 0.15, 1)
    end
end

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
            btn.border:SetColorTexture(1.0, 0.6, 0.0, 1)
            btn.bg:SetColorTexture(0.45, 0.28, 0.0, 0.92)
            SetBubbleColor(btn.icon, 1.0, 0.85, 0.5, 0.95, 0.4, 0.25, 0.0)
        else
            ns.UpdateButton()
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
    btn:SetSize(32, 32)
    btn:SetFrameStrata("HIGH")
    btn:SetClampedToScreen(true)

    -- Colored border (1px around button)
    local border = btn:CreateTexture(nil, "BACKGROUND", nil, -1)
    border:SetPoint("TOPLEFT", -1, 1)
    border:SetPoint("BOTTOMRIGHT", 1, -1)
    btn.border = border

    -- Dark inner background
    local bg = btn:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0.08, 0.08, 0.10, 0.92)
    btn.bg = bg

    -- Hover highlight
    local highlight = btn:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetAllPoints()
    highlight:SetColorTexture(1, 1, 1, 0.08)

    -- Chat bubble icon (custom drawn)
    btn.icon = CreateBubbleIcon(btn, 30)

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
        btn.border:SetColorTexture(0.7, 0.15, 0.15, 1)
        btn.bg:SetColorTexture(0.15, 0.06, 0.06, 0.92)
        SetBubbleColor(btn.icon, 0.55, 0.55, 0.55, 0.7, 0.28, 0.28, 0.30)
    else
        btn.border:SetColorTexture(0.1, 0.65, 0.1, 1)
        btn.bg:SetColorTexture(0.06, 0.12, 0.06, 0.92)
        SetBubbleColor(btn.icon, 1, 1, 1, 0.9, 0.12, 0.12, 0.15)
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

    -- Dark circular background
    local bg = minimapBtn:CreateTexture(nil, "BACKGROUND")
    bg:SetSize(26, 26)
    bg:SetPoint("CENTER")
    bg:SetColorTexture(0.05, 0.05, 0.08, 0.85)

    -- Chat bubble icon (smaller)
    minimapBtn.icon = CreateBubbleIcon(minimapBtn, 24)
    SetBubbleColor(minimapBtn.icon, 1, 1, 1, 0.9, 0.1, 0.1, 0.12)

    -- Minimap border ring (file data ID for stability)
    local border = minimapBtn:CreateTexture(nil, "OVERLAY")
    border:SetSize(54, 54)
    border:SetPoint("CENTER")
    pcall(border.SetTexture, border, 136430)

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
