local addonName, ns = ...

---------------------------------------------------------------------------
-- Keybinding header / label (shown in Key Bindings UI)
---------------------------------------------------------------------------
BINDING_HEADER_HIDECHAT = "HideChat"
BINDING_NAME_HIDECHAT_TOGGLE = "Toggle Chat Visibility"

---------------------------------------------------------------------------
-- Default saved-variable values
---------------------------------------------------------------------------
local defaults = {
    hidden           = false,
    showButton       = true,
    lockButton       = false,
    buttonPos        = nil,
    combat           = true,
    combatRestore    = true,
    fade             = true,
    fadeDuration     = 1.0,
    alphaMode        = true,
    -- Appearance
    opacity          = 0,               -- 0 = fully hidden, 0.01‑1.0 = partial
    mouseoverReveal  = true,
    -- Automation
    inactivityTimer  = 5,               -- seconds, 0 = disabled
    inactivityReshow = true,            -- show chat on new message
    instanceHide     = true,
    instanceTypes    = { party = true, raid = true, pvp = true, arena = false, scenario = true },
    screenshotHide   = false,
    -- Chat
    whisperNotify    = true,
    whisperPass      = true,            -- forward whispers to UIErrorsFrame
    keepCombatLog    = false,
    -- Minimap
    showMinimap      = true,
    minimapPos       = 220,             -- degrees around minimap ring
    -- Profiles (internal)
    profiles         = nil,             -- populated on first load
}

---------------------------------------------------------------------------
-- Shared namespace state
---------------------------------------------------------------------------
ns.isHidden       = false
ns.mouseoverActive = false
ns.defaults       = defaults
ns.version        = "1.2.0"

-- Shorthand: set a solid-colour texture
-- Accepts (tex, r, g, b [,a])  OR  (tex, {r,g,b} [,a])
-- Auto-detects whether the client needs CreateColor (12.0+) or raw (r,g,b,a).
do
    local needsColorMixin  -- nil = unknown, detect on first call
    function ns.sct(tex, r, g, b, a)
        if type(r) == "table" then a, r, g, b = g, r[1], r[2], r[3] end
        a = a or 1
        if needsColorMixin == nil then
            needsColorMixin = not pcall(tex.SetColorTexture, tex, r, g, b, a)
            if needsColorMixin then
                tex:SetColorTexture(CreateColor(r, g, b, a))
            end
            return
        end
        if needsColorMixin then
            tex:SetColorTexture(CreateColor(r, g, b, a))
        else
            tex:SetColorTexture(r, g, b, a)
        end
    end
end

-- Invisible anchor – anything parented here is invisible & non-interactive
local anchor = CreateFrame("Frame", "HideChatAnchor", UIParent)
anchor:Hide()

local savedParents  = {}
local savedShown    = {}
local alphaBackup   = {}
local suppressAlpha = false
local activeFade    = nil

---------------------------------------------------------------------------
-- Third-party chat addon detection
---------------------------------------------------------------------------
local function GetThirdPartyFrames()
    local frames = {}

    -- Chattynator
    if _G["ChattynatorFrame"] then
        frames[#frames + 1] = _G["ChattynatorFrame"]
    end
    for i = 1, 20 do
        local f = _G["ChattynatorTab" .. i]
        if f then frames[#frames + 1] = f end
    end

    -- ElvUI chat panels
    if _G["ElvUI"] then
        for _, name in ipairs({
            "LeftChatPanel", "RightChatPanel",
            "LeftChatToggleButton", "RightChatToggleButton",
            "LeftChatDataPanel", "RightChatDataPanel",
        }) do
            local f = _G[name]
            if f then frames[#frames + 1] = f end
        end
    end

    -- Glass (modern chat overlay)
    if _G["GlassFrame"] then
        frames[#frames + 1] = _G["GlassFrame"]
    end

    return frames
end

---------------------------------------------------------------------------
-- Collect all chat UI elements
---------------------------------------------------------------------------
function ns.GetChatElements()
    local elements = {}

    for i = 1, NUM_CHAT_WINDOWS do
        local cf = _G["ChatFrame" .. i]
        if cf then
            -- Skip combat log if keepCombatLog is on
            local isCombatLog = (COMBATLOG and cf == COMBATLOG)
                             or (not COMBATLOG and i == 2 and IsCombatLog and IsCombatLog(cf))
            if not (HideChatDB.keepCombatLog and isCombatLog) then
                elements[#elements + 1] = cf
            end
        end
    end

    if GeneralDockManager then
        elements[#elements + 1] = GeneralDockManager
    end

    for _, name in ipairs({
        "ChatFrameMenuButton",
        "ChatFrameChannelButton",
        "QuickJoinToastButton",
        "ChatFrameToggleVoiceDeafenButton",
        "ChatFrameToggleVoiceMuteButton",
    }) do
        local f = _G[name]
        if f then elements[#elements + 1] = f end
    end

    for _, f in ipairs(GetThirdPartyFrames()) do
        elements[#elements + 1] = f
    end

    return elements
end

---------------------------------------------------------------------------
-- Helper: set alpha on all chat elements (used by mouseover / features)
---------------------------------------------------------------------------
function ns.SetElementsAlpha(alpha, enableMouse)
    suppressAlpha = true
    for _, el in ipairs(ns.GetChatElements()) do
        el:SetAlpha(alpha)
        if enableMouse ~= nil then
            el:EnableMouse(enableMouse)
        end
    end
    suppressAlpha = false
end

---------------------------------------------------------------------------
-- Cancel any running fade
---------------------------------------------------------------------------
local function CancelFade()
    if activeFade then
        activeFade:Cancel()
        activeFade = nil
    end
end

---------------------------------------------------------------------------
-- METHOD A – Reparent (default, most robust)
---------------------------------------------------------------------------
local function ReparentHide()
    for _, el in ipairs(ns.GetChatElements()) do
        if not savedParents[el] then
            savedParents[el] = el:GetParent()
            savedShown[el]   = el:IsShown()
        end
        el:SetParent(anchor)
    end
end

local function ReparentShow()
    for el, parent in pairs(savedParents) do
        el:SetParent(parent)
        if savedShown[el] then el:Show() end
    end
    savedParents = {}
    savedShown   = {}
    if FCF_SelectDockFrame and ChatFrame1 then
        FCF_SelectDockFrame(ChatFrame1)
    end
end

---------------------------------------------------------------------------
-- METHOD B – Alpha mode (compat with chat addons / opacity > 0)
---------------------------------------------------------------------------
local function AlphaHide()
    local tgt = HideChatDB.opacity or 0
    for _, el in ipairs(ns.GetChatElements()) do
        if not alphaBackup[el] then
            alphaBackup[el] = { alpha = el:GetAlpha(), mouse = el:IsMouseEnabled() }
            if not el._hc_hooked then
                hooksecurefunc(el, "SetAlpha", function(self, a)
                    if ns.isHidden and not suppressAlpha and not ns.mouseoverActive then
                        local t = HideChatDB.opacity or 0
                        if HideChatDB.alphaMode or t > 0 then
                            if alphaBackup[self] then alphaBackup[self].alpha = a end
                            suppressAlpha = true
                            self:SetAlpha(t)
                            suppressAlpha = false
                        end
                    end
                end)
                el._hc_hooked = true
            end
        end
        suppressAlpha = true
        el:SetAlpha(tgt)
        suppressAlpha = false
        if tgt == 0 then
            el:EnableMouse(false)
        end
    end
end

local function AlphaShow()
    for el, info in pairs(alphaBackup) do
        suppressAlpha = true
        el:SetAlpha(info.alpha or 1)
        suppressAlpha = false
        el:EnableMouse(info.mouse ~= false)
    end
    alphaBackup = {}
end

-- Determine which method to use based on current settings
local function UseAlphaMethod()
    return HideChatDB.alphaMode or (HideChatDB.opacity or 0) > 0
end

---------------------------------------------------------------------------
-- Fade helper
---------------------------------------------------------------------------
local function Fade(from, to, duration, onDone)
    CancelFade()
    local elements = ns.GetChatElements()
    local elapsed  = 0
    activeFade = C_Timer.NewTicker(0.016, function()
        elapsed = elapsed + 0.016
        local p = math.min(elapsed / duration, 1)
        local a = from + (to - from) * p
        suppressAlpha = true
        for _, el in ipairs(elements) do el:SetAlpha(a) end
        suppressAlpha = false
        if p >= 1 then
            CancelFade()
            if onDone then onDone() end
        end
    end)
end

---------------------------------------------------------------------------
-- Block chat edit box while hidden
---------------------------------------------------------------------------
local function InitEditBoxBlock()
    if not ChatFrame_OpenChat then return end
    hooksecurefunc("ChatFrame_OpenChat", function()
        if not ns.isHidden then return end
        for i = 1, NUM_CHAT_WINDOWS do
            local eb = _G["ChatFrame" .. i .. "EditBox"]
            if eb and eb:HasFocus() then
                eb:ClearFocus()
                eb:Hide()
            end
        end
    end)
end

---------------------------------------------------------------------------
-- Mouseover helpers (called from Features.lua)
---------------------------------------------------------------------------
function ns.MouseoverShow()
    ns.mouseoverActive = true
    if not UseAlphaMethod() then
        for el, parent in pairs(savedParents) do
            el:SetParent(parent)
            el:SetAlpha(0.7)
            el:Show()
        end
    else
        ns.SetElementsAlpha(0.7, true)
    end
end

function ns.MouseoverHide()
    ns.mouseoverActive = false
    local tgt = HideChatDB.opacity or 0
    if not UseAlphaMethod() then
        for el, _ in pairs(savedParents) do
            el:SetParent(anchor)
        end
    else
        ns.SetElementsAlpha(tgt, tgt > 0)
    end
end

---------------------------------------------------------------------------
-- Public hide / show API
---------------------------------------------------------------------------
function ns.HideChat(silent)
    if ns.isHidden then return end
    CancelFade()

    local tgt = HideChatDB.opacity or 0

    local function commit()
        if UseAlphaMethod() then AlphaHide() else ReparentHide() end
        ns.isHidden = true
        HideChatDB.hidden = true
        if not silent then
            UIErrorsFrame:AddMessage("|cFF00FF00HideChat:|r Chat hidden", 1, 1, 1, 1, 3)
        end
        if ns.UpdateButton then ns.UpdateButton() end
        if ns.OnChatHidden then ns.OnChatHidden() end
    end

    if HideChatDB.fade and HideChatDB.fadeDuration > 0 then
        Fade(1, tgt, HideChatDB.fadeDuration, commit)
    else
        commit()
    end
end

function ns.ShowChat(silent)
    if not ns.isHidden then return end
    CancelFade()

    -- Clean up mouseover state
    ns.mouseoverActive = false

    if UseAlphaMethod() then AlphaShow() else ReparentShow() end
    ns.isHidden = false
    HideChatDB.hidden = false

    local from = HideChatDB.opacity or 0
    if HideChatDB.fade and HideChatDB.fadeDuration > 0 and from < 1 then
        Fade(from, 1, HideChatDB.fadeDuration)
    end

    if not silent then
        UIErrorsFrame:AddMessage("|cFF00FF00HideChat:|r Chat visible", 1, 1, 1, 1, 3)
    end
    if ns.UpdateButton then ns.UpdateButton() end
    if ns.StopBlink  then ns.StopBlink() end
    if ns.OnChatShown then ns.OnChatShown() end
end

function HideChat_Toggle()
    ns._combatHid = false
    if ns.isHidden then ns.ShowChat() else ns.HideChat() end
end

---------------------------------------------------------------------------
-- Addon Compartment (Retail 10.1+ minimap addon menu)
---------------------------------------------------------------------------
function HideChat_OnAddonCompartmentClick(_, buttonName)
    if buttonName == "RightButton" then
        if ns.ToggleConfig then ns.ToggleConfig() end
    else
        HideChat_Toggle()
    end
end

function HideChat_OnAddonCompartmentEnter(data)
    GameTooltip:SetOwner(data, "ANCHOR_TOPRIGHT")
    GameTooltip:AddLine("HideChat", 0, 1, 0)
    GameTooltip:AddLine(" ")
    if ns.isHidden then
        GameTooltip:AddLine("Status: Hidden", 0.9, 0.2, 0.2)
    else
        GameTooltip:AddLine("Status: Visible", 0.2, 0.9, 0.2)
    end
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine("Left-click: Toggle chat", 1, 1, 1)
    GameTooltip:AddLine("Right-click: Settings", 1, 1, 1)
    GameTooltip:Show()
end

function HideChat_OnAddonCompartmentLeave()
    GameTooltip:Hide()
end

---------------------------------------------------------------------------
-- Profile management
---------------------------------------------------------------------------
local settingKeys = {}
for k in pairs(defaults) do
    if k ~= "profiles" then settingKeys[k] = true end
end

function ns.SaveCurrentProfile()
    local name = HideChatCharDB and HideChatCharDB.activeProfile or "Default"
    if not HideChatDB.profiles then HideChatDB.profiles = {} end
    local p = {}
    for k in pairs(settingKeys) do p[k] = HideChatDB[k] end
    HideChatDB.profiles[name] = p
end

function ns.LoadProfile(name)
    local p = HideChatDB.profiles and HideChatDB.profiles[name]
    if not p then return false end
    -- Show chat before switching (avoids orphaned frames)
    if ns.isHidden then ns.ShowChat(true) end
    for k, v in pairs(p) do HideChatDB[k] = v end
    if HideChatCharDB then HideChatCharDB.activeProfile = name end
    -- Re-hide if the new profile says so
    if HideChatDB.hidden then
        C_Timer.After(0.1, function() ns.HideChat(true) end)
    end
    if ns.UpdateButton then ns.UpdateButton() end
    return true
end

function ns.CreateProfile(name)
    if not name or name == "" then return end
    if not HideChatDB.profiles then HideChatDB.profiles = {} end
    -- Copy current settings
    local p = {}
    for k in pairs(settingKeys) do p[k] = HideChatDB[k] end
    p.hidden = false
    HideChatDB.profiles[name] = p
    ns.LoadProfile(name)
end

function ns.DeleteProfile(name)
    if name == "Default" then return end
    if HideChatDB.profiles then HideChatDB.profiles[name] = nil end
    if HideChatCharDB and HideChatCharDB.activeProfile == name then
        ns.LoadProfile("Default")
    end
end

function ns.GetProfileNames()
    local names = {}
    if HideChatDB.profiles then
        for k in pairs(HideChatDB.profiles) do
            names[#names + 1] = k
        end
    end
    table.sort(names)
    return names
end

---------------------------------------------------------------------------
-- Database initialisation  (handles v1.1 → v1.2 migration)
---------------------------------------------------------------------------
local function InitDB()
    if not HideChatDB then HideChatDB = {} end

    -- Flat defaults merge (skip tables & profiles key)
    for k, v in pairs(defaults) do
        if k ~= "profiles" and k ~= "instanceTypes" then
            if HideChatDB[k] == nil then HideChatDB[k] = v end
        end
    end

    -- Instance types sub-table
    if not HideChatDB.instanceTypes then
        HideChatDB.instanceTypes = {}
    end
    for k, v in pairs(defaults.instanceTypes) do
        if HideChatDB.instanceTypes[k] == nil then
            HideChatDB.instanceTypes[k] = v
        end
    end

    -- Profile migration: existing flat settings → "Default" profile
    if not HideChatDB.profiles then
        HideChatDB.profiles = {}
        local p = {}
        for k in pairs(settingKeys) do p[k] = HideChatDB[k] end
        HideChatDB.profiles["Default"] = p
    end

    -- Per-character DB
    if not HideChatCharDB then HideChatCharDB = {} end
    if not HideChatCharDB.activeProfile then
        HideChatCharDB.activeProfile = "Default"
    end

    -- Load active profile (only overwrite keys that exist in the profile)
    local pName = HideChatCharDB.activeProfile
    if HideChatDB.profiles[pName] then
        for k, v in pairs(HideChatDB.profiles[pName]) do
            HideChatDB[k] = v
        end
    end
end

---------------------------------------------------------------------------
-- Events: login + combat
---------------------------------------------------------------------------
local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_LOGIN")
events:RegisterEvent("PLAYER_REGEN_DISABLED")
events:RegisterEvent("PLAYER_REGEN_ENABLED")

events:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_LOGIN" then
        InitDB()
        InitEditBoxBlock()

        if HideChatDB.hidden then
            C_Timer.After(0.5, function() ns.HideChat(true) end)
        end

        local function SafeCall(name, fn)
            local ok, err = pcall(fn)
            if not ok then
                print("|cFFFF0000HideChat ERROR in " .. name .. ":|r " .. tostring(err))
            end
        end

        if ns.InitButton   then SafeCall("InitButton",   ns.InitButton)   end
        if ns.InitConfig   then SafeCall("InitConfig",   ns.InitConfig)   end
        if ns.InitFeatures then SafeCall("InitFeatures", ns.InitFeatures) end

    elseif event == "PLAYER_REGEN_DISABLED" then
        if HideChatDB.combat and not ns.isHidden then
            ns._combatHid = true
            ns.HideChat(true)
        end

    elseif event == "PLAYER_REGEN_ENABLED" then
        if ns._combatHid and HideChatDB.combatRestore then
            ns._combatHid = false
            ns.ShowChat(true)
        end
    end
end)

---------------------------------------------------------------------------
-- Slash commands
---------------------------------------------------------------------------
SLASH_HIDECHAT1 = "/hidechat"
SLASH_HIDECHAT2 = "/hc"
SlashCmdList["HIDECHAT"] = function(msg)
    msg = strtrim(msg):lower()

    if msg == "config" or msg == "options" or msg == "settings" then
        if ns.ToggleConfig then ns.ToggleConfig() end

    elseif msg == "status" then
        local mode = UseAlphaMethod() and "alpha" or "reparent"
        print("|cFF00FF00HideChat v" .. ns.version .. "|r")
        print("  Profile: " .. (HideChatCharDB.activeProfile or "Default"))
        print("  Chat: " .. (ns.isHidden and "|cFFFF4444hidden|r" or "|cFF44FF44visible|r"))
        print("  Mode: " .. mode)
        print("  Combat: " .. (HideChatDB.combat and "on" or "off"))
        print("  Fade: " .. (HideChatDB.fade and string.format("%.1fs", HideChatDB.fadeDuration) or "off"))
        print("  Opacity: " .. math.floor((HideChatDB.opacity or 0) * 100) .. "%")
        if HideChatDB.instanceHide    then print("  Instance auto-hide: on") end
        if HideChatDB.inactivityTimer > 0 then print("  Inactivity: " .. HideChatDB.inactivityTimer .. "s") end
        if HideChatDB.mouseoverReveal then print("  Mouseover reveal: on") end
        if HideChatDB.keepCombatLog   then print("  Combat log kept: on") end
        local addons = {}
        local isLoaded = C_AddOns and C_AddOns.IsAddOnLoaded or IsAddOnLoaded
        if isLoaded then
            if pcall(isLoaded, "Prat-3.0") and isLoaded("Prat-3.0") then addons[#addons + 1] = "Prat-3.0" end
        end
        if _G["ChattynatorFrame"] then addons[#addons + 1] = "Chattynator" end
        if _G["ElvUI"]            then addons[#addons + 1] = "ElvUI" end
        if _G["GlassFrame"]       then addons[#addons + 1] = "Glass" end
        if #addons > 0 then print("  Chat addons: " .. table.concat(addons, ", ")) end

    elseif msg == "reset" then
        if ns.isHidden then ns.ShowChat(true) end
        for k, v in pairs(defaults) do
            if k ~= "profiles" then HideChatDB[k] = v end
        end
        HideChatDB.instanceTypes = { party = true, raid = true, pvp = true, arena = false, scenario = true }
        if ns.UpdateButton then ns.UpdateButton() end
        if ns.UpdateMinimap then ns.UpdateMinimap() end
        print("|cFF00FF00HideChat:|r Settings reset to defaults.")

    else
        HideChat_Toggle()
    end
end
