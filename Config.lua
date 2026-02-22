local addonName, ns = ...
local L = ns.L

local frame, content, checkboxes, widgets

---------------------------------------------------------------------------
-- THEME
---------------------------------------------------------------------------
local C = {
    accent   = { 0.18, 0.83, 0.75 },
    accentLo = { 0.10, 0.40, 0.35 },
    bg       = { 0.06, 0.06, 0.08 },
    cardBg   = { 0.08, 0.09, 0.12 },
    headerBg = { 0.05, 0.05, 0.07 },
    border   = { 0.15, 0.16, 0.20 },
    borderLt = { 0.22, 0.24, 0.30 },
    text     = { 0.88, 0.90, 0.93 },
    dim      = { 0.50, 0.52, 0.56 },
    danger   = { 0.85, 0.30, 0.30 },
    btnBg    = { 0.10, 0.11, 0.15 },
    btnBrd   = { 0.18, 0.20, 0.26 },
}

local sct = ns.sct

-- WoW-safe checkbox texture (renders as actual checkmark, not a square)
local CHECK_TEXTURE = "Interface\\Buttons\\UI-CheckBox-Check"

---------------------------------------------------------------------------
-- Draw helpers
---------------------------------------------------------------------------
local function MakeBorder(f, r, g, b, a, inset)
    if type(r) == "table" then a, r, g, b = g, r[1], r[2], r[3] end
    inset = inset or 0
    local t
    t = f:CreateTexture(nil, "BORDER"); sct(t, r, g, b, a or 0.5)
    t:SetHeight(1); t:SetPoint("TOPLEFT", inset, -inset); t:SetPoint("TOPRIGHT", -inset, -inset)
    t = f:CreateTexture(nil, "BORDER"); sct(t, r, g, b, a or 0.5)
    t:SetHeight(1); t:SetPoint("BOTTOMLEFT", inset, inset); t:SetPoint("BOTTOMRIGHT", -inset, inset)
    t = f:CreateTexture(nil, "BORDER"); sct(t, r, g, b, a or 0.5)
    t:SetWidth(1); t:SetPoint("TOPLEFT", inset, -inset); t:SetPoint("BOTTOMLEFT", inset, inset)
    t = f:CreateTexture(nil, "BORDER"); sct(t, r, g, b, a or 0.5)
    t:SetWidth(1); t:SetPoint("TOPRIGHT", -inset, -inset); t:SetPoint("BOTTOMRIGHT", -inset, inset)
end

---------------------------------------------------------------------------
-- Card
---------------------------------------------------------------------------
local function Card(parent, title, x, y, w, h)
    local card = CreateFrame("Frame", nil, parent)
    card:SetSize(w, h); card:SetPoint("TOPLEFT", x, y)

    local bg = card:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(); sct(bg, C.cardBg, 1)

    -- Teal accent at top
    local acc = card:CreateTexture(nil, "ARTWORK", nil, 1)
    acc:SetHeight(2); acc:SetPoint("TOPLEFT"); acc:SetPoint("TOPRIGHT")
    sct(acc, C.accent, 0.75)

    MakeBorder(card, C.border, 0.40)

    if title then
        local hdr = card:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        hdr:SetPoint("TOPLEFT", 12, -8)
        hdr:SetText("|cFF2DD4BF" .. title .. "|r")
    end
    return card
end

---------------------------------------------------------------------------
-- Checkbox  (uses WoW's built-in check texture - no Unicode)
---------------------------------------------------------------------------
local function Checkbox(parent, label, x, y, key, onToggle)
    local cb = CreateFrame("CheckButton", nil, parent)
    cb:SetSize(22, 22); cb:SetPoint("TOPLEFT", x, y)

    -- Border
    local brd = cb:CreateTexture(nil, "BACKGROUND", nil, -1)
    brd:SetSize(18, 18); brd:SetPoint("LEFT", 2, 0)
    sct(brd, C.borderLt, 0.60)

    -- Inner box
    local box = cb:CreateTexture(nil, "BACKGROUND")
    box:SetSize(16, 16); box:SetPoint("CENTER", brd)
    sct(box, 0.06, 0.07, 0.10, 1)

    -- Teal fill when checked
    local fill = cb:CreateTexture(nil, "ARTWORK", nil, 0)
    fill:SetSize(16, 16); fill:SetPoint("CENTER", box)
    sct(fill, C.accent, 0.20)
    fill:Hide()

    -- WoW checkmark texture (tinted teal)
    local mark = cb:CreateTexture(nil, "ARTWORK", nil, 1)
    mark:SetSize(24, 24); mark:SetPoint("CENTER", box, 0, 0)
    mark:SetTexture(CHECK_TEXTURE)
    mark:SetVertexColor(C.accent[1], C.accent[2], C.accent[3], 1)
    mark:Hide()
    cb._mark = mark
    cb._fill = fill

    -- Hover
    local hl = cb:CreateTexture(nil, "HIGHLIGHT")
    hl:SetSize(16, 16); hl:SetPoint("CENTER", box)
    sct(hl, 1, 1, 1, 0.06)

    local function syncMark(self)
        if self:GetChecked() then self._mark:Show(); self._fill:Show()
        else self._mark:Hide(); self._fill:Hide() end
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

    local brd = cb:CreateTexture(nil, "BACKGROUND", nil, -1)
    brd:SetSize(14, 14); brd:SetPoint("LEFT", 1, 0)
    sct(brd, C.borderLt, 0.50)
    local box = cb:CreateTexture(nil, "BACKGROUND")
    box:SetSize(12, 12); box:SetPoint("CENTER", brd)
    sct(box, 0.06, 0.07, 0.10, 1)

    local fill = cb:CreateTexture(nil, "ARTWORK", nil, 0)
    fill:SetSize(12, 12); fill:SetPoint("CENTER", box)
    sct(fill, C.accent, 0.20)
    fill:Hide()

    local mark = cb:CreateTexture(nil, "ARTWORK", nil, 1)
    mark:SetSize(20, 20); mark:SetPoint("CENTER", box, 0, 0)
    mark:SetTexture(CHECK_TEXTURE)
    mark:SetVertexColor(C.accent[1], C.accent[2], C.accent[3], 1)
    mark:Hide()
    cb._mark = mark
    cb._fill = fill

    local hl = cb:CreateTexture(nil, "HIGHLIGHT")
    hl:SetSize(12, 12); hl:SetPoint("CENTER", box)
    sct(hl, 1, 1, 1, 0.06)

    local function syncMark(self)
        if self:GetChecked() then self._mark:Show(); self._fill:Show()
        else self._mark:Hide(); self._fill:Hide() end
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

---------------------------------------------------------------------------
-- Slider
---------------------------------------------------------------------------
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
    track:SetPoint("TOPLEFT", 0, -3); track:SetPoint("BOTTOMRIGHT", 0, 3)
    sct(track, 0.04, 0.04, 0.06, 1)
    wrap._track = track

    -- Fill
    local fill = sl:CreateTexture(nil, "BACKGROUND", nil, 1)
    fill:SetPoint("TOPLEFT", track, "TOPLEFT"); fill:SetHeight(8)
    sct(fill, C.accent, 0.40)
    wrap._fill = fill

    -- Thumb
    local th = sl:CreateTexture(nil, "OVERLAY")
    th:SetSize(10, 16); sct(th, C.accent, 0.85)
    sl:SetThumbTexture(th); wrap._thumb = th

    sl:SetScript("OnValueChanged", function(self, val)
        val = math.floor(val / step + 0.5) * step
        val = math.max(lo, math.min(val, hi))
        HideChatDB[key] = val
        value:SetText("|cFF2DD4BF" .. (fmt and fmt(val) or tostring(val)) .. "|r")
        local mn, mx = self:GetMinMaxValues()
        local pct = (mx > mn) and ((val - mn) / (mx - mn)) or 0
        fill:SetWidth(math.max(1, track:GetWidth() * pct))
    end)

    wrap.slider = sl; wrap._key = key
    function wrap:SetOptionEnabled(on)
        if on then
            self.slider:EnableMouse(true)
            self.title:SetFontObject("GameFontHighlight")
            self.value:SetFontObject("GameFontHighlight")
            sct(self._thumb, C.accent, 0.85)
            sct(self._track, 0.04, 0.04, 0.06, 1)
            sct(self._fill, C.accent, 0.40)
        else
            self.slider:EnableMouse(false)
            self.title:SetFontObject("GameFontDisable")
            self.value:SetFontObject("GameFontDisable")
            sct(self._thumb, 0.20, 0.22, 0.26, 0.6)
            sct(self._track, 0.04, 0.04, 0.06, 1)
            sct(self._fill, 0.12, 0.14, 0.18, 0.4)
        end
    end
    return wrap
end

---------------------------------------------------------------------------
-- Button (style: "default" | "accent" | "danger")
---------------------------------------------------------------------------
local function Btn(parent, label, x, y, w, onClick, style)
    style = style or "default"
    local b = CreateFrame("Button", nil, parent)
    b:SetSize(w, 24); b:SetPoint("TOPLEFT", x, y)

    local bd = b:CreateTexture(nil, "BACKGROUND", nil, -1)
    bd:SetPoint("TOPLEFT", -1, 1); bd:SetPoint("BOTTOMRIGHT", 1, -1)
    sct(bd, style == "accent" and C.accentLo or (style == "danger" and {0.40, 0.15, 0.15} or C.btnBrd), 0.50)

    local bg = b:CreateTexture(nil, "BACKGROUND"); bg:SetAllPoints()
    sct(bg, style == "accent" and C.accentLo or (style == "danger" and {0.20, 0.08, 0.08} or C.btnBg), style == "default" and 0.90 or 0.70)

    local hl = b:CreateTexture(nil, "HIGHLIGHT"); hl:SetAllPoints()
    sct(hl, style == "accent" and C.accent or (style == "danger" and C.danger or {1,1,1}),
        style == "default" and 0.07 or 0.12)

    local t = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    t:SetPoint("CENTER")
    if style == "accent" then t:SetText("|cFF2DD4BF" .. label .. "|r")
    elseif style == "danger" then t:SetText("|cFFE06666" .. label .. "|r")
    else t:SetText(label) end
    b.label = t
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
StaticPopupDialogs["HIDECHAT_NEW_PROFILE"] = {
    text = L["HideChat - New profile name:"],
    button1 = L["Create"], button2 = L["Cancel"], hasEditBox = true,
    OnAccept = function(self)
        local eb = self.EditBox or self.editBox
        local n = eb and eb:GetText()
        if n and n ~= "" then
            if ns.CreateProfile(n) then
                if ns.ToggleConfig then ns.ToggleConfig(); ns.ToggleConfig() end
            end
        end
    end,
    timeout = 0, whileDead = true, hideOnEscape = true,
}
StaticPopupDialogs["HIDECHAT_COPY_PROFILE"] = {
    text = L["HideChat - Copy current profile to:"],
    button1 = L["Copy"], button2 = L["Cancel"], hasEditBox = true,
    OnShow = function(self)
        local eb = self.EditBox or self.editBox
        if eb then eb:SetText((HideChatCharDB.activeProfile or "Default") .. " (Copy)") end
    end,
    OnAccept = function(self)
        local eb = self.EditBox or self.editBox
        local n = eb and eb:GetText()
        if n and n ~= "" then
            if ns.CreateProfile(n) then
                if ns.ToggleConfig then ns.ToggleConfig(); ns.ToggleConfig() end
            end
        end
    end,
    timeout = 0, whileDead = true, hideOnEscape = true,
}
StaticPopupDialogs["HIDECHAT_RENAME_PROFILE"] = {
    text = L["HideChat - Rename profile \"%s\" to:"],
    button1 = L["Rename"], button2 = L["Cancel"], hasEditBox = true,
    OnShow = function(self)
        local eb = self.EditBox or self.editBox
        if eb then eb:SetText(HideChatCharDB.activeProfile or "") end
    end,
    OnAccept = function(self)
        local eb = self.EditBox or self.editBox
        local n = eb and eb:GetText()
        if n and n ~= "" then
            if ns.RenameProfile(HideChatCharDB.activeProfile, n) then
                if ns.ToggleConfig then ns.ToggleConfig(); ns.ToggleConfig() end
            end
        end
    end,
    timeout = 0, whileDead = true, hideOnEscape = true,
}
StaticPopupDialogs["HIDECHAT_DELETE_PROFILE"] = {
    text = L["HideChat - Delete profile \"%s\"?"],
    button1 = L["Delete"], button2 = L["Cancel"],
    OnAccept = function()
        ns.DeleteProfile(HideChatCharDB.activeProfile)
        if ns.ToggleConfig then ns.ToggleConfig(); ns.ToggleConfig() end
    end,
    timeout = 0, whileDead = true, hideOnEscape = true,
}
StaticPopupDialogs["HIDECHAT_RESET_ALL"] = {
    text = L["HideChat - Reset all settings to defaults?"],
    button1 = L["Reset"], button2 = L["Cancel"],
    OnAccept = function()
        SlashCmdList["HIDECHAT"]("reset")
    end,
    timeout = 0, whileDead = true, hideOnEscape = true,
}
StaticPopupDialogs["HIDECHAT_IMPORT_PROFILE"] = {
    text = L["HideChat - Paste import string:"],
    button1 = L["Import"], button2 = L["Cancel"], hasEditBox = true,
    OnAccept = function(self)
        local eb = self.EditBox or self.editBox
        local str = eb and eb:GetText()
        if str and str ~= "" then
            if ns.ImportProfile(str) then
                if ns.ToggleConfig then ns.ToggleConfig(); ns.ToggleConfig() end
            end
        end
    end,
    timeout = 0, whileDead = true, hideOnEscape = true,
}
StaticPopupDialogs["HIDECHAT_EXPORT_PROFILE"] = {
    text = L["HideChat - Export string (copy this):"],
    button1 = L["OK"], hasEditBox = true,
    OnShow = function(self)
        local eb = self.EditBox or self.editBox
        if eb then
            local str = ns.ExportProfile() or ""
            eb:SetText(str)
            eb:HighlightText()
        end
    end,
    timeout = 0, whileDead = true, hideOnEscape = true,
}

---------------------------------------------------------------------------
-- Build config frame
---------------------------------------------------------------------------
function ns.InitConfig()
    if frame then return end

    checkboxes = {}
    widgets    = { instChecks = {} }

    local FW, FH = 440, 640
    local CW = FW - 44

    local f = CreateFrame("Frame", "HideChatConfigFrame", UIParent)
    f:SetSize(FW, FH)
    local pos = HideChatDB.configPos
    if pos then
        f:SetPoint(pos.point, UIParent, pos.point, pos.x, pos.y)
    else
        f:SetPoint("CENTER")
    end
    f:Hide(); f:SetFrameStrata("DIALOG")
    f:SetMovable(true); f:SetClampedToScreen(true); f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local pt, _, _, x, y = self:GetPoint()
        HideChatDB.configPos = { point = pt, x = x, y = y }
    end)
    f:SetScript("OnHide", function() ns.SaveCurrentProfile() end)

    -- Shadow
    local shadow = f:CreateTexture(nil, "BACKGROUND", nil, -8)
    shadow:SetPoint("TOPLEFT", -4, 4); shadow:SetPoint("BOTTOMRIGHT", 4, -4)
    sct(shadow, 0, 0, 0, 0.45)

    -- Background
    local bg = f:CreateTexture(nil, "BACKGROUND", nil, -5)
    bg:SetAllPoints(); sct(bg, C.bg, 1)

    -- Border
    MakeBorder(f, C.border, 0.60)

    -- ==================== TITLE BAR ====================
    local titleH = 52
    local titleBg = f:CreateTexture(nil, "ARTWORK")
    titleBg:SetHeight(titleH); titleBg:SetPoint("TOPLEFT", 1, -1); titleBg:SetPoint("TOPRIGHT", -1, -1)
    sct(titleBg, C.headerBg[1], C.headerBg[2], C.headerBg[3], 1)

    -- Accent line
    local accent = f:CreateTexture(nil, "ARTWORK", nil, 1)
    accent:SetHeight(2)
    accent:SetPoint("TOPLEFT", titleBg, "BOTTOMLEFT")
    accent:SetPoint("TOPRIGHT", titleBg, "BOTTOMRIGHT")
    sct(accent, C.accent, 0.80)

    -- Title
    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 14, -10)
    title:SetText("|cFF2DD4BFHideChat|r  |cFF6B7280" .. L["Settings"] .. "|r")

    -- Version
    local ver = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    ver:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -2)
    ver:SetText("|cFF444444v" .. (ns.version or "?") .. "|r")

    -- Status text (right side)
    local statusDot = f:CreateTexture(nil, "OVERLAY")
    statusDot:SetSize(8, 8); statusDot:SetPoint("TOPRIGHT", -60, -18)
    widgets.statusDotTex = statusDot
    local statusText = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    statusText:SetPoint("RIGHT", statusDot, "LEFT", -4, 0)
    widgets.statusText = statusText

    local statusElapsed = 0
    f:SetScript("OnUpdate", function(_, dt)
        statusElapsed = statusElapsed + dt
        if statusElapsed < 0.25 then return end
        statusElapsed = 0
        if ns.isHidden then
            sct(widgets.statusDotTex, 0.85, 0.30, 0.30, 1)
            widgets.statusText:SetText("|cFFE06666" .. L["Hidden"] .. "|r")
        else
            sct(widgets.statusDotTex, 0.18, 0.83, 0.75, 1)
            widgets.statusText:SetText("|cFF2DD4BF" .. L["Visible"] .. "|r")
        end
    end)

    -- Close button
    local closeBtn = CreateFrame("Button", nil, f)
    closeBtn:SetSize(22, 22); closeBtn:SetPoint("TOPRIGHT", -8, -8)
    local cBg = closeBtn:CreateTexture(nil, "BACKGROUND")
    cBg:SetAllPoints(); sct(cBg, C.danger, 0.12)
    local cHl = closeBtn:CreateTexture(nil, "HIGHLIGHT")
    cHl:SetAllPoints(); sct(cHl, C.danger, 0.30)
    local cTxt = closeBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    cTxt:SetPoint("CENTER", 0, 0); cTxt:SetText("|cFFCC5555X|r")
    closeBtn:SetScript("OnClick", function() ns.ToggleConfig() end)

    table.insert(UISpecialFrames, "HideChatConfigFrame")

    -- ==================== SCROLL ====================
    local scrollTop = titleH + 6
    local scroll = CreateFrame("ScrollFrame", "HideChatConfigScroll", f)
    scroll:SetPoint("TOPLEFT", 10, -scrollTop)
    scroll:SetPoint("BOTTOMRIGHT", -20, 10)

    content = CreateFrame("Frame", "HideChatConfigContent", scroll)
    content:SetSize(CW, 1800)
    scroll:SetScrollChild(content)

    -- Scrollbar
    local bar = CreateFrame("Slider", nil, scroll)
    bar:SetWidth(5); bar:SetPoint("TOPRIGHT", f, -9, -(scrollTop + 2))
    bar:SetPoint("BOTTOMRIGHT", f, -9, 12)
    bar:SetMinMaxValues(0, 1); bar:SetValueStep(1)
    local barTrack = bar:CreateTexture(nil, "BACKGROUND")
    barTrack:SetAllPoints(); sct(barTrack, C.border, 0.30)
    local thumb = bar:CreateTexture(nil, "OVERLAY")
    thumb:SetSize(5, 36); sct(thumb, C.accent, 0.50)
    bar:SetThumbTexture(thumb)

    local function UpdateScrollRange()
        local visH = scroll:GetHeight()
        local childH = content:GetHeight()
        bar:SetMinMaxValues(0, math.max(childH - visH, 0))
    end
    scroll:SetScript("OnSizeChanged", UpdateScrollRange)
    content:SetScript("OnSizeChanged", UpdateScrollRange)
    bar:SetScript("OnValueChanged", function(_, val) scroll:SetVerticalScroll(val) end)
    scroll:SetScript("OnMouseWheel", function(_, delta)
        bar:SetValue(bar:GetValue() - delta * 40)
    end)
    scroll:EnableMouseWheel(true)

    -- ==================== CONTENT ====================
    local PAD  = 12
    local GAP  = 10
    local ROW  = 26
    local SROW = 40
    local Y    = 0

    ---- General ----------------------------------------------------------
    local c1 = Card(content, L["General"], 0, Y, CW, 184)
    local y1 = -28
    checkboxes.showButton = Checkbox(c1, L["Show toggle button"], PAD, y1,
        "showButton", function() if ns.UpdateButton then ns.UpdateButton() end end)
    y1 = y1 - ROW
    checkboxes.lockButton = Checkbox(c1, L["Lock button position"], PAD, y1, "lockButton")
    y1 = y1 - ROW
    Btn(c1, L["Reset Position"], PAD + 26, y1, 120, function()
        if ns.ResetButtonPos then ns.ResetButtonPos() end
    end)
    y1 = y1 - 30
    checkboxes.showMinimap = Checkbox(c1, L["Show minimap button"], PAD, y1,
        "showMinimap", function() if ns.UpdateMinimap then ns.UpdateMinimap() end end)
    y1 = y1 - ROW
    Btn(c1, L["Reset Minimap Pos"], PAD + 26, y1, 130, function()
        if ns.ResetMinimapPos then ns.ResetMinimapPos() end
    end)
    Y = Y - 184 - GAP

    ---- Combat -----------------------------------------------------------
    local c2 = Card(content, L["Combat"], 0, Y, CW, 108)
    local y2 = -28
    checkboxes.combat = Checkbox(c2, L["Auto-hide in combat"], PAD, y2,
        "combat", function() RefreshDeps() end)
    y2 = y2 - ROW
    checkboxes.combatRestore = Checkbox(c2, L["Auto-show after combat"], PAD, y2, "combatRestore")
    widgets.combatRestore = checkboxes.combatRestore
    y2 = y2 - ROW
    checkboxes.raidAutoShow = Checkbox(c2, L["Auto-show on ready-check / encounter"], PAD, y2, "raidAutoShow")
    Y = Y - 108 - GAP

    ---- Automation -------------------------------------------------------
    local c3 = Card(content, L["Automation"], 0, Y, CW, 188)
    local y3 = -28
    checkboxes.instanceHide = Checkbox(c3, L["Auto-hide in instances"], PAD, y3,
        "instanceHide", function() RefreshDeps() end)
    y3 = y3 - ROW
    local instLabels = { party=L["Dungeons"], raid=L["Raids"], pvp=L["PvP"], arena=L["Arenas"], scenario=L["Scenarios"] }
    local instOrder  = { "party", "raid", "pvp", "arena", "scenario" }
    local ix = PAD + 26
    for _, key in ipairs(instOrder) do
        local cb = InstanceCheckbox(c3, instLabels[key], ix, y3, key)
        widgets.instChecks[#widgets.instChecks + 1] = cb
        ix = ix + 78
        if ix > CW - 60 then ix = PAD + 26; y3 = y3 - 22 end
    end
    y3 = y3 - 34
    widgets.inactSlider = Slider(c3, L["Inactivity timer"], PAD + 8, y3, 210,
        0, 60, 5, "inactivityTimer",
        function(v) return v == 0 and L["off"] or (v .. "s") end)
    y3 = y3 - SROW
    checkboxes.inactivityReshow = Checkbox(c3, L["Show chat on new message"], PAD + 8, y3, "inactivityReshow")
    widgets.inactivityReshow = checkboxes.inactivityReshow
    Y = Y - 188 - GAP

    ---- Appearance -------------------------------------------------------
    local c4 = Card(content, L["Appearance"], 0, Y, CW, 210)
    local y4 = -28
    checkboxes.fade = Checkbox(c4, L["Fade transition (smooth easing)"], PAD, y4,
        "fade", function() RefreshDeps() end)
    y4 = y4 - 30
    widgets.fadeSlider = Slider(c4, L["Fade duration"], PAD + 8, y4, 210,
        0.1, 1.0, 0.1, "fadeDuration",
        function(v) return string.format("%.1fs", v) end)
    y4 = y4 - SROW
    widgets.opacSlider = Slider(c4, L["Hidden opacity"], PAD + 8, y4, 210,
        0, 1.0, 0.05, "opacity",
        function(v) return math.floor(v * 100) .. "%" end)
    y4 = y4 - SROW
    checkboxes.mouseoverReveal = Checkbox(c4, L["Show on mouse-over"], PAD, y4, "mouseoverReveal")
    y4 = y4 - ROW
    checkboxes.colorblind = Checkbox(c4, L["Colorblind mode (high contrast)"], PAD, y4,
        "colorblind", function()
            if ns.UpdateButton then ns.UpdateButton() end
            if ns.UpdateMinimap then ns.UpdateMinimap() end
        end)
    Y = Y - 210 - GAP

    ---- Chat -------------------------------------------------------------
    local c5 = Card(content, L["Chat"], 0, Y, CW, 186)
    local y5 = -28
    checkboxes.whisperNotify = Checkbox(c5, L["Blink button on whisper"], PAD, y5, "whisperNotify")
    y5 = y5 - ROW
    checkboxes.whisperPass = Checkbox(c5, L["Show whispers while hidden"], PAD, y5, "whisperPass")
    y5 = y5 - ROW
    checkboxes.whisperSound = Checkbox(c5, L["Play sound on whisper"], PAD, y5, "whisperSound")
    y5 = y5 - ROW
    checkboxes.keepCombatLog = Checkbox(c5, L["Keep combat log visible"], PAD, y5, "keepCombatLog")
    y5 = y5 - ROW
    checkboxes.screenshotHide = Checkbox(c5, L["Hide chat for screenshots"], PAD, y5, "screenshotHide")
    y5 = y5 - ROW
    checkboxes.scrollToRecent = Checkbox(c5, L["Scroll to recent on unhide"], PAD, y5, "scrollToRecent")
    Y = Y - 186 - GAP

    ---- Zone Memory ------------------------------------------------------
    local c_zone = Card(content, L["Zone Memory"], 0, Y, CW, 62)
    checkboxes.zoneMemoryEnabled = Checkbox(c_zone, L["Remember chat state per zone"], PAD, -28, "zoneMemoryEnabled")
    Btn(c_zone, L["Clear Memory"], CW - 108, -28, 94, function()
        HideChatDB.zoneMemory = {}
        print("|cFF2DD4BFHideChat:|r " .. L["Zone memory cleared."])
    end)
    Y = Y - 62 - GAP

    ---- Compatibility ----------------------------------------------------
    local c6 = Card(content, L["Compatibility"], 0, Y, CW, 82)
    checkboxes.alphaMode = Checkbox(c6, L["Alpha mode (Chattynator / Prat / ElvUI)"],
        PAD, -28, "alphaMode", function()
            if ns.isHidden then ns.ShowChat(true); ns.HideChat(true) end
            if widgets.addonNote then
                local addons = {}
                local iL = C_AddOns and C_AddOns.IsAddOnLoaded or IsAddOnLoaded
                if iL then
                    if pcall(iL, "Prat-3.0") and iL("Prat-3.0") then addons[#addons+1] = "Prat-3.0" end
                    if pcall(iL, "Chattynator") and iL("Chattynator") then addons[#addons+1] = "Chattynator" end
                end
                if _G["ElvUI"]     then addons[#addons+1] = "ElvUI" end
                if _G["GlassFrame"] then addons[#addons+1] = "Glass" end
                if #addons > 0 then
                    local list = table.concat(addons, ", ")
                    if not HideChatDB.alphaMode then
                        widgets.addonNote:SetText("|cFFE0A030" .. L["Detected:"] .. " " .. list .. " -- " .. L["enable Alpha mode"] .. "|r")
                    else
                        widgets.addonNote:SetText("|cFF666666" .. L["Detected:"] .. " " .. list .. "|r")
                    end
                end
            end
        end)
    do
        local detected = {}
        local iL = C_AddOns and C_AddOns.IsAddOnLoaded or IsAddOnLoaded
        if iL then
            if pcall(iL, "Prat-3.0") and iL("Prat-3.0") then detected[#detected+1] = "Prat-3.0" end
            if pcall(iL, "Chattynator") and iL("Chattynator") then detected[#detected+1] = "Chattynator" end
        end
        if _G["ElvUI"]     then detected[#detected+1] = "ElvUI" end
        if _G["GlassFrame"] then detected[#detected+1] = "Glass" end
        local note = c6:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
        note:SetPoint("TOPLEFT", PAD + 8, -54); note:SetWidth(CW - 24)
        note:SetJustifyH("LEFT")
        if #detected > 0 then
            local list = table.concat(detected, ", ")
            if not HideChatDB.alphaMode then
                note:SetText("|cFFE0A030" .. L["Detected:"] .. " " .. list .. " -- " .. L["enable Alpha mode"] .. "|r")
            else
                note:SetText("|cFF666666" .. L["Detected:"] .. " " .. list .. "|r")
            end
        else
            note:SetText("|cFF444444" .. L["No third-party chat addons detected"] .. "|r")
        end
        widgets.addonNote = note
    end
    Y = Y - 82 - GAP

    ---- Profiles ---------------------------------------------------------
    local c7 = Card(content, L["Profiles"], 0, Y, CW, 126)
    local y7 = -28
    local profLabel = c7:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    profLabel:SetPoint("TOPLEFT", PAD, y7); profLabel:SetText(L["Active:"] .. " Default")
    widgets.profLabel = profLabel

    Btn(c7, "<", 210, y7, 26, function()
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
    end, "accent")
    Btn(c7, ">", 240, y7, 26, function()
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
    end, "accent")

    y7 = y7 - 30
    local bx = PAD
    Btn(c7, L["New"], bx, y7, 56, function()
        StaticPopup_Show("HIDECHAT_NEW_PROFILE")
    end, "accent")
    bx = bx + 60
    Btn(c7, L["Copy"], bx, y7, 56, function()
        StaticPopup_Show("HIDECHAT_COPY_PROFILE")
    end, "accent")
    bx = bx + 60
    Btn(c7, L["Rename"], bx, y7, 64, function()
        local name = HideChatCharDB.activeProfile
        if name == "Default" then
            print("|cFF2DD4BFHideChat:|r " .. L["Cannot rename the Default profile."]); return
        end
        StaticPopup_Show("HIDECHAT_RENAME_PROFILE", name)
    end)
    bx = bx + 68
    Btn(c7, L["Delete"], bx, y7, 64, function()
        local name = HideChatCharDB.activeProfile
        if name == "Default" then
            print("|cFF2DD4BFHideChat:|r " .. L["Cannot delete Default profile."]); return
        end
        StaticPopup_Show("HIDECHAT_DELETE_PROFILE", name)
    end, "danger")

    y7 = y7 - 28
    bx = PAD
    Btn(c7, L["Export"], bx, y7, 64, function()
        StaticPopup_Show("HIDECHAT_EXPORT_PROFILE")
    end, "accent")
    bx = bx + 68
    Btn(c7, L["Import"], bx, y7, 64, function()
        StaticPopup_Show("HIDECHAT_IMPORT_PROFILE")
    end, "accent")

    local specNote = c7:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    specNote:SetPoint("TOPLEFT", bx + 76, y7 - 4); specNote:SetWidth(CW - bx - 90)
    specNote:SetJustifyH("LEFT")
    if GetSpecialization then
        local specIdx = GetSpecialization()
        local bound = HideChatDB.specProfiles and HideChatDB.specProfiles[specIdx]
        if bound then
            specNote:SetText("|cFF888888Spec " .. specIdx .. " -> " .. bound .. "|r")
        else
            specNote:SetText("|cFF555555" .. L["No spec binding"] .. "|r")
        end
    else
        specNote:SetText("|cFF555555" .. L["Spec profiles: retail only"] .. "|r")
    end
    widgets.specNote = specNote

    if GetSpecialization then
        Btn(c7, L["Bind to Spec"], bx + 68, y7, 90, function()
            local specIdx = GetSpecialization()
            if not specIdx then return end
            if not HideChatDB.specProfiles then HideChatDB.specProfiles = {} end
            local cur = HideChatCharDB.activeProfile or "Default"
            HideChatDB.specProfiles[specIdx] = cur
            print("|cFF2DD4BFHideChat:|r Spec " .. specIdx .. " bound to profile \"" .. cur .. "\".")
            if widgets.specNote then
                widgets.specNote:SetText("|cFF888888Spec " .. specIdx .. " -> " .. cur .. "|r")
            end
        end, "accent")
    end
    Y = Y - 126 - GAP

    ---- Reset + Commands -------------------------------------------------
    Y = Y - 4
    Btn(content, L["Reset All Settings"], 0, Y, 140, function()
        StaticPopup_Show("HIDECHAT_RESET_ALL")
    end, "danger")
    Y = Y - 36

    local hint = content:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    hint:SetPoint("TOPLEFT", 4, Y); hint:SetWidth(CW - 10); hint:SetJustifyH("LEFT")
    hint:SetSpacing(2)
    hint:SetText(
        "|cFF666666/hidechat|r  or  |cFF666666/hc|r  --  " .. L["toggle"] .. "\n" ..
        "|cFF666666/hc show  /  /hc hide|r  --  " .. L["force state"] .. "\n" ..
        "|cFF666666/hc config|r  --  " .. L["this panel"] .. "\n" ..
        "|cFF666666/hc status|r  --  " .. L["diagnostics"] .. "\n" ..
        "|cFF666666/hc debug|r  --  " .. L["detailed debug output"] .. "\n" ..
        "|cFF666666/hc export  /  /hc import|r  --  " .. L["profiles"] .. "\n" ..
        "|cFF666666/hc reset|r  --  " .. L["restore defaults"] .. "\n" ..
        "|cFF555555" .. L["Key Bindings: ESC > Key Bindings > HideChat"] .. "|r\n" ..
        "|cFF555555" .. L["Hold to Peek: bindable key, shows chat while held"] .. "|r"
    )
    Y = Y - 120

    content:SetHeight(math.abs(Y) + 20)

    frame = f
    frame:Hide()
end

---------------------------------------------------------------------------
-- Refresh
---------------------------------------------------------------------------
local function Refresh()
    if not frame or not checkboxes then return end
    for _, cb in pairs(checkboxes) do
        cb:SetChecked(HideChatDB[cb._key])
        if cb._mark then
            if cb:GetChecked() then cb._mark:Show() else cb._mark:Hide() end
        end
        if cb._fill then
            if cb:GetChecked() then cb._fill:Show() else cb._fill:Hide() end
        end
    end
    for _, cb in ipairs(widgets.instChecks) do
        cb:SetChecked(HideChatDB.instanceTypes[cb._subKey])
        if cb._mark then
            if cb:GetChecked() then cb._mark:Show() else cb._mark:Hide() end
        end
        if cb._fill then
            if cb:GetChecked() then cb._fill:Show() else cb._fill:Hide() end
        end
    end
    if widgets.fadeSlider  then widgets.fadeSlider.slider:SetValue(HideChatDB.fadeDuration) end
    if widgets.opacSlider  then widgets.opacSlider.slider:SetValue(HideChatDB.opacity or 0) end
    if widgets.inactSlider then widgets.inactSlider.slider:SetValue(HideChatDB.inactivityTimer) end
    if widgets.profLabel then
        local names = ns.GetProfileNames and ns.GetProfileNames() or {}
        local cur = HideChatCharDB.activeProfile or "Default"
        local idx = 1
        for i, n in ipairs(names) do if n == cur then idx = i; break end end
        local count = #names > 0 and (" |cFF555555(" .. idx .. "/" .. #names .. ")|r") or ""
        widgets.profLabel:SetText(L["Active:"] .. " |cFFFFFFFF" .. cur .. "|r" .. count)
    end
    if widgets.specNote and GetSpecialization then
        local specIdx = GetSpecialization()
        local bound = HideChatDB.specProfiles and specIdx and HideChatDB.specProfiles[specIdx]
        if bound then
            widgets.specNote:SetText("|cFF888888Spec " .. specIdx .. " -> " .. bound .. "|r")
        else
            widgets.specNote:SetText("|cFF555555" .. L["No spec binding"] .. "|r")
        end
    end
    RefreshDeps()
end

function ns.RefreshConfig() Refresh() end

---------------------------------------------------------------------------
function ns.ToggleConfig()
    if not frame then ns.InitConfig() end
    if not frame then return end
    if frame:IsShown() then frame:Hide()
    else Refresh(); frame:Show() end
end
