local addonName, ns = ...
local L = ns.L

---------------------------------------------------------------------------
-- Keybinding header / label (shown in Key Bindings UI)
---------------------------------------------------------------------------
BINDING_HEADER_HIDECHAT = "HideChat"
BINDING_NAME_HIDECHAT_TOGGLE = L["Toggle Chat Visibility"]
BINDING_NAME_HIDECHAT_PEEK   = L["Hold to Peek"]

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
    opacity          = 0,               -- 0 = fully hidden, 0.01-1.0 = partial
    mouseoverReveal  = true,
    colorblind       = false,           -- shape-based + high-contrast colours
    -- Automation
    inactivityTimer  = 5,               -- seconds, 0 = disabled
    inactivityReshow = true,            -- show chat on new message
    instanceHide     = true,
    instanceTypes    = { party = true, raid = true, pvp = true, arena = false, scenario = true },
    raidAutoShow     = true,            -- show on ready-check / encounter
    screenshotHide   = false,
    -- Chat
    whisperNotify    = true,
    whisperPass      = true,            -- forward whispers to UIErrorsFrame
    whisperSound     = true,            -- play sound on whisper while hidden
    keepCombatLog    = false,
    scrollToRecent   = true,            -- scroll to bottom on unhide
    -- Minimap
    showMinimap      = true,
    minimapPos       = 220,             -- degrees around minimap ring
    -- Config panel
    configPos        = nil,             -- saved position {point,x,y}
    -- Profiles (internal)
    profiles         = nil,             -- populated on first load
    specProfiles     = nil,             -- {[specIndex] = "profileName"}
    -- Per-zone state
    zoneMemory       = nil,             -- {[mapID] = true/false}
    zoneMemoryEnabled = false,
}

---------------------------------------------------------------------------
-- Shared namespace state
---------------------------------------------------------------------------
ns.isHidden       = false
ns.mouseoverActive = false
ns.defaults       = defaults
ns.version        = "1.4.1"

-- Named constants (avoids magic numbers scattered across files)
ns.BUTTON_DEFAULT       = { point = "BOTTOMLEFT", x = 4, y = 165 }
ns.MINIMAP_RADIUS       = 80
ns.MINIMAP_DEFAULT_ANGLE = 220
ns.FADE_TICK            = 0.016
ns.NOTIF_DISPLAY        = 1.5
ns.NOTIF_FADE           = 1.0
ns.NOTIF_COOLDOWN       = 0.5          -- debounce notifications

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

---------------------------------------------------------------------------
-- Easing functions
---------------------------------------------------------------------------
function ns.EaseInOutSine(t)
    return -(math.cos(math.pi * t) - 1) / 2
end

-- Invisible anchor - anything parented here is invisible & non-interactive
local anchor = CreateFrame("Frame", "HideChatAnchor", UIParent)
anchor:Hide()

local savedParents  = {}
local savedShown    = {}
local alphaBackup   = {}
local suppressAlpha = false
local activeFade    = nil

---------------------------------------------------------------------------
-- Custom status notification (manual fade - immune to duplicate suppression)
-- With debounce: max 1 notification per NOTIF_COOLDOWN seconds
---------------------------------------------------------------------------
local notifFrame = CreateFrame("Frame", nil, UIParent)
notifFrame:SetSize(500, 30)
notifFrame:SetPoint("TOP", UIParent, "TOP", 0, -100)
notifFrame:SetFrameStrata("HIGH")
local notifText = notifFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
notifText:SetPoint("CENTER")
notifFrame:Hide()

local notifTimer
local lastNotifTime = 0

local function ShowNotification(text)
    local now = GetTime()
    if now - lastNotifTime < ns.NOTIF_COOLDOWN then return end
    lastNotifTime = now

    notifText:SetText(text)
    notifFrame:SetAlpha(1)
    notifFrame:Show()
    notifFrame:SetScript("OnUpdate", nil)
    if notifTimer then notifTimer:Cancel() end
    notifTimer = C_Timer.NewTimer(ns.NOTIF_DISPLAY, function()
        notifTimer = nil
        local fade = 0
        notifFrame:SetScript("OnUpdate", function(self, dt)
            fade = fade + dt
            local a = 1 - (fade / ns.NOTIF_FADE)
            if a <= 0 then
                self:Hide()
                self:SetScript("OnUpdate", nil)
            else
                self:SetAlpha(a)
            end
        end)
    end)
end

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
-- METHOD A - Reparent (default, most robust)
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
    -- FCF_SelectDockFrame can call protected functions; defer if in combat
    if FCF_SelectDockFrame and ChatFrame1 then
        if InCombatLockdown() then
            local ticker
            ticker = C_Timer.NewTicker(0.5, function()
                if not InCombatLockdown() then
                    ticker:Cancel()
                    if FCF_SelectDockFrame and ChatFrame1 then
                        pcall(FCF_SelectDockFrame, ChatFrame1)
                    end
                end
            end)
        else
            pcall(FCF_SelectDockFrame, ChatFrame1)
        end
    end
end

---------------------------------------------------------------------------
-- METHOD B - Alpha mode (compat with chat addons / opacity > 0)
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
                            if InCombatLockdown() then
                                -- Defer to next frame to break the taint chain
                                C_Timer.After(0, function()
                                    if ns.isHidden and not suppressAlpha and not ns.mouseoverActive then
                                        suppressAlpha = true
                                        self:SetAlpha(t)
                                        suppressAlpha = false
                                    end
                                end)
                            else
                                suppressAlpha = true
                                self:SetAlpha(t)
                                suppressAlpha = false
                            end
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
-- Fade helper (with easing support)
---------------------------------------------------------------------------
local function Fade(from, to, duration, onDone)
    CancelFade()
    local elements = ns.GetChatElements()
    local elapsed  = 0
    activeFade = C_Timer.NewTicker(ns.FADE_TICK, function()
        elapsed = elapsed + ns.FADE_TICK
        local p = math.min(elapsed / duration, 1)
        -- Apply easing
        p = ns.EaseInOutSine(p)
        local a = from + (to - from) * p
        suppressAlpha = true
        for _, el in ipairs(elements) do el:SetAlpha(a) end
        suppressAlpha = false
        if elapsed >= duration then
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
-- Scroll chat frames to bottom on unhide
---------------------------------------------------------------------------
local function ScrollChatToRecent()
    if not HideChatDB.scrollToRecent then return end
    for i = 1, NUM_CHAT_WINDOWS do
        local cf = _G["ChatFrame" .. i]
        if cf and cf:IsShown() and cf.ScrollToBottom then
            cf:ScrollToBottom()
        end
    end
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
-- Per-zone memory helpers
---------------------------------------------------------------------------
local function GetCurrentZoneID()
    if C_Map and C_Map.GetBestMapForUnit then
        return C_Map.GetBestMapForUnit("player")
    end
    -- Classic fallback
    if GetCurrentMapAreaID then
        return GetCurrentMapAreaID()
    end
    return nil
end

local function SaveZoneState()
    if not HideChatDB.zoneMemoryEnabled then return end
    local zoneID = GetCurrentZoneID()
    if not zoneID then return end
    if not HideChatDB.zoneMemory then HideChatDB.zoneMemory = {} end
    HideChatDB.zoneMemory[zoneID] = ns.isHidden
end

local function ApplyZoneState()
    if not HideChatDB.zoneMemoryEnabled then return end
    local zoneID = GetCurrentZoneID()
    if not zoneID then return end
    if not HideChatDB.zoneMemory then return end
    local state = HideChatDB.zoneMemory[zoneID]
    if state == nil then return end  -- no memory for this zone
    if state and not ns.isHidden then
        ns.HideChat(true)
    elseif not state and ns.isHidden then
        ns.ShowChat(true)
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
            ShowNotification("|cFF2DD4BFHideChat|r  |cFFE06666" .. L["Chat hidden"] .. "|r")
        end
        if ns.UpdateButton  then ns.UpdateButton()  end
        if ns.UpdateMinimap then ns.UpdateMinimap() end
        if ns.OnChatHidden  then ns.OnChatHidden()  end
        SaveZoneState()
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

    -- Scroll to most recent messages
    ScrollChatToRecent()

    if not silent then
        ShowNotification("|cFF2DD4BFHideChat|r  |cFF2DD4BF" .. L["Chat visible"] .. "|r")
    end
    if ns.UpdateButton  then ns.UpdateButton()  end
    if ns.UpdateMinimap then ns.UpdateMinimap() end
    if ns.StopBlink     then ns.StopBlink()     end
    if ns.OnChatShown   then ns.OnChatShown()   end
    SaveZoneState()
end

function HideChat_Toggle()
    ns._combatHid = false
    if ns.isHidden then ns.ShowChat() else ns.HideChat() end
end

---------------------------------------------------------------------------
-- Hold-to-Peek (show while key held, hide on release)
---------------------------------------------------------------------------
ns._peekActive = false

function HideChat_PeekDown()
    if not ns.isHidden then return end
    ns._peekActive = true
    ns.mouseoverActive = true
    if not UseAlphaMethod() then
        for el, parent in pairs(savedParents) do
            el:SetParent(parent)
            el:SetAlpha(0.85)
            el:Show()
        end
    else
        ns.SetElementsAlpha(0.85, true)
    end
end

function HideChat_PeekUp()
    if not ns._peekActive then return end
    ns._peekActive = false
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
-- Addon Compartment (Retail 10.1+ minimap addon menu)
---------------------------------------------------------------------------
function HideChat_OnAddonCompartmentClick(_, buttonName)
    if buttonName == "RightButton" then
        if ns.ToggleConfig then ns.ToggleConfig() end
    else
        HideChat_Toggle()
    end
end

function HideChat_OnAddonCompartmentEnter(addonName, menuButton)
    -- 11.0+ Menu API passes addon name string; menuButton may be the frame
    local owner = menuButton
    if not owner or not owner.GetBottom then
        owner = _G["AddonCompartmentFrame"]
    end
    if not owner or not owner.GetBottom then return end
    GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
    GameTooltip:AddLine("HideChat", 0, 1, 0)
    GameTooltip:AddLine(" ")
    if ns.isHidden then
        GameTooltip:AddLine(L["Status: Hidden"], 0.9, 0.2, 0.2)
    else
        GameTooltip:AddLine(L["Status: Visible"], 0.2, 0.9, 0.2)
    end
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine(L["Left-click: Toggle chat"], 1, 1, 1)
    GameTooltip:AddLine(L["Right-click: Settings"], 1, 1, 1)
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
    -- Cancel any active fade before switching profiles to prevent race
    CancelFade()
    -- Crossfade: silently transition without flicker
    local wasHidden = ns.isHidden
    if wasHidden then
        -- Directly restore frames without fade
        ns.mouseoverActive = false
        ns._peekActive = false
        if UseAlphaMethod() then AlphaShow() else ReparentShow() end
        ns.isHidden = false
    end
    for k, v in pairs(p) do HideChatDB[k] = v end
    if HideChatCharDB then HideChatCharDB.activeProfile = name end
    -- Re-hide if the new profile says so (no flicker: instant)
    if HideChatDB.hidden then
        ns.isHidden = false  -- ensure HideChat() actually runs
        local savedFade = HideChatDB.fade
        HideChatDB.fade = false
        ns.HideChat(true)
        HideChatDB.fade = savedFade
    end
    if ns.UpdateButton then ns.UpdateButton() end
    return true
end

function ns.CreateProfile(name)
    if not name or name == "" then return false end
    if not HideChatDB.profiles then HideChatDB.profiles = {} end
    if HideChatDB.profiles[name] then
        print("|cFF2DD4BFHideChat:|r " .. string.format(L["Profile \"%s\" already exists."], name))
        return false
    end
    local p = {}
    for k in pairs(settingKeys) do p[k] = HideChatDB[k] end
    p.hidden = false
    HideChatDB.profiles[name] = p
    ns.LoadProfile(name)
    return true
end

function ns.RenameProfile(oldName, newName)
    if oldName == "Default" then
        print("|cFF2DD4BFHideChat:|r " .. L["Cannot rename the Default profile."])
        return false
    end
    if not newName or newName == "" then return false end
    if not HideChatDB.profiles or not HideChatDB.profiles[oldName] then return false end
    if HideChatDB.profiles[newName] then
        print("|cFF2DD4BFHideChat:|r " .. string.format(L["Profile \"%s\" already exists."], newName))
        return false
    end
    HideChatDB.profiles[newName] = HideChatDB.profiles[oldName]
    HideChatDB.profiles[oldName] = nil
    if HideChatCharDB and HideChatCharDB.activeProfile == oldName then
        HideChatCharDB.activeProfile = newName
    end
    -- Update spec profile bindings
    if HideChatDB.specProfiles then
        for spec, pName in pairs(HideChatDB.specProfiles) do
            if pName == oldName then
                HideChatDB.specProfiles[spec] = newName
            end
        end
    end
    return true
end

function ns.DeleteProfile(name)
    if name == "Default" then return end
    if HideChatDB.profiles then HideChatDB.profiles[name] = nil end
    -- Clean up spec bindings
    if HideChatDB.specProfiles then
        for spec, pName in pairs(HideChatDB.specProfiles) do
            if pName == name then
                HideChatDB.specProfiles[spec] = nil
            end
        end
    end
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
-- Profile import / export (Base64 serialisation)
---------------------------------------------------------------------------
do
    local b64 = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

    local function ToBase64(str)
        local out = {}
        local pad = 3 - (#str % 3)
        if pad == 3 then pad = 0 end
        str = str .. string.rep("\0", pad)
        for i = 1, #str, 3 do
            local a, b, c = str:byte(i, i + 2)
            local n = a * 65536 + b * 256 + c
            out[#out + 1] = b64:sub(math.floor(n / 262144) % 64 + 1, math.floor(n / 262144) % 64 + 1)
            out[#out + 1] = b64:sub(math.floor(n / 4096) % 64 + 1, math.floor(n / 4096) % 64 + 1)
            out[#out + 1] = b64:sub(math.floor(n / 64) % 64 + 1, math.floor(n / 64) % 64 + 1)
            out[#out + 1] = b64:sub(n % 64 + 1, n % 64 + 1)
        end
        for i = 1, pad do out[#out - i + 1] = "=" end
        return table.concat(out)
    end

    local function FromBase64(str)
        str = str:gsub("[^A-Za-z0-9+/=]", "")
        if #str == 0 then return "" end
        local out = {}
        local padCount = select(2, str:gsub("=", ""))
        str = str:gsub("=", "A")
        for i = 1, #str, 4 do
            local fa = b64:find(str:sub(i, i), 1, true)
            local fb = b64:find(str:sub(i + 1, i + 1), 1, true)
            local fc = b64:find(str:sub(i + 2, i + 2), 1, true)
            local fd = b64:find(str:sub(i + 3, i + 3), 1, true)
            if not fa or not fb or not fc or not fd then break end
            local a, bv, c, d = fa - 1, fb - 1, fc - 1, fd - 1
            local n = a * 262144 + bv * 4096 + c * 64 + d
            out[#out + 1] = string.char(math.floor(n / 65536) % 256)
            out[#out + 1] = string.char(math.floor(n / 256) % 256)
            out[#out + 1] = string.char(n % 256)
        end
        local result = table.concat(out)
        if padCount > 0 and padCount < #result then
            result = result:sub(1, -(padCount + 1))
        end
        return result
    end

    -- Escape/unescape special chars so |, =, {, } inside strings don't
    -- corrupt the serialised format (common with WoW colour codes like |cFF…).
    local function EscapeStr(s)
        return s:gsub("\\", "\\\\"):gsub("|", "\\p"):gsub("=", "\\e"):gsub("{", "\\l"):gsub("}", "\\r")
    end
    local function UnescapeStr(s)
        return s:gsub("\\r", "}"):gsub("\\l", "{"):gsub("\\e", "="):gsub("\\p", "|"):gsub("\\\\", "\\")
    end

    -- Simple Lua table serialiser (flat key-value only, handles subtables)
    local function Serialize(tbl)
        local parts = {}
        for k, v in pairs(tbl) do
            if type(v) == "table" then
                parts[#parts + 1] = k .. "={" .. Serialize(v) .. "}"
            elseif type(v) == "boolean" then
                parts[#parts + 1] = k .. "=" .. (v and "T" or "F")
            elseif type(v) == "number" then
                parts[#parts + 1] = k .. "=" .. tostring(v)
            elseif type(v) == "string" then
                parts[#parts + 1] = k .. "=S" .. EscapeStr(v)
            end
        end
        return table.concat(parts, "|")
    end

    local function Deserialize(str)
        local tbl = {}
        -- Parse key=value pairs separated by |
        local pos = 1
        while pos <= #str do
            local eqPos = str:find("=", pos)
            if not eqPos then break end
            local key = str:sub(pos, eqPos - 1)
            local nextChar = str:sub(eqPos + 1, eqPos + 1)
            if nextChar == "{" then
                -- Find matching brace
                local depth, endPos = 1, eqPos + 2
                while endPos <= #str and depth > 0 do
                    local ch = str:sub(endPos, endPos)
                    if ch == "{" then depth = depth + 1
                    elseif ch == "}" then depth = depth - 1 end
                    endPos = endPos + 1
                end
                local inner = str:sub(eqPos + 2, endPos - 2)
                tbl[key] = Deserialize(inner)
                pos = endPos
                if str:sub(pos, pos) == "|" then pos = pos + 1 end
            else
                local pipePos = str:find("|", eqPos + 1)
                local val = pipePos and str:sub(eqPos + 1, pipePos - 1) or str:sub(eqPos + 1)
                if val == "T" then tbl[key] = true
                elseif val == "F" then tbl[key] = false
                elseif val:sub(1, 1) == "S" then tbl[key] = UnescapeStr(val:sub(2))
                else tbl[key] = tonumber(val) end
                pos = pipePos and (pipePos + 1) or (#str + 1)
            end
        end
        return tbl
    end

    function ns.ExportProfile(name)
        local p = HideChatDB.profiles and HideChatDB.profiles[name or HideChatCharDB.activeProfile]
        if not p then return nil end
        local data = Serialize(p)
        return "HC1:" .. ToBase64(data)
    end

    function ns.ImportProfile(str, targetName)
        if not str or not str:match("^HC1:") then
            print("|cFF2DD4BFHideChat:|r " .. L["Invalid import string."])
            return false
        end
        local encoded = str:sub(5)
        local ok, data = pcall(FromBase64, encoded)
        if not ok or not data or data == "" then
            print("|cFF2DD4BFHideChat:|r " .. L["Failed to decode import string."])
            return false
        end
        local ok2, tbl = pcall(Deserialize, data)
        if not ok2 or type(tbl) ~= "table" then
            print("|cFF2DD4BFHideChat:|r " .. L["Failed to parse import data."])
            return false
        end
        -- Validate: must have at least one known key
        local valid = false
        for k in pairs(tbl) do
            if settingKeys[k] then valid = true; break end
        end
        if not valid then
            print("|cFF2DD4BFHideChat:|r " .. L["Import data contains no valid settings."])
            return false
        end
        targetName = targetName or ("Imported " .. date("%H:%M"))
        if not HideChatDB.profiles then HideChatDB.profiles = {} end
        HideChatDB.profiles[targetName] = tbl
        print("|cFF2DD4BFHideChat:|r " .. string.format(L["Profile \"%s\" imported successfully."], targetName))
        return true
    end
end

---------------------------------------------------------------------------
-- Database initialisation  (handles v1.1 -> v1.2 -> v1.4 migration)
---------------------------------------------------------------------------
local function InitDB()
    if not HideChatDB then HideChatDB = {} end

    -- Flat defaults merge (skip tables & profiles key)
    for k, v in pairs(defaults) do
        if k ~= "profiles" and k ~= "instanceTypes" and k ~= "specProfiles" and k ~= "zoneMemory" then
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

    -- Spec profiles sub-table
    if not HideChatDB.specProfiles then
        HideChatDB.specProfiles = {}
    end

    -- Zone memory sub-table
    if not HideChatDB.zoneMemory then
        HideChatDB.zoneMemory = {}
    end

    -- Profile migration: existing flat settings -> "Default" profile
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
-- Events: login + combat + raid events + spec change + zone change
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

        -- Register additional events after login
        pcall(function() events:RegisterEvent("READY_CHECK") end)
        pcall(function() events:RegisterEvent("ENCOUNTER_START") end)
        pcall(function() events:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED") end)
        pcall(function() events:RegisterEvent("ZONE_CHANGED_NEW_AREA") end)
        pcall(function() events:RegisterEvent("ZONE_CHANGED") end)

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

    elseif event == "READY_CHECK" then
        if HideChatDB.raidAutoShow and ns.isHidden then
            ns._raidAutoShowed = true
            ns.ShowChat(true)
        end

    elseif event == "ENCOUNTER_START" then
        -- Re-hide chat if it was auto-shown by ready check
        if ns._raidAutoShowed and not ns.isHidden then
            ns._raidAutoShowed = false
            ns.HideChat(true)
        end

    elseif event == "ACTIVE_TALENT_GROUP_CHANGED" then
        -- Spec-bound profiles
        if HideChatDB.specProfiles then
            local specIndex = GetSpecialization and GetSpecialization() or nil
            if specIndex and HideChatDB.specProfiles[specIndex] then
                local targetProfile = HideChatDB.specProfiles[specIndex]
                if targetProfile ~= (HideChatCharDB.activeProfile or "Default") then
                    ns.SaveCurrentProfile()
                    ns.LoadProfile(targetProfile)
                    if ns.RefreshConfig then ns.RefreshConfig() end
                end
            end
        end

    elseif event == "ZONE_CHANGED_NEW_AREA" or event == "ZONE_CHANGED" then
        -- Apply per-zone memory
        C_Timer.After(0.5, function()
            ApplyZoneState()
        end)
    end
end)

---------------------------------------------------------------------------
-- Debug output (/hc debug)
---------------------------------------------------------------------------
function ns.PrintDebug()
    local mode = UseAlphaMethod() and "alpha" or "reparent"
    print("|cFF2DD4BF--- HideChat v" .. ns.version .. " Debug ---|r")
    print("  State: " .. (ns.isHidden and "|cFFFF4444HIDDEN|r" or "|cFF44FF44VISIBLE|r"))
    print("  Mode: " .. mode)
    print("  Profile: " .. (HideChatCharDB.activeProfile or "Default"))

    -- Spec profile bindings
    if HideChatDB.specProfiles then
        local any = false
        for spec, pName in pairs(HideChatDB.specProfiles) do
            if not any then print("  Spec Profiles:"); any = true end
            print("    Spec " .. spec .. " -> " .. pName)
        end
    end

    -- Managed frames
    local elements = ns.GetChatElements()
    print("  Managed frames: " .. #elements)
    for i, el in ipairs(elements) do
        local name = el:GetName() or ("<unnamed:" .. tostring(el) .. ">")
        local alpha = string.format("%.2f", el:GetAlpha())
        local parent = el:GetParent() and (el:GetParent():GetName() or "unnamed") or "nil"
        print("    " .. i .. ". " .. name .. " (a=" .. alpha .. " p=" .. parent .. ")")
    end

    -- Third-party detection
    local addons = {}
    local isLoaded = C_AddOns and C_AddOns.IsAddOnLoaded or IsAddOnLoaded
    if isLoaded then
        if pcall(isLoaded, "Prat-3.0") and isLoaded("Prat-3.0") then addons[#addons + 1] = "Prat-3.0" end
        if pcall(isLoaded, "Chattynator") and isLoaded("Chattynator") then addons[#addons + 1] = "Chattynator" end
    end
    if _G["ElvUI"]      then addons[#addons + 1] = "ElvUI" end
    if _G["GlassFrame"] then addons[#addons + 1] = "Glass" end
    print("  Chat addons: " .. (#addons > 0 and table.concat(addons, ", ") or "none"))

    -- Flags
    print("  Flags:")
    print("    combatHid=" .. tostring(ns._combatHid or false))
    print("    mouseoverActive=" .. tostring(ns.mouseoverActive))
    print("    peekActive=" .. tostring(ns._peekActive))
    print("    hasWhisper=" .. tostring(ns._hasWhisper or false))
    print("    raidAutoShowed=" .. tostring(ns._raidAutoShowed or false))

    -- Active timers
    print("  Settings:")
    print("    fade=" .. tostring(HideChatDB.fade) .. " dur=" .. string.format("%.1f", HideChatDB.fadeDuration))
    print("    opacity=" .. math.floor((HideChatDB.opacity or 0) * 100) .. "%")
    print("    combat=" .. tostring(HideChatDB.combat) .. " restore=" .. tostring(HideChatDB.combatRestore))
    print("    inactivity=" .. (HideChatDB.inactivityTimer or 0) .. "s")
    print("    mouseoverReveal=" .. tostring(HideChatDB.mouseoverReveal))
    print("    raidAutoShow=" .. tostring(HideChatDB.raidAutoShow))
    print("    whisperSound=" .. tostring(HideChatDB.whisperSound))
    print("    colorblind=" .. tostring(HideChatDB.colorblind))
    print("    scrollToRecent=" .. tostring(HideChatDB.scrollToRecent))
    print("    zoneMemory=" .. tostring(HideChatDB.zoneMemoryEnabled))

    -- Zone memory
    if HideChatDB.zoneMemoryEnabled and HideChatDB.zoneMemory then
        local count = 0
        for _ in pairs(HideChatDB.zoneMemory) do count = count + 1 end
        print("    zoneMemory entries: " .. count)
        local zoneID = GetCurrentZoneID()
        if zoneID then
            local state = HideChatDB.zoneMemory[zoneID]
            print("    currentZone=" .. zoneID .. " state=" .. tostring(state))
        end
    end

    print("|cFF2DD4BF--- End Debug ---|r")
end

---------------------------------------------------------------------------
-- Slash commands
---------------------------------------------------------------------------
SLASH_HIDECHAT1 = "/hidechat"
SLASH_HIDECHAT2 = "/hc"
SlashCmdList["HIDECHAT"] = function(msg)
    msg = strtrim(msg):lower()

    if msg == "config" or msg == "options" or msg == "settings" then
        if ns.ToggleConfig then ns.ToggleConfig() end

    elseif msg == "show" or msg == "on" then
        if ns.isHidden then ns.ShowChat() end

    elseif msg == "hide" or msg == "off" then
        if not ns.isHidden then ns.HideChat() end

    elseif msg == "debug" then
        ns.PrintDebug()

    elseif msg == "status" then
        local mode = UseAlphaMethod() and "alpha" or "reparent"
        print("|cFF00FF00HideChat v" .. ns.version .. "|r")
        print("  " .. L["Profile:"] .. " " .. (HideChatCharDB.activeProfile or "Default"))
        print("  " .. L["Chat:"] .. " " .. (ns.isHidden and "|cFFFF4444" .. L["hidden"] .. "|r" or "|cFF44FF44" .. L["visible"] .. "|r"))
        print("  " .. L["Mode:"] .. " " .. mode)
        print("  " .. L["Combat:"] .. " " .. (HideChatDB.combat and L["on"] or L["off"]))
        print("  " .. L["Fade:"] .. " " .. (HideChatDB.fade and string.format("%.1fs", HideChatDB.fadeDuration) or L["off"]))
        print("  " .. L["Opacity:"] .. " " .. math.floor((HideChatDB.opacity or 0) * 100) .. "%")
        if HideChatDB.instanceHide    then print("  " .. L["Instance auto-hide: on"]) end
        if HideChatDB.inactivityTimer > 0 then print("  " .. L["Inactivity:"] .. " " .. HideChatDB.inactivityTimer .. "s") end
        if HideChatDB.mouseoverReveal then print("  " .. L["Mouseover reveal: on"]) end
        if HideChatDB.keepCombatLog   then print("  " .. L["Combat log kept: on"]) end
        if HideChatDB.raidAutoShow    then print("  " .. L["Raid auto-show: on"]) end
        if HideChatDB.whisperSound    then print("  " .. L["Whisper sound: on"]) end
        if HideChatDB.zoneMemoryEnabled then print("  " .. L["Zone memory: on"]) end
        local addons = {}
        local isLoaded = C_AddOns and C_AddOns.IsAddOnLoaded or IsAddOnLoaded
        if isLoaded then
            if pcall(isLoaded, "Prat-3.0") and isLoaded("Prat-3.0") then addons[#addons + 1] = "Prat-3.0" end
        end
        if _G["ChattynatorFrame"] then addons[#addons + 1] = "Chattynator" end
        if _G["ElvUI"]            then addons[#addons + 1] = "ElvUI" end
        if _G["GlassFrame"]       then addons[#addons + 1] = "Glass" end
        if #addons > 0 then print("  " .. L["Chat addons:"] .. " " .. table.concat(addons, ", ")) end

    elseif msg:match("^export") then
        local name = msg:match("^export%s+(.+)") or HideChatCharDB.activeProfile
        local str = ns.ExportProfile(name)
        if str then
            print("|cFF2DD4BFHideChat:|r " .. string.format(L["Export string for \"%s\":"], name))
            print(str)
        else
            print("|cFF2DD4BFHideChat:|r " .. L["Profile not found."])
        end

    elseif msg:match("^import") then
        local rest = msg:match("^import%s+(.+)")
        if rest then
            ns.ImportProfile(rest)
        else
            print("|cFF2DD4BFHideChat:|r " .. L["Usage: /hc import HC1:..."])
        end

    elseif msg == "reset" then
        if ns.isHidden then ns.ShowChat(true) end
        for k, v in pairs(defaults) do
            if k ~= "profiles" then HideChatDB[k] = v end
        end
        HideChatDB.instanceTypes = { party = true, raid = true, pvp = true, arena = false, scenario = true }
        HideChatDB.specProfiles = {}
        HideChatDB.zoneMemory = {}
        if ns.UpdateButton  then ns.UpdateButton()  end
        if ns.UpdateMinimap then ns.UpdateMinimap() end
        if ns.RefreshConfig then ns.RefreshConfig() end
        print("|cFF00FF00HideChat:|r " .. L["Settings reset to defaults."])

    else
        HideChat_Toggle()
    end
end
