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
    hidden        = false,
    showButton    = true,
    lockButton    = false,
    buttonPos     = nil,            -- set on first drag
    combat        = false,          -- auto-hide in combat
    combatRestore = true,           -- auto-show after combat
    fade          = true,           -- smooth fade transition
    fadeDuration  = 0.3,            -- seconds
    alphaMode     = false,          -- compatibility mode for chat addons
}

---------------------------------------------------------------------------
-- Shared namespace state
---------------------------------------------------------------------------
ns.isHidden  = false
ns.defaults  = defaults
ns.version   = "1.1.0"

-- Invisible anchor – anything parented here is invisible & non-interactive
local anchor = CreateFrame("Frame", "HideChatAnchor", UIParent)
anchor:Hide()

local savedParents  = {}
local alphaBackup   = {}
local suppressAlpha = false
local activeFade    = nil   -- reference to a running fade ticker

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

    -- Prat-3.0 enhances the default ChatFrames in-place, so no extra
    -- frames need to be collected – hiding ChatFrame1..N already covers it.

    return frames
end

---------------------------------------------------------------------------
-- Collect all chat UI elements (vanilla frames + third-party)
---------------------------------------------------------------------------
function ns.GetChatElements()
    local elements = {}

    for i = 1, NUM_CHAT_WINDOWS do
        local cf = _G["ChatFrame" .. i]
        if cf then elements[#elements + 1] = cf end
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
-- Cancel any running fade so a new toggle doesn't conflict
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
        end
        el:SetParent(anchor)
    end
end

local function ReparentShow()
    for el, parent in pairs(savedParents) do
        el:SetParent(parent)
        el:Show()
    end
    savedParents = {}
    if FCF_SelectDockFrame and ChatFrame1 then
        FCF_SelectDockFrame(ChatFrame1)
    end
end

---------------------------------------------------------------------------
-- METHOD B – Alpha mode (better compat with chat addons that reparent)
---------------------------------------------------------------------------
local function AlphaHide()
    for _, el in ipairs(ns.GetChatElements()) do
        if not alphaBackup[el] then
            alphaBackup[el] = { alpha = el:GetAlpha(), mouse = el:IsMouseEnabled() }
            -- Hook SetAlpha so other addons can't accidentally reveal the frame
            if not el._hc_hooked then
                hooksecurefunc(el, "SetAlpha", function(self, a)
                    if ns.isHidden and HideChatDB.alphaMode and not suppressAlpha then
                        if alphaBackup[self] then alphaBackup[self].alpha = a end
                        suppressAlpha = true
                        self:SetAlpha(0)
                        suppressAlpha = false
                    end
                end)
                el._hc_hooked = true
            end
        end
        suppressAlpha = true
        el:SetAlpha(0)
        suppressAlpha = false
        el:EnableMouse(false)
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

---------------------------------------------------------------------------
-- Fade helper (works with either hide method)
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
-- Block chat edit box while hidden (Enter key, click-to-chat, etc.)
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
-- Public hide / show API (used by button, keybind, slash command)
---------------------------------------------------------------------------
function ns.HideChat(silent)
    if ns.isHidden then return end
    CancelFade()

    local function commit()
        if HideChatDB.alphaMode then AlphaHide() else ReparentHide() end
        ns.isHidden = true
        HideChatDB.hidden = true
        if not silent then
            UIErrorsFrame:AddMessage("|cFF00FF00HideChat:|r Chat hidden", 1, 1, 1, 1, 3)
        end
        if ns.UpdateButton then ns.UpdateButton() end
    end

    if HideChatDB.fade and HideChatDB.fadeDuration > 0 then
        Fade(1, 0, HideChatDB.fadeDuration, commit)
    else
        commit()
    end
end

function ns.ShowChat(silent)
    if not ns.isHidden then return end
    CancelFade()

    -- Restore frames first so they exist to be faded in
    if HideChatDB.alphaMode then AlphaShow() else ReparentShow() end
    ns.isHidden = false
    HideChatDB.hidden = false

    if HideChatDB.fade and HideChatDB.fadeDuration > 0 then
        Fade(0, 1, HideChatDB.fadeDuration)
    end

    if not silent then
        print("|cFF00FF00HideChat:|r Chat visible")
    end
    if ns.UpdateButton then ns.UpdateButton() end
end

function HideChat_Toggle()
    -- Clear combat flag on any manual toggle so auto-show doesn't double-fire
    ns._combatHid = false
    if ns.isHidden then ns.ShowChat() else ns.HideChat() end
end

---------------------------------------------------------------------------
-- Addon Compartment support (Retail 10.1+ – minimap addon menu)
-- Functions referenced via ## AddonCompartmentFunc in _Mainline.toc
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
-- Events: login + combat
---------------------------------------------------------------------------
local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_LOGIN")
events:RegisterEvent("PLAYER_REGEN_DISABLED")  -- enter combat
events:RegisterEvent("PLAYER_REGEN_ENABLED")   -- leave combat

events:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_LOGIN" then
        -- Merge defaults into saved vars
        if not HideChatDB then HideChatDB = {} end
        for k, v in pairs(defaults) do
            if HideChatDB[k] == nil then HideChatDB[k] = v end
        end

        -- Block edit box while hidden
        InitEditBoxBlock()

        -- Restore previous hidden state
        if HideChatDB.hidden then
            C_Timer.After(0.5, function()
                ns.HideChat(true)
            end)
        end

        -- Let button & config initialise
        if ns.InitButton then ns.InitButton() end
        if ns.InitConfig then ns.InitConfig() end

    elseif event == "PLAYER_REGEN_DISABLED" then
        -- Only set combat flag if WE are about to hide (not already hidden)
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
-- Slash commands:  /hidechat | /hc           → toggle
--                  /hidechat config          → settings
--                  /hidechat status          → show current state
--                  /hidechat reset           → reset all settings
---------------------------------------------------------------------------
SLASH_HIDECHAT1 = "/hidechat"
SLASH_HIDECHAT2 = "/hc"
SlashCmdList["HIDECHAT"] = function(msg)
    msg = strtrim(msg):lower()

    if msg == "config" or msg == "options" or msg == "settings" then
        if ns.ToggleConfig then ns.ToggleConfig() end

    elseif msg == "status" then
        local mode = HideChatDB.alphaMode and "alpha" or "reparent"
        print("|cFF00FF00HideChat v" .. ns.version .. "|r")
        print("  Chat: " .. (ns.isHidden and "|cFFFF4444hidden|r" or "|cFF44FF44visible|r"))
        print("  Mode: " .. mode)
        print("  Combat auto-hide: " .. (HideChatDB.combat and "on" or "off"))
        print("  Fade: " .. (HideChatDB.fade and string.format("%.1fs", HideChatDB.fadeDuration) or "off"))
        -- Detect loaded chat addons
        local addons = {}
        if IsAddOnLoaded and IsAddOnLoaded("Prat-3.0") or
           C_AddOns and C_AddOns.IsAddOnLoaded and C_AddOns.IsAddOnLoaded("Prat-3.0") then
            addons[#addons + 1] = "Prat-3.0"
        end
        if _G["ChattynatorFrame"] then addons[#addons + 1] = "Chattynator" end
        if _G["ElvUI"]            then addons[#addons + 1] = "ElvUI" end
        if _G["GlassFrame"]       then addons[#addons + 1] = "Glass" end
        if #addons > 0 then
            print("  Chat addons: " .. table.concat(addons, ", "))
        end

    elseif msg == "reset" then
        -- Show chat first if hidden
        if ns.isHidden then ns.ShowChat(true) end
        -- Restore all defaults
        for k, v in pairs(defaults) do HideChatDB[k] = v end
        if ns.UpdateButton then ns.UpdateButton() end
        print("|cFF00FF00HideChat:|r Settings reset to defaults.")

    else
        HideChat_Toggle()
    end
end
