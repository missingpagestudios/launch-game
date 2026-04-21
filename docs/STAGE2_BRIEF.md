# LAUNCH — Stage 2 Brief

**Audience:** desktop Claude agent (Pepper) doing the Godot build.
**Repo:** `missingpagestudios/launch-game`
**Stage 1 output (use as economy reference):** `docs/BALANCE_FINAL.md` + `data/balance_config.json`

---

## What LAUNCH is

A 100-night narrative incremental about building a fireworks career. Player progresses through 6 zones (Backyard → World), each night plans a show, fires it, earns money + repeat fans, advances zones. At Zone 6, a single-shot donation choice determines the ending. One of 8 causes is "right" (asteroid research, true ending); the other 7 produce a standard ending. Players who read the in-game newspaper sub-columns piece together which cause is correct.

Working title: **LAUNCH**. Studio brand TBD (Rob is finalizing).

---

## What stage 2 is (this stage)

**Build the full game loop in Godot 4.6 using ONLY TEXT.** No firework rendering. No animations. No art. Just text labels, buttons, panels.

The goal: validate that the loop **works end-to-end** — start a run, advance through 100 nights, see all 4 endings, with the validated economy from stage 1.

### What you do NOT build in stage 2

- Firework particle effects (those exist in `~/projects/fireworks-demo/` from a previous prototype and will be ported in stage 3)
- Final UI design / colors / layout polish (just functional text)
- Audio
- Save/load (single-session only is fine)

### What you DO build in stage 2

1. **Title screen / new run**
   - "LAUNCH" title, "Start" button, version label
   - Optional: continue (if you implement save) or unlocks display

2. **Newspaper interstitial** (between nights)
   - Top-of-fold headline reflecting the previous night's show
   - 2-3 sub-columns of flavor text (one of which is a meteor warning column from "Dr. Eleanor Chen" that escalates over the 100 nights)
   - "Continue to Planning →" button

3. **Three-panel planning screen** (the core loop)
   - Panel 1: Fireworks loadout — buy quantities, see total engagement preview
   - Panel 2: Marketing + Enhancements — buy services, pick one tier per category
   - Panel 3: Permanent Upgrades — one-time purchases
   - Total cost vs. cash, "Fire show →" button when ready

4. **Show summary screen**
   - Show title text ("Your show in [Zone]"), no actual fireworks
   - Reveal: attendees, engagement, new repeat fans, revenue, synergies hit
   - Camera-shake-style text reveal is fine, no actual visuals
   - "Continue →" button

5. **Donation decision screen** (single-shot, appears after Z6 clear at $6B)
   - Header: "A choice on the eve of your final shows."
   - 8 causes presented neutrally — character name, plea text, no goal numbers
   - Each is a button. Plus a "Skip donation, keep $2.5B" button.
   - Cost $2.5B flat. After choice, locked for the run.

6. **Ending screens**
   - **True ending** (asteroid donated): "The world is saved. Most don't know how. You do." + something about the meteor being intercepted.
   - **Standard ending (wrong cause)**: "Your career stands as legacy. [cause name] funded." + acknowledge the meteor hit (but downplay; player's POV doesn't connect dots in this run).
   - **Standard ending (skipped)**: "You finished rich. The shows were beautiful." + meteor hits.
   - **Zone N finale** (no donation phase): Standard career-ends-here ending at the highest reached zone.

---

## Architecture suggestions

- One scene per screen (`title.tscn`, `newspaper.tscn`, `planning.tscn`, `show.tscn`, `donation.tscn`, `ending.tscn`)
- One autoload `GameState` singleton holding all per-run state (money, fans, zone, owned upgrades, donated, etc.)
- One autoload `BalanceConfig` singleton that loads `data/balance_config.json` once and exposes typed lookups
- One autoload `EconomyEngine` (port of `engine.py`) that contains all calculation methods (port directly from Python — same formulas, same parameters)

The Python sim's `engine.py` is the source of truth for all math. Port the calculation methods 1:1 to GDScript:
- `calculate_attendees()`
- `calculate_engagement()` + `calculate_synergies()`
- `calculate_revenue()` + `calculate_show_quality_mult()`
- `calculate_conversions()` (the iter 1 formula with `quality_mult = 0.3 + min(eng_per_attendee/quality_target, 2.0)`)
- `simulate_night()` orchestration including Z6 revenue tracking and donation phase trigger

---

## Reference materials in this repo

- `data/balance_config.json` — **canonical** balance config, parse this directly
- `docs/BALANCE_FINAL.md` — economy overview, strategy outcomes, parameter rationale, edge cases, iteration history
- `docs/BALANCE_FINAL_config_annotated.json` — same values as `balance_config.json` with `_comment_*` keys explaining each section. Reference only; do NOT load this in Godot.

The Python sim source code is at `~/projects/fireworks-sim/` (not in this repo) — `engine.py` is the algorithm reference if you need to disambiguate any math.

---

## Font

Rob will provide the **mx611** pixel font. Drop it in `fonts/mx611.ttf` (or whatever extension) and use it project-wide via Theme. Default monospace fallback is fine until then.

---

## Definition of done for stage 2

- Player can start a new run from title screen
- Game advances through all 100 nights without crashing
- All 4 ending states are reachable via different play patterns
- Economy values match the Python sim (an automated stress test would be ideal — run 100 simulated runs from a debug menu using the `Mogul` strategy and confirm Mogul Veteran reaches Z6 in 80%+ of runs and true ending in 50-60%)
- Newspaper interstitial shows escalating Dr. Chen meteor warnings
- Donation screen presents 8 causes neutrally; player can pick or skip

Once that loop works, stage 3 brings in the firework rendering, polish, audio.

---

## Notes for the agent

- Use Godot 4.6+ idioms (typed GDScript, `class_name`, `@export`)
- The Python sim ran on a server — Godot project should be fully self-contained (no Python dependency at runtime)
- Test on Rob's Windows machine; develop locally with `godot --path . --debug`
- Commit early and often; small commits are easier to review
- When in doubt about economy values, the canonical source is `data/balance_config.json`. Don't redo balance work — it's locked.

---

## Strategy heuristics for the auto-test feature (optional but recommended)

If you implement an automated test/replay mode for QA, port these strategies from `~/projects/fireworks-sim/strategies.py`:

- **Spectacle**: prefer high-tier fireworks, focus on crew/infra upgrades
- **Mogul**: prefer marketing + revenue upgrades, lower-tier high-volume fireworks
- **Rush**: speed-to-Z6, marketing-heavy
- **Completionist**: rotates upgrade focus, spreads donations to non-asteroid causes
- **Cheapskate**: minimal spending, no marketing/enhancements

These produce known outcomes (see BALANCE_FINAL.md table) so you can validate your engine port matches.

---

## Questions / blockers

If you hit something ambiguous, the priorities are:

1. Match the validated economy first (use `data/balance_config.json` and port `engine.py` math literally)
2. Prefer building the loop end-to-end before polishing any single screen
3. Text-only is the constraint — resist adding visuals until stage 3

Open ended design questions (e.g. "what should the Dr. Chen newspaper text say in week 6?") can be punted to placeholder text and revisited later.
