local addonName, ns = ...

local frame, content, checkboxes, widgets

---------------------------------------------------------------------------
-- THEME  (teal / dark-slate — no recycled WoW dialog textures)
---------------------------------------------------------------------------
local C = {
    accent  = { 0.18, 0.83, 0.75 },   -- teal
    dimAcc  = { 0.10, 0.50, 0.45 },   -- dim teal
    bg      = { 0.05, 0.06, 0.08 },   -- deep navy
    cardBg  = { 0.08, 0.10, 0.13 },   -- card panels
    border  = { 0.16, 0.18, 0.22 },   -- subtle borders
    text    = { 0.88, 0.90, 0.93 },   -- light text
    dim     = { 0.42, 0.44, 0.48 },   -- muted text
    danger  = { 0.92, 0.35, 0.35 },   -- red
    btnBg   = { 0.11, 0.13, 0.17 },   -- button bg
    btnBrd  = { 0.20, 0.22, 0.28 },   -- button border
}

local function rgb(t) return t[1], t[2], t[3] end

---------------------------------------------------------------------------
-- Draw helpers
---------------------------------------------------------------------------
local function HLine(parent, layer, sub, h, r, g, b, a)
    local t = parent:CreateTexture(nil, layer or "ARTWORK", nil, sub or 0)
    t:SetHeight(h or 1); t:SetColorTexture(r, g, b, a or 1)
    return t
end

local function BoxBorder(f, r, g, b, a)
    local function E(p1, p2)
        local t = f:CreateTexture(nil, "BORDER")
        t:SetColorTexture(r, g, b, a or 0.6)
        if p1 == "TOP" then
            t:SetHeight(1); t:SetPoint("TOPLEFT"); t:SetPoint("TOPRIGHT")
        elseif p1 == "BOTTOM" then
            t:SetHeight(1); t:SetPoint("BOTTOMLEFT"); t:SetPoint("BOTTOMRIGHT")
        elseif p1 == "LEFT" then
            t:SetWidth(1); t:SetPoint("TOPLEFT"); t:SetPoint("BOTTOMLEFT")
        elseif p1 == "RIGHT" then
            t:SetWidth(1); t:SetPoint("TOPRIGHT"); t:SetPoint("BOTTOMRIGHT")
        end
    end
    E("TOP"); E("BOTTOM"); E("LEFT"); E("RIGHT")
end

---------------------------------------------------------------------------
-- Card: section panel with border + accent top-line + title
---------------------------------------------------------------------------
local function Card(parent, title, x, y, w, h)
    local card = CreateFrame("Frame", nil, parent)
    card:SetSize(w, h); card:SetPoint("TOPLEFT", x, y)

    local bg = card:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(); bg:SetColorTexture(rgb(C.cardBg), 0.95)

    BoxBorder(card, rgb(C.border), 0.45)

    -- Teal accent at top
    local acc = card:CreateTexture(nil, "BORDER", nil, 1)
    acc:SetHeight(2); acc:SetPoint("TOPLEFT"); acc:SetPoint("TOPRIGHT")
    acc:SetColorTexture(rgb(C.accent), 0.65)

    if title then
        local fs = card:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        fs:SetPoint("TOPLEFT", 10, -8)
        fs:SetText("|cFF" .. "2DD4BF" .. title .. "|r")
    end
    return card
end

---------------------------------------------------------------------------
-- Widgets
---------------------------------------------------------------------------
local function SafeTex(w, m, p, ...)
    pcall(w[m], w, p, ...)
end

local function Checkbox(parent, label, x, y, key, onToggle)
    local cb = CreateFrame("CheckButton", nil, parent)
    cb:SetSize(22, 22); cb:SetPoint("TOPLEFT", x, y)
    SafeTex(cb, "SetNormalTexture",    "Interface\\Buttons\\UI-CheckBox-Up")
    SafeTex(cb, "SetPushedTexture",    "Interface\\Buttons\\UI-CheckBox-Down")
    SafeTex(cb, "SetHighlightTexture", "Interface\\Buttons\\UI-CheckBox-Highlight", "ADD")
    SafeTex(cb, "SetCheckedTexture",   "Interface\\Buttons\\UI-CheckBox-Check")
    -- Fallback: teal check mark text
    local mark = cb:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    mark:SetPoint("CENTER", 0, 0); mark:SetText("")
    cb._mark = mark
    local function syncMark(self)
        self._mark:SetText(self:GetChecked() and "|cFF2DD4BF" .. "✓" .. "|r" or "")
    end
    cb:SetScript("OnShow", syncMark)
    local t = cb:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    t:SetPoint("LEFT", cb, "RIGHT", 4, 0); t:SetText(label)
    cb.label = t; cb._key = key
    cb:SetScript("OnClick", function(self)
        local v = self:GetChecked() and true or false
        HideChatDB[key] = v; syncMark(self)
        if onToggle then onToggle(v) end
    end)
    function cb:SetOptionEnabled(on)
        if on then self:Enable(); self.label:SetFontObject("GameFontHighlight")
        else       self:Disable(); self.label:SetFontObject("GameFontDisable") end
    end
    return cb
end

local function InstanceCheckbox(parent, label, x, y, subKey)
    local cb = CreateFrame("CheckButton", nil, parent)
    cb:SetSize(18, 18); cb:SetPoint("TOPLEFT", x, y)
    SafeTex(cb, "SetNormalTexture",    "Interface\\Buttons\\UI-CheckBox-Up")
    SafeTex(cb, "SetPushedTexture",    "Interface\\Buttons\\UI-CheckBox-Down")
    SafeTex(cb, "SetHighlightTexture", "Interface\\Buttons\\UI-CheckBox-Highlight", "ADD")
    SafeTex(cb, "SetCheckedTexture",   "Interface\\Buttons\\UI-CheckBox-Check")
    local mark = cb:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    mark:SetPoint("CENTER", 0, 0); mark:SetText("")
    cb._mark = mark
    local function syncMark(self)
        self._mark:SetText(self:GetChecked() and "|cFF2DD4BF" .. "✓" .. "|r" or "")
    end
    cb:SetScript("OnShow", syncMark)
    local t = cb:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    t:SetPoint("LEFT", cb, "RIGHT", 2, 0); t:SetText(label)
    cb.label = t; cb._subKey = subKey
    cb:SetScript("OnClick", function(self)
        local v = self:GetChecked() and true or false
        HideChatDB.instanceTypes[subKey] = v; syncMark(self)
    end)
    function cb:SetOptionEnabled(on)
        if on then self:Enable(); self.label:SetFontObject("GameFontHighlightSmall")
        else       self:Disable(); self.label:SetFontObject("GameFontDisableSmall") end
    end
    return cb
end

local function Slider(parent, label, x, y, width, lo, hi, step, key, fmt)
    local wrap = CreateFrame("Frame", nil, parent)
    wrap:SetSize(width + 60, 36); wrap:SetPoint("TOPLEFT", x, y)
    local title = wrap:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    title:SetPoint("TOPLEFT", 0, 0); title:SetText(label)
    wrap.title = title
    local value = wrap:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    value:SetPoint("TOPRIGHT", 0, 0); wrap.value = value
    local sl = CreateFrame("Slider", nil, wrap)
    sl:SetSize(width, 14); sl:SetPoint("TOPLEFT", 0, -16)
    sl:SetOrientation("HORIZONTAL"); sl:SetMinMaxValues(lo, hi); sl:SetValueStep(step)
    if sl.SetObeyStepOnDrag then sl:SetObeyStepOnDrag(true) end
    sl:EnableMouse(true)
    -- Track
    local track = sl:CreateTexture(nil, "BACKGROUND")
    track:SetPoint("TOPLEFT", 0, -4); track:SetPoint("BOTTOMRIGHT", 0, 4)
    track:SetColorTexture(0.08, 0.09, 0.12, 1); wrap._track = track
    -- Fill (teal)
    local fill = sl:CreateTexture(nil, "BACKGROUND", nil, 1)
    fill:SetPoint("TOPLEFT", track, "TOPLEFT"); fill:SetHeight(6)
    fill:SetColorTexture(rgb(C.accent), 0.50); wrap._fill = fill
    -- Thumb
    local th = sl:CreateTexture(nil, "OVERLAY")
    th:SetSize(10, 16); th:SetColorTexture(rgb(C.accent), 0.9)
    sl:SetThumbTexture(th); wrap._thumb = th
    sl:SetScript("OnValueChanged", function(self, val)
        val = math.floor(val / step + 0.5) * step
        HideChatDB[key] = val
        value:SetText(fmt and fmt(val) or tostring(val))
        local mn, mx = self:GetMinMaxValues()
        local pct = (mx > mn) and ((val - mn) / (mx - mn)) or 0
        fill:SetWidth(math.max(1, track:GetWidth() * pct))
    end)
    wrap.slider = sl; wrap._key = key
    function wrap:SetOptionEnabled(on)
        if on then
            self.slider:EnableMouse(true)
            self.title:SetFontObject("GameFontHighlight"); self.value:SetFontObject("GameFontHighlight")
            self._thumb:SetColorTexture(rgb(C.accent), 0.9)
            self._track:SetColorTexture(0.08, 0.09, 0.12, 1)
        else
            self.slider:EnableMouse(false)
            self.title:SetFontObject("GameFontDisable"); self.value:SetFontObject("GameFontDisable")
            self._thumb:SetColorTexture(0.22, 0.24, 0.28, 0.7)
            self._track:SetColorTexture(0.06, 0.07, 0.09, 1)
        end
    end
    return wrap
end

local function Btn(parent, label, x, y, w, onClick)
    local b = CreateFrame("Button", nil, parent)
    b:SetSize(w, 24); b:SetPoint("TOPLEFT", x, y)
    -- Border
    local bd = b:CreateTexture(nil, "BACKGROUND", nil, -1)
    bd:SetPoint("TOPLEFT", -1, 1); bd:SetPoint("BOTTOMRIGHT", 1, -1)
    bd:SetColorTexture(rgb(C.btnBrd), 0.5)
    -- Bg
    local bg = b:CreateTexture(nil, "BACKGROUND"); bg:SetAllPoints()
    bg:SetColorTexture(rgb(C.btnBg), 0.9)
    -- Hover
    local hl = b:CreateTexture(nil, "HIGHLIGHT"); hl:SetAllPoints()
    hl:SetColorTexture(rgb(C.accent), 0.08)
    -- Label
    local t = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    t:SetPoint("CENTER"); t:SetText(label); b.label = t
    b:SetScript("OnClick", onClick)
    return b
end

---------------------------------------------------------------------------
-- Dependency refreshes
---------------------------------------------------------------------------
local function RefreshDeps()
    if not widgets then return end
    if widgets.combatRestore   then widgets.combatRestore:SetOptionEnabled(HideChatDB.combat) end
    if widgets.fadeSlider       then widgets.fadeSlider:SetOptionEnabled(HideChatDB.fade) end
    if widgets.inactivityReshow then widgets.inactivityReshow:SetOptionEnabled(HideChatDB.inactivityTimer > 0) end
    for _, cb in ipairs(widgets.instChecks or {}) do
        cb:SetOptionEnabled(HideChatDB.instanceHide)
    end
end

---------------------------------------------------------------------------
-- Profile popups
---------------------------------------------------------------------------
StaticPopupDialogs = StaticPopupDialogs or {}
StaticPopupDialogs["HIDECHAT_NEW_PROFILE"] = {
    text = "HideChat – New profile name:",
    button1 = "Create", button2 = "Cancel", hasEditBox = true,
    OnAccept = function(self)
        local n = self.editBox:GetText()
        if n and n ~= "" then
            ns.CreateProfile(n)
            if ns.ToggleConfig then ns.ToggleConfig(); ns.ToggleConfig() end
        end
    end,
    timeout = 0, whileDead = true, hideOnEscape = true,
}
StaticPopupDialogs["HIDECHAT_DELETE_PROFILE"] = {
    text = "HideChat – Delete profile \"%s\"?",
    button1 = "Delete", button2 = "Cancel",
    OnAccept = function()
        ns.DeleteProfile(HideChatCharDB.activeProfile)
        if ns.ToggleConfig then ns.ToggleConfig(); ns.ToggleConfig() end
    end,
    timeout = 0, whileDead = true, hideOnEscape = true,
}

---------------------------------------------------------------------------
-- Build config frame
---------------------------------------------------------------------------
function ns.InitConfig()
    if frame then return end

    -- Init tables BEFORE frame creation so a partial failure
    -- doesn't leave them nil while frame is already set.
    checkboxes = {}
    widgets    = { instChecks = {} }

    local FW, FH = 400, 600
    local CW = FW - 52

    frame = CreateFrame("Frame", "HideChatConfigFrame", UIParent)
    frame:SetSize(FW, FH); frame:SetPoint("CENTER")
    frame:Hide(); frame:SetFrameStrata("DIALOG")
    frame:SetMovable(true); frame:SetClampedToScreen(true); frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)

    -- Solid dark background (no WoW dialog textures)
    local bg = frame:CreateTexture(nil, "BACKGROUND", nil, -8)
    bg:SetAllPoints(); bg:SetColorTexture(rgb(C.bg), 0.98)

    -- Frame border
    BoxBorder(frame, rgb(C.border), 0.55)

    -- ==================== TITLE BAR ====================
    local titleBg = frame:CreateTexture(nil, "ARTWORK")
    titleBg:SetHeight(50); titleBg:SetPoint("TOPLEFT", 1, -1); titleBg:SetPoint("TOPRIGHT", -1, -1)
    titleBg:SetColorTexture(0.04, 0.05, 0.07, 1)

    -- Teal accent line
    local accent = HLine(frame, "ARTWORK", 1, 2, rgb(C.accent), 0.75)
    accent:SetPoint("TOPLEFT", titleBg, "BOTTOMLEFT")
    accent:SetPoint("TOPRIGHT", titleBg, "BOTTOMRIGHT")

    -- Title text  (teal "HideChat" + dim "Settings")
    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 14, -12)
    title:SetText("|cFF2DD4BFHideChat|r")

    local sub = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    sub:SetPoint("TOPLEFT", title, "TOPRIGHT", 6, -2)
    sub:SetText("|cFF888888Settings|r")

    local ver = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    ver:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -2)
    ver:SetText("|cFF555555v" .. (ns.version or "?") .. "|r")

    -- Close button
    local closeBtn = CreateFrame("Button", nil, frame)
    closeBtn:SetSize(26, 26); closeBtn:SetPoint("TOPRIGHT", -8, -8)
    local cBg = closeBtn:CreateTexture(nil, "BACKGROUND")
    cBg:SetAllPoints(); cBg:SetColorTexture(rgb(C.danger), 0.15)
    local cHl = closeBtn:CreateTexture(nil, "HIGHLIGHT")
    cHl:SetAllPoints(); cHl:SetColorTexture(rgb(C.danger), 0.35)
    local cTxt = closeBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    cTxt:SetPoint("CENTER", 0, 0); cTxt:SetText("|cFFCC6666x|r")
    closeBtn:SetScript("OnClick", function() ns.ToggleConfig() end)

    table.insert(UISpecialFrames, "HideChatConfigFrame")

    -- ==================== SCROLL ====================
    local scroll = CreateFrame("ScrollFrame", "HideChatConfigScroll", frame)
    scroll:SetPoint("TOPLEFT", 10, -56); scroll:SetPoint("BOTTOMRIGHT", -28, 10)

    content = CreateFrame("Frame", "HideChatConfigContent", scroll)
    content:SetSize(CW, 1060)
    scroll:SetScrollChild(content)

    -- Manual scrollbar (replaces removed UIPanelScrollFrameTemplate)
    local bar = CreateFrame("Slider", nil, scroll, "BackdropTemplate")
    bar:SetWidth(14); bar:SetPoint("TOPRIGHT", frame, -8, -56)
    bar:SetPoint("BOTTOMRIGHT", frame, -8, 10)
    bar:SetMinMaxValues(0, 1); bar:SetValueStep(1)
    bar:SetBackdrop({ bgFile = "Interface\\Buttons\\UI-SliderBar-Background",
        edgeFile = "Interface\\Buttons\\UI-SliderBar-Border",
        edgeSize = 8, tile = true, tileSize = 8,
        insets = { left = 3, right = 3, top = 3, bottom = 3 } })
    local thumb = bar:CreateTexture(nil, "OVERLAY")
    thumb:SetSize(14, 24)
    thumb:SetTexture("Interface\\Buttons\\UI-ScrollBar-Knob")
    bar:SetThumbTexture(thumb)

    local function UpdateScrollRange()
        local visH = scroll:GetHeight()
        local childH = content:GetHeight()
        local maxScroll = math.max(childH - visH, 0)
        bar:SetMinMaxValues(0, maxScroll)
    end
    scroll:SetScript("OnSizeChanged", UpdateScrollRange)
    content:SetScript("OnSizeChanged", UpdateScrollRange)

    bar:SetScript("OnValueChanged", function(_, val)
        scroll:SetVerticalScroll(val)
    end)
    scroll:SetScript("OnMouseWheel", function(_, delta)
        local cur = bar:GetValue()
        local step = 40
        bar:SetValue(cur - delta * step)
    end)
    scroll:EnableMouseWheel(true)

    -- ==================== CONTENT ====================
    local PAD = 8   -- card inner padding
    local Y = 0

    ---- CARD: General ────────────────────────────────────────
    local c1 = Card(content, "General", 0, Y, CW, 150)
    local y1 = -26
    checkboxes.showButton = Checkbox(c1, "Show toggle button", PAD, y1,
        "showButton", function() if ns.UpdateButton then ns.UpdateButton() end end)
    y1 = y1 - 26
    checkboxes.lockButton = Checkbox(c1, "Lock button position", PAD, y1, "lockButton")
    y1 = y1 - 28
    Btn(c1, "Reset Position", PAD + 26, y1, 120, function()
        if ns.ResetButtonPos then ns.ResetButtonPos() end
    end)
    y1 = y1 - 30
    checkboxes.showMinimap = Checkbox(c1, "Show minimap button", PAD, y1,
        "showMinimap", function() if ns.UpdateMinimap then ns.UpdateMinimap() end end)
    Y = Y - 158

    ---- CARD: Combat ─────────────────────────────────────────
    local c2 = Card(content, "Combat", 0, Y, CW, 82)
    checkboxes.combat = Checkbox(c2, "Auto-hide in combat", PAD, -26,
        "combat", function() RefreshDeps() end)
    checkboxes.combatRestore = Checkbox(c2, "Auto-show after combat", PAD, -52, "combatRestore")
    widgets.combatRestore = checkboxes.combatRestore
    Y = Y - 90

    ---- CARD: Automation ─────────────────────────────────────
    local c3 = Card(content, "Automation", 0, Y, CW, 210)
    local y3 = -26
    checkboxes.instanceHide = Checkbox(c3, "Auto-hide in instances", PAD, y3,
        "instanceHide", function() RefreshDeps() end)
    y3 = y3 - 26
    local instLabels = { party="Dungeons", raid="Raids", pvp="PvP", arena="Arenas", scenario="Scenarios" }
    local instOrder  = { "party", "raid", "pvp", "arena", "scenario" }
    local ix = PAD + 26
    for _, key in ipairs(instOrder) do
        local cb = InstanceCheckbox(c3, instLabels[key], ix, y3, key)
        widgets.instChecks[#widgets.instChecks + 1] = cb
        ix = ix + 78
        if ix > CW - 60 then ix = PAD + 26; y3 = y3 - 22 end
    end
    y3 = y3 - 34
    widgets.inactSlider = Slider(c3, "Inactivity timer", PAD + 8, y3, 200,
        0, 60, 5, "inactivityTimer",
        function(v) return v == 0 and "off" or (v .. "s") end)
    y3 = y3 - 40
    checkboxes.inactivityReshow = Checkbox(c3, "Show chat on new message", PAD + 8, y3,
        "inactivityReshow")
    widgets.inactivityReshow = checkboxes.inactivityReshow
    y3 = y3 - 28
    checkboxes.screenshotHide = Checkbox(c3, "Hide chat during screenshots", PAD, y3,
        "screenshotHide")
    Y = Y - 218

    ---- CARD: Appearance ─────────────────────────────────────
    local c4 = Card(content, "Appearance", 0, Y, CW, 175)
    local y4 = -26
    checkboxes.fade = Checkbox(c4, "Fade transition", PAD, y4,
        "fade", function() RefreshDeps() end)
    y4 = y4 - 30
    widgets.fadeSlider = Slider(c4, "Fade duration", PAD + 8, y4, 200,
        0.1, 1.0, 0.1, "fadeDuration",
        function(v) return string.format("%.1fs", v) end)
    y4 = y4 - 42
    widgets.opacSlider = Slider(c4, "Hidden opacity", PAD + 8, y4, 200,
        0, 1.0, 0.05, "opacity",
        function(v) return math.floor(v * 100) .. "%" end)
    y4 = y4 - 42
    checkboxes.mouseoverReveal = Checkbox(c4, "Show on mouse-over", PAD, y4,
        "mouseoverReveal")
    Y = Y - 183

    ---- CARD: Chat ───────────────────────────────────────────
    local c5 = Card(content, "Chat", 0, Y, CW, 108)
    local y5 = -26
    checkboxes.whisperNotify = Checkbox(c5, "Blink button on whisper", PAD, y5,
        "whisperNotify")
    y5 = y5 - 26
    checkboxes.whisperPass = Checkbox(c5, "Show whispers while hidden", PAD, y5,
        "whisperPass")
    y5 = y5 - 26
    checkboxes.keepCombatLog = Checkbox(c5, "Keep combat log visible", PAD, y5,
        "keepCombatLog", function()
            if ns.isHidden then ns.ShowChat(true); ns.HideChat(true) end
        end)
    Y = Y - 116

    ---- CARD: Compatibility ──────────────────────────────────
    local c6 = Card(content, "Compatibility", 0, Y, CW, 54)
    checkboxes.alphaMode = Checkbox(c6, "Alpha mode (Chattynator / Prat / ElvUI)",
        PAD, -26, "alphaMode", function()
            if ns.isHidden then ns.ShowChat(true); ns.HideChat(true) end
        end)
    Y = Y - 62

    ---- CARD: Profiles ───────────────────────────────────────
    local c7 = Card(content, "Profiles", 0, Y, CW, 92)
    local profLabel = c7:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    profLabel:SetPoint("TOPLEFT", PAD, -28); profLabel:SetText("Active: Default")
    widgets.profLabel = profLabel

    Btn(c7, "<", 200, -26, 28, function()
        local names = ns.GetProfileNames()
        if #names < 2 then return end
        local cur = HideChatCharDB.activeProfile
        for i, n in ipairs(names) do
            if n == cur then
                ns.SaveCurrentProfile()
                ns.LoadProfile(names[i == 1 and #names or (i - 1)])
                if ns.ToggleConfig then ns.ToggleConfig(); ns.ToggleConfig() end
                return
            end
        end
    end)
    Btn(c7, ">", 232, -26, 28, function()
        local names = ns.GetProfileNames()
        if #names < 2 then return end
        local cur = HideChatCharDB.activeProfile
        for i, n in ipairs(names) do
            if n == cur then
                ns.SaveCurrentProfile()
                ns.LoadProfile(names[i == #names and 1 or (i + 1)])
                if ns.ToggleConfig then ns.ToggleConfig(); ns.ToggleConfig() end
                return
            end
        end
    end)

    Btn(c7, "New", PAD, -60, 68, function()
        StaticPopup_Show("HIDECHAT_NEW_PROFILE")
    end)
    Btn(c7, "Copy", PAD + 74, -60, 68, function()
        StaticPopup_Show("HIDECHAT_NEW_PROFILE")
    end)
    Btn(c7, "Delete", PAD + 148, -60, 68, function()
        local name = HideChatCharDB.activeProfile
        if name == "Default" then
            print("|cFF2DD4BFHideChat:|r Cannot delete Default profile."); return
        end
        StaticPopup_Show("HIDECHAT_DELETE_PROFILE", name)
    end)
    Y = Y - 100

    ---- HINT TEXT ────────────────────────────────────────────
    Y = Y - 10
    local hint = content:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    hint:SetPoint("TOPLEFT", 4, Y); hint:SetWidth(CW - 10); hint:SetJustifyH("LEFT")
    hint:SetText(
        "|cFF555555/hidechat|r  or  |cFF555555/hc|r — toggle\n" ..
        "|cFF555555/hc config|r — settings\n" ..
        "|cFF555555/hc status|r — diagnostics\n" ..
        "|cFF555555/hc reset|r  — restore defaults"
    )

    content:SetHeight(math.abs(Y) + 80)
    frame:Hide()
end

---------------------------------------------------------------------------
-- Refresh widgets to match HideChatDB
---------------------------------------------------------------------------
local function Refresh()
    if not frame or not checkboxes then return end
    for _, cb in pairs(checkboxes) do
        cb:SetChecked(HideChatDB[cb._key])
        if cb._mark then cb._mark:SetText(cb:GetChecked() and "|cFF2DD4BF✓|r" or "") end
    end
    for _, cb in ipairs(widgets.instChecks) do
        cb:SetChecked(HideChatDB.instanceTypes[cb._subKey])
        if cb._mark then cb._mark:SetText(cb:GetChecked() and "|cFF2DD4BF✓|r" or "") end
    end
    if widgets.fadeSlider  then widgets.fadeSlider.slider:SetValue(HideChatDB.fadeDuration) end
    if widgets.opacSlider  then widgets.opacSlider.slider:SetValue(HideChatDB.opacity or 0) end
    if widgets.inactSlider then widgets.inactSlider.slider:SetValue(HideChatDB.inactivityTimer) end
    if widgets.profLabel then
        widgets.profLabel:SetText("Active: |cFFFFFFFF" ..
            (HideChatCharDB.activeProfile or "Default") .. "|r")
    end
    RefreshDeps()
end

---------------------------------------------------------------------------
function ns.ToggleConfig()
    if not frame then ns.InitConfig() end
    if frame:IsShown() then ns.SaveCurrentProfile(); frame:Hide()
    else Refresh(); frame:Show() end
end
