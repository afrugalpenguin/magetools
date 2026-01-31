# MageTools Design

WoW TBC Anniversary mage utility addon. Covers portals/teleports, conjured item management, and trade distribution. Combat features (cooldowns, timers, procs, polymorph) are handled by a separate addon.

## Architecture

Single addon with three modules sharing a common event backbone.

- **PopupMenu** — Keybind-triggered icon grid at cursor for portals and teleports.
- **ConjureManager** — HUD for conjured item counts plus a bulk conjure session panel.
- **TradeHelper** — Whisper-triggered queue system for distributing food and water.

Shared infrastructure:
- Event handler on a hidden frame (standard WoW addon pattern).
- SavedVariables (per-character) for user config.
- Slash command `/mt` or `/magetools` for configuration.
- No external library dependencies except optional Masque support.

## Module 1: PopupMenu

Keybind registered via WoW's binding system (shows in Key Bindings > MageTools). On press, a frame appears centered on the cursor.

### Layout

Grid of square icon buttons in two sections separated by a divider:
- Top row(s): Teleport spells.
- Bottom row(s): Portal spells.

Only shows spells the mage actually knows (checked via `IsSpellKnown()`). Grid reflows based on known spell count.

### Buttons

Each button is a `SecureActionButtonTemplate` frame with icon texture, registered with Masque as the `MageTools_Popup` group. Tooltip on hover shows spell name and destination.

### Conjured Item Status

Small counters along one edge of the popup — icons for mana gem, food, and water with stack counts overlaid. Also Masque-skinned.

### Dismiss

Clicking outside the frame, pressing Escape, or pressing the keybind again closes it.

## Module 2: ConjureManager

### HUD Element

Small, movable frame showing at a glance:
- Mana gem icon + charge count.
- Food icon + total stack count across bags.
- Water icon + total stack count across bags.

Icons are Masque-skinned (registered as `MageTools_HUD` group). Counts overlay as text. Frame position saved in SavedVariables. Visibility is togglable via `/mt hud` or a toggle on the popup menu — state persists across sessions. Bag scanning runs in the background regardless of visibility.

### Bag Scanning

Hooks `BAG_UPDATE` event to recount conjured items. Identifies items by item ID (locale-safe).

### Conjure Session Panel

Opened via `/mt conjure` or a button on the HUD.

Shows:
- Current raid/party size (with manual override for pre-conjuring).
- Stacks of food/water needed (configurable ratio, default: 1 water + 1 food per person).
- Current stock vs amount still needed.
- A single prominent SecureActionButton — each click casts the appropriate conjure spell.
- Progress indicator (e.g. "14/25 water stacks ready").
- "Stocked up" state when target is reached.

### Mana Gem

Tracked separately from bulk conjure. Shows current gem status and a reminder if missing.

## Module 3: TradeHelper

### Whisper Listener

Monitors `CHAT_MSG_WHISPER` for configurable keywords (default: "water", "food", "mage"). Keywords are customizable in SavedVariables.

### Queue System

- Matching whisper adds the player to a queue with what they requested (food, water, or both).
- Auto-reply: "You're queued for [water]. [3] ahead of you."
- Duplicate whispers from the same player update rather than re-queue.
- Queue displayed in a small frame (shown when non-empty, hideable).

### Distribution Workflow

- Queue frame shows a list of names and what they need.
- Click a name to target the player (if in range) and open trade.
- On trade window open, automatically place the right conjured items in the trade window.
- On trade complete, mark as served and auto-reply: "Enjoy!"
- Advance to next in queue.

### Edge Cases

- Player not in range: skip with indicator, move to next.
- Out of stock mid-distribution: trigger conjure session prompt.
- Player goes offline: remove from queue silently.

## Configuration

### Slash Commands

- `/mt hud` — toggle HUD visibility.
- `/mt conjure` — open conjure session panel.
- `/mt queue` — toggle trade queue frame.
- `/mt config` — print current settings to chat (v1).

### SavedVariables (per-character)

- HUD position (x, y) and visibility state.
- Popup menu keybind (also in WoW's binding UI).
- Whisper keywords list.
- Stacks-per-person ratio for conjure calculator.
- Auto-reply enabled/disabled.

Masque skin selection is handled by Masque itself.

## File Structure

```
MageTools/
  MageTools.toc
  Core.lua            -- event backbone, slash commands, saved vars
  PopupMenu.lua       -- keybind popup grid
  ConjureManager.lua  -- HUD, bag scanning, conjure session
  TradeHelper.lua     -- whisper queue, distribution
  Bindings.xml        -- keybind registration
```

Masque listed as optional dependency in TOC (`## OptionalDeps: Masque`). Buttons work with default WoW styling if Masque is absent. If present, groups are registered on load.
