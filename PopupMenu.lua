local MT = MageTools
local PM = {}
MT:RegisterModule("PopupMenu", PM)

local popup = nil
local buttons = {}
local BUTTON_PADDING = 4

-- Scan the spellbook for the highest rank of a spell by name
local function FindSpellInBook(targetName)
    local foundID
    local i = 1
    while true do
        local name = GetSpellBookItemName(i, BOOKTYPE_SPELL)
        if not name then break end
        if name == targetName then
            local _, id = GetSpellBookItemInfo(i, BOOKTYPE_SPELL)
            foundID = id  -- last match = highest rank
        end
        i = i + 1
    end
    return foundID
end

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
    self:CreatePopup()
end

function PM:CreatePopup()
    popup = CreateFrame("Frame", "MageToolsPopup", UIParent, "BackdropTemplate")
    popup:SetFrameStrata("DIALOG")
    popup:SetClampedToScreen(true)
    popup:Hide()
    popup:EnableMouse(true)

    -- Close on Escape
    tinsert(UISpecialFrames, "MageToolsPopup")

    -- Close when clicking outside
    popup:SetScript("OnMouseDown", function() end)

    popup:SetBackdrop(nil)

    self:BuildButtons()
end

function PM:BuildButtons()
    -- Clear old buttons
    for _, btn in ipairs(buttons) do btn:Hide() end
    wipe(buttons)
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
    local teleportRows = math.ceil(#knownTeleports / MageToolsDB.popupColumns)
    yOffset = yOffset - (teleportRows * (MageToolsDB.popupButtonSize + BUTTON_PADDING))

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
    local portalRows = math.ceil(#knownPortals / MageToolsDB.popupColumns)
    yOffset = yOffset - (portalRows * (MageToolsDB.popupButtonSize + BUTTON_PADDING))

    -- Conjure spells (scan spellbook for highest known rank)
    local conjureSpells = {}
    for _, name in ipairs({"Conjure Food", "Conjure Water"}) do
        local id = FindSpellInBook(name)
        if id then tinsert(conjureSpells, { spellID = id }) end
    end
    -- Mana gems have different spell names per tier (highest first)
    for _, name in ipairs({"Conjure Mana Emerald", "Conjure Mana Ruby", "Conjure Mana Citrine", "Conjure Mana Jade", "Conjure Mana Agate"}) do
        local id = FindSpellInBook(name)
        if id then
            tinsert(conjureSpells, { spellID = id })
            break  -- only show highest known gem
        end
    end

    if #conjureSpells > 0 then
        local conjureDivider = popup:CreateTexture(nil, "ARTWORK")
        conjureDivider:SetHeight(1)
        conjureDivider:SetPoint("TOPLEFT", popup, "TOPLEFT", 8, yOffset - 2)
        conjureDivider:SetPoint("TOPRIGHT", popup, "TOPRIGHT", -8, yOffset - 2)
        conjureDivider:SetColorTexture(0.5, 0.5, 0.5, 0.5)
        yOffset = yOffset - 6

        cols = self:CreateSpellRow(conjureSpells, yOffset, "Conjure")
        if cols > maxCols then maxCols = cols end
        local conjureRows = math.ceil(#conjureSpells / MageToolsDB.popupColumns)
        yOffset = yOffset - (conjureRows * (MageToolsDB.popupButtonSize + BUTTON_PADDING))
    end

    -- Buff spells (highest known rank)
    local buffSpells = {}
    for _, name in ipairs({"Arcane Intellect", "Arcane Brilliance", "Mage Armor"}) do
        local id = FindSpellInBook(name)
        if id then tinsert(buffSpells, { spellID = id }) end
    end

    if #buffSpells > 0 then
        local buffDivider = popup:CreateTexture(nil, "ARTWORK")
        buffDivider:SetHeight(1)
        buffDivider:SetPoint("TOPLEFT", popup, "TOPLEFT", 8, yOffset - 2)
        buffDivider:SetPoint("TOPRIGHT", popup, "TOPRIGHT", -8, yOffset - 2)
        buffDivider:SetColorTexture(0.5, 0.5, 0.5, 0.5)
        yOffset = yOffset - 6

        cols = self:CreateSpellRow(buffSpells, yOffset, "Buff")
        if cols > maxCols then maxCols = cols end
        local buffRows = math.ceil(#buffSpells / MageToolsDB.popupColumns)
        yOffset = yOffset - (buffRows * (MageToolsDB.popupButtonSize + BUTTON_PADDING))
    end

    -- Size the popup
    local totalCols = maxCols > 0 and maxCols or MageToolsDB.popupColumns
    local width = (totalCols * (MageToolsDB.popupButtonSize + BUTTON_PADDING)) + BUTTON_PADDING + 16
    local height = math.abs(yOffset) + 8
    popup:SetSize(width, height)
end

function PM:CreateSpellRow(spells, yOffset, prefix)
    local col = 0
    local row = 0
    for i, spell in ipairs(spells) do
        local btn = CreateFrame("Button", "MageTools" .. prefix .. "Btn" .. i, popup, "SecureActionButtonTemplate")
        btn:SetSize(MageToolsDB.popupButtonSize, MageToolsDB.popupButtonSize)
        local x = 8 + (col * (MageToolsDB.popupButtonSize + BUTTON_PADDING))
        local y = yOffset - (row * (MageToolsDB.popupButtonSize + BUTTON_PADDING))
        btn:SetPoint("TOPLEFT", popup, "TOPLEFT", x, y)

        btn:SetAttribute("type", "spell")
        local spellName, _, icon = GetSpellInfo(spell.spellID)
        btn:SetAttribute("spell", spellName)
        btn:RegisterForClicks("AnyUp", "AnyDown")

        -- Clear any template-injected normal texture
        local tmplNormal = btn:GetNormalTexture()
        if tmplNormal then
            tmplNormal:SetTexture(nil)
            tmplNormal:Hide()
        end

        -- Icon
        local iconTex = btn:CreateTexture(nil, "BACKGROUND")
        iconTex:SetAllPoints()
        iconTex:SetTexture(icon)
        btn.icon = iconTex

        -- Masque skinning
        local normalTex, highlightTex
        if MT.Masque:IsEnabled() then
            normalTex = btn:CreateTexture(nil, "OVERLAY")
            normalTex:SetAllPoints()
            btn:SetNormalTexture(normalTex)
        end

        highlightTex = btn:CreateTexture(nil, "HIGHLIGHT")
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
            if MageToolsDB.popupCloseOnCast then
                popup:Hide()
            end
        end)

        MT.Masque:AddButton("Popup", btn, {
            Icon = iconTex,
            Normal = normalTex,
            Highlight = highlightTex,
        })

        tinsert(buttons, btn)

        col = col + 1
        if col >= MageToolsDB.popupColumns then
            col = 0
            row = row + 1
        end
    end
    MT.Masque:ReSkin("Popup")
    return math.min(#spells, MageToolsDB.popupColumns)
end

function PM:ShowAtCursor()
    local x, y = GetCursorPosition()
    local scale = UIParent:GetEffectiveScale()
    x, y = x / scale, y / scale

    popup:ClearAllPoints()
    popup:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x, y)
    popup:Show()
end

function PM:Rebuild()
    if popup then
        self:BuildButtons()
    end
end

function PM:OnEvent(event, ...)
    if event == "SPELLS_CHANGED" then
        if popup then
            self:BuildButtons()
        end
    end
end

MT:RegisterEvents("SPELLS_CHANGED")
