local MT = MageTools
local CM = {}
MT:RegisterModule("ConjureManager", CM)

local hudFrame = nil
local sessionFrame = nil
local counts = { food = 0, water = 0, gem = 0 }
local hudButtons = {}

local BUTTON_SIZE = 32

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
        local numSlots = GetContainerNumSlots(bag)
        for slot = 1, numSlots do
            local itemID = GetContainerItemID(bag, slot)
            if itemID then
                local itemType = MT.CONJURED_ITEM_SET[itemID]
                if itemType then
                    local _, itemCount = GetContainerItemInfo(bag, slot)
                    counts[itemType] = counts[itemType] + (itemCount or 0)
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

    -- Update popup menu item counters
    local pm = MT.modules["PopupMenu"]
    if pm and pm.UpdateItemCounts then
        pm:UpdateItemCounts(counts)
    end

    -- Update conjure session if open
    if sessionFrame and sessionFrame:IsShown() then
        self:UpdateSessionProgress()
    end
end

-- HUD
function CM:CreateHUD()
    hudFrame = CreateFrame("Frame", "MageToolsHUD", UIParent)
    hudFrame:SetSize((BUTTON_SIZE * 3) + 16, BUTTON_SIZE + 16)
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

    hudFrame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 12,
        insets = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    hudFrame:SetBackdropColor(0, 0, 0, 0.6)

    local categories = {
        { type = "gem",   items = MT.MANA_GEMS },
        { type = "food",  items = MT.CONJURED_FOOD },
        { type = "water", items = MT.CONJURED_WATER },
    }

    for i, cat in ipairs(categories) do
        local btn = CreateFrame("Button", "MageToolsHUD" .. cat.type, hudFrame)
        btn:SetSize(BUTTON_SIZE, BUTTON_SIZE)
        btn:SetPoint("LEFT", hudFrame, "LEFT", 8 + ((i - 1) * (BUTTON_SIZE + 2)), 0)

        local iconPath = GetItemIcon(cat.items[1])
        local iconTex = btn:CreateTexture(nil, "BACKGROUND")
        iconTex:SetAllPoints()
        if iconPath then iconTex:SetTexture(iconPath) end
        btn.icon = iconTex

        local normalTex = btn:CreateTexture(nil, "OVERLAY")
        normalTex:SetAllPoints()
        normalTex:SetTexture("Interface\\Buttons\\UI-Quickslot2")
        btn:SetNormalTexture(normalTex)

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

-- Conjure Session
function CM:CreateConjureSession()
    sessionFrame = CreateFrame("Frame", "MageToolsConjureSession", UIParent)
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
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    sessionFrame:SetBackdropColor(0, 0, 0, 0.9)

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
        return GetNumRaidMembers()
    elseif IsInGroup() then
        return GetNumPartyMembers() + 1
    end
    return 1
end

function CM:UpdateSessionProgress()
    local groupSize = self:GetGroupSize()
    local ratio = MageToolsDB.stacksPerPerson
    local neededFood = groupSize * ratio * 20
    local neededWater = groupSize * ratio * 20

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
