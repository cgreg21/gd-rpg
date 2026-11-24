# GD RPG Engine

A modular 2D JRPG engine for Godot 4, inspired by the readable overworld exploration and party-driven encounters of 16-bit-era JRPGs.

## Goals
- Top-down exploration, interactions and map transitions
- Data-driven actors, items, skills and encounters
- Dialogue and event sequencing
- Active Time Battle (ATB) combat foundation
- Editor-friendly GDScript resources and plugin tooling

## Requirements
- Godot 4.3+ (GDScript, no third-party runtime dependencies)

## Run
Open this repository in Godot and run the project (F6/F5). The demo is intentionally asset-free so the core systems can be tested immediately.

## Layout
- `addons/gd_rpg/runtime`: reusable runtime systems
- `addons/gd_rpg/data`: typed Resource definitions
- `addons/gd_rpg/ui`: reusable UI
- `addons/gd_rpg/editor`: editor integration
- `examples/demo`: playable systems showcase
- `tests`: automated smoke checks

See [ROADMAP.md](ROADMAP.md) for the implementation plan.
