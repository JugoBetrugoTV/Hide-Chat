local addonName, ns = ...

local frame       -- main settings frame
local checkboxes  -- table of { key = checkButton } for easy refresh

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

--- Checkbox  (works in every WoW version)
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

    -- Thumb
    local thumb = slider:CreateTexture(nil, "OVERLAY")
    thumb:SetSize(14, 20)
    thumb:SetColorTexture(0.6, 0.6, 0.6, 1)
    slider:SetThumbTexture(thumb)

    slider:SetScript("OnValueChanged", function(self, val)
        val = math.floor(val / step + 0.5) * step  -- snap
        HideChatDB[key] = val
        value:SetText(fmt and fmt(val) or tostring(val))
    end)

    wrap.slider = slider
    wrap._key   = key
    return wrap
end

---------------------------------------------------------------------------
-- Build the config frame (called once from PLAYER_LOGIN)
---------------------------------------------------------------------------
function ns.InitConfig()
    if frame then return end

    local PANEL_W, PANEL_H = 340, 400

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

    -- Title
    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -16)
    title:SetText("|cFF00FF00HideChat|r Settings")

    -- Close button
    local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -4, -4)

    -- ESC to close
    table.insert(UISpecialFrames, "HideChatConfigFrame")

    ---------- checkboxes -------------------------------------------------
    checkboxes = {}
    local left, top = 20, -48

    Header(frame, "Button", left, top)
    top = top - 20
    checkboxes.showButton = Checkbox(frame, "Show toggle button", left, top,
        "showButton", function(v)
            if ns.UpdateButton then ns.UpdateButton() end
        end)

    top = top - 26
    checkboxes.lockButton = Checkbox(frame, "Lock button position", left, top, "lockButton")

    top = top - 34
    Header(frame, "Combat", left, top)
    top = top - 20
    checkboxes.combat = Checkbox(frame, "Auto-hide in combat", left, top, "combat")
    top = top - 26
    checkboxes.combatRestore = Checkbox(frame, "Auto-show after combat", left, top, "combatRestore")

    top = top - 34
    Header(frame, "Effects", left, top)
    top = top - 20
    checkboxes.fade = Checkbox(frame, "Fade transition", left, top, "fade")

    top = top - 30
    local fadeSlider = Slider(frame, "Fade duration", left + 10, top, 200,
        0.1, 1.0, 0.1, "fadeDuration",
        function(v) return string.format("%.1fs", v) end)

    top = top - 50
    Header(frame, "Compatibility", left, top)
    top = top - 20
    checkboxes.alphaMode = Checkbox(frame, "Alpha mode (for Chattynator / Prat / ElvUI)",
        left, top, "alphaMode", function(v)
            -- If currently hidden, re-hide with the new method
            if ns.isHidden then
                ns.ShowChat(true)
                ns.HideChat(true)
            end
        end)

    -- Hint text at the bottom
    top = top - 40
    local hint = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    hint:SetPoint("TOPLEFT", left, top)
    hint:SetWidth(PANEL_W - 40)
    hint:SetJustifyH("LEFT")
    hint:SetText(
        "|cFF888888/hidechat|r  or  |cFF888888/hc|r  to toggle\n" ..
        "|cFF888888/hc config|r  to open this window\n\n" ..
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
    for key, cb in pairs(checkboxes) do
        cb:SetChecked(HideChatDB[cb._key])
    end
    if frame._fadeSlider then
        frame._fadeSlider.slider:SetValue(HideChatDB.fadeDuration)
    end
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
