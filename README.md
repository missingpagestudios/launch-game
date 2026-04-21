# LAUNCH

100-night narrative incremental about building a fireworks career. Godot 4.6.

## Status

**Stage 2 (current):** text-only loop validation. Build the full game loop with text labels and buttons; no firework rendering yet.

## Build / Run

Open `project.godot` in Godot 4.6+ and press F5.

## Project layout

```
launch-game/
├── project.godot              # Godot project file
├── icon.svg                   # placeholder icon
├── scenes/
│   └── main.tscn              # entry scene (placeholder)
├── scripts/
│   └── world.gd               # entry script (placeholder)
├── data/
│   └── balance_config.json    # canonical balance config (load at runtime)
├── docs/
│   ├── STAGE2_BRIEF.md        # what to build, in detail
│   ├── BALANCE_FINAL.md       # economy spec, strategy outcomes, rationale
│   └── BALANCE_FINAL_config_annotated.json  # reference, don't load
└── fonts/                     # mx611 lands here (TBD)
```

## Reference

- **`docs/STAGE2_BRIEF.md`** — read this first
- **`docs/BALANCE_FINAL.md`** — economy spec from the Python sim that validated balance
- **`data/balance_config.json`** — load at runtime as the source of truth for all parameters

## Stages

1. ~~Python balance simulation (validated 5 strategies, 4 endings, locked economy)~~ ✓
2. **Godot text-only loop validation** ← we are here
3. Firework rendering + UI polish + audio
