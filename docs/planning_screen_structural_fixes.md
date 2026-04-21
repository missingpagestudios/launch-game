# THE LAST SHOW — Planning Screen Structural Fixes

**Context:** Previous polish rounds addressed symptoms. This round addresses the architectural issues causing those symptoms: typography hierarchy is wrong, tabs are unnecessary, and the bottom bar lacks basic design fundamentals.

**This supersedes specific sizing/styling guidance in previous documents where conflicts exist.**

---

## THE CORE ISSUE: TYPOGRAPHY HIERARCHY

Previous specs treated this like a web dashboard (small uppercase labels, minimal weight differences). This is a GAME UI. Game UIs use strong visual hierarchy with meaningful size and weight differences.

### Correct hierarchy

**Level 1: Panel Titles**
- "FIREWORKS", "MARKETING & ENHANCEMENTS", "UPGRADES"
- Inter 20px, weight 700 (bold)
- Color: `TEXT_PRIMARY` (#F0F0F0)
- Letter-spacing: 1px (not 2px)
- These are the most visually prominent elements in each panel

**Level 2: Section Headers**
- "MARKETING", "ENHANCEMENTS", "OWNED", "AVAILABLE", "LOCKED"
- Inter 13px, weight 600 (semibold), uppercase
- Color: `ACCENT_AMBER` (#FFB84D) — amber-tinted for visual distinction from panel titles
- Letter-spacing: 1.5px
- Clear secondary hierarchy — you know these are subdivisions

**Level 3: Subsection Labels**
- "SNACKS", "SOUND", "HOST" (within Enhancements)
- Inter 11px, weight 600, uppercase
- Color: `TEXT_MUTED` (#888888)
- Letter-spacing: 1px

**Level 4: Item Names**
- "Sparkler", "Firecracker", "Flyer Printer", etc.
- Inter 15px, weight 500 (medium)
- Color: `TEXT_PRIMARY`

**Level 5: Item Meta / Values**
- Costs, effects, descriptions
- Inter 13px, weight 400 (regular)
- Color: `TEXT_SECONDARY` (#B8B8B8)
- Amber (#FFB84D) for cost values specifically

**Level 6: Labels / Hints**
- "one per category", "Zone 2+", etc.
- Inter 11px, weight 400
- Color: `TEXT_MUTED` (#888888)

### The fundamental rule

**Panel titles should be AS LARGE as item names.** Not half the size. Currently panel titles at 11px and item names at 14px means items look more important than titles. This inverts hierarchy.

Fix: panel titles at 20px (larger than item names), section headers at 13-14px (smaller than items but clearly distinguished by color/weight).

---

## REMOVE TABS FROM UPGRADES PANEL

Tabs add visual complexity for no real benefit. With three sections (Owned/Available/Locked), players naturally scan the panel. Category filtering via tabs adds a layer of interaction that isn't needed.

**Replace tab UI with:**

```
UPGRADES

OWNED · 0
  (empty state text: "No upgrades yet — buy your first below.")

AVAILABLE · 1
  [Flyer Printer row with BUY button]

NEXT UNLOCK
  → Website at Zone 2

LOCKED · 14
  [Website row]
  [Portable Stage row]
  [Local Assistant row]
  [Social Media Accounts row]
  [... all locked rows]
```

**Rationale:**

- Three clear sections. No categorization needed.
- Player scrolls the entire panel. Natural scanning.
- Each upgrade row shows its category as a small tag on the right side (e.g., "MKT", "CREW") if category info is useful.
- Locked rows stay sorted by unlock requirement (Zone 2 first, then Zone 3, etc.)

**Category tag on row (optional):**
- Small text tag on right side of row: "MKT" in 10px `TEXT_DIM`
- Doesn't dominate, just provides context
- Could also be an icon if we have clean icons

This frees up ~40px of vertical space from the tab bar AND eliminates the "what does MKT mean" problem.

---

## FIX THE BOTTOM BAR FROM SCRATCH

The bottom bar is not working. Instead of iterating the current version, rebuild it with proper structure.

### Required structure

```
┌─────────────────────────────────────────────────────────────────┐
│                                                                  │
│  SELECT FIREWORKS TO CONTINUE                                    │
│  Spend $0 · Cash $10                           [☰]  [▶ RUN SHOW]│
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### Exact specifications

**Bottom bar overall:**
- Height: 84px (increase from 72px for proper breathing room)
- Background: `rgba(15, 20, 35, 0.85)`
- Border top: 1px `rgba(255, 255, 255, 0.08)`
- Padding: 16px 24px (vertical padding gives content room to breathe)
- Display: flex, align-items: center, justify-content: space-between

**Left content (informational):**
- Container: flex column, gap 4px

- Hint text "SELECT FIREWORKS TO CONTINUE" or "READY TO RUN SHOW":
  - Inter 11px, weight 500, uppercase
  - Letter-spacing: 1.5px
  - Color: `TEXT_MUTED` (#888888)

- Summary text "Spend $0 · Cash $10":
  - Inter 14px, weight 400
  - Color: `TEXT_SECONDARY` (#B8B8B8)
  - Amber (#FFB84D) for dollar values specifically

**Right content (actions):**
- Container: flex row, gap 12px, align-items: center

**Menu button (hamburger):**
- Size: 40×40 (square)
- Background: transparent
- Border: **NONE** (no border at all)
- Icon: hamburger lines, color `TEXT_MUTED` (#888888), 18px size
- Hover:
  - Background: `rgba(255, 255, 255, 0.05)`
  - Icon color: `TEXT_PRIMARY`
- Border-radius: 6px
- Cursor: pointer

**Run Show button:**
- Size: height 48px, width: auto (min 180px)
- Padding: 0 32px (horizontal)
- Border-radius: 6px
- Font: Inter 15px, weight 600
- Letter-spacing: 0.5px
- Display: flex, align-items: center, justify-content: center, gap 10px (for icon)

**Disabled state (no fireworks selected):**
- Background: `rgba(255, 184, 77, 0.1)`
- Border: 1px solid `rgba(255, 184, 77, 0.3)`
- Text color: `rgba(255, 184, 77, 0.5)`
- Cursor: not-allowed

**Enabled state (ready to run):**
- Background: `#FFB84D` solid
- Border: none
- Text color: `#0F1423` (dark navy)
- Box-shadow: `0 2px 8px rgba(255, 184, 77, 0.25)`
- Cursor: pointer

**Enabled hover:**
- Background: `#FFC864`
- Transform: translateY(-1px)
- Box-shadow: `0 4px 12px rgba(255, 184, 77, 0.4)`

**The arrow icon inside the button:**
- Same color as the text
- Size: 16px
- Positioned after "RUN SHOW" text with 10px gap

### Why the hamburger needs no border

The hamburger with a visible border looks like a boxed-in widget. Borderless (transparent until hover) lets it feel like an unobtrusive secondary control. It's "just there" — not demanding attention.

The Run Show button EARNS its prominence through solid amber fill. The hamburger doesn't need a border to compete.

---

## TOP BAR POLISH

The top bar is mostly working. Minor fixes:

**"NIGHT 1" unification:**
- Both elements use Inter, weight 600
- "NIGHT": 11px, uppercase, letter-spacing 1.5px, color `TEXT_MUTED`
- "1": 18px, color `TEXT_PRIMARY`
- Same font family, differentiated only by size and color

**Zone indicator pill:**
- Current treatment is fine but ensure text is readable
- "ZONE 1" label in 11px amber uppercase
- "Backyard" in 15px medium `TEXT_PRIMARY`

**Right side:**
- Fans icon + "0 / 20 fans" + progress bar
- Cash: just "$10" in amber, 18px weight 600, no duplicate dollar icon

---

## MARKETING & ENHANCEMENTS PANEL

Current structure is close. Final refinements:

### Marketing row

Keep compact row format:

```
[Flyers]  [$10 · +5 att]  [qty stepper]
```

- Flyers name: Inter 15px medium, `TEXT_PRIMARY`
- Cost/effect: "$10 · +5 att" — 13px regular, amber for cost, muted for effect
- Stepper on right

### Enhancement pills

Show effect inline (as specified in polish round 2). Example:

```
SNACKS    [None]  [Candy +5% tips $20]  [Vending +10% tips $100]
```

Pills are horizontal, one row per category. Categories (SNACKS/SOUND/HOST) are subsection labels in 11px amber uppercase.

### Pill styling refinements

- Height: 32px
- Padding: 8px 14px
- Border-radius: 4px
- Inter 12px medium (slightly smaller to fit more text)
- Text format: `{Name} {Effect} {Cost}` — short name, compact effect, amber cost
- Selected: solid amber background, dark text
- Unselected: transparent, subtle border, muted text
- "None": always present, amber when selected (default)

---

## FIREWORK ROWS

Working well. Final verification:

- Row height: 52px
- Tier color stripe at left (3px wide, full height)
- Name: Inter 15px medium, `TEXT_PRIMARY`
- Cost: Inter 13px semibold, amber
- Quantity stepper: compact, consistent button style
- Info button: clean circle, hover shows amber

No stats shown on rows (confirmed decision — stats in modal only).

---

## UPGRADE ROWS

**Available row structure:**

```
[icon] Flyer Printer                    $500  [BUY]
       +2 attendees permanent      MKT
```

- Icon (from new modern icons or placeholder): 28x28 on left
- Name: Inter 15px medium, `TEXT_PRIMARY`
- Description: Inter 12px regular, `TEXT_SECONDARY`
- Cost: Inter 14px semibold, amber
- Category tag: Inter 10px regular, `TEXT_DIM`
- BUY button: compact, amber styling

**Locked row structure:**

```
[lock] Website                          Zone 2+
```

- Lock icon: 20x20, muted color
- Name: Inter 14px medium, `TEXT_DIM`
- Unlock requirement: Inter 12px regular, `TEXT_DIM`

**Owned row structure:**

```
[check] Flyer Printer                   OWNED
```

- Check icon in amber
- Name: `TEXT_PRIMARY`, slight amber tint
- "OWNED" label: 10px uppercase amber

---

## COLOR VARIATIONS CHECK

One important thing to verify: **every amber element must render at exactly `#FFB84D`**. If colors look slightly different shades in different places, investigate:

1. Opacity stacking — amber on a translucent panel might render differently
2. Theme overrides — some elements might use a slightly different hex
3. Font rendering — subpixel antialiasing can shift perceived color

To audit: use a color picker on a screenshot and check every amber pixel. They should all be identical or within 1-2 RGB values.

---

## VERIFICATION

After implementation:

**Typography:**
- [ ] Panel titles (FIREWORKS, etc.) are clearly the largest/most prominent text in their panels
- [ ] Section headers (MARKETING, OWNED, etc.) are amber-tinted and distinct from panel titles
- [ ] Item names are readable but don't compete with panel titles
- [ ] Clear visual hierarchy from largest (panel titles) to smallest (labels/hints)

**Upgrades panel:**
- [ ] No tab bar (removed)
- [ ] Sections stacked vertically: Owned / Available / Next Unlock / Locked
- [ ] Panel scrolls naturally
- [ ] Each row has appropriate styling for its state

**Bottom bar:**
- [ ] Taller (84px), proper padding
- [ ] Hamburger button has NO border, transparent until hover
- [ ] Run Show button clearly enabled vs disabled
- [ ] When enabled: solid amber background, dark text, commanding presence
- [ ] Clear hierarchy: dim hint < summary < hamburger < Run Show

**Enhancement pills:**
- [ ] Show effect inline ("+5% tips")
- [ ] Clear selected vs unselected states
- [ ] Fit within panel width

**Amber consistency:**
- [ ] All amber elements render at exactly #FFB84D
- [ ] No variations or tints

---

## IMPLEMENTATION TIME

Expect ~3-4 hours for this round. Biggest chunks:

1. Typography hierarchy rework (affects all panels) — ~60 min
2. Remove tabs, rework upgrades panel layout — ~45 min
3. Rebuild bottom bar with proper structure — ~45 min
4. Enhancement pills inline effect text — ~30 min
5. Amber color audit — ~20 min
6. Final polish and verification — ~30 min

---

## THE BIG PICTURE

The planning screen has good bones. The pivot from pixel UI to modern UI was correct. The atmospheric background works. The compact rows work.

What's failing is TYPOGRAPHIC HIERARCHY. Without it, everything blurs into similar visual weight and the eye doesn't know where to look.

After this round, the screen should have clear visual order: your eye goes PANEL TITLE → SECTION HEADER → ITEM NAME → META INFO, naturally following the hierarchy. Currently everything is similar sizes and the eye bounces around.

Make panel titles BIG. Make section headers AMBER. Make items MEDIUM. Make details SMALL.
