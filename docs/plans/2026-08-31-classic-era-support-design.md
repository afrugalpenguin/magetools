# Classic Era Support - Design

Date: 2026-08-31
Status: Validated, not yet implemented

## Goal

Ship one MageTools build that works on both TBC Anniversary Classic
(interface 20505) and Classic Era (interface 11507), from a single
CurseForge project and a single release tag.

## Findings

The addon is already largely flavor-agnostic:

- Every cast sets `SetAttribute("spell", spellName)`, a name and never an
  ID. Casting by name selects the highest known rank automatically, so no
  rank table is needed.
- Teleports and portals filter on `IsSpellKnown(spellID)`.
- Buffs and conjure spells resolve via a spellbook scan.

Consequently no TBC spell can reach a button on an Era client. The gaps are
elsewhere.

## Gaps

1. `MageTools.toc` declares only interface 20505, so Era will not load it.
2. `ConjureManager.lua:304,322` derive the conjure spell name from
   `GetSpellInfo(<TBC-only ID>)`. On Era that returns nil, the attribute is
   set to nil, and the Food/Water buttons silently do nothing.
3. `ConjureManager.lua:127` takes each HUD row's icon from `items[1]`, which
   is the TBC top rank in every case. On Era `GetItemIcon` returns nil and
   the gem, food and water rows render with no icon.
4. The Mana Biscuit row is meaningless on Era (Ritual of Refreshment is
   TBC-only).

## Decisions

**Packaging.** Keep `MageTools.toc` unchanged. It is the proven base and
already maps to the CurseForge 2.5.5 bucket. Add `MageTools_Vanilla.toc`,
identical but with `## Interface: 11507`. The BigWigs packager recognises
the `_Vanilla` suffix; `.pkgmeta` and `release.yml` need no changes.

**Flavor detection.** In `Core.lua`:

    local tocVersion = select(4, GetBuildInfo())
    MageTools.tocVersion = tocVersion
    MageTools.IsEra = tocVersion < 20000

Chosen over `WOW_PROJECT_ID` because TBC Anniversary is not BCC and its
project ID is not something we should assume. The build number is directly
observable.

**Spell name resolution.** Anchor on rank-1 spell IDs, which predate TBC and
exist in both clients' data: Conjure Food 587, Conjure Water 5504, Conjure
Mana Agate 759. Replace the `MT.CONJURE_*_SPELL` constants in `Data.lua`.
`GetSpellInfo(587)` returns the client's localized name on either flavor.

Rejected: scanning the spellbook for the literal string "Conjure Food". It
works, but matches an English name and so breaks on localized clients. The
popup's buff and conjure categories already have this latent bug. Out of
scope here.

**Icons.** Do not prune the item tables. Walk down each list to the first
entry whose `GetItemIcon` resolves. The lists are already ordered
highest-first and are supersets of the vanilla set, so each flavor picks its
own correct icon with no version branching.

**Biscuit row.** Skip when `MT.IsEra`. This is the only explicit flavor
branch in the UI.

## Content audit

TBC-only, confirmed: teleport and portal spells 32271, 32272, 32266, 32267,
33690, 33691, 35715, 35717; Theramore and Stonard 49358 to 49361
(post-vanilla regardless of exact patch); items 22044, 22019, 30703, 22018,
34062.

Everything else in `Data.lua`, including both runes (17031, 17032), is
vanilla-native.

Unverified: 22895 Conjured Cinnamon Roll (food R7) and the vanilla rank cap
on 8079 Conjured Crystal Water (water R7). The icon walk above makes both
irrelevant to correctness.

## Files touched

- `MageTools_Vanilla.toc` (new)
- `Core.lua`, flavor detection
- `Data.lua`, rank-1 conjure anchors
- `ConjureManager.lua`, icon walk and biscuit row gate

## Verification

Static: luacheck clean; both TOCs list identical file sets; no remaining
reference to 33717, 27090 or 27101.

Era client, in-game: HUD gem, food and water rows resolve icons (expect
Ruby, Sweet Roll, Crystal Water); biscuit row absent; Conjure Session Food
and Water buttons cast; popup shows three faction teleports and no
Shattrath; no Molten Armor or Ritual of Refreshment.

TBC client, regression: all teleports including Shattrath present; biscuit
row present; icons unchanged; conjure buttons cast.

Load-bearing assumption: 587, 5504 and 759 are the correct rank-1 anchors.
If a Conjure button is dead on both clients after this change, that is the
cause. It can only be caught in-game.
