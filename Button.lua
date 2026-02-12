local addonName, ns = ...

local btn

---------------------------------------------------------------------------
-- Create the movable toggle button
---------------------------------------------------------------------------
function ns.InitButton()
    if btn then return end

    btn = CreateFrame("Button", "HideChatToggleButton", UIParent)
    btn:SetSize(30, 30)
    btn:SetFrameStrata("HIGH")
    btn:SetClampedToScreen(true)

    -- Dark background
    local bg = btn:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0.12, 0.12, 0.12, 0.85)
    btn.bg = bg

    -- Bright border highlight on hover
    local highlight = btn:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetAllPoints()
    highlight:SetColorTexture(1, 1, 1, 0.10)

    -- Chat bubble icon
    local icon = btn:CreateTexture(nil, "ARTWORK")
    icon:SetSize(20, 20)
    icon:SetPoint("CENTER")
    icon:SetTexture("Interface\\GossipFrame\\ChatBubbleGossipIcon")
    btn.icon = icon

    -- State colour dot (green = visible, red = hidden)
    local overlay = btn:CreateTexture(nil, "ARTWORK", nil, 1)
    overlay:SetSize(8, 8)
    overlay:SetPoint("BOTTOMRIGHT", -3, 3)
    btn.overlay = overlay

    ---------- position ---------------------------------------------------
    local pos = HideChatDB.buttonPos
    if pos then
        btn:ClearAllPoints()
        btn:SetPoint(pos.point, UIParent, pos.relPoint, pos.x, pos.y)
    else
        -- Safe default: fixed position in bottom-left, above the chat area
        btn:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", 4, 165)
    end

    ---------- dragging ---------------------------------------------------
    btn:SetMovable(true)
    btn:EnableMouse(true)
    btn:RegisterForDrag("LeftButton")
    btn:RegisterForClicks("AnyUp")

    btn:SetScript("OnDragStart", function(self)
        if not HideChatDB.lockButton then
            self:StartMoving()
        end
    end)

    btn:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local point, _, relPoint, x, y = self:GetPoint()
        HideChatDB.buttonPos = {
            point    = point,
            relPoint = relPoint,
            x        = x,
            y        = y,
        }
    end)

    ---------- clicks -----------------------------------------------------
    btn:SetScript("OnClick", function(_, button)
        if button == "RightButton" then
            if ns.ToggleConfig then ns.ToggleConfig() end
        else
            HideChat_Toggle()
        end
    end)

    ---------- tooltip ----------------------------------------------------
    btn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
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
        if not HideChatDB.lockButton then
            GameTooltip:AddLine("Drag: Move button", 0.5, 0.5, 0.5)
        end
        GameTooltip:Show()
    end)
    btn:SetScript("OnLeave", function() GameTooltip:Hide() end)

    ---------- visibility -------------------------------------------------
    if not HideChatDB.showButton then btn:Hide() end
    ns.UpdateButton()
end

---------------------------------------------------------------------------
-- Refresh button visuals to match current hidden state
---------------------------------------------------------------------------
function ns.UpdateButton()
    if not btn then return end

    if HideChatDB.showButton then
        btn:Show()
    else
        btn:Hide()
        return
    end

    if ns.isHidden then
        btn.bg:SetColorTexture(0.45, 0.08, 0.08, 0.85)
        btn.overlay:SetColorTexture(0.9, 0.2, 0.2, 1)
        btn.icon:SetDesaturated(true)
        btn.icon:SetVertexColor(0.7, 0.7, 0.7)
    else
        btn.bg:SetColorTexture(0.08, 0.30, 0.08, 0.85)
        btn.overlay:SetColorTexture(0.2, 0.9, 0.2, 1)
        btn.icon:SetDesaturated(false)
        btn.icon:SetVertexColor(1, 1, 1)
    end
end

---------------------------------------------------------------------------
-- Reset button position to default (called from config)
---------------------------------------------------------------------------
function ns.ResetButtonPos()
    if not btn then return end
    HideChatDB.buttonPos = nil
    btn:ClearAllPoints()
    btn:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", 4, 165)
end
