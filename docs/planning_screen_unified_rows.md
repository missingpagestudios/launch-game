# LAUNCH Stage 2 — Planning Screen Unified Row Design

**Context:** Current planning screen has inconsistent design languages — fireworks are compact rows, marketing is bordered cards, enhancements are pill buttons, upgrades are tall cards. This spec unifies everything into a single row pattern across all panels.

**Goal:** One visual language for all selectable items. Players learn the pattern once, apply it everywhere. Massive density improvement allows all three panels to be taller and show more content without scrolling.

---

## CORE PRINCIPLE

Every selectable item in the game is a **compact horizontal row** (~60-64px tall) with a consistent structure:

```
[stripe] [icon] Name           [meta info]            [action]
```

Where:
- **stripe:** 4px vertical color bar at left edge (tier color, category color, or state color)
- **icon:** Optional small pixel art (tier badge, category icon, lock, check) — 24×24
- **Name:** Primary text — 22px cream_bright
- **meta info:** Cost, stats, description, status — 18px text with color hierarchy
- **action:** Quantity stepper [-] N [+], or BUY button, or selection state, or just $cost

This pattern is used for fireworks, marketing items, enhancement options, and upgrades. Same height, same structure, same interaction model.

---

## PART 1: TALLER PANELS

Update vertical layout to give panels more room:

### New vertical breakdown

```
y=0   → 60   Top bar (60px, unchanged)
y=60  → 70   Atmospheric strip (10px — was 16px)
y=70  → 650  UI panels (580px tall — was 444px)
y=650 → 720  Bottom bar (70px) with 8px atmospheric strip above it visible at edges
```

This gains 136px of panel content area. Trade: less foreground silhouette visible, but with denser rows the panels become much more useful.

### Per-panel changes

All three panels grow from 444px to 580px tall. The Fireworks panel can show ~7-8 rows visible. Marketing+Enhancements can show all options without scrolling at Zone 1-3. Upgrades shows all sections cleanly.

---

## PART 2: UNIFIED ROW SPECIFICATION

### Standard Row (use everywhere)

**Dimensions:**
- Height: 64px
- Top/bottom padding: 12px (40px content area)
- Left padding after stripe: 8px
- Right padding: 8px
- Gap between rows: 4px

**Structure (left to right):**

1. **Color stripe** (4px wide, 64px tall)
   - Color depends on item type and state (see Color Stripe System below)

2. **Lead icon** (24×24, optional)
   - Tier badge for fireworks (`t1.png`-`t4.png`)
   - Category icon for upgrades (`speaker.png`, `house.png`, `fans.png`, `money.png`)
   - Lock icon for locked items (`lock.png`)
   - Check icon for owned/selected (`check.png`)
   - 12px gap after icon

3. **Name** (22px cream_bright m6x11plus)
   - Truncate with "…" if too long for available space
   - 12px gap after name

4. **Meta info** (18px, color-coded)
   - Cost: gold (`#FFD700`)
   - Effect/stat: cream_bright
   - Tags/category: cream_muted
   - Format: `cost · effect · tags`
   - Truncate with "…" on overflow

5. **Spacer** (flex, pushes action to right)

6. **Action element** (right-aligned)
   - Quantity stepper for purchasable items: `[-]  N  [+]` (~80px wide)
   - BUY button for upgrades: 64×28px gold-bordered button
   - Selection state indicator for enhancements: check icon or empty
   - Cost preview for selected items: gold value

### Color stripe system

The 4px left-edge stripe communicates state at a glance:

**For fireworks:**
- T1: `#A07050` (bronze)
- T2: `#B0B8C0` (silver)
- T3: `#D4AF37` (gold)
- T4: `#5FC8D8` (cyan)

**For marketing:**
- Default: `#8A8570` (cream_muted — neutral marketing)
- Selected (qty > 0): `#FFD700` (gold)

**For enhancements:**
- Unselected: `#4A4838` (dim — dormant option)
- Selected: `#FFD700` (gold — active choice)

**For upgrades:**
- Owned: `#FFD700` (gold — purchased)
- Available affordable: `#F5E6D0` (cream_bright — purchasable)
- Available unaffordable: `#8A8570` (cream_muted — out of reach for now)
- Locked: `#4A4838` (dim — not unlocked)

**For locked items (any type):**
- Replace stripe with `lock.png` icon (16×16) in the stripe position
- Rest of row dims appropriately

### Row state variants

**Default:**
- Background: `rgba(26, 32, 72, 0.85)` (translucent card navy)
- Stripe at full color
- Text at normal brightness

**Hover:**
- Background: `rgba(42, 48, 85, 0.92)` (brighter)
- Stripe unchanged

**Selected (qty > 0 OR selected enhancement OR owned upgrade):**
- Background: `rgba(26, 32, 72, 0.95)` (more opaque)
- Stripe in gold (`#FFD700`)
- Quantity number in gold (if stepper present)
- Optional: subtle 1px gold border around row

**Unaffordable (would exceed cash if more added):**
- Background: `rgba(18, 24, 56, 0.7)` (dimmer)
- Stripe desaturated (50% alpha)
- All text muted (`#8A8570`)
- [+] button disabled

**Locked:**
- Background: `rgba(18, 24, 56, 0.5)` (very dim)
- Stripe replaced with `lock.png` icon
- All text dim (`#4A4838`)
- No interactive controls — replaced with text "Unlocks at Zone X"

---

## PART 3: FIREWORKS PANEL

Already mostly correct. Just verify the implementation matches the unified row spec exactly.

### Layout

```
┌──────────────────────────────────────────────────────────────┐
│ FIREWORKS                                                     │
│ Budget: $487,500                                              │
│                                                               │
│ ▌ [t1] Sparkler        $2 · 1 eng · classic   [-] 0 [+] [i]  │
│ ▌ [t1] Firecracker     $3 · 2 eng · loud      [-] 0 [+] [i]  │
│ ▌ [t1] Snake           $4 · 1 eng · ground    [-] 0 [+] [i]  │
│ ▌ [t1] Smoke Bomb      $4 · 2 eng · smoke     [-] 0 [+] [i]  │
│ ▌ [t1] Bottle Rocket   $5 · 2 eng · classic   [-] 0 [+] [i]  │
│ ▌ [t1] Spinner         $6 · 3 eng · spinning  [-] 0 [+] [i]  │
│ [more rows...]                                                │
│                                                               │
│ ─────────────────────────────────                             │
│ Total: 80 fireworks · Spent: $210                             │
└──────────────────────────────────────────────────────────────┘
```

### Notes specific to fireworks

- **Info button (`[i]`):** Small icon button at far right, opens preview modal for that firework
  - Use the new `info.png` icon (see Part 7: Asset Needs)
  - 24×24 button area, 16×16 icon centered
  - Hover: cream_bright tint, subtle border
  - Click: opens modal showing single firework animation + description
  - Icon comes BEFORE the quantity stepper visually (left of [-] [N] [+])... actually no, AFTER — far right corner, separated from quantity by 8px

Revised order for firework rows: `stripe | tier_icon | name | stats | qty stepper | info_button`

### Visible rows

With 580px panel height minus header/budget/totals, you get ~7-8 rows visible at 64px each + 4px gaps. That's the sweet spot — players see enough of their options without scrolling.

---

## PART 4: MARKETING + ENHANCEMENTS PANEL

Replace BOTH the bordered marketing cards AND the pill button enhancements with unified rows.

### Layout

```
┌──────────────────────────────────────────────────────────────┐
│ MARKETING / ENHANCEMENTS                                      │
│                                                               │
│ MARKETING                                                     │
│ ▌ Flyers           +5 att · cap 20         $5    [-] 0 [+]   │
│ ▌ Local Radio      +20 att · cap 60        $50   [-] 0 [+]   │
│ ▌ Newspaper Ad     +50 att · cap 150       $120  [-] 0 [+]   │
│                                                               │
│ ENHANCEMENTS  (one per category)                              │
│                                                               │
│ Snacks                                                        │
│ ▌ None                                              ✓        │
│ ▌ Candy from Store     +5% tips             $20             │
│ ▌ Premium Snacks       +12% tips            $50             │
│                                                               │
│ Sound                                                         │
│ ▌ None                                              ✓        │
│ ▌ Boombox              +5% engagement       $50             │
│ ▌ Basic PA             +15% engagement      $300            │
│                                                               │
│ Host                                                          │
│ ▌ None                                              ✓        │
│ ▌ Local MC             +5% engagement       $50             │
│ ▌ Pro Host             +20% engagement      $200            │
│                                                               │
│ ─────────────────────────────────                             │
│ Marketing: +30 att · $15 · Enhancements: 1 selected · $50    │
└──────────────────────────────────────────────────────────────┘
```

### Marketing rows

- Same row structure as fireworks
- No tier badge (marketing doesn't have tiers)
- Stripe color: cream_muted default, gold when qty > 0
- Action: quantity stepper [-] N [+] (marketing has quantities)
- Cost preview shows total cost when qty > 0

### Enhancement rows

- Subsection headers: "Snacks", "Sound", "Host" (18px cream_muted, before each category)
- Each enhancement is a row
- Action: check icon (`check.png` 16×16) on the right when selected, empty space when not
- Click row to select (mutex within category — selecting one auto-deselects others in same category)
- "None" is the default selected state
- Stripe color: dim when unselected, gold when selected

### Subsection header formatting

```
Snacks
─────
[3 enhancement rows]
```

- Header text: 18px cream_muted, 8px below previous content
- Optional: thin 1px line under header in cream_dim
- 4px gap before first row

### Bottom totals

- Combined summary at bottom: "Marketing: +30 att · $15 · Enhancements: 1 selected · $50"
- 18px text, cream_muted with values in cream_bright

---

## PART 5: UPGRADES PANEL

Replace tall upgrade cards with the unified row pattern.

### Layout

```
┌──────────────────────────────────────────────────────────────┐
│ UPGRADES                                                      │
│ [All] [Crew] [Infra] [Rev] [Mkt]                              │
│                                                               │
│ OWNED                                                         │
│ ▌ ✓ Flyer Printer    [speaker]   +2 att perm    owned       │
│                                                               │
│ AVAILABLE                                                     │
│ ▌ Local Assistant    [fans]      +10% eng       $1,500 [BUY] │
│ ▌ Website            [speaker]   +50 att perm   $8,000 [BUY] │
│ ▌ Production Team    [fans]      +5% eng all    $50K   [BUY] │
│                                                               │
│ LOCKED                                                        │
│ → Next unlock at Zone 2: Website (+50 attendees)             │
│                                                               │
│ 🔒 Pyrotechnic Crew  [fans]      Zone 3+                     │
│ 🔒 Drone Coord       [house]     Zone 5+                     │
│                                                               │
└──────────────────────────────────────────────────────────────┘
```

### Owned upgrade rows

- Stripe: gold (purchased)
- Lead icon: `check.png` (16×16) — gold checkmark
- Name: 22px cream_bright
- Category icon (`speaker.png`, etc.): 20×20 inline after name
- Effect summary: 18px cream_muted (e.g., "+2 att perm")
- Action: text "owned" in cream_dim, right-aligned

### Available upgrade rows (the workhorse)

- Stripe: cream_bright if affordable, cream_muted if not
- Lead icon: category icon (24×24)
- Name: 22px cream_bright (or muted if unaffordable)
- Effect summary: 18px (cream_bright if affordable, cream_muted if not)
- Action: cost in gold + BUY button (gold border, gold text)
  - Affordable: BUY button enabled, hover turns gold fill
  - Unaffordable: BUY button disabled (dim, no border, not_allowed cursor)

### Locked upgrade rows

- Stripe: replaced with `lock.png` (16×16) in stripe position
- Name: 18px cream_dim (smaller and dimmer than available)
- Category icon: shown but desaturated/muted
- No effect description (just placeholder unlock condition)
- Action: text "Zone X+" in cream_muted, right-aligned
- Tooltip on hover: "Unlocks at Zone N: [full description and effect]"

### Next unlock callout

Above the locked rows list:

```
→ Next unlock at Zone 2: Website (+50 attendees permanent)
```

- 18px cream_bright text
- `rightarrow.png` icon at start (16×16)
- Highlights the immediately upcoming unlock so players have something to anticipate

### Filter tabs

Keep the existing tab pattern at the top (All, Crew, Infra, Rev, Mkt). Each tab filters the list to show only matching upgrades. This pattern is already working.

---

## PART 6: BOTTOM BAR REFINEMENTS

### Layout

```
┌──────────────────────────────────────────────────────────────┐
│ Pick at least one firework to fire your show.                │
│ Spend: $0  →  Cash after: $10              [→ RUN SHOW]      │
└──────────────────────────────────────────────────────────────┘
```

### Money treatment

- "Spend: $X" — value color depends on state:
  - $0: cream_bright/white
  - > 0 within budget: gold (`#FFD700`)
  - > cash (overspend): pink_red (`#FF5A6A`) bold
- "Cash after: $X" — always cream_bright, only shown when Spend > 0
- When Spend = $0, just show "Cash: $10"

### Run Show button

- Use `rightarrow.png` icon as prefix
- Text: "RUN SHOW" (uppercase)
- Primary button styling (gold border, gold text default, gold fill on hover)
- Disabled when no fireworks selected (with tooltip: "Pick at least one firework")

---

## PART 7: ASSET NEEDS

### NEW asset needed: Info icon

Need a small pixel art info icon for the per-firework preview button.

**Specs:**
- 64×64 source PNG, transparent background
- Cream colored circle (`#F5E6D0`) with dark "i" inside (`#0A1028`)
- OR cream "i" with subtle border circle around it
- Match the visual weight of other icons in the set

**Generation prompt for ChatGPT:**

> A small pixel art info icon — a circle with a lowercase "i" inside, classic information/help symbol. The circle is filled with cream color (#F5E6D0). The "i" inside is dark navy (#0A1028) — a chunky pixel "i" with a small dot above and a vertical line below.
>
> Style: pixel art matching the previously generated UI icons (lock, check, plus, arrow). Crisp pixel edges, no anti-aliasing, chunky pixel style, 16×16 design scaled to 64×64 image with visible pixel structure.
>
> Background: pure black (#000000) for transparency removal.
>
> Output: 1024×1024 square, with the icon centered at large scale.

After generation, key out black background → save as `info.png` → drop in `assets/images/`.

### Existing assets being used

All previously generated icons are in play:
- `t1.png` through `t4.png` — tier badges
- `money.png`, `fans.png`, `house.png`, `speaker.png` — categories
- `lock.png`, `check.png` — state indicators
- `rightarrow.png`, `plus.png` — action icons
- `starfull.png`, `starempty.png` — saved for Results screen

Plus the new `info.png` to be generated.

---

## PART 8: TYPOGRAPHY ADJUSTMENTS

With everything as compact rows, some font sizes need slight tweaks:

- Panel headers (FIREWORKS, MARKETING / ENHANCEMENTS, UPGRADES): **28px** cream_bright
- Section headers (OWNED, AVAILABLE, LOCKED, MARKETING, ENHANCEMENTS): **20px** cream_bright (was 16px — bumping up since they're now meaningful section markers)
- Subsection headers (Snacks, Sound, Host): **18px** cream_muted
- Row name text: **22px** cream_bright
- Row meta info: **18px** with color hierarchy
- Total/summary text at panel bottoms: **18px** cream_muted with values in cream_bright
- Helper text "(one per category)": **16px** cream_dim
- Tab labels (All, Crew, etc.): **18px** cream_muted (active tab gold)

---

## IMPLEMENTATION PRIORITY

In order:

1. **Update vertical layout** — panels grow to 580px (~10 min)
2. **Marketing rows** — convert from cards to compact rows (~30 min)
3. **Enhancement rows** — convert from pills to compact rows with subsection headers (~45 min)
4. **Upgrade rows** — convert from cards to compact rows for Owned/Available/Locked (~60 min)
5. **Verify color stripe system** is consistent across all row types (~20 min)
6. **Generate and integrate info icon** for fireworks (parallel — ChatGPT generation + Photopea + drop in assets) (~15 min)
7. **Hook up info button** on firework rows (modal can be stub for now) (~30 min)
8. **Verify state variants** (default/hover/selected/unaffordable/locked) work consistently across all panels (~30 min)

Total: ~4 hours of focused work.

---

## VERIFICATION CHECKLIST

After implementation:

- [ ] All three panels are 580px tall, showing more content
- [ ] Fireworks panel shows ~7-8 rows visible, plus info button on each row
- [ ] Marketing items render as compact rows (not bordered cards)
- [ ] Enhancement options render as compact rows (not pill buttons)
- [ ] Subsection headers (Snacks, Sound, Host) clearly separate enhancement categories
- [ ] All upgrades render as compact rows (not tall cards)
- [ ] Color stripes communicate state consistently:
  - Tier color for fireworks
  - Gold for selected/owned items
  - Dim for unselected/locked
  - Lock icon replaces stripe for locked items
- [ ] Hover state visible on all rows (background brightens)
- [ ] Selected state visible on all selectable rows (gold stripe + emphasized text)
- [ ] Locked items appropriately dimmed
- [ ] BUY buttons on upgrade rows have clear affordable vs. unaffordable states
- [ ] Info icon button visible on each firework row, separate from quantity stepper
- [ ] Bottom totals/summaries readable at panel bottom
- [ ] Visual language is unified — fireworks rows, marketing rows, enhancement rows, and upgrade rows all look like variations of the same pattern

---

## WHAT'S NOT CHANGING

Don't touch these — they're working:

- Three-panel layout structure
- Atmospheric layered background
- Translucent panel approach
- Top bar (Night, Zone, Cash with money icon, Fans with progress)
- Color palette
- Filter sub-tabs in Upgrades panel
- m6x11plus font

The screen architecture is solid. This change is purely about unifying the row design language across all three panels' contents.

---

## EXPECTED OUTCOME

After this change, the planning screen should:

1. Feel cohesive — one visual language everywhere
2. Show more content per panel — ~7-8 fireworks, all marketing+enhancements visible at once at low zones, more upgrades visible
3. Be easier to scan — same row pattern means players' eyes know where to look
4. Look more professional — design consistency is the #1 indicator of polish

This is the change that should take the screen from "functional but inconsistent" to "designed with intent." If after this it still doesn't feel right, we know the issue is creative direction (visual aesthetic), not layout/UX.
