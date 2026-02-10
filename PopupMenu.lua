local MT = MageTools
local PM = {}
MT:RegisterModule("PopupMenu", PM)

local popup = nil
local buttons = {}
local BUTTON_PADDING = 4
local BLOCK_GAP = 6
local BLOCK_COLS = 4

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

local toggleBtn = nil

function PM:Init()
    self:CreatePopup()
    self:CreateToggleButton()
    self:ApplyKeybind()
end

function PM:CreateToggleButton()
    toggleBtn = CreateFrame("Button", "MageToolsPopupToggle", UIParent, "SecureActionButtonTemplate")
    toggleBtn:SetSize(1, 1)
    toggleBtn:SetPoint("TOPLEFT", UIParent, "TOPLEFT", -100, 100)
    -- Register both so keyboard (fires on down) and mouse buttons (fire on up) both work
    toggleBtn:RegisterForClicks("AnyDown", "AnyUp")

    local ignoreNextUp = false
    toggleBtn:SetScript("OnClick", function(self, button, down)
        if down then
            -- Keyboard keys hit this path
            MageTools_TogglePopup()
            ignoreNextUp = true
        else
            if ignoreNextUp then
                -- This is the key-up after a keyboard down — skip it
                ignoreNextUp = false
                return
            end
            -- Mouse buttons hit this path (override bindings fire on release)
            MageTools_TogglePopup()
        end
    end)
end

function PM:ApplyKeybind()
    if not toggleBtn then return end
    ClearOverrideBindings(toggleBtn)
    local key = MageToolsDB.popupKeybind
    if key then
        SetOverrideBindingClick(toggleBtn, true, key, "MageToolsPopupToggle")
    end
end

function PM:CreatePopup()
    popup = CreateFrame("Frame", "MageToolsPopup", UIParent, "BackdropTemplate")
    popup:SetFrameStrata("DIALOG")
    popup:SetClampedToScreen(true)
    popup:Hide()
    popup:EnableMouse(false)

    -- Close on Escape
    tinsert(UISpecialFrames, "MageToolsPopup")

    popup:SetBackdrop(nil)

    self:BuildButtons()
end

local function CreateSpellButton(spell, prefix, index)
    local btnSize = MageToolsDB.popupButtonSize
    local btn = CreateFrame("Button", "MageTools" .. prefix .. "Btn" .. index, popup, "SecureActionButtonTemplate")
    btn:SetSize(btnSize, btnSize)

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
    return btn
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

    -- Conjure spells (scan spellbook for highest known rank)
    local conjureSpells = {}
    for _, name in ipairs({"Conjure Food", "Conjure Water"}) do
        local id = FindSpellInBook(name)
        if id then tinsert(conjureSpells, { spellID = id }) end
    end
    for _, name in ipairs({"Conjure Mana Emerald", "Conjure Mana Ruby", "Conjure Mana Citrine", "Conjure Mana Jade", "Conjure Mana Agate"}) do
        local id = FindSpellInBook(name)
        if id then
            tinsert(conjureSpells, { spellID = id })
            break
        end
    end

    -- Buff spells (highest known rank)
    local buffSpells = {}
    for _, name in ipairs({"Arcane Intellect", "Arcane Brilliance"}) do
        local id = FindSpellInBook(name)
        if id then tinsert(buffSpells, { spellID = id }) end
    end
    for _, name in ipairs({"Ice Armor", "Frost Armor"}) do
        local id = FindSpellInBook(name)
        if id then
            tinsert(buffSpells, { spellID = id })
            break
        end
    end
    for _, name in ipairs({"Mage Armor", "Molten Armor"}) do
        local id = FindSpellInBook(name)
        if id then tinsert(buffSpells, { spellID = id }) end
    end

    -- X layout: four blocks around cursor center
    -- TL = buffs, TR = conjure, BL = teleports, BR = portals
    local quadrants = {
        { spells = buffSpells,      prefix = "Buff"     },  -- 1: top-left
        { spells = conjureSpells,   prefix = "Conjure"  },  -- 2: top-right
        { spells = knownTeleports,  prefix = "Teleport" },  -- 3: bottom-left
        { spells = knownPortals,    prefix = "Portal"   },  -- 4: bottom-right
    }

    local btnSize = MageToolsDB.popupButtonSize
    local spacing = btnSize + BUTTON_PADDING
    local maxAbsX = 0
    local maxAbsY = 0

    for qIdx, q in ipairs(quadrants) do
        if #q.spells > 0 then
            local cols = math.min(#q.spells, BLOCK_COLS)
            local rows = math.ceil(#q.spells / BLOCK_COLS)
            local blockW = cols * spacing
            local blockH = rows * spacing

            local col = 0
            local row = 0
            for i, spell in ipairs(q.spells) do
                local btn = CreateSpellButton(spell, q.prefix, i)

                local bx, by
                if qIdx == 1 then       -- top-left
                    bx = -BLOCK_GAP - blockW + col * spacing + btnSize / 2
                    by =  BLOCK_GAP + blockH - row * spacing - btnSize / 2
                elseif qIdx == 2 then   -- top-right
                    bx =  BLOCK_GAP + col * spacing + btnSize / 2
                    by =  BLOCK_GAP + blockH - row * spacing - btnSize / 2
                elseif qIdx == 3 then   -- bottom-left
                    bx = -BLOCK_GAP - blockW + col * spacing + btnSize / 2
                    by = -BLOCK_GAP - row * spacing - btnSize / 2
                else                    -- bottom-right
                    bx =  BLOCK_GAP + col * spacing + btnSize / 2
                    by = -BLOCK_GAP - row * spacing - btnSize / 2
                end

                btn:ClearAllPoints()
                btn:SetPoint("CENTER", popup, "CENTER", bx, by)

                local edgeX = math.abs(bx) + btnSize / 2
                local edgeY = math.abs(by) + btnSize / 2
                if edgeX > maxAbsX then maxAbsX = edgeX end
                if edgeY > maxAbsY then maxAbsY = edgeY end

                col = col + 1
                if col >= BLOCK_COLS then
                    col = 0
                    row = row + 1
                end
            end
        end
    end

    MT.Masque:ReSkin("Popup")

    -- Size popup to contain all buttons
    if maxAbsX > 0 and maxAbsY > 0 then
        popup:SetSize((maxAbsX + BUTTON_PADDING) * 2, (maxAbsY + BUTTON_PADDING) * 2)
    else
        popup:SetSize(1, 1)
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
