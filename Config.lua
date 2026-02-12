local addonName, ns = ...

local frame, content, checkboxes, widgets

---------------------------------------------------------------------------
-- UI widget factories  (template-free → works in every WoW version)
---------------------------------------------------------------------------

local function Header(parent, text, x, y)
    local fs = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    fs:SetPoint("TOPLEFT", x, y)
    fs:SetText("|cFFFFD100" .. text .. "|r")
    return fs
end

local function Checkbox(parent, label, x, y, key, onToggle)
    local cb = CreateFrame("CheckButton", nil, parent)
    cb:SetSize(24, 24)
    cb:SetPoint("TOPLEFT", x, y)
    cb:SetNormalTexture("Interface\\Buttons\\UI-CheckBox-Up")
    cb:SetPushedTexture("Interface\\Buttons\\UI-CheckBox-Down")
    cb:SetHighlightTexture("Interface\\Buttons\\UI-CheckBox-Highlight", "ADD")
    cb:SetCheckedTexture("Interface\\Buttons\\UI-CheckBox-Check")
    local t = cb:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    t:SetPoint("LEFT", cb, "RIGHT", 4, 0)
    t:SetText(label)
    cb.label = t
    cb._key  = key
    cb:SetScript("OnClick", function(self)
        local v = self:GetChecked() and true or false
        HideChatDB[key] = v
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
    cb:SetNormalTexture("Interface\\Buttons\\UI-CheckBox-Up")
    cb:SetPushedTexture("Interface\\Buttons\\UI-CheckBox-Down")
    cb:SetHighlightTexture("Interface\\Buttons\\UI-CheckBox-Highlight", "ADD")
    cb:SetCheckedTexture("Interface\\Buttons\\UI-CheckBox-Check")
    local t = cb:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    t:SetPoint("LEFT", cb, "RIGHT", 2, 0)
    t:SetText(label)
    cb.label  = t
    cb._subKey = subKey
    cb:SetScript("OnClick", function(self)
        HideChatDB.instanceTypes[subKey] = self:GetChecked() and true or false
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
    local bg = sl:CreateTexture(nil, "BACKGROUND")
    bg:SetPoint("TOPLEFT", 0, -5); bg:SetPoint("BOTTOMRIGHT", 0, 5)
    bg:SetColorTexture(0.15, 0.15, 0.15, 1); wrap._bg = bg
    local th = sl:CreateTexture(nil, "OVERLAY")
    th:SetSize(14, 20); th:SetColorTexture(0.6, 0.6, 0.6, 1)
    sl:SetThumbTexture(th); wrap._thumb = th
    sl:SetScript("OnValueChanged", function(_, val)
        val = math.floor(val / step + 0.5) * step
        HideChatDB[key] = val
        value:SetText(fmt and fmt(val) or tostring(val))
    end)
    wrap.slider = sl; wrap._key = key
    function wrap:SetOptionEnabled(on)
        if on then
            self.slider:EnableMouse(true)
            self.title:SetFontObject("GameFontHighlight"); self.value:SetFontObject("GameFontHighlight")
            self._thumb:SetColorTexture(0.6, 0.6, 0.6, 1); self._bg:SetColorTexture(0.15, 0.15, 0.15, 1)
        else
            self.slider:EnableMouse(false)
            self.title:SetFontObject("GameFontDisable"); self.value:SetFontObject("GameFontDisable")
            self._thumb:SetColorTexture(0.3, 0.3, 0.3, 1); self._bg:SetColorTexture(0.10, 0.10, 0.10, 1)
        end
    end
    return wrap
end

local function ActionButton(parent, label, x, y, w, onClick)
    local b = CreateFrame("Button", nil, parent)
    b:SetSize(w, 22); b:SetPoint("TOPLEFT", x, y)
    local bg = b:CreateTexture(nil, "BACKGROUND"); bg:SetAllPoints()
    bg:SetColorTexture(0.2, 0.2, 0.2, 0.8)
    local hl = b:CreateTexture(nil, "HIGHLIGHT"); hl:SetAllPoints()
    hl:SetColorTexture(1, 1, 1, 0.08)
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

    local PW, PH = 360, 560
    local CW, CH = PW - 50, 920   -- scroll content size

    frame = CreateFrame("Frame", "HideChatConfigFrame", UIParent,
        BackdropTemplateMixin and "BackdropTemplate" or nil)
    frame:SetSize(PW, PH); frame:SetPoint("CENTER")
    frame:SetFrameStrata("DIALOG"); frame:SetMovable(true)
    frame:SetClampedToScreen(true); frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:SetBackdrop({
        bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 32,
        insets = { left = 8, right = 8, top = 8, bottom = 8 },
    })

    -- Title + version
    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -14)
    title:SetText("|cFF00FF00HideChat|r Settings")
    local ver = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    ver:SetPoint("TOP", title, "BOTTOM", 0, -1)
    ver:SetText("v" .. (ns.version or "?"))

    -- Close
    local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -4, -4)
    table.insert(UISpecialFrames, "HideChatConfigFrame")

    -- Scroll frame
    local scroll = CreateFrame("ScrollFrame", "HideChatConfigScroll", frame,
        "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 10, -48)
    scroll:SetPoint("BOTTOMRIGHT", -28, 10)

    content = CreateFrame("Frame", "HideChatConfigContent", scroll)
    content:SetSize(CW, CH)
    scroll:SetScrollChild(content)

    ---------- populate content -------------------------------------------
    checkboxes = {}
    widgets    = { instChecks = {} }
    local L, Y = 4, -4

    ---- BUTTON -----------------------------------------------------------
    Header(content, "Button", L, Y); Y = Y - 20
    checkboxes.showButton = Checkbox(content, "Show toggle button", L, Y,
        "showButton", function() if ns.UpdateButton then ns.UpdateButton() end end)
    Y = Y - 26
    checkboxes.lockButton = Checkbox(content, "Lock button position", L, Y, "lockButton")
    Y = Y - 26
    ActionButton(content, "Reset Button Position", L + 28, Y, 150, function()
        if ns.ResetButtonPos then ns.ResetButtonPos() end
    end)
    Y = Y - 28
    checkboxes.showMinimap = Checkbox(content, "Show minimap button", L, Y,
        "showMinimap", function() if ns.UpdateMinimap then ns.UpdateMinimap() end end)

    ---- COMBAT -----------------------------------------------------------
    Y = Y - 32
    Header(content, "Combat", L, Y); Y = Y - 20
    checkboxes.combat = Checkbox(content, "Auto-hide in combat", L, Y,
        "combat", function() RefreshDeps() end)
    Y = Y - 26
    checkboxes.combatRestore = Checkbox(content, "Auto-show after combat", L, Y, "combatRestore")
    widgets.combatRestore = checkboxes.combatRestore

    ---- AUTOMATION -------------------------------------------------------
    Y = Y - 32
    Header(content, "Automation", L, Y); Y = Y - 20

    checkboxes.instanceHide = Checkbox(content, "Auto-hide in instances", L, Y,
        "instanceHide", function() RefreshDeps() end)
    Y = Y - 24
    local instLabels = { party = "Dungeons", raid = "Raids", pvp = "PvP", arena = "Arenas", scenario = "Scenarios" }
    local instOrder  = { "party", "raid", "pvp", "arena", "scenario" }
    local ix = L + 28
    for _, key in ipairs(instOrder) do
        local cb = InstanceCheckbox(content, instLabels[key], ix, Y, key)
        widgets.instChecks[#widgets.instChecks + 1] = cb
        ix = ix + 80
        if ix > CW - 40 then ix = L + 28; Y = Y - 22 end
    end

    Y = Y - 32
    local inactSlider = Slider(content, "Inactivity timer", L + 10, Y, 200,
        0, 60, 5, "inactivityTimer",
        function(v) return v == 0 and "off" or (v .. "s") end)
    widgets.inactSlider = inactSlider

    Y = Y - 40
    checkboxes.inactivityReshow = Checkbox(content, "Show chat on new message", L + 10, Y,
        "inactivityReshow")
    widgets.inactivityReshow = checkboxes.inactivityReshow

    Y = Y - 28
    checkboxes.screenshotHide = Checkbox(content, "Hide chat during screenshots", L, Y,
        "screenshotHide")

    ---- APPEARANCE -------------------------------------------------------
    Y = Y - 32
    Header(content, "Appearance", L, Y); Y = Y - 20
    checkboxes.fade = Checkbox(content, "Fade transition", L, Y,
        "fade", function() RefreshDeps() end)
    Y = Y - 30
    local fadeSlider = Slider(content, "Fade duration", L + 10, Y, 200,
        0.1, 1.0, 0.1, "fadeDuration",
        function(v) return string.format("%.1fs", v) end)
    widgets.fadeSlider = fadeSlider

    Y = Y - 42
    local opacSlider = Slider(content, "Hidden opacity", L + 10, Y, 200,
        0, 1.0, 0.05, "opacity",
        function(v) return math.floor(v * 100) .. "%" end)
    widgets.opacSlider = opacSlider

    Y = Y - 42
    checkboxes.mouseoverReveal = Checkbox(content, "Show on mouse-over", L, Y,
        "mouseoverReveal")

    ---- CHAT -------------------------------------------------------------
    Y = Y - 32
    Header(content, "Chat", L, Y); Y = Y - 20
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
    Y = Y - 32
    Header(content, "Compatibility", L, Y); Y = Y - 20
    checkboxes.alphaMode = Checkbox(content, "Alpha mode (Chattynator / Prat / ElvUI)",
        L, Y, "alphaMode", function()
            if ns.isHidden then ns.ShowChat(true); ns.HideChat(true) end
        end)

    ---- PROFILES ---------------------------------------------------------
    Y = Y - 36
    Header(content, "Profiles", L, Y); Y = Y - 20

    -- Current profile label (updated in Refresh)
    local profLabel = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    profLabel:SetPoint("TOPLEFT", L, Y)
    profLabel:SetText("Active: Default")
    widgets.profLabel = profLabel

    -- Prev / Next arrows
    local profPrev = ActionButton(content, "<", L + 200, Y + 2, 24, function()
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
    local profNext = ActionButton(content, ">", L + 228, Y + 2, 24, function()
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

    Y = Y - 28
    ActionButton(content, "New", L, Y, 60, function()
        StaticPopup_Show("HIDECHAT_NEW_PROFILE")
    end)
    ActionButton(content, "Copy", L + 66, Y, 60, function()
        StaticPopup_Show("HIDECHAT_NEW_PROFILE")
    end)
    ActionButton(content, "Delete", L + 132, Y, 60, function()
        local name = HideChatCharDB.activeProfile
        if name == "Default" then
            print("|cFF00FF00HideChat:|r Cannot delete Default profile.")
            return
        end
        StaticPopup_Show("HIDECHAT_DELETE_PROFILE", name)
    end)

    ---- HINT TEXT --------------------------------------------------------
    Y = Y - 36
    local hint = content:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    hint:SetPoint("TOPLEFT", L, Y); hint:SetWidth(CW - 10); hint:SetJustifyH("LEFT")
    hint:SetText(
        "|cFF888888/hidechat|r or |cFF888888/hc|r to toggle\n" ..
        "|cFF888888/hc config|r to open this window\n" ..
        "|cFF888888/hc status|r for diagnostics\n" ..
        "|cFF888888/hc reset|r to restore defaults"
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
    end
    -- Instance type sub-checkboxes
    for _, cb in ipairs(widgets.instChecks) do
        cb:SetChecked(HideChatDB.instanceTypes[cb._subKey])
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
        -- Auto-save current profile on close
        ns.SaveCurrentProfile()
        frame:Hide()
    else
        Refresh()
        frame:Show()
    end
end
