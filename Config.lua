local addonName, ns = ...

local frame, content, checkboxes, widgets

---------------------------------------------------------------------------
-- THEME  (refined dark + teal — deeper, richer, more layered)
---------------------------------------------------------------------------
local C = {
    accent    = { 0.18, 0.83, 0.75 },
    accentDim = { 0.12, 0.55, 0.50 },
    accentLo  = { 0.08, 0.32, 0.28 },
    bg        = { 0.03, 0.03, 0.05 },
    panelBg   = { 0.05, 0.06, 0.09 },
    headerBg  = { 0.04, 0.04, 0.07 },
    headerBg2 = { 0.06, 0.07, 0.10 },
    cardBg    = { 0.07, 0.08, 0.11 },
    cardHead  = { 0.08, 0.10, 0.14 },
    border    = { 0.12, 0.14, 0.18 },
    borderLt  = { 0.18, 0.20, 0.26 },
    text      = { 0.90, 0.92, 0.95 },
    textDim   = { 0.55, 0.57, 0.62 },
    textMuted = { 0.35, 0.37, 0.42 },
    danger    = { 0.90, 0.32, 0.32 },
    dangerDim = { 0.55, 0.22, 0.22 },
    btnBg     = { 0.09, 0.10, 0.14 },
    btnBgHov  = { 0.12, 0.14, 0.19 },
    btnBrd    = { 0.16, 0.18, 0.24 },
    success   = { 0.28, 0.82, 0.42 },
}

local sct = ns.sct

---------------------------------------------------------------------------
-- Draw helpers
---------------------------------------------------------------------------
local function MakeBorder(f, r, g, b, a, inset)
    if type(r) == "table" then a, r, g, b = g, r[1], r[2], r[3] end
    inset = inset or 0
    local t
    -- top
    t = f:CreateTexture(nil, "BORDER"); sct(t, r, g, b, a or 0.5)
    t:SetHeight(1); t:SetPoint("TOPLEFT", inset, -inset); t:SetPoint("TOPRIGHT", -inset, -inset)
    -- bottom
    t = f:CreateTexture(nil, "BORDER"); sct(t, r, g, b, a or 0.5)
    t:SetHeight(1); t:SetPoint("BOTTOMLEFT", inset, inset); t:SetPoint("BOTTOMRIGHT", -inset, inset)
    -- left
    t = f:CreateTexture(nil, "BORDER"); sct(t, r, g, b, a or 0.5)
    t:SetWidth(1); t:SetPoint("TOPLEFT", inset, -inset); t:SetPoint("BOTTOMLEFT", inset, inset)
    -- right
    t = f:CreateTexture(nil, "BORDER"); sct(t, r, g, b, a or 0.5)
    t:SetWidth(1); t:SetPoint("TOPRIGHT", -inset, -inset); t:SetPoint("BOTTOMRIGHT", -inset, inset)
end

---------------------------------------------------------------------------
-- Card: polished section panel
---------------------------------------------------------------------------
local function Card(parent, title, icon, x, y, w, h)
    local card = CreateFrame("Frame", nil, parent)
    card:SetSize(w, h); card:SetPoint("TOPLEFT", x, y)

    -- Card background
    local bg = card:CreateTexture(nil, "BACKGROUND", nil, 0)
    bg:SetAllPoints(); sct(bg, C.cardBg, 0.98)

    -- Subtle header gradient area (top 28px)
    local head = card:CreateTexture(nil, "BACKGROUND", nil, 1)
    head:SetHeight(28); head:SetPoint("TOPLEFT"); head:SetPoint("TOPRIGHT")
    sct(head, C.cardHead, 0.85)

    -- Teal accent bar (top)
    local acc = card:CreateTexture(nil, "ARTWORK", nil, 2)
    acc:SetHeight(2); acc:SetPoint("TOPLEFT"); acc:SetPoint("TOPRIGHT")
    sct(acc, C.accent, 0.70)

    -- Border
    MakeBorder(card, C.border, 0.40)

    -- Section icon + title
    if title then
        local hdr = card:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        hdr:SetPoint("TOPLEFT", 12, -7)
        local ic = icon or "\226\151\136"  -- default: small diamond
        hdr:SetText("|cFF2DD4BF" .. ic .. "  " .. title .. "|r")
    end

    -- Separator line under header
    local sep = card:CreateTexture(nil, "ARTWORK", nil, 0)
    sep:SetHeight(1); sep:SetPoint("TOPLEFT", 1, -28); sep:SetPoint("TOPRIGHT", -1, -28)
    sct(sep, C.border, 0.30)

    return card
end

---------------------------------------------------------------------------
-- Widgets
---------------------------------------------------------------------------
local function Checkbox(parent, label, x, y, key, onToggle)
    local cb = CreateFrame("CheckButton", nil, parent)
    cb:SetSize(24, 22); cb:SetPoint("TOPLEFT", x, y)

    -- Outer border
    local brd = cb:CreateTexture(nil, "BACKGROUND", nil, -1)
    brd:SetSize(18, 18); brd:SetPoint("LEFT", 2, 0)
    sct(brd, C.borderLt, 0.55)

    -- Inner box
    local box = cb:CreateTexture(nil, "BACKGROUND", nil, 0)
    box:SetSize(16, 16); box:SetPoint("CENTER", brd)
    sct(box, 0.05, 0.06, 0.09, 1)

    -- Teal fill when checked
    local fill = cb:CreateTexture(nil, "ARTWORK", nil, 0)
    fill:SetSize(16, 16); fill:SetPoint("CENTER", box)
    sct(fill, C.accent, 0.25)
    fill:Hide()

    -- Checkmark character
    local mark = cb:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    mark:SetPoint("CENTER", box, 0, 0)
    mark:SetText("|cFF2DD4BF\226\156\147|r")  -- ✓
    mark:Hide()
    cb._mark = mark
    cb._fill = fill

    -- Hover
    local hl = cb:CreateTexture(nil, "HIGHLIGHT")
    hl:SetSize(16, 16); hl:SetPoint("CENTER", box)
    sct(hl, 1, 1, 1, 0.05)

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
    brd:SetSize(15, 15); brd:SetPoint("LEFT", 1, 0)
    sct(brd, C.borderLt, 0.45)
    local box = cb:CreateTexture(nil, "BACKGROUND", nil, 0)
    box:SetSize(13, 13); box:SetPoint("CENTER", brd)
    sct(box, 0.05, 0.06, 0.09, 1)

    local fill = cb:CreateTexture(nil, "ARTWORK", nil, 0)
    fill:SetSize(13, 13); fill:SetPoint("CENTER", box)
    sct(fill, C.accent, 0.20)
    fill:Hide()

    local mark = cb:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    mark:SetPoint("CENTER", box, 0, 0)
    mark:SetText("|cFF2DD4BF\226\156\147|r")
    mark:Hide()
    cb._mark = mark
    cb._fill = fill

    local hl = cb:CreateTexture(nil, "HIGHLIGHT")
    hl:SetSize(13, 13); hl:SetPoint("CENTER", box)
    sct(hl, 1, 1, 1, 0.05)

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

local function Slider(parent, label, x, y, width, lo, hi, step, key, fmt)
    local wrap = CreateFrame("Frame", nil, parent)
    wrap:SetSize(width + 70, 38); wrap:SetPoint("TOPLEFT", x, y)

    local title = wrap:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    title:SetPoint("TOPLEFT", 0, 0); title:SetText(label)
    wrap.title = title

    local value = wrap:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    value:SetPoint("TOPRIGHT", 0, 0); wrap.value = value

    local sl = CreateFrame("Slider", nil, wrap)
    sl:SetSize(width, 16); sl:SetPoint("TOPLEFT", 0, -18)
    sl:SetOrientation("HORIZONTAL"); sl:SetMinMaxValues(lo, hi); sl:SetValueStep(step)
    if sl.SetObeyStepOnDrag then sl:SetObeyStepOnDrag(true) end
    sl:EnableMouse(true)

    -- Track background (dark)
    local trackBg = sl:CreateTexture(nil, "BACKGROUND", nil, -1)
    trackBg:SetPoint("TOPLEFT", -1, -3); trackBg:SetPoint("BOTTOMRIGHT", 1, 3)
    sct(trackBg, 0.03, 0.03, 0.05, 1)
    wrap._trackBg = trackBg

    -- Track
    local track = sl:CreateTexture(nil, "BACKGROUND", nil, 0)
    track:SetPoint("TOPLEFT", 0, -4); track:SetPoint("BOTTOMRIGHT", 0, 4)
    sct(track, 0.07, 0.08, 0.11, 1)
    wrap._track = track

    -- Fill (teal)
    local fill = sl:CreateTexture(nil, "BACKGROUND", nil, 1)
    fill:SetPoint("TOPLEFT", track, "TOPLEFT"); fill:SetHeight(8)
    sct(fill, C.accent, 0.45)
    wrap._fill = fill

    -- Thumb (wider, taller)
    local th = sl:CreateTexture(nil, "OVERLAY")
    th:SetSize(12, 20); sct(th, C.accent, 0.90)
    sl:SetThumbTexture(th)
    wrap._thumb = th

    sl:SetScript("OnValueChanged", function(self, val)
        val = math.floor(val / step + 0.5) * step
        val = math.max(lo, math.min(val, hi))
        HideChatDB[key] = val
        local txt = fmt and fmt(val) or tostring(val)
        value:SetText("|cFF2DD4BF" .. txt .. "|r")
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
            sct(self._thumb, C.accent, 0.90)
            sct(self._track, 0.07, 0.08, 0.11, 1)
            sct(self._fill, C.accent, 0.45)
        else
            self.slider:EnableMouse(false)
            self.title:SetFontObject("GameFontDisable")
            self.value:SetFontObject("GameFontDisable")
            sct(self._thumb, 0.18, 0.20, 0.25, 0.6)
            sct(self._track, 0.05, 0.06, 0.08, 1)
            sct(self._fill, 0.12, 0.14, 0.18, 0.4)
        end
    end
    return wrap
end

local function Btn(parent, label, x, y, w, onClick, style)
    style = style or "default"
    local h = 26
    local b = CreateFrame("Button", nil, parent)
    b:SetSize(w, h); b:SetPoint("TOPLEFT", x, y)

    -- Outer border
    local bd = b:CreateTexture(nil, "BACKGROUND", nil, -1)
    bd:SetPoint("TOPLEFT", -1, 1); bd:SetPoint("BOTTOMRIGHT", 1, -1)
    if style == "accent" then
        sct(bd, C.accentDim, 0.50)
    elseif style == "danger" then
        sct(bd, C.dangerDim, 0.50)
    else
        sct(bd, C.btnBrd, 0.45)
    end

    -- Background
    local bg = b:CreateTexture(nil, "BACKGROUND", nil, 0)
    bg:SetAllPoints()
    if style == "accent" then
        sct(bg, C.accentLo, 0.60)
    elseif style == "danger" then
        sct(bg, 0.25, 0.08, 0.08, 0.80)
    else
        sct(bg, C.btnBg, 0.90)
    end

    -- Hover highlight
    local hl = b:CreateTexture(nil, "HIGHLIGHT")
    hl:SetAllPoints()
    if style == "accent" then
        sct(hl, C.accent, 0.12)
    elseif style == "danger" then
        sct(hl, C.danger, 0.15)
    else
        sct(hl, 1, 1, 1, 0.06)
    end

    -- Label
    local t = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    t:SetPoint("CENTER")
    if style == "accent" then
        t:SetText("|cFF2DD4BF" .. label .. "|r")
    elseif style == "danger" then
        t:SetText("|cFFE06666" .. label .. "|r")
    else
        t:SetText(label)
    end
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
StaticPopupDialogs = StaticPopupDialogs or {}
StaticPopupDialogs["HIDECHAT_NEW_PROFILE"] = {
    text = "HideChat \226\128\147 New profile name:",
    button1 = "Create", button2 = "Cancel", hasEditBox = true,
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
    text = "HideChat \226\128\147 Copy current profile to:",
    button1 = "Copy", button2 = "Cancel", hasEditBox = true,
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
    text = "HideChat \226\128\147 Rename profile \"%s\" to:",
    button1 = "Rename", button2 = "Cancel", hasEditBox = true,
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
    text = "HideChat \226\128\147 Delete profile \"%s\"?",
    button1 = "Delete", button2 = "Cancel",
    OnAccept = function()
        ns.DeleteProfile(HideChatCharDB.activeProfile)
        if ns.ToggleConfig then ns.ToggleConfig(); ns.ToggleConfig() end
    end,
    timeout = 0, whileDead = true, hideOnEscape = true,
}
StaticPopupDialogs["HIDECHAT_RESET_ALL"] = {
    text = "HideChat \226\128\147 Reset all settings to defaults?",
    button1 = "Reset", button2 = "Cancel",
    OnAccept = function()
        SlashCmdList["HIDECHAT"]("reset")
    end,
    timeout = 0, whileDead = true, hideOnEscape = true,
}
StaticPopupDialogs["HIDECHAT_IMPORT_PROFILE"] = {
    text = "HideChat \226\128\147 Paste import string:",
    button1 = "Import", button2 = "Cancel", hasEditBox = true,
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
    text = "HideChat \226\128\147 Export string (copy this):",
    button1 = "OK", hasEditBox = true,
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

    local FW, FH = 460, 660
    local CW = FW - 48

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

    -- ==================== PANEL SHADOW ====================
    -- Outer shadow (3-layer glow)
    local shadow3 = f:CreateTexture(nil, "BACKGROUND", nil, -8)
    shadow3:SetPoint("TOPLEFT", -6, 6); shadow3:SetPoint("BOTTOMRIGHT", 6, -6)
    sct(shadow3, 0, 0, 0, 0.30)

    local shadow2 = f:CreateTexture(nil, "BACKGROUND", nil, -7)
    shadow2:SetPoint("TOPLEFT", -3, 3); shadow2:SetPoint("BOTTOMRIGHT", 3, -3)
    sct(shadow2, 0, 0, 0, 0.50)

    local shadow1 = f:CreateTexture(nil, "BACKGROUND", nil, -6)
    shadow1:SetPoint("TOPLEFT", -1, 1); shadow1:SetPoint("BOTTOMRIGHT", 1, -1)
    sct(shadow1, 0, 0, 0, 0.70)

    -- Main background
    local bg = f:CreateTexture(nil, "BACKGROUND", nil, -5)
    bg:SetAllPoints(); sct(bg, C.panelBg, 0.99)

    -- Subtle inner tint at top (simulates gradient)
    local topTint = f:CreateTexture(nil, "BACKGROUND", nil, -4)
    topTint:SetHeight(120); topTint:SetPoint("TOPLEFT"); topTint:SetPoint("TOPRIGHT")
    sct(topTint, C.accent[1], C.accent[2], C.accent[3], 0.015)

    -- Frame border
    MakeBorder(f, C.border, 0.55)

    -- ==================== TITLE BAR ====================
    local titleH = 58
    local titleBg = f:CreateTexture(nil, "ARTWORK", nil, 0)
    titleBg:SetHeight(titleH); titleBg:SetPoint("TOPLEFT", 1, -1); titleBg:SetPoint("TOPRIGHT", -1, -1)
    sct(titleBg, C.headerBg[1], C.headerBg[2], C.headerBg[3], 1)

    -- Title bar bottom gradient
    local titleBg2 = f:CreateTexture(nil, "ARTWORK", nil, 1)
    titleBg2:SetHeight(20); titleBg2:SetPoint("BOTTOMLEFT", titleBg, "BOTTOMLEFT")
    titleBg2:SetPoint("BOTTOMRIGHT", titleBg, "BOTTOMRIGHT")
    sct(titleBg2, C.headerBg2[1], C.headerBg2[2], C.headerBg2[3], 0.5)

    -- Teal accent line under title
    local accent = f:CreateTexture(nil, "ARTWORK", nil, 2)
    accent:SetHeight(2)
    accent:SetPoint("TOPLEFT", titleBg, "BOTTOMLEFT")
    accent:SetPoint("TOPRIGHT", titleBg, "BOTTOMRIGHT")
    sct(accent, C.accent, 0.80)

    -- Subtle glow under accent
    local accentGlow = f:CreateTexture(nil, "ARTWORK", nil, 1)
    accentGlow:SetHeight(8)
    accentGlow:SetPoint("TOPLEFT", accent, "BOTTOMLEFT")
    accentGlow:SetPoint("TOPRIGHT", accent, "BOTTOMRIGHT")
    sct(accentGlow, C.accent[1], C.accent[2], C.accent[3], 0.06)

    -- Title: "HideChat"
    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -10)
    title:SetText("|cFF2DD4BFHideChat|r")

    -- Subtitle: "Settings"
    local sub = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    sub:SetPoint("TOPLEFT", title, "TOPRIGHT", 8, -3)
    sub:SetText("|cFF6B7280Settings|r")

    -- Version
    local ver = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    ver:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 1, -3)
    ver:SetText("|cFF444444v" .. (ns.version or "?") .. "|r")

    -- Status badge (right side of title bar)
    local statusBadge = CreateFrame("Frame", nil, f)
    statusBadge:SetSize(90, 22); statusBadge:SetPoint("TOPRIGHT", -42, -18)
    local statusBg = statusBadge:CreateTexture(nil, "BACKGROUND")
    statusBg:SetAllPoints()
    sct(statusBg, 0.06, 0.07, 0.10, 0.90)
    MakeBorder(statusBadge, C.border, 0.35)
    local statusDot = statusBadge:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    statusDot:SetPoint("CENTER", 0, 0)
    widgets.statusDot = statusDot
    widgets.statusBg  = statusBg

    local statusElapsed = 0
    f:SetScript("OnUpdate", function(_, dt)
        statusElapsed = statusElapsed + dt
        if statusElapsed < 0.25 then return end
        statusElapsed = 0
        if not widgets.statusDot then return end
        if ns.isHidden then
            widgets.statusDot:SetText("|cFFE06666\226\151\143  Hidden|r")
            sct(widgets.statusBg, 0.15, 0.06, 0.06, 0.80)
        else
            widgets.statusDot:SetText("|cFF2DD4BF\226\151\143  Visible|r")
            sct(widgets.statusBg, 0.04, 0.10, 0.09, 0.80)
        end
    end)

    -- Close button (circle-ish)
    local closeBtn = CreateFrame("Button", nil, f)
    closeBtn:SetSize(24, 24); closeBtn:SetPoint("TOPRIGHT", -10, -10)
    local cBg = closeBtn:CreateTexture(nil, "BACKGROUND")
    cBg:SetAllPoints(); sct(cBg, C.danger, 0.10)
    MakeBorder(closeBtn, C.dangerDim, 0.35)
    local cHl = closeBtn:CreateTexture(nil, "HIGHLIGHT")
    cHl:SetAllPoints(); sct(cHl, C.danger, 0.30)
    local cTxt = closeBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    cTxt:SetPoint("CENTER", 0, 0); cTxt:SetText("|cFFCC5555\195\151|r")  -- ×
    closeBtn:SetScript("OnClick", function() ns.ToggleConfig() end)

    table.insert(UISpecialFrames, "HideChatConfigFrame")

    -- ==================== SCROLL ====================
    local scrollTop = titleH + 6
    local scroll = CreateFrame("ScrollFrame", "HideChatConfigScroll", f)
    scroll:SetPoint("TOPLEFT", 12, -scrollTop)
    scroll:SetPoint("BOTTOMRIGHT", -24, 12)

    content = CreateFrame("Frame", "HideChatConfigContent", scroll)
    content:SetSize(CW, 1800)
    scroll:SetScrollChild(content)

    -- Scrollbar (thin, teal)
    local bar = CreateFrame("Slider", nil, scroll)
    bar:SetWidth(4); bar:SetPoint("TOPRIGHT", f, -11, -(scrollTop + 2))
    bar:SetPoint("BOTTOMRIGHT", f, -11, 14)
    bar:SetMinMaxValues(0, 1); bar:SetValueStep(1)
    local barTrack = bar:CreateTexture(nil, "BACKGROUND")
    barTrack:SetAllPoints(); sct(barTrack, C.border, 0.25)
    local thumb = bar:CreateTexture(nil, "OVERLAY")
    thumb:SetSize(4, 40); sct(thumb, C.accent, 0.50)
    bar:SetThumbTexture(thumb)

    local function UpdateScrollRange()
        local visH = scroll:GetHeight()
        local childH = content:GetHeight()
        local maxScroll = math.max(childH - visH, 0)
        bar:SetMinMaxValues(0, maxScroll)
    end
    scroll:SetScript("OnSizeChanged", UpdateScrollRange)
    content:SetScript("OnSizeChanged", UpdateScrollRange)
    bar:SetScript("OnValueChanged", function(_, val) scroll:SetVerticalScroll(val) end)
    scroll:SetScript("OnMouseWheel", function(_, delta)
        bar:SetValue(bar:GetValue() - delta * 40)
    end)
    scroll:EnableMouseWheel(true)

    -- ==================== CONTENT ====================
    local PAD  = 14       -- card inner padding (left)
    local GAP  = 12       -- gap between cards
    local ROW  = 28       -- checkbox row height
    local SROW = 42       -- slider row height
    local Y    = 0

    ---- CARD: General --------------------------------------------------------
    local c1 = Card(content, "General", "\226\154\153", 0, Y, CW, 196)  -- ⚙
    local y1 = -34
    checkboxes.showButton = Checkbox(c1, "Show toggle button", PAD, y1,
        "showButton", function() if ns.UpdateButton then ns.UpdateButton() end end)
    y1 = y1 - ROW
    checkboxes.lockButton = Checkbox(c1, "Lock button position", PAD, y1, "lockButton")
    y1 = y1 - ROW + 2
    Btn(c1, "Reset Position", PAD + 28, y1, 120, function()
        if ns.ResetButtonPos then ns.ResetButtonPos() end
    end)
    y1 = y1 - 32
    checkboxes.showMinimap = Checkbox(c1, "Show minimap button", PAD, y1,
        "showMinimap", function() if ns.UpdateMinimap then ns.UpdateMinimap() end end)
    y1 = y1 - ROW + 2
    Btn(c1, "Reset Minimap Pos", PAD + 28, y1, 130, function()
        if ns.ResetMinimapPos then ns.ResetMinimapPos() end
    end)
    Y = Y - 196 - GAP

    ---- CARD: Combat ---------------------------------------------------------
    local c2 = Card(content, "Combat", "\226\154\148", 0, Y, CW, 120)  -- ⚔
    local y2 = -34
    checkboxes.combat = Checkbox(c2, "Auto-hide in combat", PAD, y2,
        "combat", function() RefreshDeps() end)
    y2 = y2 - ROW
    checkboxes.combatRestore = Checkbox(c2, "Auto-show after combat", PAD, y2, "combatRestore")
    widgets.combatRestore = checkboxes.combatRestore
    y2 = y2 - ROW
    checkboxes.raidAutoShow = Checkbox(c2, "Auto-show on ready-check / encounter", PAD, y2,
        "raidAutoShow")
    Y = Y - 120 - GAP

    ---- CARD: Automation -----------------------------------------------------
    local c3 = Card(content, "Automation", "\226\143\177", 0, Y, CW, 198)  -- ⏱
    local y3 = -34
    checkboxes.instanceHide = Checkbox(c3, "Auto-hide in instances", PAD, y3,
        "instanceHide", function() RefreshDeps() end)
    y3 = y3 - ROW
    local instLabels = { party="Dungeons", raid="Raids", pvp="PvP", arena="Arenas", scenario="Scenarios" }
    local instOrder  = { "party", "raid", "pvp", "arena", "scenario" }
    local ix = PAD + 28
    for _, key in ipairs(instOrder) do
        local cb = InstanceCheckbox(c3, instLabels[key], ix, y3, key)
        widgets.instChecks[#widgets.instChecks + 1] = cb
        ix = ix + 80
        if ix > CW - 60 then ix = PAD + 28; y3 = y3 - 24 end
    end
    y3 = y3 - 36
    widgets.inactSlider = Slider(c3, "Inactivity timer", PAD + 8, y3, 220,
        0, 60, 5, "inactivityTimer",
        function(v) return v == 0 and "off" or (v .. "s") end)
    y3 = y3 - SROW
    checkboxes.inactivityReshow = Checkbox(c3, "Show chat on new message", PAD + 8, y3,
        "inactivityReshow")
    widgets.inactivityReshow = checkboxes.inactivityReshow
    Y = Y - 198 - GAP

    ---- CARD: Appearance -----------------------------------------------------
    local c4 = Card(content, "Appearance", "\226\156\168", 0, Y, CW, 222)  -- ✨
    local y4 = -34
    checkboxes.fade = Checkbox(c4, "Fade transition (smooth easing)", PAD, y4,
        "fade", function() RefreshDeps() end)
    y4 = y4 - 32
    widgets.fadeSlider = Slider(c4, "Fade duration", PAD + 8, y4, 220,
        0.1, 1.0, 0.1, "fadeDuration",
        function(v) return string.format("%.1fs", v) end)
    y4 = y4 - SROW
    widgets.opacSlider = Slider(c4, "Hidden opacity", PAD + 8, y4, 220,
        0, 1.0, 0.05, "opacity",
        function(v) return math.floor(v * 100) .. "%" end)
    y4 = y4 - SROW
    checkboxes.mouseoverReveal = Checkbox(c4, "Show on mouse-over", PAD, y4,
        "mouseoverReveal")
    y4 = y4 - ROW
    checkboxes.colorblind = Checkbox(c4, "Colorblind mode (high contrast)", PAD, y4,
        "colorblind", function()
            if ns.UpdateButton then ns.UpdateButton() end
            if ns.UpdateMinimap then ns.UpdateMinimap() end
        end)
    Y = Y - 222 - GAP

    ---- CARD: Chat -----------------------------------------------------------
    local c5 = Card(content, "Chat", "\226\156\137", 0, Y, CW, 204)  -- ✉
    local y5 = -34
    checkboxes.whisperNotify = Checkbox(c5, "Blink button on whisper", PAD, y5,
        "whisperNotify")
    y5 = y5 - ROW
    checkboxes.whisperPass = Checkbox(c5, "Show whispers while hidden", PAD, y5,
        "whisperPass")
    y5 = y5 - ROW
    checkboxes.whisperSound = Checkbox(c5, "Play sound on whisper", PAD, y5,
        "whisperSound")
    y5 = y5 - ROW
    checkboxes.keepCombatLog = Checkbox(c5, "Keep combat log visible", PAD, y5,
        "keepCombatLog")
    y5 = y5 - ROW
    checkboxes.screenshotHide = Checkbox(c5, "Hide chat for screenshots", PAD, y5,
        "screenshotHide")
    y5 = y5 - ROW
    checkboxes.scrollToRecent = Checkbox(c5, "Scroll to recent on unhide", PAD, y5,
        "scrollToRecent")
    Y = Y - 204 - GAP

    ---- CARD: Zone Memory ---------------------------------------------------
    local c_zone = Card(content, "Zone Memory", "\226\140\144", 0, Y, CW, 74)  -- ⌐
    local yz = -34
    checkboxes.zoneMemoryEnabled = Checkbox(c_zone, "Remember chat state per zone", PAD, yz,
        "zoneMemoryEnabled")
    Btn(c_zone, "Clear Memory", CW - 108, yz + 2, 94, function()
        HideChatDB.zoneMemory = {}
        print("|cFF2DD4BFHideChat:|r Zone memory cleared.")
    end)
    Y = Y - 74 - GAP

    ---- CARD: Compatibility --------------------------------------------------
    local c6 = Card(content, "Compatibility", "\226\154\161", 0, Y, CW, 90)  -- ⚡
    local y6 = -34
    checkboxes.alphaMode = Checkbox(c6, "Alpha mode (Chattynator / Prat / ElvUI)",
        PAD, y6, "alphaMode", function()
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
                        widgets.addonNote:SetText("|cFFE0A030Detected: " .. list .. " \226\128\148 enable Alpha mode|r")
                    else
                        widgets.addonNote:SetText("|cFF666666Detected: " .. list .. "|r")
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
        note:SetPoint("TOPLEFT", PAD + 10, -60); note:SetWidth(CW - 30)
        note:SetJustifyH("LEFT")
        if #detected > 0 then
            local list = table.concat(detected, ", ")
            if not HideChatDB.alphaMode then
                note:SetText("|cFFE0A030Detected: " .. list .. " \226\128\148 enable Alpha mode|r")
            else
                note:SetText("|cFF666666Detected: " .. list .. "|r")
            end
        else
            note:SetText("|cFF444444No third-party chat addons detected|r")
        end
        widgets.addonNote = note
    end
    Y = Y - 90 - GAP

    ---- CARD: Profiles -------------------------------------------------------
    local c7 = Card(content, "Profiles", "\226\145\191", 0, Y, CW, 134)  -- ⑿
    local y7 = -34
    local profLabel = c7:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    profLabel:SetPoint("TOPLEFT", PAD, y7); profLabel:SetText("Active: Default")
    widgets.profLabel = profLabel

    Btn(c7, "\226\151\128", 220, y7 + 2, 28, function()  -- ◀
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
    Btn(c7, "\226\150\182", 252, y7 + 2, 28, function()  -- ▶
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

    y7 = y7 - 32
    local bx = PAD
    Btn(c7, "New", bx, y7, 58, function()
        StaticPopup_Show("HIDECHAT_NEW_PROFILE")
    end, "accent")
    bx = bx + 64
    Btn(c7, "Copy", bx, y7, 58, function()
        StaticPopup_Show("HIDECHAT_COPY_PROFILE")
    end, "accent")
    bx = bx + 64
    Btn(c7, "Rename", bx, y7, 70, function()
        local name = HideChatCharDB.activeProfile
        if name == "Default" then
            print("|cFF2DD4BFHideChat:|r Cannot rename the Default profile."); return
        end
        StaticPopup_Show("HIDECHAT_RENAME_PROFILE", name)
    end)
    bx = bx + 76
    Btn(c7, "Delete", bx, y7, 70, function()
        local name = HideChatCharDB.activeProfile
        if name == "Default" then
            print("|cFF2DD4BFHideChat:|r Cannot delete Default profile."); return
        end
        StaticPopup_Show("HIDECHAT_DELETE_PROFILE", name)
    end, "danger")

    y7 = y7 - 30
    bx = PAD
    Btn(c7, "Export", bx, y7, 70, function()
        StaticPopup_Show("HIDECHAT_EXPORT_PROFILE")
    end, "accent")
    bx = bx + 76
    Btn(c7, "Import", bx, y7, 70, function()
        StaticPopup_Show("HIDECHAT_IMPORT_PROFILE")
    end, "accent")

    -- Spec profile binding
    local specNote = c7:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    specNote:SetPoint("TOPLEFT", bx + 82, y7 - 4); specNote:SetWidth(CW - bx - 100)
    specNote:SetJustifyH("LEFT")
    if GetSpecialization then
        local specIdx = GetSpecialization()
        local bound = HideChatDB.specProfiles and HideChatDB.specProfiles[specIdx]
        if bound then
            specNote:SetText("|cFF888888Spec " .. specIdx .. " \226\134\146 " .. bound .. "|r")
        else
            specNote:SetText("|cFF555555No spec binding|r")
        end
    else
        specNote:SetText("|cFF555555Spec profiles: retail only|r")
    end
    widgets.specNote = specNote

    if GetSpecialization then
        Btn(c7, "Bind to Spec", bx + 76, y7, 94, function()
            local specIdx = GetSpecialization()
            if not specIdx then return end
            if not HideChatDB.specProfiles then HideChatDB.specProfiles = {} end
            local cur = HideChatCharDB.activeProfile or "Default"
            HideChatDB.specProfiles[specIdx] = cur
            print("|cFF2DD4BFHideChat:|r Spec " .. specIdx .. " bound to profile \"" .. cur .. "\".")
            if widgets.specNote then
                widgets.specNote:SetText("|cFF888888Spec " .. specIdx .. " \226\134\146 " .. cur .. "|r")
            end
        end, "accent")
    end
    Y = Y - 134 - GAP

    ---- RESET BUTTON ---------------------------------------------------------
    Y = Y - 4
    Btn(content, "Reset All Settings", 0, Y, 150, function()
        StaticPopup_Show("HIDECHAT_RESET_ALL")
    end, "danger")
    Y = Y - 38

    ---- COMMAND REFERENCE (styled card) ------------------------------------
    local cmdCard = Card(content, "Commands", "\226\140\168", 0, Y, CW, 148)  -- ⌨
    local cmdText = cmdCard:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    cmdText:SetPoint("TOPLEFT", PAD + 2, -34); cmdText:SetWidth(CW - PAD * 2)
    cmdText:SetJustifyH("LEFT"); cmdText:SetSpacing(3)
    cmdText:SetText(
        "|cFF6B7280/hidechat|r  or  |cFF6B7280/hc|r |cFF444444\226\128\148|r toggle\n" ..
        "|cFF6B7280/hc show|r  /  |cFF6B7280/hc hide|r |cFF444444\226\128\148|r force state\n" ..
        "|cFF6B7280/hc config|r |cFF444444\226\128\148|r this panel\n" ..
        "|cFF6B7280/hc status|r |cFF444444\226\128\148|r diagnostics\n" ..
        "|cFF6B7280/hc debug|r |cFF444444\226\128\148|r detailed debug output\n" ..
        "|cFF6B7280/hc export|r  /  |cFF6B7280/hc import|r |cFF444444\226\128\148|r profiles\n" ..
        "|cFF6B7280/hc reset|r |cFF444444\226\128\148|r restore defaults"
    )
    Y = Y - 148 - GAP

    -- Keybind hint at very bottom
    local kbHint = content:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    kbHint:SetPoint("TOPLEFT", 4, Y); kbHint:SetWidth(CW - 10); kbHint:SetJustifyH("CENTER")
    kbHint:SetText("|cFF333338ESC \226\134\146 Key Bindings \226\134\146 HideChat   \194\183   Hold-to-Peek keybind available|r")
    Y = Y - 20

    content:SetHeight(math.abs(Y) + 20)

    frame = f
    frame:Hide()
end

---------------------------------------------------------------------------
-- Refresh widgets to match HideChatDB
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
        widgets.profLabel:SetText("Active: |cFFFFFFFF" .. cur .. "|r" .. count)
    end
    if widgets.specNote and GetSpecialization then
        local specIdx = GetSpecialization()
        local bound = HideChatDB.specProfiles and specIdx and HideChatDB.specProfiles[specIdx]
        if bound then
            widgets.specNote:SetText("|cFF888888Spec " .. specIdx .. " \226\134\146 " .. bound .. "|r")
        else
            widgets.specNote:SetText("|cFF555555No spec binding|r")
        end
    end
    RefreshDeps()
end

function ns.RefreshConfig()
    Refresh()
end

---------------------------------------------------------------------------
function ns.ToggleConfig()
    if not frame then ns.InitConfig() end
    if not frame then return end
    if frame:IsShown() then frame:Hide()
    else Refresh(); frame:Show() end
end
