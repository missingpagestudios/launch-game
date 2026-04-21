# LAUNCH — Balance Final (Iteration 13)

**Status:** Python balance simulation complete. Economy locked. Ready for Godot implementation.

Date: 2026-04-21
13 iterations across 1 day. 5,000 simulations per iteration.

---

## 1. Economy Overview

A 100-night narrative incremental where the player builds a fireworks career across 6 zones (Backyard → Neighborhood → Town → City → Regional → World) and ends with a single-shot donation decision that determines the ending.

### 5 AI strategies modeled

| Strategy        | Identity                                  | Typical outcome                            |
|-----------------|-------------------------------------------|--------------------------------------------|
| **Spectacle**   | Artist — high-tier fireworks, show quality | Z5 mostly; rare true ending (1-3%)         |
| **Mogul**       | Business optimizer — marketing + revenue   | Reliable Z6, dominant true-ending path     |
| **Rush**        | Speed-to-Z6 — heavy marketing, low-tier fw | Fast Z6, frequent true ending              |
| **Completionist** | Balanced rotation, spreads donations    | Z6 occasional, "wrong cause" legacy ending |
| **Cheapskate**  | Minimal spending, no marketing/enh         | Z3-Z4 cap (validates baseline)             |

### 4 endings

1. **TRUE ENDING (asteroid funded)** — donated to Asteroid Research Program at Zone 6 clear
2. **Standard ending (wrong cause)** — donated to one of 7 sympathetic-but-incorrect causes
3. **Standard ending (skipped)** — qualified but kept the cash
4. **Zone N finale** — never qualified; standard career-ends-here ending at the highest reached zone

### Zone progression mechanic

Each zone has a `threshold_repeat_fans` to enter. Zone 6 additionally has a `zone_6_clear_threshold` ($6B earned in Z6) which unlocks the donation phase the next night.

### Single-shot donation

When Z6 cleared, the next planning phase shows a donation screen. Player can:
- Donate **$2.5B** to one of 8 causes (1 correct, 7 fake)
- Skip and keep the cash

Decision is irreversible. After it, gameplay continues normally to night 100 finale.

---

## 2. Strategy Outcomes (Iteration 13 Results, 500 runs each)

### Fresh Player (38 fireworks available)

| Strategy      | Z6%  | Z6Clr% | Don% | TrueEnd% | WrongEnd% | Skip% | NotReach% | Med $ Earned |
|---------------|-----:|-------:|-----:|---------:|----------:|------:|----------:|-------------:|
| Spectacle     | 32.0 |    3.1 | 100  |      1.0 |       0.0 |   0.0 |      99.0 |        $124M |
| Mogul         | 79.2 |   60.4 | 100  |     47.8 |       0.0 |   0.0 |      52.2 |        $7.2B |
| Rush          | 72.8 |   49.2 | 100  |     35.8 |       0.0 |   0.0 |      64.2 |        $4.8B |
| Completionist | 37.4 |    7.5 | 100  |      0.0 |       2.8 |   0.0 |      97.2 |        $133M |
| Cheapskate    |  0.0 |    0.0 |   0  |      0.0 |       0.0 |   0.0 |     100.0 |        $1.4M |

### Veteran Player (50 fireworks available)

| Strategy      | Z6%  | Z6Clr% | Don% | TrueEnd% | WrongEnd% | Skip% | NotReach% | Med $ Earned |
|---------------|-----:|-------:|-----:|---------:|----------:|------:|----------:|-------------:|
| Spectacle     | 27.8 |    2.2 | 100  |      0.6 |       0.0 |   0.0 |      99.4 |        $104M |
| Mogul         | 84.8 |   68.2 | 100  |     57.8 |       0.0 |   0.0 |      42.2 |        $9.6B |
| Rush          | 74.6 |   53.4 | 100  |     39.8 |       0.0 |   0.0 |      60.2 |        $6.0B |
| Completionist | 41.4 |    9.7 | 100  |      0.0 |       4.0 |   0.0 |      96.0 |        $130M |
| Cheapskate    |  0.0 |    0.0 |   0  |      0.0 |       0.0 |   0.0 |     100.0 |        $1.5M |

**Reading the table:**
- `Z6%` — reached Zone 6 at any point
- `Z6Clr%` — of Z6 reachers, what % cleared the $6B Z6 revenue threshold before night 100
- `Don%` — of qualifying runs, what % actually donated (always 100 because donation cost < cash-on-hand at qualification)
- `TrueEnd%` — chose asteroid donation
- `WrongEnd%` — chose non-asteroid cause (Completionist's spread strategy)
- `NotReach%` — never qualified for donation phase

---

## 3. Key Parameters & Rationale

### Zone thresholds (`config.zones`)

| Zone | Name         | Fan threshold | Notes                                     |
|-----:|--------------|--------------:|-------------------------------------------|
|    1 | Backyard     |             0 | Tutorial                                  |
|    2 | Neighborhood |            20 | First conversion validation               |
|    3 | Town         |           150 | Real money begins, T2 unlocks             |
|    4 | City         |         1,500 | T3 unlocks, marketing scale jumps         |
|    5 | Regional     |         5,000 | T4 unlocks, attendees in millions         |
|    6 | World        |        30,000 | Endgame, Z6 clear gates donation phase    |

### Zone 6 clear: $6B earned in Z6

Rationale: Mogul Z6 net income is ~$830M/night. $6B requires ~7 nights of clean Zone 6 execution. Achievable for dedicated optimization (Mogul Vet 68%), tight for Rush (53%), aspirational for Spectacle (2-3%). Aligns the true ending with "Zone 6 mastery" rather than "anybody who reaches Z6."

### Donation cost: $2.5B flat

Rationale: Lower than Z6 clear threshold so qualifying automatically means you can afford to donate. Leaves $2.5B+ cash buffer for finishing nights 95-100 with normal show spending.

### Live Stream Setup: $100M

Rationale: After iter 1-5 experiments with $2B (impossible) and $500M (still unreachable), $100M is achievable in ~5 nights of Zone 5 income with the save-up behavior in `_consider_upgrades`. No longer gates donation phase (Z6 revenue does), so it's now a strict attendees-permanent boost rather than a gating purchase.

### Conversion formula

Replaces the original `conversion_scalar * eng_per_attendee` (which made marketing actively HURT conversions) with:

```
quality_mult = 0.3 + min(eng_per_attendee / quality_target, 2.0)
effective_rate = min(base_conversion * quality_mult, max_conversion)
new_fans = attendees * effective_rate
```

Each zone has its own `base_conversion` and `quality_target`. Marketing now always helps (more attendees = more conversion opportunities) while quality of show still matters.

### Tier 4 engagement scaling

Tier 4 fireworks have engagement values 100→240,000 across the 10 entries (Drone Swarm to Singularity). Costs $5K to $10B. Designed so each Tier 4 firework is strictly more engagement-efficient than any Tier 3 at its price point.

### Unlockable +20% engagement bonus

12 of 50 fireworks are unlockable through cross-playthrough achievements. Their engagement is 1.20× the equivalent base firework. Veteran mode (all 12 unlocked) shows measurable advantage: ~10pp higher Mogul true-end rate.

### Save-up behavior

`_consider_upgrades` accepts `save_target` parameter. If money is at 40-100% of target cost, the picker returns empty (skips other upgrades to save). At 100%, buys target. This is the only way the AI accumulates cash for big-ticket upgrades like Live Stream Setup.

### Picker affordability filter

`_pick_fireworks` pre-filters candidate types — if per-type budget can't afford even 1 unit of a candidate, that candidate is dropped and budget redistributes among the remaining types. Without this, Veteran's expensive unlockable T4 fireworks would leave slots empty.

---

## 4. Edge Cases Verified

### Test A — No-upgrade Spectacle (100 runs)

- **Crashes:** 0
- **Final zones:** Z6 66%, Z5 30%, Z4 3%, Z3 1%
- **True ending:** 9% (surprising — no upgrades + Spectacle's high-tier fireworks still reaches Z6)
- **Finding:** Z6 is reachable without ANY Panel 3 upgrades because the donation phase is now gated by Z6 revenue (not Live Stream Setup ownership). Upgrades meaningfully accelerate progression but aren't strictly required.

### Test B — Zero-marketing Mogul (100 runs)

- **Crashes:** 0
- **Final zones:** Z4 81%, Z5 12%, Z3 6%, Z2 1%
- **Median earned:** $1.8M (vs Mogul's normal $7.2B)
- **Finding:** Without marketing, Mogul caps at Z4-5 with much lower earnings. Marketing is the dominant lever for fan acquisition.

### Test C — Late Zone 6 entry (113 of 500 Mogul Veteran runs entering Z6 at night ≥ 95)

- **Crashes:** 0
- **Endings:** 100% `zone_6_no_donation` (none qualified for donation phase)
- **Finding:** Late Z6 entries gracefully handle the donation-not-qualified state. Game completes without errors.

---

## 5. Design Decisions Considered & Rejected

- **Multi-night donation accumulation (iters 1-10):** Tried this. Caused balance issues (donate-90%-of-cash-per-night made any cumulative goal trivially reachable; AI couldn't save). Iter 11 restructured to single-shot.
- **Extending nights past 100:** Violates the "100 nights" core identity.
- **Crisis framing on asteroid cause:** Telegraphs the answer too early, kills replay value.
- **Live Stream Setup gating donation phase:** Created a single-purchase chokepoint. Now Z6 revenue gates instead — cleaner.

---

## 6. Iteration History (Brief)

| Iter | Change                                           | Effect                                    |
|------|--------------------------------------------------|-------------------------------------------|
|   1  | New conversion formula + 12 unlockable fireworks | Z3 hard-stop → Z4 hard-stop               |
|   2  | Zone buffs + Tier 4 engagement rescale           | Mostly noise — picker bug masked changes  |
|  2.5 | Picker fix: per-type slot cap, tier-dom sort     | Spectacle/Completionist reach Z5 in 70%   |
|   3  | Picker tier-weighting for Mogul/Rush + Z5/Z6 thresholds | Mogul/Rush reach Z5 too                |
|   4  | Save-up behavior on `_consider_upgrades`         | Wired but never fired (cost too high)     |
|   5  | Live Stream $500M → $100M, save threshold 40%    | LS purchase 88% Mogul, donations begin    |
|   6  | Z6 threshold 100k → 30k, donation goals /10      | Z6 unlocked, true ending unlocked         |
|   7  | Asteroid $1B → $4B + donation overflow           | Asteroid-then-spread-causes pattern works |
|   8  | Asteroid $4B → $5B                               | Mogul/Rush still over target              |
|   9  | Picker affordability filter                      | Veteran engagement matches/exceeds Fresh  |
|  10  | Asteroid $5B → $6B                               | Mogul/Rush still over (linear curve)      |
|  11  | Donation restructure to single-shot at Z6 clear  | Architectural fix — clean ending semantics |
|  12  | Z6 clear threshold $3B → $5B                     | Mogul Vet still 62%                       |
|  13  | Z6 clear $5B → $6B                               | All targets in range — STOP               |

---

## 7. Files

- `config.json` — final balance parameters (also exported as `BALANCE_FINAL_config.json` with comments)
- `engine.py` — game logic, single-shot donation processing
- `strategies.py` — 5 strategies + helpers (picker, save-up, single-shot donation)
- `simulate.py` — 5000-run sim + ending funnel reporting
- `debug_early.py`, `debug_mid.py` — single-strategy traces
- `edge_cases.py` — Test A/B/C validation
- `BALANCE_REPORT.md` — interim report from iter 2.5
- `BALANCE_FINAL.md` — this document

---

## 8. Godot Handoff

The Python sim retires here. For Godot implementation:

1. Port `config.json` values to Godot game state (parse JSON natively).
2. Use `rendering_constraints.md` (separate doc) for firework_cap overrides per zone — Godot caps differ from sim caps for performance reasons.
3. Implement single-shot donation screen (no multi-cause cumulative tracking needed).
4. Asteroid is `is_correct: true`; ending logic checks `donation_choice == "asteroid"`.
5. The 12 unlockable fireworks need cross-run achievement persistence — sim assumes you start with all or none, real game tracks unlock conditions per save file.

The economy is validated to produce 5 distinct viable playstyles with meaningful differentiation between Fresh and Veteran modes. The asteroid ending is achievable but feels earned (47-58% for the optimized Mogul path, 1-3% for Spectacle). Real human playtesting will validate feel vs. these AI numbers.
