# Changelog

## v2.2.1
- Popup menu now works in combat (armor buffs, etc.)
- Add Theramore (Alliance) and Stonard (Horde) teleport and portal spells

## v2.2.0
- Smart gem conjure: auto-deletes existing mana gem before conjuring a new one (both click and release-to-cast modes)
- Popup category toggles: hide/show Buffs, Food/Water, Gems, Teleports, or Portals in Options
- Fix popup button icons appearing black (texture layer order)
- Fix release-to-cast mode casting when cursor is off all buttons

## v2.1.0
- Add party chat detection for food/water requests (opt-in toggle in Trade Helper settings)

## v2.0.5
- Fix HUD showing wrong mana gem/food/water icon — now matches what's actually in your bags

## v2.0.4
- Fix finnicky frame dragging by propagating drag events from child buttons to parent frames

## v2.0.3
- Fix addon loading and showing HUD on non-Mage characters

## v2.0.2
- Fix Shattrath teleport/portal not showing for both factions (use correct faction-specific spell IDs)

## v2.0.1
- Fix Tour.lua missing from release package

## v2.0.0
- Add onboarding tour with welcome splash and guided highlights
- Tour auto-starts on first install and after major updates
- Tour steps: HUD, Conjure Session, Popup Menu, Options
- Cancel tour on combat entry
- Start tour anytime with /mgt tour

## v1.14.6
- Improve bag count update responsiveness in conjure window

## v1.14.5
- Add luacheck linting configuration
- Update addon icon

## v1.14.4
- Remove Bindings.xml (unsupported in TBC Classic Anniversary)

## v1.14.3
- Add changelog and include in release zip

## v1.14.2
- Add GitHub releases workflow and packaging

## v1.14.1
- Update README tagline and keyword defaults

## v1.14.0
- Update gitignore with standard patterns

## v1.13.1
- Support custom whisper keywords in queue matching

## v1.13.0
- Drive conjure session serving count from trade queue

## v1.12.0
- Auto-target player on queue row click via secure macro
- Right-click to remove from queue

## v1.11.0
- Tabbed options layout replacing sidebar
- Fix checkbox persistence (coerce nil to false)
- Add conjure session shortcut button in trade queue

## v1.10.1
- Add spacing between HUD controls in options

## v1.10.0
- Update conjure session on group roster changes

## v1.9.1
- Add quadrant labels (Buffs, Conjure, Teleports, Portals)
- Add button borders when Masque is not active
- Single-row layout for all spell categories

## v1.9.0
- Release-to-cast mode using secure handler WrapScript
- Hold keybind to open, hover spell, release to cast

## v1.8.0
- X layout with four quadrants around cursor center
- Mouse button keybind support

## v1.7.1
- Rewrite keybind system using SetOverrideBindingClick

## v1.7.0
- Add Bindings.xml to TOC and keybind button to options

## v1.6.0
- Add vertical/horizontal orientation toggle for HUD

## v1.5.1
- Increase README logo width to 400px

## v1.5.0
- Add Ice/Frost Armor and Molten Armor to buff row

## v1.4.0
- Add buff spells row to popup menu
- Add README logo

## v1.3.0
- Add options panel with configurable settings
- Conjure session fixes

## v1.2.1
- Update APIs for TBC Classic Anniversary client

## v1.2.0
- Address code review issues for TBC compatibility

## v1.1.0
- Add whisper queue and trade distribution system

## v1.0.3
- Add bag scanning, HUD, and conjure session panel

## v1.0.2
- Add keybind-triggered portal/teleport icon grid

## v1.0.1
- Add mage spell and conjured item ID tables
- Add Masque integration helper

## v1.0.0
- Initial release: TOC, event backbone, and saved variables
