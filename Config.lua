local addonName, ns = ...

local frame, content, checkboxes, widgets

-- Theme colors
local ACCENT   = { 0.00, 0.75, 0.35 }   -- green accent
local TITLE_BG = { 0.06, 0.06, 0.10 }    -- title bar background
local PANEL_BG = { 0.04, 0.04, 0.06 }    -- main panel background
local SECTION  = { 0.80, 0.60, 0.00 }    -- section header gold
local BTN_BG   = { 0.14, 0.14, 0.20 }    -- button background
local BTN_HL   = { 0.22, 0.22, 0.30 }    -- button hover
local BORDER   = { 0.20, 0.20, 0.25 }    -- frame border

---------------------------------------------------------------------------
-- UI widget factories  (template-free → works in every WoW version)
---------------------------------------------------------------------------

local function Header(parent, text, x, y)
    local fs = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    fs:SetPoint("TOPLEFT", x, y)
    fs:SetText("|cFFFFD100" .. text .. "|r")
    -- Decorative underline
    local line = parent:CreateTexture(nil, "ARTWORK")
    line:SetHeight(1)
    line:SetPoint("TOPLEFT", x, y - 15)
    line:SetPoint("RIGHT", parent, "RIGHT", -12, 0)
    line:SetColorTexture(SECTION[1], SECTION[2], SECTION[3], 0.25)
    return fs
end

local function SafeSetTexture(widget, method, path, ...)
    pcall(widget[method], widget, path, ...)
end

local function Checkbox(parent, label, x, y, key, onToggle)
    local cb = CreateFrame("CheckButton", nil, parent)
    cb:SetSize(24, 24)
    cb:SetPoint("TOPLEFT", x, y)
    SafeSetTexture(cb, "SetNormalTexture", "Interface\\Buttons\\UI-CheckBox-Up")
    SafeSetTexture(cb, "SetPushedTexture", "Interface\\Buttons\\UI-CheckBox-Down")
    SafeSetTexture(cb, "SetHighlightTexture", "Interface\\Buttons\\UI-CheckBox-Highlight", "ADD")
    SafeSetTexture(cb, "SetCheckedTexture", "Interface\\Buttons\\UI-CheckBox-Check")
    -- Fallback check mark if textures don't exist
    local checkMark = cb:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    checkMark:SetPoint("CENTER", 0, 0)
    checkMark:SetText("")
    cb._checkMark = checkMark
    cb:SetScript("OnShow", function(self)
        self._checkMark:SetText(self:GetChecked() and "|cFF00FF00✓|r" or "")
    end)
    local t = cb:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    t:SetPoint("LEFT", cb, "RIGHT", 4, 0)
    t:SetText(label)
    cb.label = t
    cb._key  = key
    cb:SetScript("OnClick", function(self)
        local v = self:GetChecked() and true or false
        HideChatDB[key] = v
        self._checkMark:SetText(v and "|cFF00FF00✓|r" or "")
        if onToggle then onToggle(v) end
    end)
    function cb:SetOptionEnabled(on)
        if on then self:Enable(); self.label:SetFontObject("GameFontHighlight")
        else       self:Disable(); self.label:SetFontObject("GameFontDisable") end
    end
    return cb
end

--- Instance-type checkbox (writes into HideChatDB.instanceTypes[subKey])
local function InstanceCheckbox(parent, label, x, y, subKey)
    local cb = CreateFrame("CheckButton", nil, parent)
    cb:SetSize(20, 20)
    cb:SetPoint("TOPLEFT", x, y)
    SafeSetTexture(cb, "SetNormalTexture", "Interface\\Buttons\\UI-CheckBox-Up")
    SafeSetTexture(cb, "SetPushedTexture", "Interface\\Buttons\\UI-CheckBox-Down")
    SafeSetTexture(cb, "SetHighlightTexture", "Interface\\Buttons\\UI-CheckBox-Highlight", "ADD")
    SafeSetTexture(cb, "SetCheckedTexture", "Interface\\Buttons\\UI-CheckBox-Check")
    local checkMark = cb:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    checkMark:SetPoint("CENTER", 0, 0)
    checkMark:SetText("")
    cb._checkMark = checkMark
    cb:SetScript("OnShow", function(self)
        self._checkMark:SetText(self:GetChecked() and "|cFF00FF00✓|r" or "")
    end)
    local t = cb:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    t:SetPoint("LEFT", cb, "RIGHT", 2, 0)
    t:SetText(label)
    cb.label  = t
    cb._subKey = subKey
    cb:SetScript("OnClick", function(self)
        local v = self:GetChecked() and true or false
        HideChatDB.instanceTypes[subKey] = v
        self._checkMark:SetText(v and "|cFF00FF00✓|r" or "")
    end)
    function cb:SetOptionEnabled(on)
        if on then self:Enable(); self.label:SetFontObject("GameFontHighlightSmall")
        else       self:Disable(); self.label:SetFontObject("GameFontDisableSmall") end
    end
    return cb
end

local function Slider(parent, label, x, y, width, minVal, maxVal, step, key, fmt)
    local wrap = CreateFrame("Frame", nil, parent)
    wrap:SetSize(width + 60, 36)
    wrap:SetPoint("TOPLEFT", x, y)
    local title = wrap:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    title:SetPoint("TOPLEFT", 0, 0); title:SetText(label)
    wrap.title = title
    local value = wrap:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    value:SetPoint("TOPRIGHT", 0, 0)
    wrap.value = value
    local sl = CreateFrame("Slider", nil, wrap)
    sl:SetSize(width, 14); sl:SetPoint("TOPLEFT", 0, -16)
    sl:SetOrientation("HORIZONTAL")
    sl:SetMinMaxValues(minVal, maxVal); sl:SetValueStep(step)
    if sl.SetObeyStepOnDrag then sl:SetObeyStepOnDrag(true) end
    sl:EnableMouse(true)
    -- Track background
    local bg = sl:CreateTexture(nil, "BACKGROUND")
    bg:SetPoint("TOPLEFT", 0, -4); bg:SetPoint("BOTTOMRIGHT", 0, 4)
    bg:SetColorTexture(0.10, 0.10, 0.14, 1); wrap._bg = bg
    -- Track fill (accent colored)
    local fill = sl:CreateTexture(nil, "BACKGROUND", nil, 1)
    fill:SetPoint("TOPLEFT", bg, "TOPLEFT"); fill:SetHeight(6)
    fill:SetColorTexture(ACCENT[1], ACCENT[2], ACCENT[3], 0.4)
    wrap._fill = fill
    -- Thumb
    local th = sl:CreateTexture(nil, "OVERLAY")
    th:SetSize(12, 18); th:SetColorTexture(0.65, 0.65, 0.70, 1)
    sl:SetThumbTexture(th); wrap._thumb = th
    sl:SetScript("OnValueChanged", function(self, val)
        val = math.floor(val / step + 0.5) * step
        HideChatDB[key] = val
        value:SetText(fmt and fmt(val) or tostring(val))
        -- Update fill width
        local min, max = self:GetMinMaxValues()
        local pct = (max > min) and ((val - min) / (max - min)) or 0
        fill:SetWidth(math.max(1, bg:GetWidth() * pct))
    end)
    wrap.slider = sl; wrap._key = key
    function wrap:SetOptionEnabled(on)
        if on then
            self.slider:EnableMouse(true)
            self.title:SetFontObject("GameFontHighlight"); self.value:SetFontObject("GameFontHighlight")
            self._thumb:SetColorTexture(0.65, 0.65, 0.70, 1)
            self._bg:SetColorTexture(0.10, 0.10, 0.14, 1)
        else
            self.slider:EnableMouse(false)
            self.title:SetFontObject("GameFontDisable"); self.value:SetFontObject("GameFontDisable")
            self._thumb:SetColorTexture(0.30, 0.30, 0.33, 1)
            self._bg:SetColorTexture(0.08, 0.08, 0.10, 1)
        end
    end
    return wrap
end

local function ActionButton(parent, label, x, y, w, onClick)
    local b = CreateFrame("Button", nil, parent)
    b:SetSize(w, 24); b:SetPoint("TOPLEFT", x, y)
    -- Border
    local bd = b:CreateTexture(nil, "BACKGROUND", nil, -1)
    bd:SetPoint("TOPLEFT", -1, 1); bd:SetPoint("BOTTOMRIGHT", 1, -1)
    bd:SetColorTexture(BORDER[1], BORDER[2], BORDER[3], 0.6)
    -- Background
    local bg = b:CreateTexture(nil, "BACKGROUND"); bg:SetAllPoints()
    bg:SetColorTexture(BTN_BG[1], BTN_BG[2], BTN_BG[3], 0.9)
    -- Hover
    local hl = b:CreateTexture(nil, "HIGHLIGHT"); hl:SetAllPoints()
    hl:SetColorTexture(1, 1, 1, 0.06)
    -- Label
    local t = b:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    t:SetPoint("CENTER"); t:SetText(label); b.label = t
    b:SetScript("OnClick", onClick)
    return b
end

---------------------------------------------------------------------------
-- Dependent-option refresh
---------------------------------------------------------------------------
local function RefreshDeps()
    if not widgets then return end
    widgets.combatRestore:SetOptionEnabled(HideChatDB.combat)
    widgets.fadeSlider:SetOptionEnabled(HideChatDB.fade)
    widgets.inactivityReshow:SetOptionEnabled(HideChatDB.inactivityTimer > 0)
    for _, cb in ipairs(widgets.instChecks) do
        cb:SetOptionEnabled(HideChatDB.instanceHide)
    end
end

---------------------------------------------------------------------------
-- Profile static popups
---------------------------------------------------------------------------
StaticPopupDialogs = StaticPopupDialogs or {}

StaticPopupDialogs["HIDECHAT_NEW_PROFILE"] = {
    text = "HideChat – New profile name:",
    button1 = "Create", button2 = "Cancel",
    hasEditBox = true,
    OnAccept = function(self)
        local name = self.editBox:GetText()
        if name and name ~= "" then
            ns.CreateProfile(name)
            if ns.ToggleConfig then ns.ToggleConfig(); ns.ToggleConfig() end
        end
    end,
    timeout = 0, whileDead = true, hideOnEscape = true,
}

StaticPopupDialogs["HIDECHAT_DELETE_PROFILE"] = {
    text = "HideChat – Delete profile \"%s\"?",
    button1 = "Delete", button2 = "Cancel",
    OnAccept = function()
        local name = HideChatCharDB.activeProfile
        ns.DeleteProfile(name)
        if ns.ToggleConfig then ns.ToggleConfig(); ns.ToggleConfig() end
    end,
    timeout = 0, whileDead = true, hideOnEscape = true,
}

---------------------------------------------------------------------------
-- Build the config frame (called once from PLAYER_LOGIN)
---------------------------------------------------------------------------
function ns.InitConfig()
    if frame then return end

    local PW, PH = 380, 580
    local CW, CH = PW - 50, 940

    frame = CreateFrame("Frame", "HideChatConfigFrame", UIParent,
        BackdropTemplateMixin and "BackdropTemplate" or nil)
    frame:SetSize(PW, PH); frame:SetPoint("CENTER")
    frame:Hide()
    frame:SetFrameStrata("DIALOG"); frame:SetMovable(true)
    frame:SetClampedToScreen(true); frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)

    -- Try backdrop, fall back to flat background
    if frame.SetBackdrop then
        pcall(frame.SetBackdrop, frame, {
            bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true, tileSize = 32, edgeSize = 32,
            insets = { left = 8, right = 8, top = 8, bottom = 8 },
        })
    end

    -- Fallback flat background (always present behind backdrop)
    local panelBg = frame:CreateTexture(nil, "BACKGROUND", nil, -8)
    panelBg:SetAllPoints()
    panelBg:SetColorTexture(PANEL_BG[1], PANEL_BG[2], PANEL_BG[3], 0.97)

    -- Fallback border edges
    local function Edge(p1, rel, p2, w, h, ox, oy)
        local e = frame:CreateTexture(nil, "BACKGROUND", nil, -7)
        e:SetColorTexture(BORDER[1], BORDER[2], BORDER[3], 0.5)
        if w and h then e:SetSize(w, h) end
        if p1 == "TOPLEFT" then
            e:SetPoint("TOPLEFT", ox or 0, oy or 0)
            e:SetPoint(p2, rel, p2, ox or 0, oy or 0)
        else
            e:SetPoint(p1, ox or 0, oy or 0)
            e:SetPoint(p2, ox or 0, oy or 0)
        end
        return e
    end
    -- Top border
    local topEdge = frame:CreateTexture(nil, "BACKGROUND", nil, -7)
    topEdge:SetHeight(1); topEdge:SetColorTexture(BORDER[1], BORDER[2], BORDER[3], 0.5)
    topEdge:SetPoint("TOPLEFT", 0, 0); topEdge:SetPoint("TOPRIGHT", 0, 0)
    -- Bottom border
    local botEdge = frame:CreateTexture(nil, "BACKGROUND", nil, -7)
    botEdge:SetHeight(1); botEdge:SetColorTexture(BORDER[1], BORDER[2], BORDER[3], 0.5)
    botEdge:SetPoint("BOTTOMLEFT", 0, 0); botEdge:SetPoint("BOTTOMRIGHT", 0, 0)
    -- Left border
    local leftEdge = frame:CreateTexture(nil, "BACKGROUND", nil, -7)
    leftEdge:SetWidth(1); leftEdge:SetColorTexture(BORDER[1], BORDER[2], BORDER[3], 0.5)
    leftEdge:SetPoint("TOPLEFT", 0, 0); leftEdge:SetPoint("BOTTOMLEFT", 0, 0)
    -- Right border
    local rightEdge = frame:CreateTexture(nil, "BACKGROUND", nil, -7)
    rightEdge:SetWidth(1); rightEdge:SetColorTexture(BORDER[1], BORDER[2], BORDER[3], 0.5)
    rightEdge:SetPoint("TOPRIGHT", 0, 0); rightEdge:SetPoint("BOTTOMRIGHT", 0, 0)

    -- Title bar background
    local titleBar = frame:CreateTexture(nil, "ARTWORK")
    titleBar:SetHeight(44)
    titleBar:SetPoint("TOPLEFT", 1, -1); titleBar:SetPoint("TOPRIGHT", -1, -1)
    titleBar:SetColorTexture(TITLE_BG[1], TITLE_BG[2], TITLE_BG[3], 1)

    -- Green accent line under title bar
    local accentLine = frame:CreateTexture(nil, "ARTWORK", nil, 1)
    accentLine:SetHeight(2)
    accentLine:SetPoint("TOPLEFT", titleBar, "BOTTOMLEFT", 0, 0)
    accentLine:SetPoint("TOPRIGHT", titleBar, "BOTTOMRIGHT", 0, 0)
    accentLine:SetColorTexture(ACCENT[1], ACCENT[2], ACCENT[3], 0.7)

    -- Title text
    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -10)
    title:SetText("|cFF00CC55HideChat|r |cFFAAAAAASettings|r")

    -- Version
    local ver = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    ver:SetPoint("TOP", title, "BOTTOM", 0, -2)
    ver:SetText("v" .. (ns.version or "?"))

    -- Close button (custom)
    local closeBtn = CreateFrame("Button", nil, frame)
    closeBtn:SetSize(24, 24)
    closeBtn:SetPoint("TOPRIGHT", -6, -6)
    local closeBg = closeBtn:CreateTexture(nil, "BACKGROUND")
    closeBg:SetAllPoints(); closeBg:SetColorTexture(0.5, 0.1, 0.1, 0.4)
    local closeHl = closeBtn:CreateTexture(nil, "HIGHLIGHT")
    closeHl:SetAllPoints(); closeHl:SetColorTexture(0.8, 0.15, 0.15, 0.6)
    local closeText = closeBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    closeText:SetPoint("CENTER", 0, 0); closeText:SetText("|cFFFFFFFFX|r")
    closeBtn:SetScript("OnClick", function() ns.ToggleConfig() end)

    table.insert(UISpecialFrames, "HideChatConfigFrame")

    -- Scroll frame
    local scroll = CreateFrame("ScrollFrame", "HideChatConfigScroll", frame,
        "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 12, -50)
    scroll:SetPoint("BOTTOMRIGHT", -28, 12)

    content = CreateFrame("Frame", "HideChatConfigContent", scroll)
    content:SetSize(CW, CH)
    scroll:SetScrollChild(content)

    ---------- populate content -------------------------------------------
    checkboxes = {}
    widgets    = { instChecks = {} }
    local L, Y = 4, -8

    ---- BUTTON -----------------------------------------------------------
    Header(content, "Button", L, Y); Y = Y - 22
    checkboxes.showButton = Checkbox(content, "Show toggle button", L, Y,
        "showButton", function() if ns.UpdateButton then ns.UpdateButton() end end)
    Y = Y - 26
    checkboxes.lockButton = Checkbox(content, "Lock button position", L, Y, "lockButton")
    Y = Y - 28
    ActionButton(content, "Reset Position", L + 28, Y, 130, function()
        if ns.ResetButtonPos then ns.ResetButtonPos() end
    end)
    Y = Y - 30
    checkboxes.showMinimap = Checkbox(content, "Show minimap button", L, Y,
        "showMinimap", function() if ns.UpdateMinimap then ns.UpdateMinimap() end end)

    ---- COMBAT -----------------------------------------------------------
    Y = Y - 36
    Header(content, "Combat", L, Y); Y = Y - 22
    checkboxes.combat = Checkbox(content, "Auto-hide in combat", L, Y,
        "combat", function() RefreshDeps() end)
    Y = Y - 26
    checkboxes.combatRestore = Checkbox(content, "Auto-show after combat", L, Y, "combatRestore")
    widgets.combatRestore = checkboxes.combatRestore

    ---- AUTOMATION -------------------------------------------------------
    Y = Y - 36
    Header(content, "Automation", L, Y); Y = Y - 22

    checkboxes.instanceHide = Checkbox(content, "Auto-hide in instances", L, Y,
        "instanceHide", function() RefreshDeps() end)
    Y = Y - 26
    local instLabels = { party = "Dungeons", raid = "Raids", pvp = "PvP", arena = "Arenas", scenario = "Scenarios" }
    local instOrder  = { "party", "raid", "pvp", "arena", "scenario" }
    local ix = L + 28
    for _, key in ipairs(instOrder) do
        local cb = InstanceCheckbox(content, instLabels[key], ix, Y, key)
        widgets.instChecks[#widgets.instChecks + 1] = cb
        ix = ix + 80
        if ix > CW - 40 then ix = L + 28; Y = Y - 24 end
    end

    Y = Y - 36
    local inactSlider = Slider(content, "Inactivity timer", L + 10, Y, 200,
        0, 60, 5, "inactivityTimer",
        function(v) return v == 0 and "off" or (v .. "s") end)
    widgets.inactSlider = inactSlider

    Y = Y - 42
    checkboxes.inactivityReshow = Checkbox(content, "Show chat on new message", L + 10, Y,
        "inactivityReshow")
    widgets.inactivityReshow = checkboxes.inactivityReshow

    Y = Y - 30
    checkboxes.screenshotHide = Checkbox(content, "Hide chat during screenshots", L, Y,
        "screenshotHide")

    ---- APPEARANCE -------------------------------------------------------
    Y = Y - 36
    Header(content, "Appearance", L, Y); Y = Y - 22
    checkboxes.fade = Checkbox(content, "Fade transition", L, Y,
        "fade", function() RefreshDeps() end)
    Y = Y - 32
    local fadeSlider = Slider(content, "Fade duration", L + 10, Y, 200,
        0.1, 1.0, 0.1, "fadeDuration",
        function(v) return string.format("%.1fs", v) end)
    widgets.fadeSlider = fadeSlider

    Y = Y - 44
    local opacSlider = Slider(content, "Hidden opacity", L + 10, Y, 200,
        0, 1.0, 0.05, "opacity",
        function(v) return math.floor(v * 100) .. "%" end)
    widgets.opacSlider = opacSlider

    Y = Y - 44
    checkboxes.mouseoverReveal = Checkbox(content, "Show on mouse-over", L, Y,
        "mouseoverReveal")

    ---- CHAT -------------------------------------------------------------
    Y = Y - 36
    Header(content, "Chat", L, Y); Y = Y - 22
    checkboxes.whisperNotify = Checkbox(content, "Blink button on whisper", L, Y,
        "whisperNotify")
    Y = Y - 26
    checkboxes.whisperPass = Checkbox(content, "Show whispers while hidden", L, Y,
        "whisperPass")
    Y = Y - 26
    checkboxes.keepCombatLog = Checkbox(content, "Keep combat log visible", L, Y,
        "keepCombatLog", function()
            if ns.isHidden then ns.ShowChat(true); ns.HideChat(true) end
        end)

    ---- COMPATIBILITY ----------------------------------------------------
    Y = Y - 36
    Header(content, "Compatibility", L, Y); Y = Y - 22
    checkboxes.alphaMode = Checkbox(content, "Alpha mode (Chattynator / Prat / ElvUI)",
        L, Y, "alphaMode", function()
            if ns.isHidden then ns.ShowChat(true); ns.HideChat(true) end
        end)

    ---- PROFILES ---------------------------------------------------------
    Y = Y - 40
    Header(content, "Profiles", L, Y); Y = Y - 22

    local profLabel = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    profLabel:SetPoint("TOPLEFT", L, Y)
    profLabel:SetText("Active: Default")
    widgets.profLabel = profLabel

    local profPrev = ActionButton(content, "<", L + 200, Y + 2, 28, function()
        local names = ns.GetProfileNames()
        if #names < 2 then return end
        local cur = HideChatCharDB.activeProfile
        for i, n in ipairs(names) do
            if n == cur then
                local prev = names[i == 1 and #names or (i - 1)]
                ns.SaveCurrentProfile()
                ns.LoadProfile(prev)
                if ns.ToggleConfig then ns.ToggleConfig(); ns.ToggleConfig() end
                return
            end
        end
    end)
    local profNext = ActionButton(content, ">", L + 232, Y + 2, 28, function()
        local names = ns.GetProfileNames()
        if #names < 2 then return end
        local cur = HideChatCharDB.activeProfile
        for i, n in ipairs(names) do
            if n == cur then
                local nxt = names[i == #names and 1 or (i + 1)]
                ns.SaveCurrentProfile()
                ns.LoadProfile(nxt)
                if ns.ToggleConfig then ns.ToggleConfig(); ns.ToggleConfig() end
                return
            end
        end
    end)

    Y = Y - 30
    ActionButton(content, "New", L, Y, 70, function()
        StaticPopup_Show("HIDECHAT_NEW_PROFILE")
    end)
    ActionButton(content, "Copy", L + 76, Y, 70, function()
        StaticPopup_Show("HIDECHAT_NEW_PROFILE")
    end)
    ActionButton(content, "Delete", L + 152, Y, 70, function()
        local name = HideChatCharDB.activeProfile
        if name == "Default" then
            print("|cFF00FF00HideChat:|r Cannot delete Default profile.")
            return
        end
        StaticPopup_Show("HIDECHAT_DELETE_PROFILE", name)
    end)

    ---- HINT TEXT --------------------------------------------------------
    Y = Y - 40
    local hint = content:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    hint:SetPoint("TOPLEFT", L, Y); hint:SetWidth(CW - 10); hint:SetJustifyH("LEFT")
    hint:SetText(
        "|cFF666666/hidechat|r or |cFF666666/hc|r — toggle\n" ..
        "|cFF666666/hc config|r — this window\n" ..
        "|cFF666666/hc status|r — diagnostics\n" ..
        "|cFF666666/hc reset|r — restore defaults"
    )

    -- Resize content to actual height
    content:SetHeight(math.abs(Y) + 60)

    frame:Hide()
end

---------------------------------------------------------------------------
-- Refresh all widgets to match current HideChatDB
---------------------------------------------------------------------------
local function Refresh()
    if not frame then return end
    for _, cb in pairs(checkboxes) do
        cb:SetChecked(HideChatDB[cb._key])
        if cb._checkMark then
            cb._checkMark:SetText(cb:GetChecked() and "|cFF00FF00✓|r" or "")
        end
    end
    -- Instance type sub-checkboxes
    for _, cb in ipairs(widgets.instChecks) do
        cb:SetChecked(HideChatDB.instanceTypes[cb._subKey])
        if cb._checkMark then
            cb._checkMark:SetText(cb:GetChecked() and "|cFF00FF00✓|r" or "")
        end
    end
    -- Sliders
    if widgets.fadeSlider  then widgets.fadeSlider.slider:SetValue(HideChatDB.fadeDuration) end
    if widgets.opacSlider  then widgets.opacSlider.slider:SetValue(HideChatDB.opacity or 0) end
    if widgets.inactSlider then widgets.inactSlider.slider:SetValue(HideChatDB.inactivityTimer) end
    -- Profile label
    if widgets.profLabel then
        widgets.profLabel:SetText("Active: |cFFFFFFFF" .. (HideChatCharDB.activeProfile or "Default") .. "|r")
    end
    RefreshDeps()
end

---------------------------------------------------------------------------
-- Toggle the config window
---------------------------------------------------------------------------
function ns.ToggleConfig()
    if not frame then ns.InitConfig() end
    if frame:IsShown() then
        ns.SaveCurrentProfile()
        frame:Hide()
    else
        Refresh()
        frame:Show()
    end
end
