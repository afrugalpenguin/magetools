# Onboarding Tour Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add a guided onboarding tour that highlights key MageTools UI elements for new users and after major updates.

**Architecture:** New `Tour.lua` module using WoW's built-in `ActionButton_ShowOverlayGlow` for highlighting and a custom tooltip frame for descriptions. Tour state persisted via `MageToolsDB.tourVersion`. Three steps: HUD, Popup Menu, Options Panel.

**Tech Stack:** WoW Lua, SecureActionButtonTemplate glow APIs, BackdropTemplate frames.

---

### Task 1: Register Tour.lua in the .toc file

**Files:**
- Modify: `MageTools.toc`

**Step 1: Add Tour.lua to the .toc load order**

Add `Tour.lua` after `Options.lua` and before `PopupMenu.lua`. Tour needs Options and ConjureManager modules to exist, but since module Init() is deferred until ADDON_LOADED, load order between modules doesn't strictly matter — just keep it logically grouped.

In `MageTools.toc`, change:

```
Options.lua
Data.lua
```

to:

```
Options.lua
Tour.lua
Data.lua
```

**Step 2: Commit**

```bash
git add MageTools.toc
git commit -m "chore: add Tour.lua to toc load order"
```

---

### Task 2: Create the Tour tooltip frame

**Files:**
- Create: `Tour.lua`

**Step 1: Create Tour.lua with module registration and tooltip frame builder**

```lua
local MT = MageTools
local Tour = {}
MT:RegisterModule("Tour", Tour)

local TOUR_VERSION = 1

-- Style constants (matches Options.lua / WhatsNew.lua)
local BG_COLOR = { 0.08, 0.08, 0.12, 0.98 }
local BORDER_COLOR = { 0.4, 0.6, 0.9, 1 }
local ACCENT_COLOR = { 0.4, 0.6, 0.9 }

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
    skipBtn:SetSize(60, 22)
    skipBtn:SetPoint("BOTTOMRIGHT", -12, 8)
    skipBtn:SetText("Skip")
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
```

**Step 2: Commit**

```bash
git add Tour.lua
git commit -m "feat(tour): create tooltip frame scaffold"
```

---

### Task 3: Define tour steps and glow logic

**Files:**
- Modify: `Tour.lua`

**Step 1: Add the step definitions and glow helper functions**

Append after `CreateTooltipFrame`:

```lua
local glowingFrame = nil

local function ShowGlow(frame)
    if glowingFrame then
        ActionButton_HideOverlayGlow(glowingFrame)
    end
    glowingFrame = frame
    if frame then
        ActionButton_ShowOverlayGlow(frame)
    end
end

local function HideGlow()
    if glowingFrame then
        ActionButton_HideOverlayGlow(glowingFrame)
        glowingFrame = nil
    end
end

local steps = {
    {
        title = "The HUD",
        desc = "This is your HUD — it shows how much conjured food, water, and gems you're carrying at a glance.",
        setup = function()
            local hud = MageToolsHUD
            if hud and not hud:IsShown() then hud:Show() end
            return hud
        end,
        teardown = function() end,
    },
    {
        title = "The Popup Menu",
        desc = "This is the spell popup — use it to quickly cast teleports, portals, and conjures. Bind a key in Options to open it.",
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
        desc = "Customise MageTools here — button sizes, HUD layout, whisper keywords, and more. Open anytime with /mgt options.",
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
```

**Step 2: Commit**

```bash
git add Tour.lua
git commit -m "feat(tour): add step definitions and glow helpers"
```

---

### Task 4: Implement tour start, advance, and stop logic

**Files:**
- Modify: `Tour.lua`

**Step 1: Add the core tour control functions**

Append after the `steps` table:

```lua
local function PositionTooltip(targetFrame)
    tooltipFrame:ClearAllPoints()
    -- Position below the target frame, or above if near screen bottom
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
        -- Frame doesn't exist yet, skip this step
        if index < #steps then
            ShowStep(index + 1)
        else
            Tour:Stop()
        end
        return
    end

    -- Apply glow
    ShowGlow(targetFrame)

    -- Update tooltip content
    tooltipFrame.title:SetText("|cffFFD200" .. step.title .. "|r")
    tooltipFrame.desc:SetText(step.desc)
    tooltipFrame.counter:SetText(string.format("Step %d of %d", index, #steps))

    -- Update button text
    if index == #steps then
        tooltipFrame.nextBtn:SetText("Finish")
    else
        tooltipFrame.nextBtn:SetText("Next")
    end

    -- Resize tooltip to fit description text
    local descHeight = tooltipFrame.desc:GetStringHeight()
    tooltipFrame:SetHeight(descHeight + 80)

    -- Position and show
    PositionTooltip(targetFrame)
    tooltipFrame:Show()
end

function Tour:Start()
    if isRunning then return end
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
    isRunning = false

    -- Teardown current step
    if currentStep > 0 and steps[currentStep] then
        steps[currentStep].teardown()
    end
    HideGlow()

    if tooltipFrame then
        tooltipFrame:Hide()
    end
    currentStep = 0
end
```

**Step 2: Commit**

```bash
git add Tour.lua
git commit -m "feat(tour): implement start, advance, and stop logic"
```

---

### Task 5: Add combat cancellation

**Files:**
- Modify: `Tour.lua`

**Step 1: Add OnEvent handler and register PLAYER_REGEN_DISABLED**

Append after `Tour:Stop`:

```lua
function Tour:OnEvent(event, ...)
    if event == "PLAYER_REGEN_DISABLED" then
        if isRunning then
            Tour:Stop()
            print("|cff69ccf0MageTools|r Tour cancelled (entering combat). Type |cffFFD200/mgt tour|r to restart.")
        end
    end
end

MT:RegisterEvents("PLAYER_REGEN_DISABLED")
```

**Step 2: Commit**

```bash
git add Tour.lua
git commit -m "feat(tour): cancel tour on combat"
```

---

### Task 6: Add auto-start on login and slash command

**Files:**
- Modify: `Tour.lua`
- Modify: `Core.lua`

**Step 1: Add Init function to Tour.lua for auto-start**

Append after the `OnEvent` function in `Tour.lua`:

```lua
function Tour:Init()
    if not MageToolsDB.tourVersion or MageToolsDB.tourVersion < TOUR_VERSION then
        -- Delay slightly so all frames are created
        C_Timer.After(2, function()
            Tour:Start()
        end)
    end
end
```

**Step 2: Add `/mgt tour` slash command to Core.lua**

In `Core.lua`, in the `SlashCmdList["MAGETOOLS"]` function, add a new `elseif` branch before the `else` block:

```lua
    elseif cmd == "tour" then
        local tour = MageTools.modules["Tour"]
        if tour then tour:Start() end
```

Also add the tour command to the help text:

```lua
            print("  /mgt tour - Start onboarding tour")
```

**Step 3: Commit**

```bash
git add Tour.lua Core.lua
git commit -m "feat(tour): auto-start on first install and add slash command"
```

---

### Task 7: Run luacheck and verify

**Step 1: Run luacheck**

```bash
luacheck .
```

Expected: 0 warnings / 0 errors in 9 files

**Step 2: Fix any luacheck issues if they arise**

Common issues to watch for:
- `ActionButton_ShowOverlayGlow` and `ActionButton_HideOverlayGlow` may need adding to `.luacheckrc` globals
- `C_Timer` may need adding to `.luacheckrc` globals
- `UISpecialFrames` may need adding to `.luacheckrc` globals

**Step 3: Commit any luacheck fixes**

```bash
git add .luacheckrc
git commit -m "chore: add tour globals to luacheck config"
```

---

### Task 8: Final review and integration test checklist

**Manual in-game test plan:**

1. Delete `MageToolsDB` saved variable (or set `tourVersion = nil`) and `/reload` — tour should auto-start after 2 seconds
2. Step 1: HUD should glow, tooltip describes the HUD, "Next" button visible
3. Step 2: Popup menu appears and glows, tooltip describes it, "Next" button visible
4. Step 3: Options panel opens and glows, "Finish" button visible
5. Click "Finish" — options panel closes, glow removed, `MageToolsDB.tourVersion` is set
6. `/reload` — tour should NOT auto-start (tourVersion matches)
7. `/mgt tour` — tour restarts manually
8. Enter combat during tour — tour cancels with chat message
9. Press Escape during tour — tour dismisses
