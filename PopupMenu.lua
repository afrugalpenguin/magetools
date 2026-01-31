local MT = MageTools
local PM = {}
MT:RegisterModule("PopupMenu", PM)

local popup = nil
local buttons = {}
local itemButtons = {}
local BUTTON_SIZE = 36
local BUTTON_PADDING = 4
local COLUMNS = 5

-- Binding header and name (for Key Bindings UI)
BINDING_HEADER_MAGETOOLS = "MageTools"
BINDING_NAME_MAGETOOLS_POPUP = "Toggle Portal Menu"

function MageTools_TogglePopup()
    if not popup then return end
    if popup:IsShown() then
        popup:Hide()
    else
        PM:ShowAtCursor()
    end
end

function PM:Init()
    MT.Masque:Init()
    self:CreatePopup()
end

function PM:CreatePopup()
    popup = CreateFrame("Frame", "MageToolsPopup", UIParent)
    popup:SetFrameStrata("DIALOG")
    popup:SetClampedToScreen(true)
    popup:Hide()
    popup:EnableMouse(true)

    -- Close on Escape
    tinsert(UISpecialFrames, "MageToolsPopup")

    -- Close when clicking outside
    popup:SetScript("OnMouseDown", function() end)

    -- Background
    popup:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    popup:SetBackdropColor(0, 0, 0, 0.85)

    self:BuildButtons()
end

function PM:BuildButtons()
    -- Clear old buttons
    for _, btn in ipairs(buttons) do btn:Hide() end
    wipe(buttons)
    for _, btn in ipairs(itemButtons) do btn:Hide() end
    wipe(itemButtons)

    local playerFaction = UnitFactionGroup("player")
    local knownTeleports = {}
    local knownPortals = {}

    for _, spell in ipairs(MT.TELEPORTS) do
        if (spell.faction == playerFaction or spell.faction == "Neutral") and IsSpellKnown(spell.spellID) then
            tinsert(knownTeleports, spell)
        end
    end
    for _, spell in ipairs(MT.PORTALS) do
        if (spell.faction == playerFaction or spell.faction == "Neutral") and IsSpellKnown(spell.spellID) then
            tinsert(knownPortals, spell)
        end
    end

    local yOffset = -8
    local maxCols = 0

    -- Teleport row(s)
    local cols = self:CreateSpellRow(knownTeleports, yOffset, "Teleport")
    if cols > maxCols then maxCols = cols end
    local teleportRows = math.ceil(#knownTeleports / COLUMNS)
    yOffset = yOffset - (teleportRows * (BUTTON_SIZE + BUTTON_PADDING))

    -- Divider
    if #knownTeleports > 0 and #knownPortals > 0 then
        local divider = popup:CreateTexture(nil, "ARTWORK")
        divider:SetHeight(1)
        divider:SetPoint("TOPLEFT", popup, "TOPLEFT", 8, yOffset - 2)
        divider:SetPoint("TOPRIGHT", popup, "TOPRIGHT", -8, yOffset - 2)
        divider:SetColorTexture(0.5, 0.5, 0.5, 0.5)
        yOffset = yOffset - 6
    end

    -- Portal row(s)
    cols = self:CreateSpellRow(knownPortals, yOffset, "Portal")
    if cols > maxCols then maxCols = cols end
    local portalRows = math.ceil(#knownPortals / COLUMNS)
    yOffset = yOffset - (portalRows * (BUTTON_SIZE + BUTTON_PADDING))

    -- Item counters along the bottom
    yOffset = yOffset - 4
    self:CreateItemCounters(yOffset)
    yOffset = yOffset - (BUTTON_SIZE + 8)

    -- Size the popup
    local totalCols = maxCols > 0 and maxCols or COLUMNS
    local width = (totalCols * (BUTTON_SIZE + BUTTON_PADDING)) + BUTTON_PADDING + 16
    local height = math.abs(yOffset) + 8
    popup:SetSize(width, height)
end

function PM:CreateSpellRow(spells, yOffset, prefix)
    local col = 0
    local row = 0
    for i, spell in ipairs(spells) do
        local btn = CreateFrame("Button", "MageTools" .. prefix .. "Btn" .. i, popup, "SecureActionButtonTemplate")
        btn:SetSize(BUTTON_SIZE, BUTTON_SIZE)
        local x = 8 + (col * (BUTTON_SIZE + BUTTON_PADDING))
        local y = yOffset - (row * (BUTTON_SIZE + BUTTON_PADDING))
        btn:SetPoint("TOPLEFT", popup, "TOPLEFT", x, y)

        btn:SetAttribute("type", "spell")
        btn:SetAttribute("spell", spell.spellID)
        btn:RegisterForClicks("AnyUp", "AnyDown")

        -- Icon
        local spellName, _, icon = GetSpellInfo(spell.spellID)
        local iconTex = btn:CreateTexture(nil, "BACKGROUND")
        iconTex:SetAllPoints()
        iconTex:SetTexture(icon)
        btn.icon = iconTex

        -- Normal/highlight textures for Masque compatibility
        local normalTex = btn:CreateTexture(nil, "OVERLAY")
        normalTex:SetAllPoints()
        normalTex:SetTexture("Interface\\Buttons\\UI-Quickslot2")
        btn:SetNormalTexture(normalTex)

        local highlightTex = btn:CreateTexture(nil, "HIGHLIGHT")
        highlightTex:SetAllPoints()
        highlightTex:SetTexture("Interface\\Buttons\\ButtonHilight-Square")
        highlightTex:SetBlendMode("ADD")
        btn:SetHighlightTexture(highlightTex)

        -- Tooltip
        btn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetSpellByID(spell.spellID)
            GameTooltip:Show()
        end)
        btn:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)

        -- Close popup after casting
        btn:SetScript("PostClick", function()
            popup:Hide()
        end)

        MT.Masque:AddButton("Popup", btn, {
            Icon = iconTex,
            Normal = normalTex,
            Highlight = highlightTex,
        })

        tinsert(buttons, btn)

        col = col + 1
        if col >= COLUMNS then
            col = 0
            row = row + 1
        end
    end
    MT.Masque:ReSkin("Popup")
    return math.min(#spells, COLUMNS)
end

function PM:CreateItemCounters(yOffset)
    local categories = {
        { type = "gem",   label = "Gem" },
        { type = "food",  label = "Food" },
        { type = "water", label = "Water" },
    }

    for i, cat in ipairs(categories) do
        local btn = CreateFrame("Button", "MageToolsItem" .. cat.label, popup)
        btn:SetSize(BUTTON_SIZE, BUTTON_SIZE)
        local x = 8 + ((i - 1) * (BUTTON_SIZE + BUTTON_PADDING))
        btn:SetPoint("TOPLEFT", popup, "TOPLEFT", x, yOffset)

        -- Get icon from first item in category
        local itemList
        if cat.type == "food" then itemList = MT.CONJURED_FOOD
        elseif cat.type == "water" then itemList = MT.CONJURED_WATER
        else itemList = MT.MANA_GEMS end

        local _, _, iconPath = GetItemInfo(itemList[1])
        local iconTex = btn:CreateTexture(nil, "BACKGROUND")
        iconTex:SetAllPoints()
        if iconPath then
            iconTex:SetTexture(iconPath)
        end
        btn.icon = iconTex

        local normalTex = btn:CreateTexture(nil, "OVERLAY")
        normalTex:SetAllPoints()
        normalTex:SetTexture("Interface\\Buttons\\UI-Quickslot2")
        btn:SetNormalTexture(normalTex)

        -- Count text
        local countText = btn:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
        countText:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", -2, 2)
        btn.countText = countText
        btn.itemType = cat.type

        MT.Masque:AddButton("HUD", btn, {
            Icon = iconTex,
            Normal = normalTex,
        })

        tinsert(itemButtons, btn)
    end
    MT.Masque:ReSkin("HUD")
end

function PM:UpdateItemCounts(counts)
    for _, btn in ipairs(itemButtons) do
        local count = counts[btn.itemType] or 0
        btn.countText:SetText(count > 0 and count or "")
    end
end

function PM:ShowAtCursor()
    local x, y = GetCursorPosition()
    local scale = UIParent:GetEffectiveScale()
    x, y = x / scale, y / scale

    popup:ClearAllPoints()
    popup:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x, y)
    popup:Show()
end

function PM:OnEvent(event, ...)
    if event == "SPELLS_CHANGED" then
        if popup then
            self:BuildButtons()
        end
    end
end

MT:RegisterEvents("SPELLS_CHANGED")
