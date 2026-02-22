local addonName, ns = ...
local L = ns.L

local btn         -- toggle button
local minimapBtn  -- minimap button
local sct = ns.sct

---------------------------------------------------------------------------
-- THEME
---------------------------------------------------------------------------
local TEAL    = { 0.18, 0.83, 0.75 }   -- accent
local CORAL   = { 0.95, 0.40, 0.40 }   -- hidden state
local AMBER   = { 0.98, 0.75, 0.15 }   -- whisper blink
local SLATE   = { 0.10, 0.12, 0.16 }   -- dark bg

-- Colorblind-safe alternatives (high contrast, blue/orange)
local CB_VISIBLE = { 0.20, 0.60, 1.00 }   -- bright blue
local CB_HIDDEN  = { 1.00, 0.55, 0.00 }   -- bright orange
local CB_WHISPER = { 1.00, 1.00, 0.20 }   -- bright yellow

-- Get current theme colours based on colorblind setting
local function GetColors()
    if HideChatDB and HideChatDB.colorblind then
        return CB_VISIBLE, CB_HIDDEN, CB_WHISPER
    end
    return TEAL, CORAL, AMBER
end

---------------------------------------------------------------------------
-- Helper: create a floating chat-bubble icon with shadow + shine
-- Colorblind mode adds a shape indicator (square=hidden, circle=visible)
---------------------------------------------------------------------------
local function CreateBubble(parent, s, compact)
    local p = {}
    local yOff  = compact and 0 or (s * 0.06)   -- vertical lift
    local shOff = compact and 0.5 or 1           -- shadow x-shift
    local shAlp = compact and 0.30 or 0.45       -- shadow alpha

    -- Drop shadow
    p.sBod = parent:CreateTexture(nil, "BACKGROUND", nil, 1)
    p.sBod:SetSize(s * 0.72, s * 0.46)
    p.sBod:SetPoint("CENTER", parent, "CENTER", shOff, yOff - 0.5)
    sct(p.sBod, 0, 0, 0, shAlp)
    p.sTail = parent:CreateTexture(nil, "BACKGROUND", nil, 1)
    p.sTail:SetSize(s * 0.22, s * 0.17)
    p.sTail:SetPoint("TOPLEFT", p.sBod, "BOTTOMLEFT", s * 0.12, 1)
    sct(p.sTail, 0, 0, 0, shAlp)

    -- Main body
    p.body = parent:CreateTexture(nil, "ARTWORK", nil, 0)
    p.body:SetSize(s * 0.70, s * 0.44)
    p.body:SetPoint("CENTER", parent, "CENTER", 0, yOff)

    -- Tail
    p.tail = parent:CreateTexture(nil, "ARTWORK", nil, 0)
    p.tail:SetSize(s * 0.20, s * 0.15)
    p.tail:SetPoint("TOPLEFT", p.body, "BOTTOMLEFT", s * 0.10, 1)

    -- Top shine (subtle highlight strip)
    p.shine = parent:CreateTexture(nil, "ARTWORK", nil, 1)
    p.shine:SetSize(s * 0.60, s * 0.07)
    p.shine:SetPoint("TOP", p.body, "TOP", 0, -1)
    sct(p.shine, 1, 1, 1, compact and 0.12 or 0.18)

    -- Three dots (default) / shape indicator for colorblind
    p.dots = {}
    local dotSz = math.max(3, s * 0.11)
    local space  = s * 0.19
    for i = -1, 1 do
        local d = parent:CreateTexture(nil, "ARTWORK", nil, 2)
        d:SetSize(dotSz, dotSz)
        d:SetPoint("CENTER", p.body, "CENTER", i * space, -0.5)
        p.dots[#p.dots + 1] = d
    end

    -- Colorblind shape indicator (overlaid, hidden by default)
    p.cbIndicator = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    p.cbIndicator:SetPoint("CENTER", p.body, "CENTER", 0, -0.5)
    p.cbIndicator:SetText("")
    p.cbIndicator:Hide()

    return p
end

local function ColorBubble(p, r, g, b, a, dr, dg, db)
    sct(p.body, r, g, b, a)
    sct(p.tail, r, g, b, a)
    for _, d in ipairs(p.dots) do
        sct(d, dr or 0.06, dg or 0.08, db or 0.10, 1)
    end
end

-- Update colorblind shape indicator
local function UpdateCBIndicator(bubble, isHidden, isWhisper)
    if not bubble or not bubble.cbIndicator then return end
    if HideChatDB and HideChatDB.colorblind then
        -- Show shape: X when hidden, checkmark when visible, ! when whisper
        if isWhisper then
            bubble.cbIndicator:SetText("|cFFFFFF00!|r")
        elseif isHidden then
            bubble.cbIndicator:SetText("|cFFFFAAAAX|r")
        else
            bubble.cbIndicator:SetText("")
        end
        bubble.cbIndicator:Show()
        -- Hide dots in colorblind mode, show indicator instead
        for _, d in ipairs(bubble.dots) do d:Hide() end
    else
        bubble.cbIndicator:Hide()
        for _, d in ipairs(bubble.dots) do d:Show() end
    end
end

---------------------------------------------------------------------------
-- WHISPER BLINK ANIMATION
---------------------------------------------------------------------------
local blinkTicker, blinkState = nil, false

function ns.StartBlink()
    if blinkTicker then return end
    ns._hasWhisper = true
    blinkState = false
    blinkTicker = C_Timer.NewTicker(0.5, function()
        blinkState = not blinkState
        local _, _, amber = GetColors()
        if blinkState then
            if btn then
                ColorBubble(btn.bubble, amber[1], amber[2], amber[3], 1, 0.40, 0.28, 0.02)
                sct(btn.bubble.shine, 1, 1, 1, 0.25)
                UpdateCBIndicator(btn.bubble, nil, true)
            end
            if minimapBtn then
                ColorBubble(minimapBtn.bubble, amber[1], amber[2], amber[3], 1, 0.40, 0.28, 0.02)
                UpdateCBIndicator(minimapBtn.bubble, nil, true)
            end
        else
            ns.UpdateButton()
            ns.UpdateMinimap()
        end
    end)
end

function ns.StopBlink()
    ns._hasWhisper = false
    if blinkTicker then blinkTicker:Cancel(); blinkTicker = nil end
    blinkState = false
    ns.UpdateButton()
    ns.UpdateMinimap()
end

---------------------------------------------------------------------------
-- TOGGLE BUTTON  (floating chat bubble - no square frame)
---------------------------------------------------------------------------
function ns.InitButton()
    if btn then return end

    local b = CreateFrame("Button", "HideChatToggleButton", UIParent)
    b:SetSize(38, 32)
    b:SetFrameStrata("HIGH")
    b:SetClampedToScreen(true)

    -- The bubble IS the icon - no opaque square behind it
    b.bubble = CreateBubble(b, 36)

    -- Hover highlight (covers the bubble area)
    local hl = b:CreateTexture(nil, "HIGHLIGHT")
    hl:SetSize(28, 20)
    hl:SetPoint("CENTER", 0, 2)
    sct(hl, 1, 1, 1, 0.08)

    ---------- position ---------------------------------------------------
    local pos = HideChatDB.buttonPos
    if pos then
        b:ClearAllPoints()
        b:SetPoint(pos.point, UIParent, pos.relPoint, pos.x, pos.y)
    else
        local d = ns.BUTTON_DEFAULT
        b:SetPoint(d.point, UIParent, d.point, d.x, d.y)
    end

    ---------- dragging ---------------------------------------------------
    b:SetMovable(true); b:EnableMouse(true)
    b:RegisterForDrag("LeftButton"); b:RegisterForClicks("AnyUp")
    b:SetScript("OnDragStart", function(self)
        if not HideChatDB.lockButton then self:StartMoving() end
    end)
    b:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local pt, _, rel, x, y = self:GetPoint()
        HideChatDB.buttonPos = { point = pt, relPoint = rel, x = x, y = y }
    end)

    ---------- clicks -----------------------------------------------------
    b:SetScript("OnClick", function(_, button)
        if button == "RightButton" then
            if ns.ToggleConfig then ns.ToggleConfig() end
        elseif button == "MiddleButton" then
            -- Quick-reply to last whisper
            if ns._hasWhisper and ns.QuickReply then
                ns.QuickReply()
            else
                HideChat_Toggle()
            end
        else
            HideChat_Toggle()
        end
    end)

    ---------- tooltip ----------------------------------------------------
    b:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        local teal = GetColors()
        GameTooltip:AddLine("HideChat", teal[1], teal[2], teal[3])
        GameTooltip:AddLine(" ")
        if ns.isHidden then
            local _, coral = GetColors()
            GameTooltip:AddLine(L["Status: Hidden"], coral[1], coral[2], coral[3])
        else
            GameTooltip:AddLine(L["Status: Visible"], teal[1], teal[2], teal[3])
        end
        if ns._hasWhisper then
            local _, _, amber = GetColors()
            GameTooltip:AddLine(L["New whisper!"], amber[1], amber[2], amber[3])
        end
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine(L["Left-click: Toggle chat"], 0.8, 0.8, 0.8)
        GameTooltip:AddLine(L["Right-click: Settings"], 0.8, 0.8, 0.8)
        if ns._hasWhisper then
            GameTooltip:AddLine(L["Middle-click: Quick reply"], 0.8, 0.8, 0.8)
        end
        if not HideChatDB.lockButton then
            GameTooltip:AddLine(L["Drag: Move button"], 0.5, 0.5, 0.5)
        end
        GameTooltip:Show()
    end)
    b:SetScript("OnLeave", function() GameTooltip:Hide() end)

    ---------- visibility -------------------------------------------------
    -- Promote to upvalue only after full init succeeds
    btn = b
    if not HideChatDB.showButton then btn:Hide() end
    ns.UpdateButton()
    ns.InitMinimapButton()
end

---------------------------------------------------------------------------
-- Refresh toggle button
---------------------------------------------------------------------------
function ns.UpdateButton()
    if not btn then return end
    if HideChatDB.showButton then btn:Show() else btn:Hide(); return end
    if blinkState then return end

    local teal, coral = GetColors()
    if ns.isHidden then
        -- Muted coral/orange bubble
        ColorBubble(btn.bubble, coral[1], coral[2], coral[3], 0.65, 0.30, 0.10, 0.10)
        sct(btn.bubble.shine, 1, 1, 1, 0.10)
    else
        -- Bright teal/blue bubble
        ColorBubble(btn.bubble, teal[1], teal[2], teal[3], 1, 0.04, 0.20, 0.18)
        sct(btn.bubble.shine, 1, 1, 1, 0.22)
    end

    UpdateCBIndicator(btn.bubble, ns.isHidden, false)

    -- Refresh tooltip live if currently hovering
    if GameTooltip:IsOwned(btn) then
        btn:GetScript("OnEnter")(btn)
    end
end

function ns.ResetButtonPos()
    if not btn then return end
    HideChatDB.buttonPos = nil
    btn:ClearAllPoints()
    local d = ns.BUTTON_DEFAULT
    btn:SetPoint(d.point, UIParent, d.point, d.x, d.y)
end

---------------------------------------------------------------------------
-- MINIMAP BUTTON
---------------------------------------------------------------------------
local function UpdateMinimapPosition()
    if not minimapBtn then return end
    local angle = math.rad(HideChatDB.minimapPos or ns.MINIMAP_DEFAULT_ANGLE)
    local r = ns.MINIMAP_RADIUS
    minimapBtn:ClearAllPoints()
    minimapBtn:SetPoint("CENTER", Minimap, "CENTER",
        math.cos(angle) * r, math.sin(angle) * r)
end

function ns.InitMinimapButton()
    if minimapBtn then return end

    local m = CreateFrame("Button", "HideChatMinimapButton", Minimap)
    m:SetSize(32, 32)
    m:SetFrameStrata("MEDIUM"); m:SetFrameLevel(8)

    -- Dark circle bg
    local bg = m:CreateTexture(nil, "BACKGROUND")
    bg:SetSize(26, 26); bg:SetPoint("CENTER")
    sct(bg, SLATE[1], SLATE[2], SLATE[3], 0.92)

    -- Chat bubble icon (compact = centered, no big offsets)
    m.bubble = CreateBubble(m, 22, true)
    local teal = GetColors()
    ColorBubble(m.bubble, teal[1], teal[2], teal[3], 1, 0.04, 0.20, 0.18)

    -- Standard minimap ring (safe file-data ID)
    local ring = m:CreateTexture(nil, "OVERLAY")
    ring:SetSize(54, 54); ring:SetPoint("CENTER")
    pcall(ring.SetTexture, ring, 136430)

    -- Hover
    local hl = m:CreateTexture(nil, "HIGHLIGHT")
    hl:SetSize(24, 24); hl:SetPoint("CENTER")
    sct(hl, 1, 1, 1, 0.12)

    ---------- position ---------------------------------------------------
    -- Promote to upvalue only after full init succeeds
    minimapBtn = m
    UpdateMinimapPosition()

    ---------- dragging ---------------------------------------------------
    minimapBtn:RegisterForDrag("LeftButton"); minimapBtn:RegisterForClicks("AnyUp")
    minimapBtn:SetScript("OnDragStart", function(self) self._drag = true end)
    minimapBtn:SetScript("OnDragStop",  function(self) self._drag = false end)
    minimapBtn:SetScript("OnUpdate", function(self)
        if not self._drag then return end
        local mx, my = Minimap:GetCenter()
        if not mx or not my then return end
        local cx, cy = GetCursorPosition()
        local s = UIParent:GetEffectiveScale()
        HideChatDB.minimapPos = math.deg(math.atan2(cy/s - my, cx/s - mx))
        UpdateMinimapPosition()
    end)

    ---------- clicks -----------------------------------------------------
    minimapBtn:SetScript("OnClick", function(_, button)
        if button == "RightButton" then
            if ns.ToggleConfig then ns.ToggleConfig() end
        elseif button == "MiddleButton" then
            if ns._hasWhisper and ns.QuickReply then
                ns.QuickReply()
            else
                HideChat_Toggle()
            end
        else
            HideChat_Toggle()
        end
    end)

    ---------- tooltip ----------------------------------------------------
    minimapBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        local teal2 = GetColors()
        GameTooltip:AddLine("HideChat", teal2[1], teal2[2], teal2[3])
        GameTooltip:AddLine(" ")
        if ns.isHidden then
            local _, coral = GetColors()
            GameTooltip:AddLine(L["Status: Hidden"], coral[1], coral[2], coral[3])
        else
            GameTooltip:AddLine(L["Status: Visible"], teal2[1], teal2[2], teal2[3])
        end
        if ns._hasWhisper then
            local _, _, amber = GetColors()
            GameTooltip:AddLine(L["New whisper!"], amber[1], amber[2], amber[3])
        end
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine(L["Left-click: Toggle"], 0.8, 0.8, 0.8)
        GameTooltip:AddLine(L["Right-click: Settings"], 0.8, 0.8, 0.8)
        if ns._hasWhisper then
            GameTooltip:AddLine(L["Middle-click: Quick reply"], 0.8, 0.8, 0.8)
        end
        GameTooltip:AddLine(L["Drag: Reposition"], 0.5, 0.5, 0.5)
        GameTooltip:Show()
    end)
    minimapBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

    ns.UpdateMinimap()
end

function ns.ResetMinimapPos()
    if not minimapBtn then return end
    HideChatDB.minimapPos = ns.MINIMAP_DEFAULT_ANGLE
    UpdateMinimapPosition()
end

function ns.UpdateMinimap()
    if not minimapBtn then return end
    if HideChatDB.showMinimap then
        minimapBtn:Show(); UpdateMinimapPosition()
        if blinkState then return end   -- don't overwrite blink colour
        local teal, coral = GetColors()
        -- Update bubble colour to reflect current state
        if ns.isHidden then
            ColorBubble(minimapBtn.bubble, coral[1], coral[2], coral[3], 0.65, 0.30, 0.10, 0.10)
        else
            ColorBubble(minimapBtn.bubble, teal[1], teal[2], teal[3], 1, 0.04, 0.20, 0.18)
        end
        UpdateCBIndicator(minimapBtn.bubble, ns.isHidden, false)
        -- Refresh tooltip live if currently hovering
        if GameTooltip:IsOwned(minimapBtn) then
            minimapBtn:GetScript("OnEnter")(minimapBtn)
        end
    else minimapBtn:Hide() end
end
