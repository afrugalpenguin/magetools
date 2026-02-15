local MT = MageTools
local PM = {}
MT:RegisterModule("PopupMenu", PM)

local popup = nil
local buttons = {}
local labels = {}
local BUTTON_PADDING = 4
local BLOCK_GAP = 6
local BLOCK_COLS = 99  -- no wrapping, each category stays on one row

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

-- Delete the current mana gem from bags so a new one can be conjured
local function FindAndDeleteManaGem()
    for bag = 0, NUM_BAG_SLOTS do
        local numSlots = C_Container.GetContainerNumSlots(bag)
        for slot = 1, numSlots do
            local info = C_Container.GetContainerItemInfo(bag, slot)
            if info and info.itemID then
                for _, gemID in ipairs(MT.MANA_GEMS) do
                    if info.itemID == gemID then
                        C_Container.PickupContainerItem(bag, slot)
                        DeleteCursorItem()
                        return true
                    end
                end
            end
        end
    end
    return false
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
    self:CreateToggleButton()
    self:UpdateReleaseMode()
    self:CreatePopup()
    self:ApplyKeybind()
end

function PM:CreateToggleButton()
    toggleBtn = CreateFrame("Button", "MageToolsPopupToggle", UIParent, "SecureActionButtonTemplate")
    toggleBtn:SetSize(1, 1)
    toggleBtn:SetPoint("TOPLEFT", UIParent, "TOPLEFT", -100, 100)
    toggleBtn:RegisterForClicks("AnyDown", "AnyUp")

    -- Insecure methods called from secure WrapScript via CallMethod
    function toggleBtn:MGT_ShowPopup()
        if popup and not popup:IsShown() then
            PM:ShowAtCursor()
        end
    end
    function toggleBtn:MGT_HidePopup()
        if popup and popup:IsShown() then
            popup:Hide()
        end
    end
    function toggleBtn:MGT_TogglePopup()
        MageTools_TogglePopup()
    end
    function toggleBtn:MGT_DeleteGem()
        FindAndDeleteManaGem()
    end

    -- Hide popup after release-mode cast (runs AFTER template processes the click)
    toggleBtn:SetScript("PostClick", function(self)
        if self:GetAttribute("mgtcastpending") then
            self:SetAttribute("mgtcastpending", nil)
            if popup and popup:IsShown() then
                popup:Hide()
            end
        end
    end)

    -- WrapScript pre-handler: runs in secure env BEFORE SecureActionButtonTemplate processes click.
    -- Uses "popupopen" attribute for state (works for both keyboard hold-release and mouse two-press).
    -- IMPORTANT: Do NOT call MGT_HidePopup when casting — that triggers OnHide which clears
    -- type/spell via insecure SetAttribute before the template can process them. PostClick handles it.
    SecureHandlerWrapScript(toggleBtn, "OnClick", toggleBtn, [[
        -- Clear stale cast attributes so template doesn't act on previous state
        self:SetAttribute("type", nil)
        self:SetAttribute("typerelease", nil)

        local rm = self:GetAttribute("releasemode")
        local sp = self:GetAttribute("mgtspell")
        local isOpen = self:GetAttribute("popupopen")

        if not rm then
            self:CallMethod("MGT_TogglePopup")
            return
        end

        if not isOpen then
            -- First press (or key-down): show popup
            self:SetAttribute("mgtspell", nil)
            self:SetAttribute("popupopen", 1)
            self:CallMethod("MGT_ShowPopup")
        elseif sp then
            -- Second press (or key-up after hover): cast spell
            if self:GetAttribute("mgtdelgem") then
                self:CallMethod("MGT_DeleteGem")
                self:SetAttribute("mgtdelgem", nil)
            end
            self:SetAttribute("popupopen", nil)
            self:SetAttribute("mgtcastpending", 1)
            self:SetAttribute("pressAndHoldAction", 1)
            self:SetAttribute("type", "spell")
            self:SetAttribute("typerelease", "spell")
            self:SetAttribute("spell", sp)
            return "cast"
        else
            -- Second press (or key-up) without hover: cancel
            self:SetAttribute("popupopen", nil)
            self:CallMethod("MGT_HidePopup")
        end
    ]])
end

function PM:UpdateReleaseMode()
    if toggleBtn then
        toggleBtn:SetAttribute("releasemode", MageToolsDB.popupReleaseMode and true or nil)
    end
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

    popup:SetScript("OnHide", function()
        PM:ApplyKeybind()
        -- Clear release-mode state so next open starts fresh
        if toggleBtn then
            toggleBtn:SetAttribute("type", nil)
            toggleBtn:SetAttribute("spell", nil)
            toggleBtn:SetAttribute("mgtspell", nil)
            toggleBtn:SetAttribute("popupopen", nil)
            toggleBtn:SetAttribute("mgtcastpending", nil)
            toggleBtn:SetAttribute("mgtdelgem", nil)
        end
    end)

    self:BuildButtons()
end

local function CreateSpellButton(spell, prefix, index, isGemConjure)
    local btnSize = MageToolsDB.popupButtonSize
    local btn = CreateFrame("Button", "MageTools" .. prefix .. "Btn" .. index, popup, "SecureActionButtonTemplate")
    btn:SetSize(btnSize, btnSize)

    btn:SetAttribute("type", "spell")
    local spellName, _, icon = GetSpellInfo(spell.spellID)
    btn:SetAttribute("spell", spellName)
    btn:RegisterForClicks("AnyUp", "AnyDown")

    if isGemConjure then
        btn:SetAttribute("mgtgemconjure", 1)
    end

    -- Clear any template-injected normal texture
    local tmplNormal = btn:GetNormalTexture()
    if tmplNormal then
        tmplNormal:SetTexture(nil)
        tmplNormal:Hide()
    end

    -- Icon
    local iconTex = btn:CreateTexture(nil, "ARTWORK")
    iconTex:SetPoint("TOPLEFT", 1, -1)
    iconTex:SetPoint("BOTTOMRIGHT", -1, 1)
    iconTex:SetTexture(icon)
    btn.icon = iconTex

    -- Masque skinning
    local normalTex, highlightTex
    if MT.Masque:IsEnabled() then
        normalTex = btn:CreateTexture(nil, "OVERLAY")
        normalTex:SetAllPoints()
        btn:SetNormalTexture(normalTex)
    else
        -- Thin border around icon (BACKGROUND so icon at ARTWORK draws on top)
        local border = btn:CreateTexture(nil, "BACKGROUND")
        border:SetAllPoints()
        border:SetColorTexture(0, 0, 0, 1)
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

    -- Release-to-cast: secure snippet tracks hovered spell on toggleBtn
    -- The OnClick WrapScript on toggleBtn reads mgtspell and sets type/spell to cast
    SecureHandlerWrapScript(btn, "OnEnter", toggleBtn, [[
        if owner:GetAttribute("releasemode") then
            owner:SetAttribute("mgtspell", self:GetAttribute("spell"))
            owner:SetAttribute("mgtdelgem", self:GetAttribute("mgtgemconjure"))
        end
    ]])
    SecureHandlerWrapScript(btn, "OnLeave", toggleBtn, [[
        if owner:GetAttribute("releasemode") then
            owner:SetAttribute("mgtspell", nil)
            owner:SetAttribute("mgtdelgem", nil)
        end
    ]])

    -- Direct-click mode: delete existing gem before conjuring
    if isGemConjure then
        btn:SetScript("PreClick", function()
            FindAndDeleteManaGem()
        end)
    end

    -- Close popup after direct-click cast (click mode)
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
    -- Clear old buttons and labels
    for _, btn in ipairs(buttons) do btn:Hide() end
    wipe(buttons)
    for _, lbl in ipairs(labels) do lbl:Hide() end
    wipe(labels)

    local cats = MageToolsDB.popupCategories
    local playerFaction = UnitFactionGroup("player")
    local knownTeleports = {}
    local knownPortals = {}

    if cats.teleports then
        for _, spell in ipairs(MT.TELEPORTS) do
            if (spell.faction == playerFaction or spell.faction == "Neutral") and IsSpellKnown(spell.spellID) then
                tinsert(knownTeleports, spell)
            end
        end
    end
    if cats.portals then
        for _, spell in ipairs(MT.PORTALS) do
            if (spell.faction == playerFaction or spell.faction == "Neutral") and IsSpellKnown(spell.spellID) then
                tinsert(knownPortals, spell)
            end
        end
    end

    -- Conjure spells: food/water and gems split into separate lists
    local conjureFoodWater = {}
    local conjureGems = {}
    if cats.conjureFood then
        for _, name in ipairs({"Conjure Food", "Conjure Water"}) do
            local id = FindSpellInBook(name)
            if id then tinsert(conjureFoodWater, { spellID = id }) end
        end
    end
    if cats.conjureGems then
        for _, name in ipairs({"Conjure Mana Emerald", "Conjure Mana Ruby", "Conjure Mana Citrine", "Conjure Mana Jade", "Conjure Mana Agate"}) do
            local id = FindSpellInBook(name)
            if id then
                tinsert(conjureGems, { spellID = id, isGem = true })
                break
            end
        end
    end
    -- Combine enabled conjure spells into one quadrant
    local conjureSpells = {}
    for _, s in ipairs(conjureFoodWater) do tinsert(conjureSpells, s) end
    for _, s in ipairs(conjureGems) do tinsert(conjureSpells, s) end

    -- Buff spells (highest known rank)
    local buffSpells = {}
    if cats.buffs then
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
    end

    -- X layout: four blocks around cursor center
    -- TL = buffs, TR = conjure, BL = teleports, BR = portals
    local quadrants = {
        { spells = buffSpells,      prefix = "Buff",     label = "Buffs"     },  -- 1: top-left
        { spells = conjureSpells,   prefix = "Conjure",  label = "Conjure"   },  -- 2: top-right
        { spells = knownTeleports,  prefix = "Teleport", label = "Teleports" },  -- 3: bottom-left
        { spells = knownPortals,    prefix = "Portal",   label = "Portals"   },  -- 4: bottom-right
    }

    local btnSize = MageToolsDB.popupButtonSize
    local spacing = btnSize + BUTTON_PADDING
    local maxAbsX = 0
    local maxAbsY = 0

    local LABEL_GAP = 2

    for qIdx, q in ipairs(quadrants) do
        if #q.spells > 0 then
            local cols = math.min(#q.spells, BLOCK_COLS)
            local rows = math.ceil(#q.spells / BLOCK_COLS)
            local blockW = cols * spacing
            local blockH = rows * spacing

            local col = 0
            local row = 0
            for i, spell in ipairs(q.spells) do
                local btn = CreateSpellButton(spell, q.prefix, i, spell.isGem)

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

            -- Quadrant label
            local lbl = popup:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            lbl:SetText(q.label)
            lbl:SetTextColor(0.41, 0.80, 0.94, 0.8)

            if qIdx == 1 then       -- top-left: label above block, right-aligned
                lbl:SetPoint("BOTTOMRIGHT", popup, "CENTER", -BLOCK_GAP, BLOCK_GAP + blockH + LABEL_GAP)
            elseif qIdx == 2 then   -- top-right: label above block, left-aligned
                lbl:SetPoint("BOTTOMLEFT", popup, "CENTER", BLOCK_GAP, BLOCK_GAP + blockH + LABEL_GAP)
            elseif qIdx == 3 then   -- bottom-left: label below block, right-aligned
                lbl:SetPoint("TOPRIGHT", popup, "CENTER", -BLOCK_GAP, -BLOCK_GAP - blockH - LABEL_GAP)
            else                    -- bottom-right: label below block, left-aligned
                lbl:SetPoint("TOPLEFT", popup, "CENTER", BLOCK_GAP, -BLOCK_GAP - blockH - LABEL_GAP)
            end

            tinsert(labels, lbl)

            -- Account for label in popup bounds
            local labelEdgeY = BLOCK_GAP + blockH + LABEL_GAP + 12
            if labelEdgeY > maxAbsY then maxAbsY = labelEdgeY end
        end
    end

    MT.Masque:ReSkin("Popup")

    -- Size popup to contain all buttons, labels, and backdrop padding
    local EDGE_PADDING = 8
    if maxAbsX > 0 and maxAbsY > 0 then
        popup:SetSize((maxAbsX + EDGE_PADDING) * 2, (maxAbsY + EDGE_PADDING) * 2)
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
