# GD RPG Engine Roadmap

A practical, incremental plan for a reusable 2D JRPG engine built with Godot 4 and GDScript.

The target is the feel and systems of classic 16-bit JRPGs: readable top-down exploration, story-driven events, a memorable party, and an Active Time Battle (ATB) combat loop. The visual target is **pixel-perfect 2D with an optional CRT display shader**, inspired by the presentation of 16-bit console RPGs. The project will use original sample content and assets; it will not depend on proprietary game data.

**Status legend:** [x] Done · [~] In progress · [ ] Planned

## Product principles

- **KISS first:** implement the smallest complete feature; avoid speculative abstractions.
- **Godot-native:** use scenes, nodes, signals, typed GDScript and custom Resources.
- **Data-driven where useful:** actors, items, skills, enemies, dialogue and events should be editable as resources.
- **Modular layout:** keep runtime, data, UI, editor tools, examples and tests in separate subdirectories.
- **Playable increments:** each milestone should leave the demo runnable.
- **No mandatory third-party runtime dependencies.**
- **Pixel-art integrity:** render at a fixed virtual resolution, preserve integer pixel scaling, and avoid filtered or subpixel movement.
- **Optional CRT presentation:** CRT effects must be configurable and disableable; the clean pixel-perfect image remains available.
- **Quality with every change:** refactor for simplicity, add or update tests, and verify the exact commit's CI before calling work complete.

## Visual direction — pixel-perfect 16-bit + CRT

### Pixel-perfect rendering rules
- [x] Set the virtual resolution to 320×180, with a documented 16:9 presentation.
- [x] Open the game at 1920×1080 Full HD by default (exact 6× integer scale).\n- [x] Add a GitHub Actions visual capture workflow for demo/pixel-test scenes, clean and CRT, at 1080p.
- [x] Configure viewport stretching with integer scaling; Godot uses letterboxing/pillarboxing rather than fractional pixel scaling.
- [x] Set the default window size to 1920×1080 (Full HD, 16:9).
- [x] Set nearest-neighbor canvas texture filtering as the project default.
- [ ] Keep sprite, tile and UI artwork aligned to the pixel grid.
- [ ] Keep character and camera rendering pixel-aligned; avoid visible subpixel jitter while moving or following the player.
- [ ] Define a consistent pixel-art scale for tiles, characters, portraits, effects and UI.
- [ ] Ensure menus, dialogue boxes and battle HUD use the same pixel grid and scaling rules.
- [ ] Document recommended import settings for spritesheets, tilesets and fonts.

### CRT shader and display options
- [ ] Add an optional full-screen CRT canvas shader, applied once at the final presentation stage.
- [ ] Implement configurable scanlines and subtle phosphor/RGB grille mask.
- [ ] Add restrained vignette and screen curvature controls.
- [ ] Add optional, subtle bloom and chromatic aberration; keep both disabled or minimal by default.
- [ ] Expose shader parameters through a small display settings resource or settings menu.
- [ ] Provide clean, subtle CRT and stronger retro presets, plus a fully disabled mode.
- [ ] Ensure the shader does not blur source pixels excessively or make text/UI hard to read.
- [ ] Check shader performance at the target resolution and on integrated GPUs.

**Visual acceptance:** at integer scale, source pixels remain crisp and stable during movement; the CRT effect can be toggled without changing gameplay or breaking UI readability. The clean mode must look correct without any CRT shader.

## P0 — Project foundation

- [x] Initialize the Godot 4 project and modular addon layout.
- [x] Register the engine plugin and custom types.
- [x] Add typed actor data resources.
- [x] Add top-down character movement.
- [x] Add the interactable contract.
- [x] Add dialogue resource and dialogue runner foundations.
- [x] Add the ATB timer foundation.
- [x] Add an asset-free playable demo.
- [x] Add GitHub Actions CI with headless editor validation and runtime smoke test.

**Exit criteria**
- The project imports and starts in headless mode.
- The demo can be launched from the editor.
- CI validates the pushed commit on `main`.

## P1 — Exploration and world

### P1.0 — Pixel-perfect rendering foundation
- [ ] Implement the virtual resolution and integer viewport scaling rules above.
- [ ] Configure nearest-neighbor filtering as the default for pixel-art content.
- [x] Add a reusable pixel-aligned camera setup that rounds camera world coordinates to whole virtual pixels (scrolling-map verification remains).
- [x] Add a pixel-grid test scene with a moving marker, tile grid and UI to reveal filtering issues.
- [x] Add an optional CRT overlay shader with clean and CRT modes (scanlines, grille and vignette).
- [x] Expose runtime CRT enable/disable and effect strength through the overlay script; F3 toggles it in the demo.
- [~] Document the initial pixel-art settings; camera alignment, shader tuning and broader import guidance remain.

**Progress:** the project now runs at 320×180 with integer viewport scaling and nearest-neighbor filtering. `RPGPixelCamera` rounds camera coordinates to whole virtual pixels and is used by the demo. The demo is also the first `RPGMap`, with a named default spawn. The CRT overlay remains toggleable at runtime. Scrolling-map camera verification, real screen curvature/bloom, and visual checks across multiple physical window sizes remain open. CI screenshot capture validates the target 1080p output but does not replace manual inspection on physical displays.

### P1.1 — Maps and navigation
- [ ] Establish a reusable map scene structure using `TileMapLayer`.
- [ ] Add player spawn markers and named spawn points.
- [ ] Add map-to-map transitions with fade in/out.
- [ ] Preserve party and world state when changing maps.
- [ ] Add camera follow, limits and optional room framing.
- [ ] Add collision layers/masks conventions and example collision tiles.
- [ ] Add a small connected sample area (village, route and interior).

**Acceptance:** the player can walk between at least three maps, arrive at the correct spawn point, collide with obstacles, and retain world state.

### P1.2 — Interactions and event commands
- [ ] Add a small event command model: show message, wait, move character, change switch, change variable, transfer map.
- [ ] Add event execution with predictable sequencing and cancellation.
- [ ] Add NPC facing and interaction range.
- [ ] Add trigger zones for automatic events.
- [ ] Add switches and variables persisted in world state.
- [ ] Add simple branching conditions.
- [ ] Add example quest using NPCs, switches and map transfers.

**Acceptance:** a complete short quest can be played from start to finish without custom one-off scripts for each event.

## P2 — JRPG content and progression

### P2.1 — Party and character data
- [ ] Define actor stats, growth curves and progression data.
- [ ] Add party roster and active party (initially up to four members).
- [ ] Add experience, levels and stat growth.
- [ ] Add equipment slots and equipment stat modifiers.
- [ ] Add status conditions and recovery rules.
- [ ] Add a party menu showing status and equipment.

### P2.2 — Inventory and items
- [ ] Add item resources (consumables, key items and equipment).
- [ ] Add stackable inventory with configurable limits.
- [ ] Add item use rules in and out of battle.
- [ ] Add shop stock, buying and selling.
- [ ] Add treasure containers and event rewards.

### P2.3 — Save and load
- [ ] Define a versioned save-data format.
- [ ] Save party, inventory, switches, variables, current map and spawn point.
- [ ] Add multiple save slots and basic save metadata.
- [ ] Handle missing or outdated resource references safely.
- [ ] Add save/load tests and a demo save point.

**Acceptance:** a player can save during exploration, restart the game, load, and continue with the same party, inventory and quest state.

## P3 — Battle system

### P3.1 — Battle loop
- [ ] Turn the ATB timer foundation into a complete battle state machine.
- [ ] Add battle start/end flow and party/enemy sides.
- [ ] Add battle command selection (attack, skill, item, defend).
- [ ] Add target selection and valid-target rules.
- [ ] Add damage, healing, critical hits and defeat handling.
- [ ] Add victory rewards, experience and drops.
- [ ] Add escape rules and game-over handling.

### P3.2 — Skills, enemies and encounters
- [ ] Add skill resources with costs, targeting and effects.
- [ ] Add enemy resources with stats, skills and simple behavior.
- [ ] Add enemy formations and encounter definitions.
- [ ] Add map encounter zones and configurable encounter rates.
- [ ] Add status effects, durations and turn/tick processing.
- [ ] Add elemental affinities and resistance rules.
- [ ] Add battle test scenarios that do not require a full map.

### P3.3 — Battle presentation
- [ ] Add a readable battle HUD for party gauges, HP/MP and commands.
- [ ] Add battle messages and action feedback.
- [ ] Add lightweight hit, cast, damage and victory animations.
- [ ] Add battle music and transition hooks.
- [ ] Add a complete sample encounter with at least three party members and multiple enemy types.

**Acceptance:** a full encounter can start from the map, run through ATB commands, resolve victory or defeat, grant rewards, and return to exploration.

## P4 — Dialogue, presentation and user experience

- [ ] Add dialogue choices and conditional branches.
- [ ] Add speaker names, portraits and text presentation settings.
- [ ] Add text speed, instant display and input-to-advance behavior.
- [ ] Add localization-ready string resources and language selection.
- [ ] Add reusable menus for title, pause, party, inventory and options.
- [ ] Add audio buses, sound effects and music transitions.
- [ ] Add controller support and configurable input actions.
- [ ] Add UI scaling, readable fonts and accessibility options.
- [ ] Add display settings for virtual resolution/window mode and CRT presets.
- [ ] Add transition effects for maps, battles and important events.

**Acceptance:** the sample quest can be completed using keyboard or controller, with dialogue, menus, audio and configurable presentation.

## P5 — Editor tools and authoring workflow

### P5.1 — Content authoring
- [ ] Add editor inspectors for actor, item, skill and enemy resources.
- [ ] Add reusable map, NPC, trigger and treasure scene templates.
- [ ] Add an event authoring workflow for the supported command set.
- [ ] Add validation messages for missing references and invalid event data.
- [ ] Add import guidance/helpers for spritesheets, tilesets and audio.
- [ ] Document resource naming and folder conventions.

### P5.2 — Demo game
- [ ] Build a short, coherent vertical slice using only engine features.
- [ ] Include a title screen, village, world route, dungeon and boss encounter.
- [ ] Include several NPCs, one quest, shops, treasure and save/load.
- [ ] Include a small party, equipment, skills and enemy formations.
- [ ] Provide original placeholder art/audio that can be replaced easily.
- [ ] Showcase both clean pixel-perfect rendering and optional CRT presentation.

**Acceptance:** a new user can open the demo, understand the project structure, play the vertical slice, and create a small variation by editing resources and scenes.

## P6 — Stability, documentation and release

- [ ] Add automated tests for data resources and core runtime systems.
- [ ] Add deterministic test hooks for battle and event sequencing where practical.
- [ ] Add performance checks for map/event-heavy scenes and the CRT shader.
- [ ] Test supported Godot 4 versions and document the compatibility range.
- [ ] Document installation, setup, architecture and extension points.
- [ ] Add tutorials: first map, first NPC, first quest and first battle.
- [ ] Document pixel-art import settings, virtual resolution and CRT configuration.
- [ ] Add a changelog and versioning policy.
- [ ] Prepare a tagged example release.

**Acceptance:** a clean checkout can be imported, tested, run and extended using the documentation.

## Cross-cutting engineering checklist

Apply these to every feature, not as a late cleanup phase:

- [ ] Keep scripts focused and avoid abstractions without a concrete use case.
- [ ] Use typed GDScript and clear names.
- [ ] Keep reusable engine code under `addons/gd_rpg/`; keep demo-specific code under `examples/`.
- [x] Add headless tests for named map spawn lookup and default fallback.
- [ ] Add tests for logic that can be tested without rendering.
- [x] Add a reproducible automated screenshot capture for visual behavior (GitHub Actions/Xvfb); retain manual checks on physical displays.
- [ ] Update the README or relevant docs when public behavior changes.
- [ ] Preserve pixel alignment and nearest-neighbor sampling in all new visual features.
- [x] Run the headless editor validation, world unit tests and runtime smoke test in GitHub Actions.
- [ ] Perform a KISS refactor, then verify CI on the exact commit pushed to `main`.

## Suggested implementation order

1. P1.0 Pixel-perfect rendering and CRT foundation.
2. P1.1 Maps, spawn points and transitions.
3. P1.2 Event commands and a small quest.
4. P2.1 Party and character progression.
5. P2.2 Inventory and items.
6. P2.3 Save/load.
7. P3.1 Complete battle loop.
8. P3.2 Skills, enemies and encounters.
9. P3.3 Battle presentation.
10. P4 Dialogue and player-facing menus.
11. P5 Editor workflow and vertical-slice demo.
12. P6 Hardening, documentation and release.

Priorities describe implementation order, not promises or fixed dates. Keep each task small enough to review, test and ship independently.
