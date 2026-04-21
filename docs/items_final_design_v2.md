# THE LAST SHOW — Final Items Design (v2)

**Context:** This supersedes the previous items_final_design.md. Enhancement effects now use FLAT bonuses (simple, readable, non-compounding) instead of percentage multipliers.

**Core design principle:** Every item should be readable as a plain English statement that tells the player exactly what happens. No hidden math, no stacking percentages, no ambiguity.

---

## MECHANICAL MODEL

### How effects combine in a show

**Step 1: Base per-fan values from fireworks**
```
tips_per_fan_base = sum(fw.tips × qty) for all selected fireworks
reach_per_fan_base = sum(fw.reach × qty) for all selected fireworks
retention_per_fan_base = sum(fw.retention × qty) for all selected fireworks
```

**Step 2: Add flat bonuses from enhancements (if any selected)**
```
tips_per_fan = tips_per_fan_base + snacks_bonus
reach_per_fan = reach_per_fan_base + host_bonus
retention_per_fan = retention_per_fan_base + music_bonus
```

**Step 3: Apply global multipliers from upgrades and specialist**
```
tips_per_fan *= total_tips_multiplier
reach_per_fan *= total_reach_multiplier
retention_per_fan *= total_retention_multiplier
```

**Step 4: Aggregate to totals**
```
attendance = walk_up + passive_from_fans + marketing_bonus + live_acts_bonus
total_tips = tips_per_fan × attendance
total_reach = reach_per_fan × attendance
star_rating = lookup(retention_per_fan, zone)
new_fans = floor(total_reach × REACH_TO_FAN_RATIO)
```

**This keeps math clean:** flat bonuses add, multipliers multiply. No compounding of percentages.

---

## STAT MAPPING (which enhancement does what)

| Category | Effect | Plain Language |
|----------|--------|----------------|
| Snacks | +Tips per attendee | "Audience tips more when snacking" |
| Music | +Retention per attendee | "Your show feels more polished" |
| Host | +Reach per attendee | "Charismatic host spreads word about your show" |
| Live Acts | +Attendees tonight | "Band brings extra crowd" |
| Specialist | ×Multiplier on all stats | "Pro elevates every aspect" |

Each category has ONE clear purpose. No confusion about what boosts what.

---

## MARKETING ITEMS (9)

Consumable per-night purchases. Each brings NEW attendees to tonight's show only.

| ID | Name | Cost | Effect | Cap/Night | Min Zone |
|----|------|-----:|--------|----------:|---------:|
| M1 | Flyers | $5 | +5 attendees | 20 | 1 |
| M2 | Community Newsletter | $40 | +25 attendees | 5 | 2 |
| M3 | Newspaper Ad | $150 | +125 attendees | 3 | 3 |
| M4 | Radio Spot | $600 | +800 attendees | 2 | 3 |
| M5 | Billboard | $1,500 | +2,500 attendees | 3 | 4 |
| M6 | Social Media Campaign | $3,000 | +5,000 attendees | 3 | 4 |
| M7 | TV Commercial | $8,000 | +15,000 attendees | 2 | 4 |
| M8 | National PR Campaign | $50,000 | +100,000 attendees | 2 | 5 |
| M9 | Streaming Partnership | $500,000 | +2,000,000 attendees | 2 | 6 |

**Player reads:** "Flyers bring 5 people to tonight's show, $5 each, up to 20 per night."

---

## ENHANCEMENTS (22 items)

One enhancement per category per night. Player picks one from each category.

### Snacks — Audience tips more generously

| ID | Name | Cost | Effect | Min Zone |
|----|------|-----:|--------|---------:|
| E1 | Candy Stand | $3 | +$0.20 tips per attendee | 1 |
| E2 | Vending Machines | $15 | +$0.50 tips per attendee | 2 |
| E3 | Food Vendors | $100 | +$2 tips per attendee | 3 |
| E4 | Catering Team | $1,000 | +$8 tips per attendee | 4 |
| E5 | Gourmet Experience | $10,000 | +$25 tips per attendee | 5 |

**Player reads:** "Candy Stand adds $0.20 in tips per attendee. With 50 attendees tonight, that's +$10 for $3. Worth it."

**Break-even math:**
- Candy Stand: profitable with 15+ attendees
- Vending: profitable with 30+ attendees (Zone 2 has 15-30 walk-up alone)
- Food Vendors: profitable with 50+ attendees
- Catering: profitable with 125+ attendees
- Gourmet: profitable with 400+ attendees

All profitable at their min_zone based on expected attendance.

### Music — Your show feels more polished (boosts Retention)

| ID | Name | Cost | Effect | Min Zone |
|----|------|-----:|--------|---------:|
| E6 | Boombox | $10 | +0.3 retention per attendee | 1 |
| E7 | Basic PA System | $75 | +0.8 retention per attendee | 2 |
| E8 | Pro Sound System | $500 | +2 retention per attendee | 3 |
| E9 | Arena Sound System | $1,500 | +5 retention per attendee | 4 |
| E10 | Concert Sound System | $5,000 | +10 retention per attendee | 5 |

**Player reads:** "Boombox adds 0.3 retention per attendee. Better star ratings = more fans return next show."

**Strategic note:** Music directly helps hit star rating thresholds. If you're close to next star tier, music can push you over.

### Host — Charismatic host spreads word about your show (boosts Reach)

| ID | Name | Cost | Effect | Min Zone |
|----|------|-----:|--------|---------:|
| E11 | Local MC | $10 | +0.5 reach per attendee | 1 |
| E12 | Neighborhood Announcer | $50 | +1 reach per attendee | 2 |
| E13 | Professional Host | $150 | +2.5 reach per attendee | 3 |
| E14 | Radio Personality | $1,000 | +6 reach per attendee | 4 |
| E15 | Celebrity Host | $12,000 | +15 reach per attendee | 5 |

**Player reads:** "Local MC adds 0.5 reach per attendee. More reach = more new fans joining your pool."

**Strategic note:** Host accelerates fan growth. Useful when racing to hit zone fan thresholds.

### Live Acts — Band brings extra crowd (direct attendance)

| ID | Name | Cost | Effect | Min Zone |
|----|------|-----:|--------|---------:|
| E16 | Mom & Pop Band | $25 | +15 attendees | 2 |
| E17 | Local Professional Band | $150 | +75 attendees | 3 |
| E18 | Regional Music Act | $800 | +400 attendees | 4 |
| E19 | National Touring Band | $8,000 | +8,000 attendees | 5 |
| E20 | Chart-Topping Artist | $200,000 | +100,000 attendees | 6 |

**Player reads:** "Mom & Pop Band brings 15 extra people to tonight's show."

**Strategic note:** Live Acts are like flexible marketing — they add attendees without using marketing caps. Useful for packing shows when marketing is maxed.

### Specialist — Professional multiplies firework effectiveness

| ID | Name | Cost | Effect | Min Zone |
|----|------|-----:|--------|---------:|
| E21 | Pyro-Choreographer | $8,000 | +30% to all firework stats | 5 |
| E22 | Master Pyrotechnician | $150,000 | +60% to all firework stats | 6 |

**Player reads:** "Pyro-Choreographer makes every firework 30% more effective across the board."

**Strategic note:** Only useful if firing many fireworks. Scales with your show size.

---

## UPGRADES (13 items)

Permanent purchases. Chains REPLACE previous tier (you own only the highest tier in each chain).

### Marketing Upgrades (STACK — target different marketing items)

Different strategic patterns for each to create varied playstyles.

| ID | Name | Cost | Effect | Min Zone | Pattern |
|----|------|-----:|--------|---------:|---------|
| U1 | Mailing List | $100 | +3 attendees baseline per show + Flyers give 50% more | 1 | Baseline + Multiplier |
| U2 | Website | $2,500 | Community Newsletter cap 5→8 + Newsletters give 30% more | 2 | Cap + Multiplier |
| U3 | Social Media Presence | $25,000 | Social Media Campaign gives 50% more | 3 | Pure Multiplier |
| U4 | Radio Partnership | $500,000 | Radio Spots cost -30%, Billboards cost -20% | 4 | Cost Reducer |
| U5 | TV Network Deal | $30,000,000 | +5,000 attendees baseline per show + TV Commercial 30% more | 5 | Baseline + Multiplier |
| U6 | Live Stream Setup | $100,000,000 | Streaming Partnership cap 2→5 + 30% more effective | 5 | Cap + Multiplier |

**Player reads each clearly:**
- Mailing List: "3 extra attendees every show, and each Flyer brings 7-8 people instead of 5"
- Website: "Can buy up to 8 Community Newsletters per night (was 5), each bringing 32 people instead of 25"
- Social Media Presence: "Each Social Media Campaign brings 7,500 people instead of 5,000"
- Radio Partnership: "Radio Spots now cost $420 instead of $600. Billboards cost $1,200 instead of $1,500"
- TV Network Deal: "5,000 extra attendees every show, and each TV Commercial brings 19,500 people instead of 15,000"
- Live Stream Setup: "Can buy up to 5 Streaming Partnerships per night (was 2), each bringing 2.6M people instead of 2M"

**Marketing upgrades STACK because they target different consumables.** Owning Mailing List AND Website AND Social Media Presence all simultaneously is fine — they each improve different marketing items.

### Revenue Upgrades — Better Stage = More Tips (REPLACE chain)

All boost Tips permanently. Each replaces the previous.

| ID | Name | Cost | Effect | Min Zone |
|----|------|-----:|--------|---------:|
| U7 | Portable Stage | $5,000 | All tips +15% permanently | 2 |
| U8 | Professional Stage | $150,000 | All tips +35% permanently (replaces Portable) | 3 |
| U9 | Custom Arena | $15,000,000 | All tips +60% permanently (replaces Professional) | 4 |
| U10 | World Stage | $2,000,000,000 | All tips +100% permanently (replaces Custom) | 5 |

**Player reads:** "Professional Stage gives you +35% tips on every show forever. Replaces your Portable Stage."

**Why replacement:** Each upgrade is just "a better version of the same thing." Stacking them wouldn't make narrative sense — you only have one stage at your show.

### Crew Upgrades — Better Crew = Better Everything (REPLACE chain)

All boost all three stats permanently. Each replaces previous.

| ID | Name | Cost | Effect | Min Zone |
|----|------|-----:|--------|---------:|
| U11 | Local Assistant | $2,500 | All firework stats +10% permanently | 2 |
| U12 | Pyrotechnic Crew | $100,000 | All firework stats +25% permanently (replaces Local Assistant) | 3 |
| U13 | Production Team | $10,000,000 | All firework stats +40% permanently (replaces Pyrotechnic Crew) | 4 |

**Player reads:** "Production Team gives +40% to all firework stats forever. Replaces your Pyrotechnic Crew."

**Note:** Specialist enhancements (Pyro-Choreographer, Master Pyrotechnician) are PER-NIGHT all-stat boosts. Crew upgrades are PERMANENT all-stat boosts. They stack — you can have both active (one-night specialist + permanent crew).

---

## REMOVED ITEMS

- **Research Lab** ($50B, unclear purpose) — deleted
- **Fireworks Stage** ($75K, vague effect) — deleted
- **Infrastructure category** (empty after removals) — deleted

---

## UI DISPLAY GUIDELINES

### Enhancement pills on planning screen

Each pill shows the plain effect:

```
SNACKS    [None] [Candy +$0.20/att $3] [Vending +$0.50/att $15]
MUSIC     [None] [Boombox +0.3 ret/att $10] [Basic PA +0.8 ret/att $75]
HOST      [None] [Local MC +0.5 reach/att $10] [Announcer +1 reach/att $50]
LIVE ACTS [None] [Mom & Pop +15 att $25]
SPECIALIST [None] [Pyro-Chor +30% stats $8K]
```

Abbreviations used:
- "att" → "attendee" (singular, in pill context "per att" is clear)
- "ret" → "retention"
- "stats" → umbrella for all three

If space allows, write full words:
- "+$0.20 tips per attendee"
- "+0.3 retention per attendee"

### Info modal

Info modal for enhancement shows full plain language description with no abbreviations.

---

## PLAYER-FACING NARRATIVE

The game's economic logic in one paragraph:

> You fire fireworks to produce three audience reactions: **tips** (money tonight), **reach** (new fans spread through word of mouth), and **retention** (memorable moments that bring existing fans back). Your fireworks each have these three stats. You can supplement with snacks to boost tips, music to boost retention, hosts to boost reach, live acts to bring more people directly, and specialists to multiply everything. Marketing gets people there in the first place. Upgrades give you permanent bonuses that compound over the long run.

Every purchase has a clear mechanical effect that feeds into this narrative.

---

## SIMULATION TUNING NOTES

The balance agent should validate:

1. **Attendance math works at every zone** — walk-up + passive + marketing + live acts = plausible crowds
2. **Each enhancement is profitable at min_zone** — verified via break-even in this doc
3. **Upgrades create meaningful decisions** — replacement chains mean player can't stack revenue/crew, creating real "when to upgrade" choices
4. **Marketing upgrades with varied patterns** create distinct strategic paths
5. **Five strategies still differentiate** — Mogul, Rush, Spectacle, Completionist, Cheapskate all produce distinct outcomes

Balance levers available:
- Firework base stats (tips/reach/retention values per firework)
- REACH_TO_FAN_RATIO global constant
- Zone-specific retention star thresholds
- Zone effectiveness falloff curve
- Enhancement bonus magnitudes
- Upgrade multiplier percentages

Tune these until strategy outcomes match targets (~50% Mogul true ending, etc.).

---

## COMPLETE INVENTORY

- **Marketing:** 9 items
- **Enhancements:** 22 items (5 categories)
  - Snacks: 5
  - Music: 5
  - Host: 5
  - Live Acts: 5
  - Specialist: 2
- **Upgrades:** 13 items (3 categories)
  - Marketing: 6 (stack)
  - Revenue: 4 (replace chain)
  - Crew: 3 (replace chain)

**Total: 44 distinct purchasable items across the game.**

Every item has a clear strategic purpose, plain-language description, and math that holds up at its intended zone.
