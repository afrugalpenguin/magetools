# MageTools

A mage utility addon for WoW TBC Anniversary. Handles portals, teleports, conjured item tracking, and trade distribution so you can focus on the important things — like not dying.

## Features

### Portal/Teleport Popup
Bind a key in **Key Bindings > MageTools** to open a compact icon grid at your cursor. Shows only spells you know, filtered by faction. Click to cast, popup closes automatically.

### Conjured Item HUD
A small draggable frame showing your current mana gem charges, food stacks, and water stacks at a glance. Counts update automatically as you conjure or trade away items. Toggle with `/mt hud`.

### Conjure Session
Open with `/mt conjure` or from the HUD. Shows how many stacks of food and water you need based on your current group/raid size, tracks progress as you conjure, and tells you when you're stocked up. Food and water buttons cast the appropriate conjure spell on each click.

### Trade Helper
When someone whispers you a keyword (default: "water", "food", or "mage"), they're automatically added to a queue with an auto-reply confirming their position. Click a name in the queue frame, target the player, and open trade — items are placed in the trade window automatically. Completed trades send an "Enjoy!" reply and advance the queue.

## Installation

Copy the `MageTools` folder into your TBC Anniversary addons directory:

```
World of Warcraft/_classic_/Interface/AddOns/MageTools/
```

## Commands

| Command | Description |
|---------|-------------|
| `/mt` | Show help |
| `/mt hud` | Toggle the item count HUD |
| `/mt conjure` | Toggle the conjure session panel |
| `/mt queue` | Toggle the trade queue frame |
| `/mt config` | Print current settings |

## Configuration

Settings are stored per-character in `MageToolsDB`. Defaults:

- **Whisper keywords:** water, food, mage
- **Stacks per person:** 1 (food + water per group member)
- **Auto-reply:** enabled
- **HUD:** visible, center of screen

## Masque Support

MageTools supports [Masque](https://www.curseforge.com/wow/addons/masque) for button skinning. Install Masque separately — MageTools buttons will use your selected skin automatically. Works fine without Masque installed.

## Keybinding

Set your popup keybind in **Escape > Key Bindings > MageTools > Toggle Portal Menu**.
