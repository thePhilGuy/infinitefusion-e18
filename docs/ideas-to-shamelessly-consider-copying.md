# Ideas to shamelessly consider copying

A field notebook for our Infinite Fusion extensions. Borrow the good ideas,
credit their sources, and keep upstream integration boring. The Pokémon can have
three heads; our maintenance strategy should ideally have one.

Research snapshot: **2026-09-04**. Target: **6.7.2**, with local extensions in
[`998_zzz_extensions`](../Data/Scripts/998_zzz_extensions).

## What I actually looked at

GitHub's [fork listing](https://github.com/infinitefusion/infinitefusion-e18/forks)
showed more than 17 entries; the [public API](https://api.github.com/repos/infinitefusion/infinitefusion-e18/forks?per_page=100)
returned 79 direct forks. This pass covers **17 selected visible active forks**,
including their branch lists and recent commit histories, plus Kuray and separate
community mods. It is a practical survey, not an exhaustive audit of every fork
or branch. Dates and activity are discovery hints, not quality scores.

Evidence labels used below:

- **Code:** inspected the implementation or commit diff.
- **Docs:** the project's own documentation describes the feature.
- **History:** branch/commit evidence; behavior has not been validated.
- **Proposal:** our adaptation, including hook and effort estimates. These are
  design judgments, not promises that foreign code will run unchanged here.

No foreign game or mod was executed during this survey. Links to commits identify
specific changes; branch-based links are moving references.

## The shortlist

| Priority | Idea | Why it earns a slot | Extension fit |
| --- | --- | --- | --- |
| First | Fusion correctness fixes | Protect EXP, moves, abilities, and shiny state during the thing this game is named after | Small moveset hook; EXP medium; full unfusing harder |
| First | PC search | Find the creature you remember by type or name instead of conducting a box census | Medium; read-only query UI |
| First | Teleporter keeps the bike | Removes a tiny irritation that somehow occurs every eight seconds | Small, with a scoped vehicle hook |
| Next | EVs alongside our IV display | Our stats page is already instrumented | Small UI extension |
| Next | Route encounter journal | Useful for collectors and optional challenge runs | Medium; saved event state |
| Next | Party ↔ box-row team swap | Switch between complete teams without six separate administrative proceedings | Medium; transactional storage operation |
| Next | Explicit evolution lock | Keep the design you like without repeated cancellation | Small/medium; saved Pokémon flag |
| Later | Battle your own collection | A repeatable training room and a playground for ridiculous fusions | Medium/high; isolated battle setup |
| Later | Shiny palette preview | Preview cosmetic results before committing | Medium/high; respect current shiny implementation |
| Dessert | Optional roaming champion | Cynthia as a configurable encounter, not an operating-system interrupt | Medium/high; encounter and trainer-data integration |

## 1. Fix the fusion bookkeeping before buying it a hat

**Code — DoubleUTH.** The `bugfix` branch descends directly from our upstream
`5b85e72c` baseline. Its five subsequent commits are unusually relevant:
[branch history](https://github.com/DoubleUTH/infinitefusion-e18/commits/bugfix).

Two particularly clean leads:

- [Stable fusion moveset merging](https://github.com/DoubleUTH/infinitefusion-e18/commit/824e3372283ef3d37d483c32fd226eefe25f37e0)
  replaces plain concatenation with a level-ordered merge. The commit addresses
  generated trainer fusions receiving moves from only the head. Our
  [`FusedSpecies#calculate_moveset`](../Data/Scripts/052_InfiniteFusion/Fusion/FusedSpecies.rb)
  still uses `combine_arrays`.
- [Count gained EXP once](https://github.com/DoubleUTH/infinitefusion-e18/commit/bdc8a00e81f1010d0e107ba934577240d5c3b0cc)
  moves fusion EXP accounting outside the per-level animation loop. Our
  [`pbGainExpOne`](<../Data/Scripts/011_Battle/003_Battle/004_Battle_ExpAndMoveLearning.rb>)
  still increments `exp_gained_since_fused` inside that loop. One large award can
  therefore inflate the recorded fusion gain repeatedly.

**Proposal:** start with a prepended `calculate_moveset` implementation that merges
only the returned move data. For EXP, investigate a per-award wrapper and counter
correction rather than duplicating `pbGainExpOne`; caps and multi-level awards
need explicit handling. Test one-level, multi-level, capped, and zero-EXP cases.

The broader [unfusing correction](https://github.com/DoubleUTH/infinitefusion-e18/commit/d1bbd4f4002e7f7e9a2b3f69cfb41212aea3ffb8)
repairs which output Pokémon receives shiny/ability/move data and restructures
party/PC handling. **This is a harder extraction:** it changes local intermediate
objects inside a large method. Treat its diff as a behavioral specification and
regression checklist. Our trade-unfusing wrapper only changes `foreign?`; it does
not address these bookkeeping problems. Exercise body/head shiny combinations,
full party, PC unfusing, and learned moves before adopting any fix.

## 2. A PC search box: Bill discovers databases

**Code — Sthakur27's sidmod.**
[`PCSearch.rb`](https://github.com/Sthakur27/infinitefusion-plus/blob/sidmod/Data/Scripts/052_InfiniteFusion/Menus/PC/PCSearch.rb)
implements type, level-range, partial-name, and dex-range filters. It returns a
box/slot selection, and its type matching handles either type position.

**Proposal:** expose “Find Pokémon” through our existing `StartMenuExtensions`
registry first. Query storage without rearranging it, then open the selected
box/slot. Add ability, nature, IV-total, and head/body-species filters after that
works. Those last filters are our wishlist, not a claim about the inspected file.

Use [`PokemonStorageScreen`](../Data/Scripts/016_UI/PokemonStorage/PokemonStorageScreen.rb)
and the scene's selection methods as integration points. Define how eggs and
fusions are searched. A useful first acceptance check is finding the same Pokémon
by either constituent species without accidentally treating its nickname as its
species name. Search should be pleasantly incapable of losing a Pokémon.

## 3. Teleport without confiscating my bicycle

**Code — PJ's QoL work.** The
[teleporter fix](https://github.com/pjbatista/infinitefusion-e18/commit/1f7e2186911be4b3c58f65b648c69b8567924eac)
passes the destination map to `pbCancelVehicles`, allowing the vehicle logic to
make the right decision. Our
[`useTeleporter`](<../Data/Scripts/052_InfiniteFusion/Gameplay/Items/New Items effects.rb>)
still calls it without that argument.

**Proposal:** wrap the teleporter operation and supply the destination only to
its vehicle-cancellation call. Check the actual `Kernel`/instance dispatch before
choosing the prepend target. Restore temporary context in `ensure`. Validate an
outdoor destination, a bike-forbidden destination, and cancellation.

PJ also has a
[Secret Capsule implementation](https://github.com/pjbatista/infinitefusion-e18/commit/93c720d9a6bc4145624ad0e8d661a4f2261b446c).
Our file registers `SECRETCAPSULE` twice, with the later block still marked
incomplete. A focused replacement handler using the current ability API could
be worthwhile. Check ordinary and fused ability lists, cancellation, and item
consumption; the follow-up commit fixes helper names, so this older diff is an
idea source rather than a ready-made transplant.

## 4. Kuray's buffet, with a smaller plate

**Docs — [Kuray Infinite Fusion](https://github.com/kurayamiblackheart/kurayshinyrevamp#list-of-constant-features).**
Its documented features include IV/EV display, pre-evolution move relearning,
evolution locking, PC sorting, self-battles, shiny palette variations and previews,
configurable level caps, and mod loading. Kuray is a standalone fork, so assess
features individually against 6.7.2.

**Proposal:** extend our existing text-command decorator with EV display; add a
per-Pokémon evolution lock through evolution checks; prototype palette preview
against this checkout's `ImprovedShinies` classes. Keep cosmetic preview separate
from changing saved shiny state. A fluorescent Gengar should be a considered
artistic mistake.

Already covered here: fusion breeding and IV visibility through our extensions;
level caps and storage multiselect exist upstream. The interesting work is in
refinements, not implementing those features twice. Pre-evolution relearning and
PC sorting deserve a current-code check before scheduling.

## 5. An encounter journal, optionally with consequences

**Code — [Celeaxy's encounter implementation](https://github.com/Celeaxy/PIF_NuzlockeMode/blob/main/Scripts/500_NuzlockeMode/Encounters.rb).**
It records map/encounter-type pairs and persists state with `SaveData.register`.
The [project documentation](https://github.com/Celeaxy/PIF_NuzlockeMode#ruleset)
describes a pause-menu encounter view, duplicate-species handling, permanent
fainting, and party-menu leveling; compatibility was tested on 6.2.4 and 6.4.3.

**Proposal:** borrow the journal concept independently of the full ruleset. Show
where encounters were seen or caught, then optionally enforce a configurable
allowance. Use catch/battle events, `SaveData.register`, and our pause-menu
registry. Define gifts, eggs, fishing, caves spanning maps, statics, and shiny
exceptions explicitly. “Route” is a gameplay concept; a map ID is a file number
wearing a little hat.

Two more recent branches are useful specifications:
[Ymirbot's configurable encounter allowance](https://github.com/Ymirbot/infinitefusion/commit/fcaa660de2a7a81861305095500c93a1efbcf3e4)
and [MrChuck123's trainer-flee option](https://github.com/MrChuck123/infinitefusion-e18/commit/6f8b06414b87815a2981e09e5f6aa1ef1c849e1a).
The former changes a `Plugins/Nuzlocke` implementation; the latter spans world
rules, settings, and tests. Their behavior is more portable than their file layout.

Celeaxy's [party-leveling implementation](https://github.com/Celeaxy/PIF_NuzlockeMode/blob/main/Scripts/500_NuzlockeMode/UI/LevelUp.rb)
is also worth studying for a “train to cap” action, but it copies a large party
menu method. Our version should inject a command, then let existing level-up
routines process moves and evolutions.

## 6. Swap teams; stop doing inventory yoga

**Docs — [sidmod's PC and storage features](https://github.com/Sthakur27/infinitefusion-plus/tree/sidmod#pc--storage).**
It describes exchanging the party with a six-slot box row, with checks for an
able Pokémon, mail, and uneven team sizes. Its multiselect changes also address
occupied destinations and preserving the selected shape. This fork targets 6.8.2.

**Proposal:** implement one validated party/row exchange command. Capture both
sides, validate the complete result, then apply it together. Preserve exact
Pokémon objects and ordering. Test three-versus-six teams, eggs, fainted teams,
mail, and cancellation. Add confirmation showing the two teams before exchange.

Our [multiselect implementation](../Data/Scripts/052_InfiniteFusion/Menus/PC/Multiselect/MultiSelect_PokemonStorageScreen.rb)
already exists; “add multiselect” is not a useful task. Review specific behavior
against the newer fork instead.

## 7. A practice arena for our own terrible inventions

**Docs/history — [sidmod](https://github.com/Sthakur27/infinitefusion-plus/tree/sidmod).**
Its Random Battle modes draw from the player's collection and include borrowed
teams and spectator modes. There is also a substantial offline simulator/tooling
tree. The README's throughput and win-rate numbers are author-reported results,
not measurements reproduced here.

**Proposal:** start smaller: choose a box row as an opponent and launch an isolated
practice battle from the pause menu. Clone participants and restore temporary
battle context. Practice should not consume items, change EXP, or mutate the
stored originals. Then consider AI-controlled player teams and generated teams.

AI changes are a separate, high-effort project: battle heuristics, move semantics,
and version differences make “copy the better AI” deceptively expensive. The
first useful arena is simply a repeatable place to learn why six Shedinja heads
were not the loophole we hoped for.

## 8. Cynthia has located your position

**Code — [Cynthia encounters](https://github.com/Hewdraw/infinitefusion-but-cynthia-randomly-attacks-you/blob/main/Data/Scripts/1000_Cynthia/Cynthia_Encounters.rb).**
The implementation accumulates encounter chance, incorporates badge progression,
and can trigger Cynthia while Repel is active. The surrounding source tree also
contains bespoke AI and several additional gameplay systems.

**Proposal:** a deliberately small, optional roaming-rival extension: cooldown,
badge-scaled team, safe-map exclusions, and a warning cue. Persist the cooldown,
check that the party is able, and use an existing trainer battle entrypoint. Use
trainer data available in our version or provide extension-owned definitions.

Keep the original fork as inspiration rather than importing its entire encounter
system. Repel summoning Cynthia is an outstanding joke and a questionable default.

## 9. Performance ideas worth measuring

**Docs/history — [high-performance fork](https://github.com/SebastianMeinberger/infinitefusion-high-performance/blob/main/readme.md).**
The README explicitly labels the project not yet usable. Its `benchmarking`
branch adds load-time metrics and benchmark maps; `variable_fps` includes animation
and battle-system rewrites and lazy loading.

**Proposal:** borrow measurement before machinery: optional timings around startup,
box opening, sprite loading, and battle entry, compared with extensions enabled
and disabled. A small timing wrapper fits our architecture. Engine replacement,
variable-FPS conversion, and animation rewrites are separate undertakings.

## The 17-fork reconnaissance ledger

A matching default branch does not establish an empty fork. Several of the best
finds were hiding in named branches. “History” below means the relevant branch's
recent commits were inspected, not that every change was reviewed.

| Fork | Branches/evidence inspected | Useful takeaway  Inspected revision |
| --- | --- | ---  --- |
| [ITGourmand/InfiniteFusionFR](https://github.com/ITGourmand/InfiniteFusionFR) | `main` docs/history; language/mobile/release branches listed | French localization and shiny work. Good localization reference; not a focused QoL donor.  [`7e311f82`](https://github.com/ITGourmand/InfiniteFusionFR/commit/7e311f82b489069250d24fe2067986c368ce7261) |
| [Hewdraw/Cynthia](https://github.com/Hewdraw/infinitefusion-but-cynthia-randomly-attacks-you) | `main` history/tree and encounter code | Roaming champion concept; broad custom gameplay surrounds it.  [`2ca13b56`](https://github.com/Hewdraw/infinitefusion-but-cynthia-randomly-attacks-you/commit/2ca13b56ff326337abf1a2714f3b6abef522855b) |
| [DoubleUTH](https://github.com/DoubleUTH/infinitefusion-e18/tree/bugfix) | `bugfix` history and three diffs; `level100` listed | Strongest baseline match: five fixes immediately after 6.7.2.  [`d1bbd4f4`](https://github.com/DoubleUTH/infinitefusion-e18/commit/d1bbd4f4002e7f7e9a2b3f69cfb41212aea3ffb8) |
| [eliaz9toon/infinitefusionESP](https://github.com/eliaz9toon/infinitefusionESP) | Branch list and `main` history | Recent inspected changes concern collaboration/readme text; full translation coverage unverified.  [`fb282023`](https://github.com/eliaz9toon/infinitefusionESP/commit/fb282023fddf91a7f591c48c69473276a3a18416) |
| [matthewfro18/e18](https://github.com/matthewfro18/infinitefusion-e18) | Branch list and `main` history | Historical snapshot; no distinctive extension surfaced in this pass.  [`0d9741a4`](https://github.com/matthewfro18/infinitefusion-e18/commit/0d9741a460b901a71b3bcd98f74dff25a80e2472) |
| [matthewfro18/e18-1](https://github.com/matthewfro18/infinitefusion-e18-1) | Branch list and `main` history | Older settings/rate-limit history; no distinct feature verified.  [`be46d62c`](https://github.com/matthewfro18/infinitefusion-e18-1/commit/be46d62c8708af3f92b645c53e6640ce8b398c47) |
| [me-cedric](https://github.com/me-cedric/infinitefusion-e18) | `main`, `develop`, `develop-6.6` histories | Web-version WIP on `develop`; interesting portability research, not a small Ruby extension.  [`32a05276`](https://github.com/me-cedric/infinitefusion-e18/commit/32a0527632588bc85c1aa24fe314b72b54844d40) |
| [mhmmn/randomtweaks](https://github.com/mhmmn/infinitefusion-randomtweaks/tree/random-tweaks) | `random-tweaks` history/diff | Randomizer offsets and competitive movesets; marked WIP and touches compiler/data widely.  [`b1e35462`](https://github.com/mhmmn/infinitefusion-randomtweaks/commit/b1e35462c157008424f4c99f08e11ea84fe6d825) |
| [MrChuck123](https://github.com/MrChuck123/infinitefusion-e18/tree/nuzlocke-mode) | `nuzlocke-mode` history and flee-option diff | Challenge-rule UX, nickname enforcement, and trainer fleeing.  [`6f8b0641`](https://github.com/MrChuck123/infinitefusion-e18/commit/6f8b06414b87815a2981e09e5f6aa1ef1c849e1a) |
| [pjbatista](https://github.com/pjbatista/infinitefusion-e18) | `secret-capsule-impl`, `teleport-bike-fix` histories/diffs | Two focused item/transport fixes.  [`d6380625`](https://github.com/pjbatista/infinitefusion-e18/commit/d6380625ac009de0879598121bea1fdbdcc3702d) |
| [RyanChouHua](https://github.com/RyanChouHua/infinitefusion-e18) | Branch list, `main`, `infinitefusion-patch-1` histories | Inspected patch tip changes readme; no gameplay feature verified.  [`ec60522d`](https://github.com/RyanChouHua/infinitefusion-e18/commit/ec60522d331a100a30c7632a1fa540113b09e815) |
| [SebastianMeinberger/high-performance](https://github.com/SebastianMeinberger/infinitefusion-high-performance) | README; `benchmarking`, `variable_fps` histories | Measurement ideas; unfinished engine-scale work.  [`ff9a0d8c`](https://github.com/SebastianMeinberger/infinitefusion-high-performance/commit/ff9a0d8c449fbf6740ca31a52814010cba3bbf5d) |
| [stampil](https://github.com/stampil/infinitefusion-e18) | `main` history | Shiny scene/hue work; inspect overlap with our existing `ImprovedShinies` before adopting.  [`39f4c786`](https://github.com/stampil/infinitefusion-e18/commit/39f4c7860db716dab8eace705f4d8df83b8f3de8) |
| [Sthakur27/plus](https://github.com/Sthakur27/infinitefusion-plus/tree/sidmod) | `sidmod` README/history/tree and PC search code | Search, team exchange, practice battles; a rich 6.8.2 reference.  [`fbd8d32c`](https://github.com/Sthakur27/infinitefusion-plus/commit/fbd8d32cda58a1bc39e6d603bd1887aeeba427a1) |
| [Sukeshi7/sprites-only](https://github.com/Sukeshi7/infinitefusion-e18-sprites-only) | `main` history | Asset-stripping/distribution fork; no gameplay extension identified.  [`a7858cd8`](https://github.com/Sukeshi7/infinitefusion-e18-sprites-only/commit/a7858cd83267c52a6b7d721bfa339c5eb15fa6ee) |
| [Xeaster/apk](https://github.com/Xeaster/infinitefusion-apk/tree/claude/android-project-conversion-PPPjf) | Android branch history | JoiPlay packaging script/guide; the repo name alone does not establish a native Android port.  [`856c4c25`](https://github.com/Xeaster/infinitefusion-apk/commit/856c4c25636330f121365e3545621c4160179e0c) |
| [Ymirbot](https://github.com/Ymirbot/infinitefusion/tree/releases-nuzlocke) | `releases`, `releases-nuzlocke` histories and allowance diff | Plugin-based challenge rules, configurable encounters; normal releases branch reverted its catch-rule change.  [`ad133544`](https://github.com/Ymirbot/infinitefusion/commit/ad1335443b8c08808366d13559ad3663511199f4) |

## Wider web finds

- [Kuray](https://github.com/kurayamiblackheart/kurayshinyrevamp) is the main
  feature catalogue; its credit list is useful for tracing original contributions.
- [Celeaxy's standalone Nuzlocke mod](https://github.com/Celeaxy/PIF_NuzlockeMode)
  is closer to our installable-extension philosophy than a whole-game fork.
- [PJ's own QoL announcement](https://www.reddit.com/r/PokemonInfiniteFusion/comments/1jmu6jh/)
  also lists Pickup notifications and Battle Tower/Factory fixes. Treat these as
  discovery leads; this pass inspected the teleporter and capsule code specifically.
- [Infinite Fusion Multiplayer](https://github.com/NoamRothschild/infinitefusionmultiplayer)
  surfaced as a Kuray fork, but the page inspected mostly repeats Kuray's README.
  Multiplayer implementation and viability remain unverified. Park it until there
  is concrete networking code worth reviewing. “It has multiplayer in the name”
  is not a transport protocol.

## A sensible first batch

1. **Moveset ordering + fusion EXP investigation.** Concrete 6.7.2 defects and
   narrow behavioral targets; correctness first.
2. **PC search + EV visibility.** Daily benefits and natural reuse of our menu and
   summary hooks.
3. **Teleporter bike fix + team-row swap.** Reduce chores without changing the
   battle balance.
4. **Encounter journal.** Useful by itself; optional challenge policy can follow.
5. **Practice arena or roaming rival.** Choose controlled experiments or occasional
   Garchomp-related workplace incidents according to taste.

For direct code reuse, retain contributor attribution and inspect the source's
license at the chosen revision. Celeaxy declares GPL-3.0; this notebook has not
established reuse terms for every other source. Most proposed work above is a
fresh, small extension inspired by behavior, not a wholesale transplant.
