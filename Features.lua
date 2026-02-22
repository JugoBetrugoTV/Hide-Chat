local addonName, ns = ...
local L = ns.L

---------------------------------------------------------------------------
-- Initialise all feature modules (called from PLAYER_LOGIN)
---------------------------------------------------------------------------
function ns.InitFeatures()
    ns.InitInactivity()
    ns.InitMouseover()
    ns.InitInstanceHide()
    ns.InitWhisper()
    ns.InitScreenshot()
    ns.InitMinimapFallback()
end

---------------------------------------------------------------------------
-- 1.  INACTIVITY TIMER  - auto-hide after N seconds of silence,
--     optionally re-show when a new message arrives.
---------------------------------------------------------------------------
local inactivityHandle = nil

local function StartInactivityTimer()
    if inactivityHandle then inactivityHandle:Cancel(); inactivityHandle = nil end
    local delay = HideChatDB.inactivityTimer
    if not delay or delay <= 0 then return end
    if ns.isHidden then return end
    inactivityHandle = C_Timer.NewTimer(delay, function()
        inactivityHandle = nil
        if not ns.isHidden then
            ns.HideChat(true)
        end
    end)
end

function ns.ResetInactivityTimer()
    StartInactivityTimer()
end

function ns.InitInactivity()
    local f = CreateFrame("Frame")
    -- Register common chat events to detect "activity"
    for _, ev in ipairs({
        "CHAT_MSG_SAY", "CHAT_MSG_YELL", "CHAT_MSG_CHANNEL",
        "CHAT_MSG_WHISPER", "CHAT_MSG_WHISPER_INFORM",
        "CHAT_MSG_GUILD", "CHAT_MSG_OFFICER",
        "CHAT_MSG_PARTY", "CHAT_MSG_PARTY_LEADER",
        "CHAT_MSG_RAID", "CHAT_MSG_RAID_LEADER",
        "CHAT_MSG_INSTANCE_CHAT", "CHAT_MSG_INSTANCE_CHAT_LEADER",
        "CHAT_MSG_EMOTE", "CHAT_MSG_SYSTEM",
    }) do
        pcall(function() f:RegisterEvent(ev) end)
    end
    -- BNet (may not exist in Classic Era)
    pcall(function() f:RegisterEvent("CHAT_MSG_BN_WHISPER") end)
    pcall(function() f:RegisterEvent("CHAT_MSG_BN_WHISPER_INFORM") end)

    f:SetScript("OnEvent", function()
        if not HideChatDB or HideChatDB.inactivityTimer <= 0 then return end
        -- New message arrived: optionally re-show, then restart timer
        if ns.isHidden and HideChatDB.inactivityReshow then
            ns.ShowChat(true)
        end
        StartInactivityTimer()
    end)
end

-- Hook into hide/show lifecycle
function ns.OnChatHidden()
    -- Stop inactivity timer while already hidden
    if inactivityHandle then inactivityHandle:Cancel(); inactivityHandle = nil end
end

function ns.OnChatShown()
    StartInactivityTimer()
end

---------------------------------------------------------------------------
-- 2.  MOUSEOVER REVEAL  - show chat when cursor enters the chat area
---------------------------------------------------------------------------
function ns.InitMouseover()
    local detector = CreateFrame("Frame", "HideChatMouseoverDetector", UIParent)
    detector:SetFrameStrata("BACKGROUND")
    detector:EnableMouse(false)   -- transparent to clicks

    -- Compute the bounding box that covers ChatFrame1 AND any third-party
    -- chat panels (ElvUI, Chattynator, Glass) so mouseover works everywhere.
    local function UpdateDetectorBounds()
        detector:ClearAllPoints()

        -- Collect all visible chat regions to compute a union rect
        local lo, bo, ri, to  -- screen-space bounds (left, bottom, right, top)

        local function ExpandBounds(f)
            if not f or not f.GetLeft or not f:IsVisible() then return end
            local fl, fb, fw, fh = f:GetLeft(), f:GetBottom(), f:GetWidth(), f:GetHeight()
            if not fl or not fb then return end
            local fr, ft = fl + fw, fb + fh
            lo = lo and math.min(lo, fl) or fl
            bo = bo and math.min(bo, fb) or fb
            ri = ri and math.max(ri, fr) or fr
            to = to and math.max(to, ft) or ft
        end

        ExpandBounds(ChatFrame1)

        -- Third-party chat panels
        local tp = { "ChattynatorFrame", "LeftChatPanel", "RightChatPanel", "GlassFrame" }
        for _, name in ipairs(tp) do ExpandBounds(_G[name]) end

        if lo and bo and ri and to then
            detector:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", lo - 10, bo - 10)
            detector:SetPoint("TOPRIGHT", UIParent, "BOTTOMLEFT", ri + 10, to + 10)
        else
            -- Fallback: bottom-left area
            detector:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", 0, 0)
            detector:SetSize(440, 200)
        end
    end
    UpdateDetectorBounds()

    -- Re-anchor when chat frame moves (user drag, addon repositioning)
    if ChatFrame1 then
        hooksecurefunc(ChatFrame1, "SetPoint", UpdateDetectorBounds)
        -- Also hook resize events
        hooksecurefunc(ChatFrame1, "SetSize", UpdateDetectorBounds)
        if ChatFrame1.SetWidth then
            hooksecurefunc(ChatFrame1, "SetWidth", UpdateDetectorBounds)
        end
        if ChatFrame1.SetHeight then
            hooksecurefunc(ChatFrame1, "SetHeight", UpdateDetectorBounds)
        end
    end
    -- Also hook third-party panels if they exist at init time
    for _, name in ipairs({ "ChattynatorFrame", "LeftChatPanel", "GlassFrame" }) do
        local f = _G[name]
        if f then
            if f.SetPoint then hooksecurefunc(f, "SetPoint", UpdateDetectorBounds) end
            if f.SetSize  then hooksecurefunc(f, "SetSize",  UpdateDetectorBounds) end
            if f.SetWidth then hooksecurefunc(f, "SetWidth", UpdateDetectorBounds) end
            if f.SetHeight then hooksecurefunc(f, "SetHeight", UpdateDetectorBounds) end
        end
    end

    local active = false
    local cooldown = 0

    detector:SetScript("OnUpdate", function(self, elapsed)
        cooldown = cooldown - elapsed
        if not ns.isHidden then
            if active then active = false end
            return
        end
        if not HideChatDB.mouseoverReveal then return end
        if cooldown > 0 then return end

        if self:IsMouseOver() then
            if not active then
                active = true
                ns.MouseoverShow()
            end
        else
            if active then
                active = false
                cooldown = 0.2   -- small cooldown to prevent flicker
                ns.MouseoverHide()
            end
        end
    end)
end

---------------------------------------------------------------------------
-- 3.  INSTANCE-BASED AUTO-HIDE
---------------------------------------------------------------------------
function ns.InitInstanceHide()
    local f = CreateFrame("Frame")
    f:RegisterEvent("PLAYER_ENTERING_WORLD")
    f:RegisterEvent("ZONE_CHANGED_NEW_AREA")

    local wasHiddenByInstance = false

    f:SetScript("OnEvent", function()
        if not HideChatDB.instanceHide then
            -- Feature turned off: restore if we hid it
            if wasHiddenByInstance and ns.isHidden then
                wasHiddenByInstance = false
                ns.ShowChat(true)
            end
            return
        end

        local inInstance, instanceType = IsInInstance()
        local shouldHide = inInstance
            and HideChatDB.instanceTypes
            and HideChatDB.instanceTypes[instanceType]

        if shouldHide and not ns.isHidden then
            wasHiddenByInstance = true
            ns.HideChat(true)
        elseif not shouldHide and wasHiddenByInstance then
            wasHiddenByInstance = false
            if ns.isHidden then ns.ShowChat(true) end
        end
    end)
end

---------------------------------------------------------------------------
-- 4.  WHISPER PASSTHROUGH  +  WHISPER NOTIFICATION  +  SOUND  +  QUICK-REPLY
---------------------------------------------------------------------------
-- Track last whisper sender for quick-reply
ns._lastWhisperSender = nil
ns._lastWhisperIsBNet = false

function ns.InitWhisper()
    local f = CreateFrame("Frame")
    f:RegisterEvent("CHAT_MSG_WHISPER")
    pcall(function() f:RegisterEvent("CHAT_MSG_BN_WHISPER") end)

    f:SetScript("OnEvent", function(_, event, text, sender)
        if not ns.isHidden then return end

        -- Track sender for quick-reply
        ns._lastWhisperSender = sender
        ns._lastWhisperIsBNet = (event == "CHAT_MSG_BN_WHISPER")

        -- Passthrough: show whisper text in UIErrorsFrame
        if HideChatDB.whisperPass and UIErrorsFrame then
            local tag = (event == "CHAT_MSG_BN_WHISPER") and "[BNet] " or ""
            local line = "|cFFFF88FF" .. tag .. sender .. ":|r " .. text
            UIErrorsFrame:AddMessage(line, 1, 1, 1, 1, 5)
        end

        -- Sound notification
        if HideChatDB.whisperSound then
            local soundID = SOUNDKIT and SOUNDKIT.TELL_MESSAGE or 3081
            PlaySound(soundID, "Master")
        end

        -- Notification: tell Button.lua to start blinking
        if HideChatDB.whisperNotify then
            if ns.StartBlink then ns.StartBlink() end
        end
    end)
end

-- Quick-reply: open edit box with /w <sender> pre-filled
function ns.QuickReply()
    if not ns._lastWhisperSender then
        print("|cFF2DD4BFHideChat:|r " .. L["No recent whisper to reply to."])
        return
    end
    -- Show chat first if hidden
    if ns.isHidden then ns.ShowChat() end
    local prefix
    if ns._lastWhisperIsBNet then
        prefix = "/w " .. ns._lastWhisperSender .. " "
    else
        prefix = "/w " .. ns._lastWhisperSender .. " "
    end
    if ChatFrame_OpenChat then
        ChatFrame_OpenChat(prefix)
    end
end

---------------------------------------------------------------------------
-- 5.  SCREENSHOT MODE  - hide chat briefly for a clean screenshot
---------------------------------------------------------------------------
function ns.InitScreenshot()
    if not Screenshot then return end
    local orig = Screenshot
    Screenshot = function(...)
        if HideChatDB.screenshotHide and not ns.isHidden then
            -- Instantly hide (no fade) for a clean capture
            local saved = HideChatDB.fade
            HideChatDB.fade = false
            ns.HideChat(true)
            HideChatDB.fade = saved
            -- Restore after the frame is rendered
            C_Timer.After(0.15, function()
                ns.ShowChat(true)
            end)
        end
        return orig(...)
    end
end

---------------------------------------------------------------------------
-- 6.  MINIMAP BUTTON FALLBACK  - anchor to UIParent if Minimap is hidden
---------------------------------------------------------------------------
function ns.InitMinimapFallback()
    if not Minimap then return end
    -- Cancel previous ticker if re-initialised (e.g. after /reload)
    if ns._minimapFallbackTicker then
        ns._minimapFallbackTicker:Cancel()
        ns._minimapFallbackTicker = nil
    end
    local minimapBtn = _G["HideChatMinimapButton"]
    -- Check periodically (every 2s) if minimap visibility changed
    local wasVisible = Minimap:IsVisible()
    ns._minimapFallbackTicker = C_Timer.NewTicker(2, function()
        minimapBtn = minimapBtn or _G["HideChatMinimapButton"]
        if not minimapBtn then return end
        local visible = Minimap:IsVisible()
        if visible == wasVisible then return end
        wasVisible = visible
        if not visible then
            -- Minimap hidden: move button to UIParent
            minimapBtn:SetParent(UIParent)
            minimapBtn:ClearAllPoints()
            minimapBtn:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -20, -20)
        else
            -- Minimap restored: move back
            minimapBtn:SetParent(Minimap)
            if ns.UpdateMinimap then ns.UpdateMinimap() end
        end
    end)
end
