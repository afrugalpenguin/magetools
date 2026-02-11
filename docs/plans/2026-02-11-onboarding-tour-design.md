# Onboarding Tour Design

## Overview

A guided tour that highlights key MageTools features for new users and after major updates. Uses a glowing border and tooltip to draw attention to UI elements one at a time without blocking gameplay.

## Trigger Conditions

- **First install**: `MageToolsDB.tourVersion` is nil — tour auto-starts on login.
- **Major update**: `MageToolsDB.tourVersion` is less than the current tour version — tour auto-starts on login.
- **Manual**: `/mgt tour` starts the tour at any time.

The tour version is an integer stored in `Tour.lua` and bumped when a significant feature is added.

## Architecture

New `Tour.lua` module registered via `MT:RegisterModule`.

### Components

- **Glow effect**: `ActionButton_ShowOverlayGlow` / `ActionButton_HideOverlayGlow` — the built-in WoW proc glow. Familiar to players, no extra libraries needed, available in TBC Classic Anniversary.
- **Tooltip frame**: A backdrop frame positioned near the glowing element containing:
  - Title text (bold)
  - Description text
  - "Next" button (becomes "Finish" on the last step)
  - "Skip Tour" button
  - Step counter (e.g. "1 of 3")

### State

- `MageToolsDB.tourVersion` — last completed tour version (nil = never seen)
- Current tour version constant in `Tour.lua`
- No mid-tour resume — if interrupted, restarts from step 1

## Tour Steps

### Step 1 — The HUD

- Target: The food/water/gem count HUD
- Glow the HUD frame
- Tooltip: "This is your HUD — it shows how much conjured food, water, and gems you're carrying at a glance."

### Step 2 — The Popup Menu

- Programmatically show the popup menu for this step
- Glow the popup menu frame
- Tooltip: "This is the spell popup — use it to quickly cast teleports, portals, and conjures. Bind a key in Options to open it."
- Dismiss the popup menu on "Next"

### Step 3 — The Options Panel

- Programmatically open the options panel
- Glow the options frame
- Tooltip: "Customise MageTools here — button sizes, HUD layout, whisper keywords, and more. Open anytime with /mgt options."
- Dismiss the options panel on "Finish"
- Set `MageToolsDB.tourVersion` to current tour version

## Edge Cases

- **Combat**: Tour cancels on `PLAYER_REGEN_DISABLED`. Player can restart with `/mgt tour`.
- **Interruption** (logout, Escape): Tour does not save progress. Restarts from step 1 next time.
- **Escape key**: Pressing Escape dismisses the tour (standard WoW frame behaviour via `UISpecialFrames`).

## Slash Command

- `/mgt tour` — starts the tour regardless of `tourVersion` state.

## Files Changed

- New: `Tour.lua`
- Modified: `Core.lua` (register Tour.lua load, add `/mgt tour` subcommand)
- Modified: `MageTools.toc` (add Tour.lua)
- Modified: `Core.lua` defaults (add `tourVersion` default as nil)
