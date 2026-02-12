local addonName, ns = ...

local frame       -- main settings frame
local checkboxes  -- table of { key = checkButton } for easy refresh
local widgets     -- all dependent widgets for enable/disable

---------------------------------------------------------------------------
-- Helpers to build UI widgets without version-specific templates
---------------------------------------------------------------------------

--- Section header
local function Header(parent, text, x, y)
    local fs = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    fs:SetPoint("TOPLEFT", x, y)
    fs:SetText("|cFFFFD100" .. text .. "|r")
    return fs
end

--- Checkbox  (works in every WoW version – no templates required)
local function Checkbox(parent, label, x, y, key, onToggle)
    local cb = CreateFrame("CheckButton", nil, parent)
    cb:SetSize(24, 24)
    cb:SetPoint("TOPLEFT", x, y)
    cb:SetNormalTexture("Interface\\Buttons\\UI-CheckBox-Up")
    cb:SetPushedTexture("Interface\\Buttons\\UI-CheckBox-Down")
    cb:SetHighlightTexture("Interface\\Buttons\\UI-CheckBox-Highlight", "ADD")
    cb:SetCheckedTexture("Interface\\Buttons\\UI-CheckBox-Check")

    local text = cb:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    text:SetPoint("LEFT", cb, "RIGHT", 4, 0)
    text:SetText(label)
    cb.label = text
    cb._key  = key

    cb:SetScript("OnClick", function(self)
        local checked = self:GetChecked() and true or false
        HideChatDB[key] = checked
        if onToggle then onToggle(checked) end
    end)

    --- Dim the checkbox when disabled so it's visually obvious
    function cb:SetOptionEnabled(enabled)
        if enabled then
            self:Enable()
            self.label:SetFontObject("GameFontHighlight")
        else
            self:Disable()
            self.label:SetFontObject("GameFontDisable")
        end
    end

    return cb
end

--- Slider (template-free, so it works identically everywhere)
local function Slider(parent, label, x, y, width, minVal, maxVal, step, key, fmt)
    local wrap = CreateFrame("Frame", nil, parent)
    wrap:SetSize(width + 60, 36)
    wrap:SetPoint("TOPLEFT", x, y)

    local title = wrap:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    title:SetPoint("TOPLEFT", 0, 0)
    title:SetText(label)
    wrap.title = title

    local value = wrap:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    value:SetPoint("TOPRIGHT", 0, 0)
    wrap.value = value

    local slider = CreateFrame("Slider", nil, wrap)
    slider:SetSize(width, 14)
    slider:SetPoint("TOPLEFT", 0, -16)
    slider:SetOrientation("HORIZONTAL")
    slider:SetMinMaxValues(minVal, maxVal)
    slider:SetValueStep(step)
    if slider.SetObeyStepOnDrag then slider:SetObeyStepOnDrag(true) end
    slider:EnableMouse(true)

    -- Track background
    local bg = slider:CreateTexture(nil, "BACKGROUND")
    bg:SetPoint("TOPLEFT", 0, -5)
    bg:SetPoint("BOTTOMRIGHT", 0, 5)
    bg:SetColorTexture(0.15, 0.15, 0.15, 1)
    wrap._bg = bg

    -- Thumb
    local thumb = slider:CreateTexture(nil, "OVERLAY")
    thumb:SetSize(14, 20)
    thumb:SetColorTexture(0.6, 0.6, 0.6, 1)
    slider:SetThumbTexture(thumb)
    wrap._thumb = thumb

    slider:SetScript("OnValueChanged", function(self, val)
        val = math.floor(val / step + 0.5) * step  -- snap
        HideChatDB[key] = val
        value:SetText(fmt and fmt(val) or tostring(val))
    end)

    wrap.slider = slider
    wrap._key   = key

    --- Enable / disable visuals for the whole slider group
    function wrap:SetOptionEnabled(enabled)
        if enabled then
            self.slider:EnableMouse(true)
            self.title:SetFontObject("GameFontHighlight")
            self.value:SetFontObject("GameFontHighlight")
            self._thumb:SetColorTexture(0.6, 0.6, 0.6, 1)
            self._bg:SetColorTexture(0.15, 0.15, 0.15, 1)
        else
            self.slider:EnableMouse(false)
            self.title:SetFontObject("GameFontDisable")
            self.value:SetFontObject("GameFontDisable")
            self._thumb:SetColorTexture(0.3, 0.3, 0.3, 1)
            self._bg:SetColorTexture(0.10, 0.10, 0.10, 1)
        end
    end

    return wrap
end

--- Small action button (e.g. "Reset Position")
local function ActionButton(parent, label, x, y, width, onClick)
    local b = CreateFrame("Button", nil, parent)
    b:SetSize(width, 22)
    b:SetPoint("TOPLEFT", x, y)

    local bg = b:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0.2, 0.2, 0.2, 0.8)

    local hl = b:CreateTexture(nil, "HIGHLIGHT")
    hl:SetAllPoints()
    hl:SetColorTexture(1, 1, 1, 0.08)

    local text = b:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    text:SetPoint("CENTER")
    text:SetText(label)
    b.label = text

    b:SetScript("OnClick", onClick)
    return b
end

---------------------------------------------------------------------------
-- Refresh dependent option states (gray-out logic)
---------------------------------------------------------------------------
local function RefreshDependencies()
    if not widgets then return end
    -- "Auto-show after combat" only makes sense if combat-hide is on
    widgets.combatRestore:SetOptionEnabled(HideChatDB.combat)
    -- Fade slider only usable when fade is on
    widgets.fadeSlider:SetOptionEnabled(HideChatDB.fade)
end

---------------------------------------------------------------------------
-- Build the config frame (called once from PLAYER_LOGIN)
---------------------------------------------------------------------------
function ns.InitConfig()
    if frame then return end

    local PANEL_W, PANEL_H = 340, 430

    frame = CreateFrame("Frame", "HideChatConfigFrame", UIParent,
        BackdropTemplateMixin and "BackdropTemplate" or nil)
    frame:SetSize(PANEL_W, PANEL_H)
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("DIALOG")
    frame:SetMovable(true)
    frame:SetClampedToScreen(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)

    frame:SetBackdrop({
        bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 32,
        insets = { left = 8, right = 8, top = 8, bottom = 8 },
    })

    -- Title  +  version
    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -16)
    title:SetText("|cFF00FF00HideChat|r Settings")

    local ver = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    ver:SetPoint("TOP", title, "BOTTOM", 0, -2)
    ver:SetText("v" .. (ns.version or "?"))

    -- Close button
    local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -4, -4)

    -- ESC to close
    table.insert(UISpecialFrames, "HideChatConfigFrame")

    ---------- checkboxes & widgets ---------------------------------------
    checkboxes = {}
    widgets    = {}
    local left, top = 20, -54

    ---- Button section
    Header(frame, "Button", left, top)
    top = top - 20
    checkboxes.showButton = Checkbox(frame, "Show toggle button", left, top,
        "showButton", function()
            if ns.UpdateButton then ns.UpdateButton() end
        end)

    top = top - 26
    checkboxes.lockButton = Checkbox(frame, "Lock button position", left, top, "lockButton")

    top = top - 26
    ActionButton(frame, "Reset Button Position", left + 28, top, 150, function()
        if ns.ResetButtonPos then ns.ResetButtonPos() end
    end)

    ---- Combat section
    top = top - 32
    Header(frame, "Combat", left, top)
    top = top - 20
    checkboxes.combat = Checkbox(frame, "Auto-hide in combat", left, top,
        "combat", function() RefreshDependencies() end)

    top = top - 26
    checkboxes.combatRestore = Checkbox(frame, "Auto-show after combat", left, top, "combatRestore")
    widgets.combatRestore = checkboxes.combatRestore

    ---- Effects section
    top = top - 32
    Header(frame, "Effects", left, top)
    top = top - 20
    checkboxes.fade = Checkbox(frame, "Fade transition", left, top,
        "fade", function() RefreshDependencies() end)

    top = top - 30
    local fadeSlider = Slider(frame, "Fade duration", left + 10, top, 200,
        0.1, 1.0, 0.1, "fadeDuration",
        function(v) return string.format("%.1fs", v) end)
    widgets.fadeSlider = fadeSlider

    ---- Compatibility section
    top = top - 48
    Header(frame, "Compatibility", left, top)
    top = top - 20
    checkboxes.alphaMode = Checkbox(frame, "Alpha mode (for Chattynator / Prat / ElvUI)",
        left, top, "alphaMode", function()
            -- If currently hidden, re-hide with the new method
            if ns.isHidden then
                ns.ShowChat(true)
                ns.HideChat(true)
            end
        end)

    ---- Hint text at the bottom
    top = top - 40
    local hint = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    hint:SetPoint("TOPLEFT", left, top)
    hint:SetWidth(PANEL_W - 40)
    hint:SetJustifyH("LEFT")
    hint:SetText(
        "|cFF888888/hidechat|r  or  |cFF888888/hc|r  to toggle\n" ..
        "|cFF888888/hc config|r  to open this window\n" ..
        "|cFF888888/hc status|r  for diagnostics\n" ..
        "|cFF888888/hc reset|r   to restore defaults\n\n" ..
        "Alpha mode uses transparency instead of reparenting.\n" ..
        "Enable it if you experience issues with other chat addons."
    )

    -- Store slider ref for refresh
    frame._fadeSlider = fadeSlider

    frame:Hide()  -- start closed
end

---------------------------------------------------------------------------
-- Refresh every widget to match current HideChatDB values
---------------------------------------------------------------------------
local function Refresh()
    if not frame then return end
    for _, cb in pairs(checkboxes) do
        cb:SetChecked(HideChatDB[cb._key])
    end
    if frame._fadeSlider then
        frame._fadeSlider.slider:SetValue(HideChatDB.fadeDuration)
    end
    RefreshDependencies()
end

---------------------------------------------------------------------------
-- Toggle the config window
---------------------------------------------------------------------------
function ns.ToggleConfig()
    if not frame then ns.InitConfig() end
    if frame:IsShown() then
        frame:Hide()
    else
        Refresh()
        frame:Show()
    end
end
