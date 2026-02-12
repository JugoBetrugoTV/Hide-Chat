local addonName, ns = ...

---------------------------------------------------------------------------
-- Keybinding header / label (shown in Key Bindings UI)
---------------------------------------------------------------------------
BINDING_HEADER_HIDECHAT = "HideChat"
BINDING_NAME_HIDECHAT_TOGGLE = "Toggle Chat Visibility"

---------------------------------------------------------------------------
-- State
---------------------------------------------------------------------------
local isHidden = false
local savedParents = {}

-- Invisible anchor – anything parented to this frame becomes invisible and
-- unclickable, even if WoW's own code calls :Show() on it.
local anchor = CreateFrame("Frame", "HideChatAnchor", UIParent)
anchor:Hide()

---------------------------------------------------------------------------
-- Collect every chat-related UI element that should be hidden.
-- Nil-checks keep this compatible across Retail, Classic Era, TBC and MoP.
---------------------------------------------------------------------------
local function GetChatElements()
    local elements = {}

    for i = 1, NUM_CHAT_WINDOWS do
        local chatFrame = _G["ChatFrame" .. i]
        if chatFrame then
            elements[#elements + 1] = chatFrame
        end
    end

    -- The dock manager holds the chat tabs
    if GeneralDockManager then
        elements[#elements + 1] = GeneralDockManager
    end

    -- Buttons that sit next to the chat frame (may not exist in every version)
    local extras = {
        "ChatFrameMenuButton",
        "ChatFrameChannelButton",
        "QuickJoinToastButton",
        "ChatFrameToggleVoiceDeafenButton",
        "ChatFrameToggleVoiceMuteButton",
    }
    for _, name in ipairs(extras) do
        local frame = _G[name]
        if frame then
            elements[#elements + 1] = frame
        end
    end

    return elements
end

---------------------------------------------------------------------------
-- Hide / Show helpers
---------------------------------------------------------------------------
local function DoHide()
    local elements = GetChatElements()
    for _, el in ipairs(elements) do
        if not savedParents[el] then
            savedParents[el] = el:GetParent()
        end
        el:SetParent(anchor)
    end
end

local function DoShow()
    for el, parent in pairs(savedParents) do
        el:SetParent(parent)
        el:Show()
    end
    savedParents = {}

    -- Re-select the primary chat tab so the dock state is restored properly
    if FCF_SelectDockFrame and ChatFrame1 then
        FCF_SelectDockFrame(ChatFrame1)
    end
end

---------------------------------------------------------------------------
-- Toggle (global – referenced from Bindings.xml)
---------------------------------------------------------------------------
function HideChat_Toggle()
    if isHidden then
        DoShow()
        isHidden = false
        print("|cFF00FF00HideChat:|r Chat visible")
    else
        DoHide()
        isHidden = true
        -- Use the error frame so the message is visible even though chat is gone
        UIErrorsFrame:AddMessage("|cFF00FF00HideChat:|r Chat hidden", 1, 1, 1, 1, 3)
    end

    if HideChatDB then
        HideChatDB.hidden = isHidden
    end
end

---------------------------------------------------------------------------
-- Restore saved state on login
---------------------------------------------------------------------------
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGIN" then
        HideChatDB = HideChatDB or { hidden = false }

        if HideChatDB.hidden then
            -- Short delay so every chat frame has finished initialising
            C_Timer.After(0.5, function()
                DoHide()
                isHidden = true
            end)
        end
    end
end)

---------------------------------------------------------------------------
-- Slash commands:  /hidechat  or  /hc
---------------------------------------------------------------------------
SLASH_HIDECHAT1 = "/hidechat"
SLASH_HIDECHAT2 = "/hc"
SlashCmdList["HIDECHAT"] = function()
    HideChat_Toggle()
end
