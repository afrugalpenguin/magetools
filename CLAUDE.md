# MageTools

A mage utility addon for WoW TBC Anniversary Classic.

## WoW Addon Development

- This is a TBC Anniversary Classic addon project. TBC Anniversary is NOT the same as BCC (Burning Crusade Classic). Do not assume they share the same APIs, TOC interfaces, or CurseForge flavor support.
- Use CraftFrame APIs (not TradeSkillFrame) for TBC Anniversary profession windows.
- Bindings.xml is NOT supported in TBC Classic Anniversary. Do not attempt XML keybinding approaches.
- For keybinds, use SetOverrideBindingClick instead of Bindings.xml or XML-based binding attributes.
- IsSpellKnown() may not work for all spells in TBC; verify with GetSpellInfo or test in-game before assuming.

### Lua / WoW API Guidelines

- GetSpellInfo does NOT return spell rank in TBC. Use GetSpellSubtext() for rank information.
- Always check if a spell ID is the talent ID, the buff ID, or the castable spell ID — they are often different.
- When implementing UI elements (sliders, checkboxes, frames), always verify callback functions actually fire and that dimension changes propagate to child elements.

## Release Process

- Version bumps require updating: Core.lua version, CHANGELOG.md, and WhatsNew.lua.
- The .toc file uses `@project-version@` placeholder — do NOT hardcode the version there.
- Always run luacheck before committing.
- Release flow: bump version → update changelog → commit → tag → push → push tags.
- Do NOT create git tags before the commit is pushed.
- CurseForge uses a webhook triggered by GitHub releases; no API token upload needed unless explicitly stated.
- Use `/release` skill to automate this process.

## Debugging Rules

- When the user reports a visual bug, ask clarifying questions about EXACTLY what they see before assuming the cause. Do not guess 'border bleed-through' when the user says 'tooltip misalignment.'
- When fixing spell IDs, always check for talent vs buff vs base spell ID distinctions. Multiple ranks may exist; verify the player can actually cast the spell at that rank.
- When a fix causes a regression (e.g., slider displays go blank), revert immediately rather than iterating forward on a broken state.
- Use `/bugfix` skill for structured bug fixing.

## General Behavior

### Session Continuations
- When resuming a session, do NOT re-explore the entire codebase. Assume prior context is valid unless the user says otherwise.
- Ask what changed since last session rather than reading every file again.
