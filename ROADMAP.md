# GD RPG Engine Roadmap

## P0 — Foundation
- [x] Initialize Godot 4 project and modular addon layout
- [x] Add plugin registration and typed data resources
- [x] Add top-down movement and interaction contract
- [x] Add dialogue resource and runner
- [x] Add ATB battle loop foundation
- [x] Add asset-free playable demo
- [x] Add CI validation workflow
- [x] Run Godot headless import and smoke tests on CI

## P1 — Core JRPG systems
- [ ] Map transitions, spawn points and persistent map state
- [ ] Event commands (message, move, wait, switch, transfer)
- [ ] Party management, equipment, inventory and save/load
- [ ] Battle commands, targeting, status effects and victory rewards
- [ ] Resource-driven enemy formations and encounter zones
- [ ] Dialogue choices, portraits and localization

## P2 — Authoring workflow
- [ ] Map/event inspector dock and reusable scene templates
- [ ] Database browser for actors, items, skills and enemies
- [ ] Import helpers for spritesheets, tilesets and audio
- [ ] Example project with a complete short quest

## P3 — Polish
- [ ] Audio buses, music transitions and sound cues
- [ ] Controller remapping, accessibility and UI themes
- [ ] Profiling, documentation and compatibility matrix

## Engineering rules
- Keep modules small and independent.
- Prefer typed GDScript and native Godot Resources.
- No dependency without a concrete need.
- Every feature includes a KISS refactor and a test or reproducible manual check.
