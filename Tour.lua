local MT = MageTools
local Tour = {}
MT:RegisterModule("Tour", Tour)

local TOUR_VERSION = 1

-- Style constants (matches Options.lua / WhatsNew.lua)
local BG_COLOR = { 0.08, 0.08, 0.12, 0.98 }
local BORDER_COLOR = { 0.4, 0.6, 0.9, 1 }
local tooltipFrame = nil
local currentStep = 0
local isRunning = false

local function CreateTooltipFrame()
    local f = CreateFrame("Frame", "MageToolsTour", UIParent, "BackdropTemplate")
    f:SetSize(280, 140)
    f:SetFrameStrata("TOOLTIP")
    f:SetBackdrop({
        bgFile = "Interface\\BUTTONS\\WHITE8X8",
        edgeFile = "Interface\\BUTTONS\\WHITE8X8",
        edgeSize = 1,
    })
    f:SetBackdropColor(BG_COLOR[1], BG_COLOR[2], BG_COLOR[3], BG_COLOR[4])
    f:SetBackdropBorderColor(BORDER_COLOR[1], BORDER_COLOR[2], BORDER_COLOR[3], BORDER_COLOR[4])
    f:Hide()

    tinsert(UISpecialFrames, "MageToolsTour")

    -- Title
    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 12, -10)
    f.title = title

    -- Description
    local desc = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    desc:SetPoint("TOPLEFT", 12, -32)
    desc:SetPoint("TOPRIGHT", -12, -32)
    desc:SetJustifyH("LEFT")
    desc:SetWordWrap(true)
    f.desc = desc

    -- Step counter
    local counter = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    counter:SetPoint("BOTTOMLEFT", 12, 10)
    f.counter = counter

    -- Skip button
    local skipBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    skipBtn:SetSize(70, 22)
    skipBtn:SetPoint("BOTTOMRIGHT", -12, 8)
    skipBtn:SetText("Skip Tour")
    skipBtn:SetNormalFontObject("GameFontNormalSmall")
    f.skipBtn = skipBtn

    -- Next button
    local nextBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    nextBtn:SetSize(60, 22)
    nextBtn:SetPoint("RIGHT", skipBtn, "LEFT", -6, 0)
    nextBtn:SetText("Next")
    nextBtn:SetNormalFontObject("GameFontNormalSmall")
    f.nextBtn = nextBtn

    return f
end

local glowFrame = nil

local function CreateGlowFrame()
    local f = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    f:SetFrameStrata("TOOLTIP")
    f:SetBackdrop({
        edgeFile = "Interface\\BUTTONS\\WHITE8X8",
        edgeSize = 2,
    })
    f:SetBackdropBorderColor(0.4, 0.8, 1.0, 1)
    f:Hide()

    -- Pulse animation
    local ag = f:CreateAnimationGroup()
    ag:SetLooping("BOUNCE")
    local fade = ag:CreateAnimation("Alpha")
    fade:SetFromAlpha(1)
    fade:SetToAlpha(0.3)
    fade:SetDuration(0.8)
    fade:SetSmoothing("IN_OUT")
    f.pulse = ag

    return f
end

local function ShowGlow(frame)
    if not glowFrame then
        glowFrame = CreateGlowFrame()
    end
    local pad = 4
    glowFrame:SetParent(frame)
    glowFrame:ClearAllPoints()
    glowFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", -pad, pad)
    glowFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", pad, -pad)
    glowFrame:SetFrameLevel(frame:GetFrameLevel() + 10)
    glowFrame:Show()
    glowFrame.pulse:Play()
end

local function HideGlow()
    if glowFrame then
        glowFrame.pulse:Stop()
        glowFrame:Hide()
    end
end

local steps = {
    {
        title = "The HUD",
        desc = "This is your HUD \226\128\148 it shows how much conjured food, water, and gems you're carrying at a glance.",
        setup = function()
            local hud = MageToolsHUD
            if hud and not hud:IsShown() then hud:Show() end
            return hud
        end,
        teardown = function() end,
    },
    {
        title = "The Popup Menu",
        desc = "This is the spell popup \226\128\148 use it to quickly cast teleports, portals, and conjures. Bind a key in Options to open it.",
        setup = function()
            local popup = MageToolsPopup
            if popup and not popup:IsShown() then popup:Show() end
            return popup
        end,
        teardown = function()
            local popup = MageToolsPopup
            if popup and popup:IsShown() then popup:Hide() end
        end,
    },
    {
        title = "Options",
        desc = "Customise MageTools here \226\128\148 button sizes, HUD layout, whisper keywords, and more. Open anytime with /mgt options.",
        setup = function()
            local opts = MT.modules["Options"]
            if opts then opts:Show() end
            return MageToolsOptions
        end,
        teardown = function()
            local opts = MT.modules["Options"]
            if opts then opts:Hide() end
        end,
    },
}

local function PositionTooltip(targetFrame)
    tooltipFrame:ClearAllPoints()
    local _, targetBottom = targetFrame:GetCenter()
    if targetBottom and targetBottom < 200 then
        tooltipFrame:SetPoint("BOTTOM", targetFrame, "TOP", 0, 10)
    else
        tooltipFrame:SetPoint("TOP", targetFrame, "BOTTOM", 0, -10)
    end
end

local function ShowStep(index)
    local step = steps[index]
    if not step then return end

    -- Teardown previous step
    if currentStep > 0 and steps[currentStep] then
        steps[currentStep].teardown()
    end
    HideGlow()

    currentStep = index

    -- Setup this step and get the target frame
    local targetFrame = step.setup()
    if not targetFrame then
        if index < #steps then
            ShowStep(index + 1)
        else
            Tour:Stop()
        end
        return
    end

    ShowGlow(targetFrame)

    tooltipFrame.title:SetText("|cffFFD200" .. step.title .. "|r")
    tooltipFrame.desc:SetText(step.desc)
    tooltipFrame.counter:SetText(string.format("Step %d of %d", index, #steps))

    if index == #steps then
        tooltipFrame.nextBtn:SetText("Finish")
    else
        tooltipFrame.nextBtn:SetText("Next")
    end

    local descHeight = tooltipFrame.desc:GetStringHeight()
    tooltipFrame:SetHeight(descHeight + 80)

    PositionTooltip(targetFrame)
    tooltipFrame:Show()
end

function Tour:Start()
    if isRunning then return end
    if InCombatLockdown() then return end
    if not tooltipFrame then
        tooltipFrame = CreateTooltipFrame()

        tooltipFrame.nextBtn:SetScript("OnClick", function()
            if currentStep < #steps then
                ShowStep(currentStep + 1)
            else
                Tour:Stop()
                MageToolsDB.tourVersion = TOUR_VERSION
            end
        end)

        tooltipFrame.skipBtn:SetScript("OnClick", function()
            Tour:Stop()
            MageToolsDB.tourVersion = TOUR_VERSION
        end)

        -- ESC dismissal: stop tour but don't persist tourVersion,
        -- so the tour re-shows next login (matches "restart from step 1" design)
        tooltipFrame:SetScript("OnHide", function()
            if isRunning then
                Tour:Stop()
            end
        end)
    end

    isRunning = true
    currentStep = 0
    ShowStep(1)
end

function Tour:Stop()
    if not isRunning then return end
    -- Set false before teardown to prevent OnHide re-entry
    isRunning = false

    if currentStep > 0 and steps[currentStep] then
        steps[currentStep].teardown()
    end
    HideGlow()

    if tooltipFrame then
        tooltipFrame:Hide()
    end
    currentStep = 0
end

function Tour:OnEvent(event, ...)
    if event == "PLAYER_REGEN_DISABLED" then
        if isRunning then
            Tour:Stop()
            print("|cff69ccf0MageTools|r Tour cancelled (entering combat). Type |cffFFD200/mgt tour|r to restart.")
        end
    end
end

MT:RegisterEvents("PLAYER_REGEN_DISABLED")

function Tour:Init()
    if not MageToolsDB.tourVersion or MageToolsDB.tourVersion < TOUR_VERSION then
        C_Timer.After(2, function()
            Tour:Start()
        end)
    end
end
