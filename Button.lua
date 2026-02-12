local addonName, ns = ...

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

---------------------------------------------------------------------------
-- Helper: create a floating chat-bubble icon with shadow + shine
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

    -- Three dots
    p.dots = {}
    local dotSz = math.max(3, s * 0.11)
    local space  = s * 0.19
    for i = -1, 1 do
        local d = parent:CreateTexture(nil, "ARTWORK", nil, 2)
        d:SetSize(dotSz, dotSz)
        d:SetPoint("CENTER", p.body, "CENTER", i * space, -0.5)
        p.dots[#p.dots + 1] = d
    end

    return p
end

local function ColorBubble(p, r, g, b, a, dr, dg, db)
    sct(p.body, r, g, b, a)
    sct(p.tail, r, g, b, a)
    for _, d in ipairs(p.dots) do
        sct(d, dr or 0.06, dg or 0.08, db or 0.10, 1)
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
        if not btn then return end
        blinkState = not blinkState
        if blinkState then
            ColorBubble(btn.bubble, AMBER[1], AMBER[2], AMBER[3], 1, 0.40, 0.28, 0.02)
            sct(btn.bubble.shine, 1, 1, 1, 0.25)
        else
            ns.UpdateButton()
        end
    end)
end

function ns.StopBlink()
    ns._hasWhisper = false
    if blinkTicker then blinkTicker:Cancel(); blinkTicker = nil end
    blinkState = false
    ns.UpdateButton()
end

---------------------------------------------------------------------------
-- TOGGLE BUTTON  (floating chat bubble — no square frame)
---------------------------------------------------------------------------
function ns.InitButton()
    if btn then return end

    btn = CreateFrame("Button", "HideChatToggleButton", UIParent)
    btn:SetSize(38, 32)
    btn:SetFrameStrata("HIGH")
    btn:SetClampedToScreen(true)

    -- The bubble IS the icon — no opaque square behind it
    btn.bubble = CreateBubble(btn, 36)

    -- Hover highlight (covers the bubble area)
    local hl = btn:CreateTexture(nil, "HIGHLIGHT")
    hl:SetSize(28, 20)
    hl:SetPoint("CENTER", 0, 2)
    sct(hl, 1, 1, 1, 0.08)

    ---------- position ---------------------------------------------------
    local pos = HideChatDB.buttonPos
    if pos then
        btn:ClearAllPoints()
        btn:SetPoint(pos.point, UIParent, pos.relPoint, pos.x, pos.y)
    else
        btn:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", 4, 165)
    end

    ---------- dragging ---------------------------------------------------
    btn:SetMovable(true); btn:EnableMouse(true)
    btn:RegisterForDrag("LeftButton"); btn:RegisterForClicks("AnyUp")
    btn:SetScript("OnDragStart", function(self)
        if not HideChatDB.lockButton then self:StartMoving() end
    end)
    btn:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local pt, _, rel, x, y = self:GetPoint()
        HideChatDB.buttonPos = { point = pt, relPoint = rel, x = x, y = y }
    end)

    ---------- clicks -----------------------------------------------------
    btn:SetScript("OnClick", function(_, b)
        if b == "RightButton" then
            if ns.ToggleConfig then ns.ToggleConfig() end
        else HideChat_Toggle() end
    end)

    ---------- tooltip ----------------------------------------------------
    btn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine("HideChat", TEAL[1], TEAL[2], TEAL[3])
        GameTooltip:AddLine(" ")
        if ns.isHidden then
            GameTooltip:AddLine("Status: Hidden", CORAL[1], CORAL[2], CORAL[3])
        else
            GameTooltip:AddLine("Status: Visible", TEAL[1], TEAL[2], TEAL[3])
        end
        if ns._hasWhisper then
            GameTooltip:AddLine("New whisper!", AMBER[1], AMBER[2], AMBER[3])
        end
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("Left-click: Toggle chat", 0.8, 0.8, 0.8)
        GameTooltip:AddLine("Right-click: Settings", 0.8, 0.8, 0.8)
        if not HideChatDB.lockButton then
            GameTooltip:AddLine("Drag: Move button", 0.5, 0.5, 0.5)
        end
        GameTooltip:Show()
    end)
    btn:SetScript("OnLeave", function() GameTooltip:Hide() end)

    ---------- visibility -------------------------------------------------
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

    if ns.isHidden then
        -- Muted coral bubble
        ColorBubble(btn.bubble, CORAL[1], CORAL[2], CORAL[3], 0.65, 0.30, 0.10, 0.10)
        sct(btn.bubble.shine, 1, 1, 1, 0.10)
    else
        -- Bright teal bubble
        ColorBubble(btn.bubble, TEAL[1], TEAL[2], TEAL[3], 1, 0.04, 0.20, 0.18)
        sct(btn.bubble.shine, 1, 1, 1, 0.22)
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
    local r = 80
    minimapBtn:ClearAllPoints()
    minimapBtn:SetPoint("CENTER", Minimap, "CENTER",
        math.cos(angle) * r, math.sin(angle) * r)
end

function ns.InitMinimapButton()
    if minimapBtn then return end

    minimapBtn = CreateFrame("Button", "HideChatMinimapButton", Minimap)
    minimapBtn:SetSize(32, 32)
    minimapBtn:SetFrameStrata("MEDIUM"); minimapBtn:SetFrameLevel(8)

    -- Dark circle bg
    local bg = minimapBtn:CreateTexture(nil, "BACKGROUND")
    bg:SetSize(26, 26); bg:SetPoint("CENTER")
    sct(bg, SLATE[1], SLATE[2], SLATE[3], 0.92)

    -- Chat bubble icon (compact = centered, no big offsets)
    minimapBtn.bubble = CreateBubble(minimapBtn, 22, true)
    ColorBubble(minimapBtn.bubble, TEAL[1], TEAL[2], TEAL[3], 1, 0.04, 0.20, 0.18)

    -- Standard minimap ring (safe file-data ID)
    local ring = minimapBtn:CreateTexture(nil, "OVERLAY")
    ring:SetSize(54, 54); ring:SetPoint("CENTER")
    pcall(ring.SetTexture, ring, 136430)

    -- Hover
    local hl = minimapBtn:CreateTexture(nil, "HIGHLIGHT")
    hl:SetSize(24, 24); hl:SetPoint("CENTER")
    sct(hl, 1, 1, 1, 0.12)

    ---------- position ---------------------------------------------------
    UpdateMinimapPosition()

    ---------- dragging ---------------------------------------------------
    minimapBtn:RegisterForDrag("LeftButton"); minimapBtn:RegisterForClicks("AnyUp")
    minimapBtn:SetScript("OnDragStart", function(self) self._drag = true end)
    minimapBtn:SetScript("OnDragStop",  function(self) self._drag = false end)
    minimapBtn:SetScript("OnUpdate", function(self)
        if not self._drag then return end
        local mx, my = Minimap:GetCenter()
        local cx, cy = GetCursorPosition()
        local s = UIParent:GetEffectiveScale()
        HideChatDB.minimapPos = math.deg(math.atan2(cy/s - my, cx/s - mx))
        UpdateMinimapPosition()
    end)

    ---------- clicks -----------------------------------------------------
    minimapBtn:SetScript("OnClick", function(_, b)
        if b == "RightButton" then
            if ns.ToggleConfig then ns.ToggleConfig() end
        else HideChat_Toggle() end
    end)

    ---------- tooltip ----------------------------------------------------
    minimapBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:AddLine("HideChat", TEAL[1], TEAL[2], TEAL[3])
        GameTooltip:AddLine(" ")
        if ns.isHidden then
            GameTooltip:AddLine("Status: Hidden", CORAL[1], CORAL[2], CORAL[3])
        else
            GameTooltip:AddLine("Status: Visible", TEAL[1], TEAL[2], TEAL[3])
        end
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("Left-click: Toggle", 0.8, 0.8, 0.8)
        GameTooltip:AddLine("Right-click: Settings", 0.8, 0.8, 0.8)
        GameTooltip:AddLine("Drag: Reposition", 0.5, 0.5, 0.5)
        GameTooltip:Show()
    end)
    minimapBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

    ns.UpdateMinimap()
end

function ns.UpdateMinimap()
    if not minimapBtn then return end
    if HideChatDB.showMinimap then
        minimapBtn:Show(); UpdateMinimapPosition()
    else minimapBtn:Hide() end
end
