local MT = MageTools
local CM = {}
MT:RegisterModule("ConjureManager", CM)

local hudFrame = nil
local sessionFrame = nil
local counts = { food = 0, water = 0, gem = 0 }
local hudButtons = {}

function CM:Init()
    self:ScanBags()
    self:CreateHUD()
    self:CreateConjureSession()
    if MageToolsDB.hudVisible then
        hudFrame:Show()
    else
        hudFrame:Hide()
    end
end

-- Bag scanning
function CM:ScanBags()
    counts.food = 0
    counts.water = 0
    counts.gem = 0
    for bag = 0, NUM_BAG_SLOTS do
        local numSlots = C_Container.GetContainerNumSlots(bag)
        for slot = 1, numSlots do
            local info = C_Container.GetContainerItemInfo(bag, slot)
            if info and info.itemID then
                local itemType = MT.CONJURED_ITEM_SET[info.itemID]
                if itemType then
                    counts[itemType] = counts[itemType] + (info.stackCount or 0)
                end
            end
        end
    end
    self:UpdateDisplays()
end

function CM:GetCounts()
    return counts
end

function CM:UpdateDisplays()
    -- Update HUD
    for _, btn in ipairs(hudButtons) do
        local count = counts[btn.itemType] or 0
        btn.countText:SetText(count > 0 and count or "0")
    end

    -- Update conjure session if open
    if sessionFrame and sessionFrame:IsShown() then
        self:UpdateSessionProgress()
    end
end

-- HUD
function CM:CreateHUD()
    hudFrame = CreateFrame("Frame", "MageToolsHUD", UIParent, "BackdropTemplate")
    local btnSize = MageToolsDB.hudButtonSize
    local vertical = MageToolsDB.hudVertical
    if vertical then
        hudFrame:SetSize(btnSize + 16, (btnSize * 3) + 16)
    else
        hudFrame:SetSize((btnSize * 3) + 16, btnSize + 16)
    end
    hudFrame:SetPoint(
        MageToolsDB.hudPoint or "CENTER",
        UIParent,
        MageToolsDB.hudPoint or "CENTER",
        MageToolsDB.hudX or 0,
        MageToolsDB.hudY or 0
    )
    hudFrame:SetFrameStrata("LOW")
    hudFrame:SetClampedToScreen(true)
    hudFrame:SetMovable(true)
    hudFrame:EnableMouse(true)
    hudFrame:RegisterForDrag("LeftButton")
    hudFrame:SetScript("OnDragStart", function(self) self:StartMoving() end)
    hudFrame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local point, _, _, x, y = self:GetPoint()
        MageToolsDB.hudPoint = point
        MageToolsDB.hudX = x
        MageToolsDB.hudY = y
    end)

    hudFrame:SetBackdrop(nil)

    local categories = {
        { type = "gem",   items = MT.MANA_GEMS },
        { type = "food",  items = MT.CONJURED_FOOD },
        { type = "water", items = MT.CONJURED_WATER },
    }

    for i, cat in ipairs(categories) do
        local btn = CreateFrame("Button", "MageToolsHUD" .. cat.type, hudFrame)
        btn:SetSize(btnSize, btnSize)
        if vertical then
            btn:SetPoint("TOP", hudFrame, "TOP", 0, -8 - ((i - 1) * (btnSize + 2)))
        else
            btn:SetPoint("LEFT", hudFrame, "LEFT", 8 + ((i - 1) * (btnSize + 2)), 0)
        end

        local iconPath = GetItemIcon(cat.items[1])
        local iconTex = btn:CreateTexture(nil, "BACKGROUND")
        iconTex:SetAllPoints()
        if iconPath then iconTex:SetTexture(iconPath) end
        btn.icon = iconTex

        local normalTex
        if MT.Masque:IsEnabled() then
            normalTex = btn:CreateTexture(nil, "OVERLAY")
            normalTex:SetAllPoints()
            btn:SetNormalTexture(normalTex)
        end

        local countText = btn:CreateFontString(nil, "OVERLAY", "NumberFontNormalLarge")
        countText:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", -2, 2)
        btn.countText = countText
        btn.itemType = cat.type

        MT.Masque:AddButton("HUD", btn, {
            Icon = iconTex,
            Normal = normalTex,
        })

        tinsert(hudButtons, btn)
    end
    MT.Masque:ReSkin("HUD")
end

function CM:ToggleHUD()
    if hudFrame:IsShown() then
        hudFrame:Hide()
        MageToolsDB.hudVisible = false
        print("|cff69ccf0MageTools|r HUD hidden.")
    else
        hudFrame:Show()
        MageToolsDB.hudVisible = true
        print("|cff69ccf0MageTools|r HUD shown.")
    end
end

function CM:RebuildHUD()
    if not hudFrame then return end
    local btnSize = MageToolsDB.hudButtonSize
    local vertical = MageToolsDB.hudVertical
    if vertical then
        hudFrame:SetSize(btnSize + 16, (btnSize * 3) + 16)
    else
        hudFrame:SetSize((btnSize * 3) + 16, btnSize + 16)
    end
    for i, btn in ipairs(hudButtons) do
        btn:SetSize(btnSize, btnSize)
        btn:ClearAllPoints()
        if vertical then
            btn:SetPoint("TOP", hudFrame, "TOP", 0, -8 - ((i - 1) * (btnSize + 2)))
        else
            btn:SetPoint("LEFT", hudFrame, "LEFT", 8 + ((i - 1) * (btnSize + 2)), 0)
        end
    end
end

-- Conjure Session
function CM:CreateConjureSession()
    sessionFrame = CreateFrame("Frame", "MageToolsConjureSession", UIParent, "BackdropTemplate")
    sessionFrame:SetSize(220, 180)
    sessionFrame:SetPoint("CENTER")
    sessionFrame:SetFrameStrata("HIGH")
    sessionFrame:SetClampedToScreen(true)
    sessionFrame:SetMovable(true)
    sessionFrame:EnableMouse(true)
    sessionFrame:RegisterForDrag("LeftButton")
    sessionFrame:SetScript("OnDragStart", function(self) self:StartMoving() end)
    sessionFrame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
    sessionFrame:Hide()

    tinsert(UISpecialFrames, "MageToolsConjureSession")

    sessionFrame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 12,
        insets = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    sessionFrame:SetBackdropColor(0, 0, 0, MageToolsDB.sessionBgAlpha)

    -- Close button
    local closeBtn = CreateFrame("Button", nil, sessionFrame, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", sessionFrame, "TOPRIGHT", -2, -2)

    -- Title
    local title = sessionFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -10)
    title:SetText("|cff69ccf0Conjure Session|r")

    -- Group size display
    local groupText = sessionFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    groupText:SetPoint("TOP", 0, -32)
    sessionFrame.groupText = groupText

    -- Food progress
    local foodText = sessionFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    foodText:SetPoint("TOP", 0, -52)
    sessionFrame.foodText = foodText

    -- Water progress
    local waterText = sessionFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    waterText:SetPoint("TOP", 0, -72)
    sessionFrame.waterText = waterText

    -- Status
    local statusText = sessionFrame:CreateFontString(nil, "OVERLAY", "GameFontGreen")
    statusText:SetPoint("TOP", 0, -96)
    sessionFrame.statusText = statusText

    -- Conjure Food button
    local foodBtn = CreateFrame("Button", "MageToolsConjureFood", sessionFrame, "SecureActionButtonTemplate")
    foodBtn:SetSize(90, 28)
    foodBtn:SetPoint("BOTTOMLEFT", sessionFrame, "BOTTOMLEFT", 12, 12)
    foodBtn:SetAttribute("type", "spell")
    foodBtn:SetAttribute("spell", GetSpellInfo(MT.CONJURE_FOOD_SPELL))
    foodBtn:RegisterForClicks("AnyUp", "AnyDown")
    local foodNormal = foodBtn:GetNormalTexture()
    if foodNormal then foodNormal:SetTexture(nil); foodNormal:Hide() end
    foodBtn:SetNormalFontObject("GameFontNormal")
    foodBtn:SetText("Food")
    local foodBtnTex = foodBtn:CreateTexture(nil, "BACKGROUND")
    foodBtnTex:SetAllPoints()
    foodBtnTex:SetTexture("Interface\\Buttons\\UI-Panel-Button-Up")
    foodBtnTex:SetTexCoord(0, 0.625, 0, 0.6875)
    sessionFrame.foodBtn = foodBtn

    -- Conjure Water button
    local waterBtn = CreateFrame("Button", "MageToolsConjureWater", sessionFrame, "SecureActionButtonTemplate")
    waterBtn:SetSize(90, 28)
    waterBtn:SetPoint("BOTTOMRIGHT", sessionFrame, "BOTTOMRIGHT", -12, 12)
    waterBtn:SetAttribute("type", "spell")
    waterBtn:SetAttribute("spell", GetSpellInfo(MT.CONJURE_WATER_SPELL))
    waterBtn:RegisterForClicks("AnyUp", "AnyDown")
    local waterNormal = waterBtn:GetNormalTexture()
    if waterNormal then waterNormal:SetTexture(nil); waterNormal:Hide() end
    waterBtn:SetNormalFontObject("GameFontNormal")
    waterBtn:SetText("Water")
    local waterBtnTex = waterBtn:CreateTexture(nil, "BACKGROUND")
    waterBtnTex:SetAllPoints()
    waterBtnTex:SetTexture("Interface\\Buttons\\UI-Panel-Button-Up")
    waterBtnTex:SetTexCoord(0, 0.625, 0, 0.6875)
    sessionFrame.waterBtn = waterBtn
end

function CM:GetGroupSize()
    if IsInRaid() then
        return GetNumGroupMembers()
    elseif IsInGroup() then
        return GetNumGroupMembers()
    end
    return 1
end

function CM:UpdateSessionProgress()
    local groupSize = self:GetGroupSize()
    local neededFood = groupSize * MageToolsDB.foodStacksPerPerson * 20
    local neededWater = groupSize * MageToolsDB.waterStacksPerPerson * 20

    sessionFrame.groupText:SetText("Group size: " .. groupSize)
    sessionFrame.foodText:SetText("Food: " .. counts.food .. " / " .. neededFood)
    sessionFrame.waterText:SetText("Water: " .. counts.water .. " / " .. neededWater)

    if counts.food >= neededFood and counts.water >= neededWater then
        sessionFrame.statusText:SetText("Stocked up!")
    else
        sessionFrame.statusText:SetText("")
    end
end

function CM:ToggleConjureSession()
    if sessionFrame:IsShown() then
        sessionFrame:Hide()
    else
        self:UpdateSessionProgress()
        sessionFrame:Show()
    end
end

function CM:OnEvent(event, ...)
    if event == "BAG_UPDATE" then
        self:ScanBags()
    end
end

MT:RegisterEvents("BAG_UPDATE")
