local addonName, ns = ...

---------------------------------------------------------------------------
-- Initialise all feature modules (called from PLAYER_LOGIN)
---------------------------------------------------------------------------
function ns.InitFeatures()
    ns.InitInactivity()
    ns.InitMouseover()
    ns.InitInstanceHide()
    ns.InitWhisper()
    ns.InitScreenshot()
end

---------------------------------------------------------------------------
-- 1.  INACTIVITY TIMER  – auto-hide after N seconds of silence,
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
-- 2.  MOUSEOVER REVEAL  – show chat when cursor enters the chat area
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
        local s = UIParent:GetEffectiveScale()

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
    end
    -- Also hook third-party panels if they exist at init time
    for _, name in ipairs({ "ChattynatorFrame", "LeftChatPanel", "GlassFrame" }) do
        local f = _G[name]
        if f and f.SetPoint then
            hooksecurefunc(f, "SetPoint", UpdateDetectorBounds)
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
-- 4.  WHISPER PASSTHROUGH  +  WHISPER NOTIFICATION
---------------------------------------------------------------------------
function ns.InitWhisper()
    local f = CreateFrame("Frame")
    f:RegisterEvent("CHAT_MSG_WHISPER")
    pcall(function() f:RegisterEvent("CHAT_MSG_BN_WHISPER") end)

    f:SetScript("OnEvent", function(_, event, text, sender)
        if not ns.isHidden then return end

        -- Passthrough: show whisper text in UIErrorsFrame
        if HideChatDB.whisperPass then
            local tag = (event == "CHAT_MSG_BN_WHISPER") and "[BNet] " or ""
            local line = "|cFFFF88FF" .. tag .. sender .. ":|r " .. text
            UIErrorsFrame:AddMessage(line, 1, 1, 1, 1, 5)
        end

        -- Notification: tell Button.lua to start blinking
        if HideChatDB.whisperNotify then
            if ns.StartBlink then ns.StartBlink() end
        end
    end)
end

---------------------------------------------------------------------------
-- 5.  SCREENSHOT MODE  – hide chat briefly for a clean screenshot
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
