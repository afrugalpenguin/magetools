local MT = MageTools
local WN = {}
MT:RegisterModule("WhatsNew", WN)

local whatsNewFrame = nil

local changelog = {
    {
        version = "2.4.0",
        features = {
            "Ritual of Refreshment (Refreshment Table) in popup conjure section",
        },
        fixes = {},
    },
    {
        version = "2.3.0",
        features = {
            "Teleport/portal reagent counts on HUD (Rune of Teleportation, Rune of Portals)",
            "Toggle reagent display on/off in Options",
        },
        fixes = {},
    },
    {
        version = "2.2.3",
        features = {},
        fixes = {
            "Fix popup Show/Hide/position blocked in combat",
        },
    },
    {
        version = "2.2.2",
        features = {},
        fixes = {
            "Fix mana gem delete not working in release-to-cast mode",
        },
    },
    {
        version = "2.2.1",
        features = {
            "Popup menu now works in combat (armor buffs, etc.)",
            "Added Theramore and Stonard teleport/portal spells",
        },
        fixes = {},
    },
    {
        version = "2.2.0",
        features = {
            "Smart gem conjure — auto-deletes existing mana gem before conjuring a new one",
            "Popup category toggles — hide/show Buffs, Food/Water, Gems, Teleports, or Portals in Options",
        },
        fixes = {
            "Fix popup button icons appearing black",
            "Fix release-to-cast mode casting when cursor is off all buttons",
        },
    },
    {
        version = "2.1.0",
        features = {
            "Party chat detection — party members can request food/water via chat keywords (enable in Trade Helper settings)",
        },
        fixes = {},
    },
    {
        version = "2.0.5",
        features = {},
        fixes = {
            "HUD icons now match the actual conjured items in your bags",
        },
    },
    {
        version = "2.0.4",
        features = {},
        fixes = {
            "Fix finnicky frame dragging (HUD, Trade Queue, Conjure Session)",
        },
    },
    {
        version = "2.0.3",
        features = {},
        fixes = {
            "Fix addon loading and showing HUD on non-Mage characters",
        },
    },
    {
        version = "2.0.2",
        features = {},
        fixes = {
            "Fix Shattrath teleport/portal not showing for both factions",
        },
    },
    {
        version = "2.0.1",
        features = {},
        fixes = {
            "Fix Tour.lua missing from release package",
        },
    },
    {
        version = "2.0.0",
        features = {
            "Onboarding tour with welcome splash and guided highlights",
            "Tour steps: HUD, Conjure Session, Popup Menu, Options",
            "Start tour anytime with /mgt tour",
        },
        fixes = {},
    },
    {
        version = "1.14.6",
        features = {},
        fixes = {
            "Improve bag count update responsiveness in conjure window",
        },
    },
    {
        version = "1.14.5",
        features = {},
        fixes = {
            "Add luacheck linting configuration",
            "Update addon icon",
        },
    },
    {
        version = "1.14.4",
        features = {},
        fixes = {
            "Remove Bindings.xml (unsupported in TBC Classic Anniversary)",
        },
    },
    {
        version = "1.14.3",
        features = {},
        fixes = {
            "Add changelog and include in release zip",
        },
    },
    {
        version = "1.14.2",
        features = {},
        fixes = {
            "Add GitHub releases workflow and packaging",
        },
    },
    {
        version = "1.14.1",
        features = {},
        fixes = {
            "Update README tagline and keyword defaults",
        },
    },
    {
        version = "1.14.0",
        features = {},
        fixes = {
            "Update gitignore with standard patterns",
        },
    },
    {
        version = "1.13.1",
        features = {},
        fixes = {
            "Support custom whisper keywords in queue matching",
        },
    },
    {
        version = "1.13.0",
        features = {
            "Drive conjure session serving count from trade queue",
        },
        fixes = {},
    },
    {
        version = "1.12.0",
        features = {
            "Auto-target player on queue row click via secure macro",
            "Right-click to remove from queue",
        },
        fixes = {},
    },
    {
        version = "1.11.0",
        features = {
            "Tabbed options layout replacing sidebar",
            "Add conjure session shortcut button in trade queue",
        },
        fixes = {
            "Fix checkbox persistence (coerce nil to false)",
        },
    },
    {
        version = "1.10.1",
        features = {},
        fixes = {
            "Add spacing between HUD controls in options",
        },
    },
    {
        version = "1.10.0",
        features = {},
        fixes = {
            "Update conjure session on group roster changes",
        },
    },
    {
        version = "1.9.1",
        features = {
            "Add quadrant labels (Buffs, Conjure, Teleports, Portals)",
            "Add button borders when Masque is not active",
            "Single-row layout for all spell categories",
        },
        fixes = {},
    },
    {
        version = "1.9.0",
        features = {
            "Release-to-cast mode using secure handler WrapScript",
            "Hold keybind to open, hover spell, release to cast",
        },
        fixes = {},
    },
    {
        version = "1.8.0",
        features = {
            "X layout with four quadrants around cursor center",
            "Mouse button keybind support",
        },
        fixes = {},
    },
    {
        version = "1.7.1",
        features = {},
        fixes = {
            "Rewrite keybind system using SetOverrideBindingClick",
        },
    },
    {
        version = "1.7.0",
        features = {
            "Add Bindings.xml to TOC and keybind button to options",
        },
        fixes = {},
    },
    {
        version = "1.6.0",
        features = {
            "Add vertical/horizontal orientation toggle for HUD",
        },
        fixes = {},
    },
    {
        version = "1.5.0",
        features = {
            "Add Ice/Frost Armor and Molten Armor to buff row",
        },
        fixes = {},
    },
    {
        version = "1.4.0",
        features = {
            "Add buff spells row to popup menu",
        },
        fixes = {},
    },
    {
        version = "1.3.0",
        features = {
            "Add options panel with configurable settings",
        },
        fixes = {
            "Conjure session fixes",
        },
    },
    {
        version = "1.2.1",
        features = {},
        fixes = {
            "Update APIs for TBC Classic Anniversary client",
        },
    },
    {
        version = "1.2.0",
        features = {},
        fixes = {
            "Address code review issues for TBC compatibility",
        },
    },
    {
        version = "1.1.0",
        features = {
            "Add whisper queue and trade distribution system",
        },
        fixes = {},
    },
    {
        version = "1.0.3",
        features = {
            "Add bag scanning, HUD, and conjure session panel",
        },
        fixes = {},
    },
    {
        version = "1.0.2",
        features = {
            "Add keybind-triggered portal/teleport icon grid",
        },
        fixes = {},
    },
    {
        version = "1.0.1",
        features = {
            "Add mage spell and conjured item ID tables",
            "Add Masque integration helper",
        },
        fixes = {},
    },
    {
        version = "1.0.0",
        features = {
            "Initial release: TOC, event backbone, and saved variables",
        },
        fixes = {},
    },
}

function WN:GetChangelog()
    return changelog
end

function WN:ShouldShow()
    local currentVersion = MT.version
    local lastSeen = MageToolsDB.lastSeenVersion
    return lastSeen == nil or lastSeen ~= currentVersion
end

function WN:MarkAsSeen()
    MageToolsDB.lastSeenVersion = MT.version
end

-- Modal UI

local function CreateWhatsNewFrame()
    -- Dim overlay
    local overlay = CreateFrame("Frame", nil, UIParent)
    overlay:SetAllPoints()
    overlay:SetFrameStrata("FULLSCREEN_DIALOG")
    overlay:SetFrameLevel(199)
    overlay:EnableMouse(true)
    local overlayTex = overlay:CreateTexture(nil, "BACKGROUND")
    overlayTex:SetAllPoints()
    overlayTex:SetColorTexture(0, 0, 0, 0.5)
    overlay:Hide()

    -- Main frame
    local f = CreateFrame("Frame", "MageToolsWhatsNew", UIParent, "BackdropTemplate")
    f:SetSize(420, 360)
    f:SetPoint("CENTER", UIParent, "CENTER", 0, 50)
    f:SetFrameStrata("FULLSCREEN_DIALOG")
    f:SetFrameLevel(200)
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
    f:SetBackdropColor(0.08, 0.08, 0.12, 0.98)
    f:SetBackdropBorderColor(0.4, 0.6, 0.9, 1)

    tinsert(UISpecialFrames, "MageToolsWhatsNew")

    -- Title
    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -12)
    title:SetText("|cff88ddffWhat's New in MageTools v" .. MT.version .. "|r")
    f.title = title

    -- Decorative line
    local line = f:CreateTexture(nil, "ARTWORK")
    line:SetHeight(1)
    line:SetPoint("TOPLEFT", f, "TOPLEFT", 12, -36)
    line:SetPoint("TOPRIGHT", f, "TOPRIGHT", -12, -36)
    line:SetColorTexture(0.4, 0.6, 0.9, 0.5)

    -- Scroll frame
    local scrollFrame = CreateFrame("ScrollFrame", "MageToolsWhatsNewScroll", f, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", f, "TOPLEFT", 12, -42)
    scrollFrame:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -30, 44)

    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetSize(scrollFrame:GetWidth(), 1)
    scrollFrame:SetScrollChild(scrollChild)
    f.scrollChild = scrollChild

    -- Got it button
    local btn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    btn:SetSize(100, 26)
    btn:SetPoint("BOTTOM", f, "BOTTOM", 0, 10)
    btn:SetText("Got it!")
    btn:SetScript("OnClick", function()
        WN:Hide()
    end)

    f.overlay = overlay
    return f
end

local function PopulateChangelog(frame)
    -- Clear previous content
    local children = { frame.scrollChild:GetChildren() }
    for _, child in ipairs(children) do
        child:Hide()
        child:SetParent(nil)
    end

    local scrollWidth = frame.scrollChild:GetWidth()
    if scrollWidth < 10 then scrollWidth = 370 end
    local yOffset = 0

    for i, entry in ipairs(changelog) do
        -- Version header
        local header = frame.scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        header:SetPoint("TOPLEFT", frame.scrollChild, "TOPLEFT", 0, yOffset)
        header:SetWidth(scrollWidth)
        header:SetJustifyH("LEFT")
        if entry.version == MT.version then
            header:SetText("|cffFFCC00Version " .. entry.version .. " (Current)|r")
        else
            header:SetText("|cff888888Version " .. entry.version .. "|r")
        end
        yOffset = yOffset - 20

        -- Features
        if entry.features and #entry.features > 0 then
            local label = frame.scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            label:SetPoint("TOPLEFT", frame.scrollChild, "TOPLEFT", 4, yOffset)
            label:SetText("|cff88ddffFeatures:|r")
            yOffset = yOffset - 16

            for _, feat in ipairs(entry.features) do
                local text = frame.scrollChild:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
                text:SetPoint("TOPLEFT", frame.scrollChild, "TOPLEFT", 12, yOffset)
                text:SetWidth(scrollWidth - 20)
                text:SetJustifyH("LEFT")
                text:SetText("|cffcccccc-|r " .. feat)
                local height = text:GetStringHeight()
                yOffset = yOffset - height - 2
            end
            yOffset = yOffset - 4
        end

        -- Fixes
        if entry.fixes and #entry.fixes > 0 then
            local label = frame.scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            label:SetPoint("TOPLEFT", frame.scrollChild, "TOPLEFT", 4, yOffset)
            label:SetText("|cff88ff88Fixes:|r")
            yOffset = yOffset - 16

            for _, fix in ipairs(entry.fixes) do
                local text = frame.scrollChild:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
                text:SetPoint("TOPLEFT", frame.scrollChild, "TOPLEFT", 12, yOffset)
                text:SetWidth(scrollWidth - 20)
                text:SetJustifyH("LEFT")
                text:SetText("|cffcccccc-|r " .. fix)
                local height = text:GetStringHeight()
                yOffset = yOffset - height - 2
            end
            yOffset = yOffset - 4
        end

        -- Spacing between versions
        yOffset = yOffset - 12
    end

    frame.scrollChild:SetHeight(math.abs(yOffset))
end

function WN:Show()
    if not whatsNewFrame then
        whatsNewFrame = CreateWhatsNewFrame()
    end
    whatsNewFrame.title:SetText("|cff88ddffWhat's New in MageTools v" .. MT.version .. "|r")
    PopulateChangelog(whatsNewFrame)
    whatsNewFrame.overlay:Show()
    whatsNewFrame:Show()
end

function WN:Hide()
    if whatsNewFrame then
        whatsNewFrame:Hide()
        whatsNewFrame.overlay:Hide()
    end
    self:MarkAsSeen()
end

function WN:IsShown()
    return whatsNewFrame and whatsNewFrame:IsShown()
end
