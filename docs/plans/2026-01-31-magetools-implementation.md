# MageTools Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build a WoW TBC Anniversary mage utility addon with a keybind-triggered portal/teleport popup, conjured item HUD with bulk conjure session, and whisper-triggered trade distribution.

**Architecture:** Single addon with three Lua modules (PopupMenu, ConjureManager, TradeHelper) sharing a common event backbone in Core.lua. Masque support is optional — buttons work without it. All state is per-character via SavedVariablesPerCharacter.

**Tech Stack:** Lua, WoW TBC API (Interface: 20505), SecureActionButtonTemplate, Masque (optional dependency)

---

### Task 1: TOC and Core Event Backbone

**Files:**
- Create: `MageTools.toc`
- Create: `Core.lua`

**Step 1: Create TOC file**

```toc
## Interface: 20505
## Title: MageTools
## Notes: Mage utility addon — portals, conjure tracking, trade helper
## Author: russell
## SavedVariablesPerCharacter: MageToolsDB
## OptionalDeps: Masque

Core.lua
PopupMenu.lua
ConjureManager.lua
TradeHelper.lua
```

**Step 2: Create Core.lua with event backbone and saved variables**

```lua
MageTools = {}
MageTools.modules = {}

local frame = CreateFrame("Frame")

local defaults = {
    hudVisible = true,
    hudX = 0,
    hudY = 0,
    hudPoint = "CENTER",
    whisperKeywords = { "water", "food", "mage" },
    stacksPerPerson = 1,
    autoReply = true,
    queueVisible = true,
}

function MageTools:RegisterModule(name, mod)
    self.modules[name] = mod
end

function MageTools:InitDB()
    MageToolsDB = MageToolsDB or {}
    for k, v in pairs(defaults) do
        if MageToolsDB[k] == nil then
            if type(v) == "table" then
                MageToolsDB[k] = {}
                for i, val in ipairs(v) do
                    MageToolsDB[k][i] = val
                end
            else
                MageToolsDB[k] = v
            end
        end
    end
end

frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        local addon = ...
        if addon == "MageTools" then
            MageTools:InitDB()
            for name, mod in pairs(MageTools.modules) do
                if mod.Init then
                    mod:Init()
                end
            end
            self:UnregisterEvent("ADDON_LOADED")
        end
        return
    end
    for name, mod in pairs(MageTools.modules) do
        if mod.OnEvent then
            mod:OnEvent(event, ...)
        end
    end
end)

function MageTools:RegisterEvents(...)
    for i = 1, select("#", ...) do
        frame:RegisterEvent(select(i, ...))
    end
end

-- Slash commands
SLASH_MAGETOOLS1 = "/mt"
SLASH_MAGETOOLS2 = "/magetools"
SlashCmdList["MAGETOOLS"] = function(msg)
    local cmd = strlower(strtrim(msg))
    if cmd == "hud" then
        local cm = MageTools.modules["ConjureManager"]
        if cm then cm:ToggleHUD() end
    elseif cmd == "conjure" then
        local cm = MageTools.modules["ConjureManager"]
        if cm then cm:ToggleConjureSession() end
    elseif cmd == "queue" then
        local th = MageTools.modules["TradeHelper"]
        if th then th:ToggleQueue() end
    elseif cmd == "config" then
        print("|cff69ccf0MageTools|r config:")
        print("  HUD visible: " .. tostring(MageToolsDB.hudVisible))
        print("  Auto-reply: " .. tostring(MageToolsDB.autoReply))
        print("  Stacks/person: " .. MageToolsDB.stacksPerPerson)
        print("  Keywords: " .. table.concat(MageToolsDB.whisperKeywords, ", "))
    else
        print("|cff69ccf0MageTools|r commands:")
        print("  /mt hud - Toggle HUD")
        print("  /mt conjure - Conjure session")
        print("  /mt queue - Toggle trade queue")
        print("  /mt config - Show config")
    end
end
```

**Step 3: Commit**

```
git add MageTools.toc Core.lua
git commit -m "feat(core): add TOC and event backbone with saved variables"
```

---

### Task 2: Spell and Item Data Table

**Files:**
- Create: `Data.lua`
- Modify: `MageTools.toc` (add Data.lua before other modules)

**Step 1: Add Data.lua to TOC after Core.lua**

In `MageTools.toc`, the file list becomes:
```
Core.lua
Data.lua
PopupMenu.lua
ConjureManager.lua
TradeHelper.lua
```

**Step 2: Create Data.lua with all spell/item IDs**

```lua
local MT = MageTools

MT.TELEPORTS = {
    -- Alliance
    { spellID = 3561,  name = "Stormwind",    faction = "Alliance" },
    { spellID = 3562,  name = "Ironforge",    faction = "Alliance" },
    { spellID = 3565,  name = "Darnassus",    faction = "Alliance" },
    { spellID = 32271, name = "Exodar",       faction = "Alliance" },
    -- Horde
    { spellID = 3567,  name = "Orgrimmar",    faction = "Horde" },
    { spellID = 3563,  name = "Undercity",    faction = "Horde" },
    { spellID = 3566,  name = "Thunder Bluff", faction = "Horde" },
    { spellID = 32272, name = "Silvermoon",   faction = "Horde" },
    -- Neutral
    { spellID = 35715, name = "Shattrath",    faction = "Neutral" },
}

MT.PORTALS = {
    -- Alliance
    { spellID = 10059, name = "Stormwind",    faction = "Alliance" },
    { spellID = 11416, name = "Ironforge",    faction = "Alliance" },
    { spellID = 11419, name = "Darnassus",    faction = "Alliance" },
    { spellID = 32266, name = "Exodar",       faction = "Alliance" },
    -- Horde
    { spellID = 11417, name = "Orgrimmar",    faction = "Horde" },
    { spellID = 11418, name = "Undercity",    faction = "Horde" },
    { spellID = 11420, name = "Thunder Bluff", faction = "Horde" },
    { spellID = 32267, name = "Silvermoon",   faction = "Horde" },
    -- Neutral
    { spellID = 33691, name = "Shattrath",    faction = "Neutral" },
}

-- Conjured food item IDs (all ranks, highest first)
MT.CONJURED_FOOD = {
    22019, -- Conjured Croissant (Rank 7)
    8075,  -- Conjured Sourdough (Rank 6)
    1487,  -- Conjured Pumpernickel (Rank 5)
    1114,  -- Conjured Rye (Rank 4)
    1113,  -- Conjured Bread (Rank 3)
    5349,  -- Conjured Muffin (Rank 2)
}

-- Conjured water item IDs (all ranks, highest first)
MT.CONJURED_WATER = {
    30703, -- Conjured Mountain Spring Water (Rank 9)
    22018, -- Conjured Glacier Water (Rank 8)
    8079,  -- Conjured Crystal Water (Rank 7)
    8078,  -- Conjured Sparkling Water (Rank 6)
    8077,  -- Conjured Mineral Water (Rank 5)
    3772,  -- Conjured Spring Water (Rank 4)
    2136,  -- Conjured Purified Water (Rank 3)
    2288,  -- Conjured Fresh Water (Rank 2)
    5350,  -- Conjured Water (Rank 1)
}

-- Mana gem item IDs (highest first)
MT.MANA_GEMS = {
    22044, -- Mana Emerald
    8008,  -- Mana Ruby
    8007,  -- Mana Citrine
    5513,  -- Mana Jade
    5514,  -- Mana Agate
}

-- Conjure spell IDs (highest rank)
MT.CONJURE_FOOD_SPELL = 33717  -- Conjure Food Rank 7
MT.CONJURE_WATER_SPELL = 27090 -- Conjure Water Rank 9
MT.CONJURE_GEM_SPELL = 27101   -- Conjure Mana Emerald

-- Build a lookup set of all conjured item IDs for fast bag scanning
MT.CONJURED_ITEM_SET = {}
for _, id in ipairs(MT.CONJURED_FOOD) do MT.CONJURED_ITEM_SET[id] = "food" end
for _, id in ipairs(MT.CONJURED_WATER) do MT.CONJURED_ITEM_SET[id] = "water" end
for _, id in ipairs(MT.MANA_GEMS) do MT.CONJURED_ITEM_SET[id] = "gem" end
```

**Step 3: Commit**

```
git add Data.lua MageTools.toc
git commit -m "feat(data): add mage spell and conjured item ID tables"
```

---

### Task 3: Masque Helper

**Files:**
- Create: `MasqueHelper.lua`
- Modify: `MageTools.toc` (add MasqueHelper.lua after Data.lua)

**Step 1: Add MasqueHelper.lua to TOC after Data.lua**

File list becomes:
```
Core.lua
Data.lua
MasqueHelper.lua
PopupMenu.lua
ConjureManager.lua
TradeHelper.lua
```

**Step 2: Create MasqueHelper.lua**

```lua
local MT = MageTools

MT.Masque = {}
local MSQ = nil
local groups = {}

function MT.Masque:Init()
    local lib = LibStub and LibStub("Masque", true)
    if lib then
        MSQ = lib
    end
end

function MT.Masque:GetGroup(name)
    if not MSQ then return nil end
    if not groups[name] then
        groups[name] = MSQ:Group("MageTools", name)
    end
    return groups[name]
end

function MT.Masque:AddButton(groupName, button, data)
    local group = self:GetGroup(groupName)
    if group then
        group:AddButton(button, data)
    end
end

function MT.Masque:ReSkin(groupName)
    local group = self:GetGroup(groupName)
    if group then
        group:ReSkin()
    end
end
```

**Step 3: Commit**

```
git add MasqueHelper.lua MageTools.toc
git commit -m "feat(masque): add Masque integration helper"
```

---

### Task 4: PopupMenu — Frame and Keybind

**Files:**
- Create: `PopupMenu.lua`
- Create: `Bindings.xml`

**Step 1: Create Bindings.xml**

```xml
<Bindings>
    <Binding name="MAGETOOLS_POPUP" header="MAGETOOLS">
        MageTools_TogglePopup()
    </Binding>
</Bindings>
```

**Step 2: Create PopupMenu.lua**

```lua
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
```

**Step 3: Commit**

```
git add PopupMenu.lua Bindings.xml
git commit -m "feat(popup): add keybind-triggered portal/teleport icon grid"
```

---

### Task 5: ConjureManager — Bag Scanning and HUD

**Files:**
- Create: `ConjureManager.lua`

**Step 1: Create ConjureManager.lua**

```lua
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

        local _, _, iconPath = GetItemInfo(cat.items[1])
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
    foodBtn:SetAttribute("spell", MT.CONJURE_FOOD_SPELL)
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
    waterBtn:SetAttribute("spell", MT.CONJURE_WATER_SPELL)
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
```

**Step 2: Commit**

```
git add ConjureManager.lua
git commit -m "feat(conjure): add bag scanning, HUD, and conjure session panel"
```

---

### Task 6: TradeHelper — Whisper Queue and Distribution

**Files:**
- Create: `TradeHelper.lua`

**Step 1: Create TradeHelper.lua**

```lua
local MT = MageTools
local TH = {}
MT:RegisterModule("TradeHelper", TH)

local queue = {}  -- { { name = "Player", request = "water" }, ... }
local queueFrame = nil
local queueButtons = {}
local MAX_QUEUE_DISPLAY = 10
local pendingTrade = nil  -- name of player we're trying to trade with

function TH:Init()
    self:CreateQueueFrame()
    self:UpdateQueueDisplay()
end

-- Whisper handling
function TH:MatchKeyword(msg)
    msg = strlower(msg)
    local matched = {}
    for _, keyword in ipairs(MageToolsDB.whisperKeywords) do
        if strfind(msg, strlower(keyword)) then
            if keyword == "food" then
                matched.food = true
            elseif keyword == "water" then
                matched.water = true
            elseif keyword == "mage" then
                matched.food = true
                matched.water = true
            end
        end
    end
    if matched.food and matched.water then
        return "both"
    elseif matched.food then
        return "food"
    elseif matched.water then
        return "water"
    end
    return nil
end

function TH:AddToQueue(name, request)
    -- Check for duplicates, update existing
    for _, entry in ipairs(queue) do
        if entry.name == name then
            entry.request = request
            self:UpdateQueueDisplay()
            return
        end
    end
    tinsert(queue, { name = name, request = request })
    self:UpdateQueueDisplay()

    if MageToolsDB.autoReply then
        local position = #queue
        local reqText = request
        if request == "both" then reqText = "food and water" end
        SendChatMessage("You're queued for " .. reqText .. ". " .. (position - 1) .. " ahead of you.", "WHISPER", nil, name)
    end

    -- Show queue frame if hidden
    if not queueFrame:IsShown() then
        queueFrame:Show()
    end
end

function TH:RemoveFromQueue(index)
    local entry = tremove(queue, index)
    if entry and MageToolsDB.autoReply then
        SendChatMessage("Enjoy!", "WHISPER", nil, entry.name)
    end
    self:UpdateQueueDisplay()
    if #queue == 0 then
        queueFrame:Hide()
    end
end

-- Find conjured items in bags and trade them
function TH:FindConjuredItem(itemType)
    local itemList
    if itemType == "food" then
        itemList = MT.CONJURED_FOOD
    else
        itemList = MT.CONJURED_WATER
    end
    -- Find a full stack first (20), otherwise any stack
    local bestBag, bestSlot, bestCount = nil, nil, 0
    for bag = 0, NUM_BAG_SLOTS do
        local numSlots = GetContainerNumSlots(bag)
        for slot = 1, numSlots do
            local itemID = GetContainerItemID(bag, slot)
            if itemID then
                for _, validID in ipairs(itemList) do
                    if itemID == validID then
                        local _, itemCount = GetContainerItemInfo(bag, slot)
                        if itemCount and itemCount > bestCount then
                            bestBag, bestSlot, bestCount = bag, slot, itemCount
                        end
                    end
                end
            end
        end
    end
    return bestBag, bestSlot
end

function TH:PlaceItemsInTrade(request)
    local tradeSlot = 1
    if request == "food" or request == "both" then
        local bag, slot = self:FindConjuredItem("food")
        if bag then
            PickupContainerItem(bag, slot)
            ClickTradeButton(tradeSlot)
            tradeSlot = tradeSlot + 1
        end
    end
    if request == "water" or request == "both" then
        local bag, slot = self:FindConjuredItem("water")
        if bag then
            PickupContainerItem(bag, slot)
            ClickTradeButton(tradeSlot)
        end
    end
end

-- Queue Frame
function TH:CreateQueueFrame()
    queueFrame = CreateFrame("Frame", "MageToolsQueue", UIParent)
    queueFrame:SetSize(200, 40)
    queueFrame:SetPoint("RIGHT", UIParent, "RIGHT", -20, 0)
    queueFrame:SetFrameStrata("MEDIUM")
    queueFrame:SetClampedToScreen(true)
    queueFrame:SetMovable(true)
    queueFrame:EnableMouse(true)
    queueFrame:RegisterForDrag("LeftButton")
    queueFrame:SetScript("OnDragStart", function(self) self:StartMoving() end)
    queueFrame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
    queueFrame:Hide()

    tinsert(UISpecialFrames, "MageToolsQueue")

    queueFrame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 12,
        insets = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    queueFrame:SetBackdropColor(0, 0, 0, 0.8)

    -- Title
    local title = queueFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    title:SetPoint("TOP", 0, -6)
    title:SetText("|cff69ccf0Trade Queue|r")
    queueFrame.title = title

    -- Create row buttons
    for i = 1, MAX_QUEUE_DISPLAY do
        local row = CreateFrame("Button", "MageToolsQueueRow" .. i, queueFrame)
        row:SetSize(180, 18)
        row:SetPoint("TOP", queueFrame, "TOP", 0, -8 - (i * 18))

        local nameText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        nameText:SetPoint("LEFT", 6, 0)
        row.nameText = nameText

        local reqText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        reqText:SetPoint("RIGHT", -6, 0)
        row.reqText = reqText

        row:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")

        row:SetScript("OnClick", function()
            if queue[i] then
                -- Target player and initiate trade
                pendingTrade = queue[i]
                TargetByName(queue[i].name, true)
                InitiateTrade("target")
            end
        end)

        row:Hide()
        tinsert(queueButtons, row)
    end
end

function TH:UpdateQueueDisplay()
    local visibleCount = math.min(#queue, MAX_QUEUE_DISPLAY)
    for i = 1, MAX_QUEUE_DISPLAY do
        if i <= visibleCount then
            local entry = queue[i]
            queueButtons[i].nameText:SetText(entry.name)
            local reqLabel = entry.request
            if reqLabel == "both" then reqLabel = "food+water" end
            queueButtons[i].reqText:SetText("|cffaaaaaa" .. reqLabel .. "|r")
            queueButtons[i]:Show()
        else
            queueButtons[i]:Hide()
        end
    end
    -- Resize frame
    local height = 28 + (visibleCount * 18)
    queueFrame:SetSize(200, math.max(40, height))
end

function TH:ToggleQueue()
    if queueFrame:IsShown() then
        queueFrame:Hide()
        MageToolsDB.queueVisible = false
    else
        queueFrame:Show()
        MageToolsDB.queueVisible = true
    end
end

function TH:OnEvent(event, ...)
    if event == "CHAT_MSG_WHISPER" then
        local msg, sender = ...
        local request = self:MatchKeyword(msg)
        if request then
            -- Strip realm name if present
            local name = strsplit("-", sender)
            self:AddToQueue(name, request)
        end
    elseif event == "TRADE_SHOW" then
        -- Trade window opened — if we have a pending trade, place items
        if pendingTrade then
            self:PlaceItemsInTrade(pendingTrade.request)
        end
    elseif event == "TRADE_ACCEPT_UPDATE" then
        -- Nothing needed here, handled on close
    elseif event == "UI_INFO_MESSAGE" then
        local _, msg = ...
        if msg and strfind(msg, "Trade complete") then
            -- Find and remove the served player
            if pendingTrade then
                for i, entry in ipairs(queue) do
                    if entry.name == pendingTrade.name then
                        self:RemoveFromQueue(i)
                        break
                    end
                end
                pendingTrade = nil
            end
        end
    elseif event == "TRADE_CLOSED" then
        -- Reset pending if trade cancelled
        -- (Don't remove from queue — they still need items)
    elseif event == "GROUP_ROSTER_UPDATE" or event == "PARTY_MEMBERS_CHANGED" then
        -- Remove offline players from queue
        local toRemove = {}
        for i, entry in ipairs(queue) do
            if not UnitIsConnected(entry.name) then
                tinsert(toRemove, i)
            end
        end
        for j = #toRemove, 1, -1 do
            tremove(queue, toRemove[j])
        end
        if #toRemove > 0 then
            self:UpdateQueueDisplay()
        end
    end
end

MT:RegisterEvents("CHAT_MSG_WHISPER", "TRADE_SHOW", "TRADE_CLOSED", "UI_INFO_MESSAGE", "PARTY_MEMBERS_CHANGED")
```

**Step 2: Commit**

```
git add TradeHelper.lua
git commit -m "feat(trade): add whisper queue and trade distribution system"
```

---

### Task 7: Integration Testing and Polish

**Files:**
- Modify: `Core.lua` (if any wiring issues)
- Modify: any module as needed

**Step 1: Verify TOC file lists all files in correct order**

Expected final `MageTools.toc` file list:
```
Core.lua
Data.lua
MasqueHelper.lua
PopupMenu.lua
ConjureManager.lua
TradeHelper.lua
```

**Step 2: Test checklist (manual, in-game)**

Load into TBC Anniversary on a mage character and verify:

- [ ] Addon loads without Lua errors (`/mt` prints help)
- [ ] `/mt config` shows default settings
- [ ] HUD appears with gem/food/water counts
- [ ] `/mt hud` toggles HUD, state persists on reload
- [ ] HUD is draggable, position persists on reload
- [ ] Keybind appears in Key Bindings > MageTools
- [ ] Binding the key and pressing it opens popup at cursor
- [ ] Popup shows only known teleport/portal spells for your faction
- [ ] Clicking a spell button casts the spell and closes popup
- [ ] Pressing Escape closes popup
- [ ] Conjured item counts update when conjuring food/water
- [ ] `/mt conjure` opens session panel with correct group size
- [ ] Session panel food/water buttons cast the right spells
- [ ] "Stocked up" message appears when targets are met
- [ ] Whisper keyword triggers queue entry and auto-reply
- [ ] Queue frame appears with player name and request
- [ ] Clicking queue row targets player and opens trade
- [ ] Items auto-placed in trade window
- [ ] Completed trade removes player from queue with "Enjoy!" reply
- [ ] With Masque installed, buttons are skinnable
- [ ] Without Masque installed, buttons render with default WoW style

**Step 3: Fix any issues found, commit**

```
git add -A
git commit -m "fix(integration): address issues from in-game testing"
```

---

### Task 8: Final commit and tag

**Step 1: Tag the release**

```
git tag -a v0.1.0 -m "Initial release: popup menu, conjure manager, trade helper"
```
