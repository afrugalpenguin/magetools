local MT = MageTools
local OPT = {}
MT:RegisterModule("Options", OPT)

local optionsFrame = nil

-- Style constants (matches WhatsNew.lua)
local BG_COLOR = { 0.08, 0.08, 0.12, 0.98 }
local BORDER_COLOR = { 0.4, 0.6, 0.9, 1 }
local HEADER_COLOR = "|cffFFD200"
local ACCENT_COLOR = { 0.4, 0.6, 0.9 }

local SIDEBAR_WIDTH = 120
local FRAME_WIDTH = 500
local FRAME_HEIGHT = 400

--------------------------------------------------------------------------------
-- Control Builders
--------------------------------------------------------------------------------

local function CreateHeader(parent, text, yOffset)
    local label = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetPoint("TOPLEFT", parent, "TOPLEFT", 8, yOffset)
    label:SetText(HEADER_COLOR .. text .. "|r")

    local line = parent:CreateTexture(nil, "ARTWORK")
    line:SetHeight(1)
    line:SetPoint("TOPLEFT", parent, "TOPLEFT", 8, yOffset - 14)
    line:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -8, yOffset - 14)
    line:SetColorTexture(ACCENT_COLOR[1], ACCENT_COLOR[2], ACCENT_COLOR[3], 0.4)

    return yOffset - 22
end

local function CreateCheckbox(parent, label, dbKey, yOffset, onChange)
    local cb = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    cb:SetPoint("TOPLEFT", parent, "TOPLEFT", 8, yOffset)
    local cbText = cb.text or (cb.GetName and cb:GetName() and _G[cb:GetName() .. "Text"])
    if cbText then
        cbText:SetText(label)
        cbText:SetFontObject("GameFontHighlight")
    else
        local text = cb:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        text:SetPoint("LEFT", cb, "RIGHT", 4, 0)
        text:SetText(label)
    end
    cb:SetChecked(MageToolsDB[dbKey])
    cb:SetScript("OnClick", function(self)
        MageToolsDB[dbKey] = self:GetChecked()
        if onChange then onChange(self:GetChecked()) end
    end)
    return yOffset - 28
end

local function CreateSlider(parent, label, dbKey, minVal, maxVal, step, yOffset, onChange)
    -- Label
    local text = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    text:SetPoint("TOPLEFT", parent, "TOPLEFT", 12, yOffset)
    text:SetText(label)

    -- Value display
    local valueText = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    valueText:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -12, yOffset)

    -- Slider frame
    local slider = CreateFrame("Slider", nil, parent, "OptionsSliderTemplate")
    slider:SetPoint("TOPLEFT", parent, "TOPLEFT", 14, yOffset - 16)
    slider:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -14, yOffset - 16)
    slider:SetHeight(16)
    slider:SetMinMaxValues(minVal, maxVal)
    slider:SetValueStep(step)
    slider:SetObeyStepOnDrag(true)

    -- Hide the template's own labels
    local low = slider.Low or _G[slider:GetName() .. "Low"]
    local high = slider.High or _G[slider:GetName() .. "High"]
    local sliderText = slider.Text or _G[slider:GetName() .. "Text"]
    if low then low:SetText("") end
    if high then high:SetText("") end
    if sliderText then sliderText:SetText("") end

    local currentVal = MageToolsDB[dbKey]
    slider:SetValue(currentVal)

    local function FormatValue(val)
        if step < 1 then
            return string.format("%.2f", val)
        end
        return tostring(math.floor(val + 0.5))
    end

    valueText:SetText(FormatValue(currentVal))

    slider:SetScript("OnValueChanged", function(self, value)
        -- Snap to step
        value = math.floor(value / step + 0.5) * step
        MageToolsDB[dbKey] = value
        valueText:SetText(FormatValue(value))
        if onChange then onChange(value) end
    end)

    return yOffset - 42
end

local function CreateKeybind(parent, label, bindingName, yOffset)
    local text = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    text:SetPoint("TOPLEFT", parent, "TOPLEFT", 12, yOffset)
    text:SetText(label)

    local btn = CreateFrame("Button", nil, parent, "BackdropTemplate")
    btn:SetSize(120, 22)
    btn:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -12, yOffset + 2)
    btn:SetBackdrop({
        bgFile = "Interface\\BUTTONS\\WHITE8X8",
        edgeFile = "Interface\\BUTTONS\\WHITE8X8",
        edgeSize = 1,
    })
    btn:SetBackdropColor(0.15, 0.15, 0.15, 1)
    btn:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)

    local btnText = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    btnText:SetPoint("CENTER")

    local function UpdateLabel()
        local key = GetBindingKey(bindingName)
        btnText:SetText(key or "|cff666666Not bound|r")
    end
    UpdateLabel()

    local waiting = false

    btn:SetScript("OnClick", function(self, click)
        if click == "RightButton" then
            -- Unbind on right-click
            local key = GetBindingKey(bindingName)
            if key then
                SetBinding(key, nil)
                SaveBindings(GetCurrentBindingSet())
            end
            UpdateLabel()
            return
        end
        if waiting then return end
        waiting = true
        btnText:SetText("|cffFFD200Press a key...|r")
        self:SetBackdropBorderColor(ACCENT_COLOR[1], ACCENT_COLOR[2], ACCENT_COLOR[3], 1)
        self:SetScript("OnKeyDown", function(self, key)
            if key == "ESCAPE" then
                -- Cancel
            else
                -- Clear any old binding for this action
                local oldKey = GetBindingKey(bindingName)
                if oldKey then SetBinding(oldKey, nil) end
                SetBinding(key, bindingName)
                SaveBindings(GetCurrentBindingSet())
            end
            waiting = false
            self:SetScript("OnKeyDown", nil)
            self:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
            self:EnableKeyboard(false)
            UpdateLabel()
        end)
        self:EnableKeyboard(true)
    end)
    btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")

    return yOffset - 28
end

local function CreateKeywordEditor(parent, yOffset)
    local headerY = CreateHeader(parent, "Whisper Keywords", yOffset)
    yOffset = headerY

    local keywordFrame = CreateFrame("Frame", nil, parent)
    keywordFrame:SetPoint("TOPLEFT", parent, "TOPLEFT", 8, yOffset)
    keywordFrame:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -8, yOffset)
    keywordFrame:SetHeight(120)

    local rows = {}
    local scrollOffset = 0

    local function RefreshKeywords()
        for _, row in ipairs(rows) do
            row:Hide()
        end

        local keywords = MageToolsDB.whisperKeywords
        for i, kw in ipairs(keywords) do
            local row = rows[i]
            if not row then
                row = CreateFrame("Frame", nil, keywordFrame)
                row:SetHeight(22)
                row:SetPoint("TOPLEFT", keywordFrame, "TOPLEFT", 0, -((i - 1) * 24))
                row:SetPoint("TOPRIGHT", keywordFrame, "TOPRIGHT", 0, -((i - 1) * 24))

                local kwText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
                kwText:SetPoint("LEFT", 4, 0)
                row.kwText = kwText

                local removeBtn = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
                removeBtn:SetSize(20, 20)
                removeBtn:SetPoint("RIGHT", row, "RIGHT", -2, 0)
                removeBtn:SetText("x")
                removeBtn:SetNormalFontObject("GameFontNormalSmall")
                row.removeBtn = removeBtn

                rows[i] = row
            end
            row.kwText:SetText(kw)
            row.removeBtn:SetScript("OnClick", function()
                tremove(MageToolsDB.whisperKeywords, i)
                RefreshKeywords()
            end)
            row:Show()
        end

        -- Adjust keywordFrame height
        keywordFrame:SetHeight(math.max(24, #keywords * 24 + 30))
    end

    -- Add keyword input
    local addBox = CreateFrame("EditBox", nil, keywordFrame, "InputBoxTemplate")
    addBox:SetSize(120, 20)
    addBox:SetAutoFocus(false)
    addBox:SetFontObject("GameFontHighlightSmall")

    local addBtn = CreateFrame("Button", nil, keywordFrame, "UIPanelButtonTemplate")
    addBtn:SetSize(50, 22)
    addBtn:SetText("Add")
    addBtn:SetNormalFontObject("GameFontNormalSmall")

    -- Position at the bottom of current keywords
    local function RepositionAdd()
        local count = #MageToolsDB.whisperKeywords
        local addY = -(count * 24)
        addBox:ClearAllPoints()
        addBox:SetPoint("TOPLEFT", keywordFrame, "TOPLEFT", 4, addY - 2)
        addBtn:ClearAllPoints()
        addBtn:SetPoint("LEFT", addBox, "RIGHT", 6, 0)
    end

    addBtn:SetScript("OnClick", function()
        local newKW = strtrim(addBox:GetText())
        if newKW ~= "" then
            tinsert(MageToolsDB.whisperKeywords, newKW)
            addBox:SetText("")
            RefreshKeywords()
            RepositionAdd()
        end
    end)
    addBox:SetScript("OnEnterPressed", function()
        addBtn:Click()
    end)
    addBox:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
    end)

    RefreshKeywords()
    RepositionAdd()

    -- Return offset accounting for keyword list + add row
    local totalHeight = (#MageToolsDB.whisperKeywords * 24) + 30
    return yOffset - totalHeight
end

--------------------------------------------------------------------------------
-- Category Content Builders
--------------------------------------------------------------------------------

local function BuildGeneralContent(parent)
    local y = -8

    -- HUD section
    y = CreateHeader(parent, "HUD", y)
    y = CreateCheckbox(parent, "Show HUD", "hudVisible", y, function(checked)
        local cm = MT.modules["ConjureManager"]
        if cm then
            if checked then
                if MageToolsHUD then MageToolsHUD:Show() end
            else
                if MageToolsHUD then MageToolsHUD:Hide() end
            end
        end
    end)
    y = CreateCheckbox(parent, "Vertical HUD", "hudVertical", y, function()
        local cm = MT.modules["ConjureManager"]
        if cm and cm.RebuildHUD then cm:RebuildHUD() end
    end)
    y = CreateSlider(parent, "HUD Button Size", "hudButtonSize", 24, 48, 2, y, function()
        local cm = MT.modules["ConjureManager"]
        if cm and cm.RebuildHUD then cm:RebuildHUD() end
    end)

    -- Popup Menu section
    y = CreateHeader(parent, "Popup Menu", y - 6)

    y = CreateKeybind(parent, "Toggle Keybind", "MAGETOOLS_POPUP", y)
    y = CreateSlider(parent, "Buttons Per Row", "popupColumns", 3, 8, 1, y, function()
        local pm = MT.modules["PopupMenu"]
        if pm and pm.Rebuild then pm:Rebuild() end
    end)
    y = CreateCheckbox(parent, "Close Popup on Cast", "popupCloseOnCast", y)

    parent:SetHeight(math.abs(y) + 8)
end

local function BuildTradeContent(parent)
    local y = -8

    -- Auto-Reply section
    y = CreateHeader(parent, "Auto-Reply", y)
    y = CreateCheckbox(parent, "Enable Auto-Reply", "autoReply", y)

    -- Whisper Keywords section
    y = CreateKeywordEditor(parent, y - 6)

    -- Trade section
    y = CreateHeader(parent, "Trade", y - 6)
    y = CreateCheckbox(parent, "Auto-Place Items in Trade", "autoPlaceItems", y)
    y = CreateSlider(parent, "Food Stacks Per Person", "foodStacksPerPerson", 1, 10, 1, y)
    y = CreateSlider(parent, "Water Stacks Per Person", "waterStacksPerPerson", 1, 10, 1, y)

    parent:SetHeight(math.abs(y) + 8)
end

local function BuildAppearanceContent(parent)
    local y = -8

    y = CreateHeader(parent, "Button Sizes", y)
    y = CreateSlider(parent, "Popup Button Size", "popupButtonSize", 28, 48, 2, y, function()
        local pm = MT.modules["PopupMenu"]
        if pm and pm.Rebuild then pm:Rebuild() end
    end)

    y = CreateHeader(parent, "Queue", y - 6)
    y = CreateSlider(parent, "Max Queue Display", "maxQueueDisplay", 5, 20, 1, y, function()
        local th = MT.modules["TradeHelper"]
        if th and th.RebuildQueue then th:RebuildQueue() end
    end)

    y = CreateHeader(parent, "Opacity", y - 6)
    y = CreateSlider(parent, "Session Background Opacity", "sessionBgAlpha", 0.0, 1.0, 0.05, y, function()
        if MageToolsConjureSession then
            MageToolsConjureSession:SetBackdropColor(0, 0, 0, MageToolsDB.sessionBgAlpha)
        end
    end)

    parent:SetHeight(math.abs(y) + 8)
end

--------------------------------------------------------------------------------
-- Shared Layout Builder
--------------------------------------------------------------------------------

local categoryDefs = {
    { name = "General",      builder = BuildGeneralContent },
    { name = "Trade Helper", builder = BuildTradeContent },
    { name = "Appearance",   builder = BuildAppearanceContent },
}

-- Builds the sidebar + scrollable content layout into any parent frame.
-- topOffset: Y offset from parent top where the layout begins.
-- contentWidth (optional): explicit width for scroll children.
-- Returns a layout controller table.
local function BuildOptionsLayout(parent, topOffset, contentWidth)
    local layout = {
        categories = {},
        contentFrames = {},
        activeCategory = nil,
    }

    -- Sidebar
    local sidebar = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    sidebar:SetPoint("TOPLEFT", parent, "TOPLEFT", 1, topOffset)
    sidebar:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", 1, 1)
    sidebar:SetWidth(SIDEBAR_WIDTH)

    -- Sidebar separator line
    local sepLine = parent:CreateTexture(nil, "ARTWORK")
    sepLine:SetWidth(1)
    sepLine:SetPoint("TOPLEFT", sidebar, "TOPRIGHT", 0, 0)
    sepLine:SetPoint("BOTTOMLEFT", sidebar, "BOTTOMRIGHT", 0, 0)
    sepLine:SetColorTexture(ACCENT_COLOR[1], ACCENT_COLOR[2], ACCENT_COLOR[3], 0.3)

    -- Content area with scroll support
    local contentArea = CreateFrame("ScrollFrame", nil, parent, "UIPanelScrollFrameTemplate")
    contentArea:SetPoint("TOPLEFT", parent, "TOPLEFT", SIDEBAR_WIDTH + 6, topOffset - 2)
    contentArea:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -26, 6)

    local function ShowCategory(index)
        if layout.activeCategory == index then return end
        layout.activeCategory = index

        for i, catBtn in ipairs(layout.categories) do
            if i == index then
                catBtn:SetBackdropColor(ACCENT_COLOR[1], ACCENT_COLOR[2], ACCENT_COLOR[3], 0.3)
            else
                catBtn:SetBackdropColor(0, 0, 0, 0)
            end
        end

        contentArea:SetScrollChild(layout.contentFrames[index])
        for i, frame in ipairs(layout.contentFrames) do
            if i == index then
                frame:Show()
            else
                frame:Hide()
            end
        end
    end

    -- Create category buttons and content frames
    for i, def in ipairs(categoryDefs) do
        local catBtn = CreateFrame("Button", nil, sidebar, "BackdropTemplate")
        catBtn:SetSize(SIDEBAR_WIDTH - 2, 28)
        catBtn:SetPoint("TOPLEFT", sidebar, "TOPLEFT", 1, -((i - 1) * 30) - 4)
        catBtn:SetBackdrop({
            bgFile = "Interface\\BUTTONS\\WHITE8X8",
        })
        catBtn:SetBackdropColor(0, 0, 0, 0)

        local catLabel = catBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        catLabel:SetPoint("LEFT", 10, 0)
        catLabel:SetText(def.name)
        catBtn.label = catLabel

        catBtn:SetScript("OnEnter", function(self)
            if layout.activeCategory ~= i then
                self:SetBackdropColor(ACCENT_COLOR[1], ACCENT_COLOR[2], ACCENT_COLOR[3], 0.15)
            end
        end)
        catBtn:SetScript("OnLeave", function(self)
            if layout.activeCategory ~= i then
                self:SetBackdropColor(0, 0, 0, 0)
            end
        end)
        catBtn:SetScript("OnClick", function()
            ShowCategory(i)
        end)

        tinsert(layout.categories, catBtn)

        -- Content frame (scrollchild)
        local content = CreateFrame("Frame", nil, contentArea)
        local w = contentWidth or parent:GetWidth() - SIDEBAR_WIDTH - 36
        if w < 100 then w = 340 end
        content:SetWidth(w)
        content:SetHeight(FRAME_HEIGHT)
        content:Hide()

        def.builder(content)
        tinsert(layout.contentFrames, content)
    end

    -- Show first category by default
    ShowCategory(1)

    layout.ShowCategory = ShowCategory
    return layout
end

--------------------------------------------------------------------------------
-- Standalone Options Frame
--------------------------------------------------------------------------------

local function CreateOptionsFrame()
    local f = CreateFrame("Frame", "MageToolsOptions", UIParent, "BackdropTemplate")
    f:SetSize(FRAME_WIDTH, FRAME_HEIGHT)
    f:SetPoint("CENTER")
    f:SetFrameStrata("DIALOG")
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", function(self) self:StartMoving() end)
    f:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
    f:SetClampedToScreen(true)
    f:Hide()

    f:SetBackdrop({
        bgFile = "Interface\\BUTTONS\\WHITE8X8",
        edgeFile = "Interface\\BUTTONS\\WHITE8X8",
        edgeSize = 1,
    })
    f:SetBackdropColor(BG_COLOR[1], BG_COLOR[2], BG_COLOR[3], BG_COLOR[4])
    f:SetBackdropBorderColor(BORDER_COLOR[1], BORDER_COLOR[2], BORDER_COLOR[3], BORDER_COLOR[4])

    tinsert(UISpecialFrames, "MageToolsOptions")

    -- Title bar
    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -10)
    title:SetText("|cff88ddffMageTools Options|r")

    -- Decorative line under title
    local titleLine = f:CreateTexture(nil, "ARTWORK")
    titleLine:SetHeight(1)
    titleLine:SetPoint("TOPLEFT", f, "TOPLEFT", 12, -32)
    titleLine:SetPoint("TOPRIGHT", f, "TOPRIGHT", -12, -32)
    titleLine:SetColorTexture(ACCENT_COLOR[1], ACCENT_COLOR[2], ACCENT_COLOR[3], 0.5)

    -- Close button
    local closeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", f, "TOPRIGHT", -2, -2)

    -- Build the shared layout inside this frame
    BuildOptionsLayout(f, -36, FRAME_WIDTH - SIDEBAR_WIDTH - 36)

    return f
end

--------------------------------------------------------------------------------
-- Public API
--------------------------------------------------------------------------------

function OPT:Toggle()
    if not optionsFrame then
        optionsFrame = CreateOptionsFrame()
    end
    if optionsFrame:IsShown() then
        optionsFrame:Hide()
    else
        optionsFrame:Show()
    end
end

function OPT:Show()
    if not optionsFrame then
        optionsFrame = CreateOptionsFrame()
    end
    optionsFrame:Show()
end

function OPT:Hide()
    if optionsFrame then
        optionsFrame:Hide()
    end
end

--------------------------------------------------------------------------------
-- Blizzard Interface Integration
--------------------------------------------------------------------------------

function OPT:RegisterBlizzardOptions()
    local panel = CreateFrame("Frame")
    panel.name = "MageTools"

    -- Defer layout build until the panel is shown and has real dimensions
    local initialized = false
    panel:SetScript("OnShow", function(self)
        if initialized then return end
        initialized = true

        -- Title
        local title = self:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        title:SetPoint("TOPLEFT", 16, -16)
        title:SetText("|cff88ddffMageTools|r")

        -- Decorative line
        local titleLine = self:CreateTexture(nil, "ARTWORK")
        titleLine:SetHeight(1)
        titleLine:SetPoint("TOPLEFT", self, "TOPLEFT", 16, -38)
        titleLine:SetPoint("TOPRIGHT", self, "TOPRIGHT", -16, -38)
        titleLine:SetColorTexture(ACCENT_COLOR[1], ACCENT_COLOR[2], ACCENT_COLOR[3], 0.5)

        -- Build the shared layout now that the panel has dimensions
        BuildOptionsLayout(self, -44)
    end)

    if Settings and Settings.RegisterCanvasLayoutCategory then
        local category = Settings.RegisterCanvasLayoutCategory(panel, panel.name)
        Settings.RegisterAddOnCategory(category)
    elseif InterfaceOptions_AddCategory then
        InterfaceOptions_AddCategory(panel)
    end
end

function OPT:Init()
    self:RegisterBlizzardOptions()
end
