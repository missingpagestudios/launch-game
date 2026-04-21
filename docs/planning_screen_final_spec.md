# LAUNCH Stage 2 — Planning Screen Final Implementation Spec

This consolidates the UX overhaul, icon integration, and button styling into one comprehensive spec.

**Goal:** Transform Planning Screen from "functional UI" to "polished game screen" through compact rows, tier color signaling, integrated icons, and refined button styling.

---

## ASSETS AVAILABLE

The following icons have been added to `assets/images/` (64×64px each, transparent backgrounds):

- `t1.png` — Tier 1 badge
- `t2.png` — Tier 2 badge
- `t3.png` — Tier 3 badge
- `t4.png` — Tier 4 badge
- `fans.png` — People silhouettes (use for fan count display + crew category)
- `money.png` — Dollar sign (use for cash/money displays + revenue category)
- `house.png` — Building silhouette (use for Infrastructure category)
- `speaker.png` — Megaphone (use for Marketing category)
- `lock.png` — Padlock icon (use for locked items/upgrades/fireworks)
- `check.png` — Checkmark (use for owned upgrades, completed items)
- `starfull.png` — Filled star (use for quality ratings on Results screen, premium indicators)
- `starempty.png` — Empty star outline (use for unfilled quality ratings)
- `rightarrow.png` — Right-pointing arrow (use for "next/advance" buttons, Run Show button, "next unlock" callout)
- `plus.png` — Plus symbol (use optionally for [+] quantity buttons or "add" actions)

**Display sizing:** All icons are 64×64 source. Display at integer divisions for crisp pixel art:
- 64×64 (full size — rare, only for emphasis)
- 32×32 (most common — buttons, badges, headers)
- 16×16 (small — inline with text)

**Critical:** When importing these PNGs into Godot, set:
- Filter: Off (Nearest neighbor)
- Mipmaps: Off
- Compression: Lossless

This preserves the crisp pixel art. Default Godot import will smooth them.

---

## PART 1: COMPACT FIREWORK ROWS (Highest Impact)

Replace current tall firework cards with compact 64px rows showing more fireworks at once.

### Row layout (64px tall)

```
┌──────────────────────────────────────────────────────────────────────┐
│ ▌ Sparkler [t1.png]  $2 · 1 eng · classic, beginner   [-] 0 [+] $0 │
└──────────────────────────────────────────────────────────────────────┘
```

**Components left to right:**

- **4px vertical color stripe at left edge** — full row height, color indicates tier
- **8px gap**
- **Firework name** — 22px cream_bright, m6x11plus
- **8px gap**
- **Tier badge image** — `t1.png`/`t2.png`/`t3.png`/`t4.png` displayed at 24×24 (downscaled from 64)
- **12px gap**
- **Stats line** — 18px text: cost in gold, " · ", engagement in cream, " · ", tags in cream_muted
- **flex spacer pushing right**
- **Quantity stepper** — `[-]` button, number display, `[+]` button (compact, ~80px total)
- **8px gap**
- **Cost preview** — 18px gold, right-aligned (shows "$60" when qty > 0, blank when 0)
- **8px right padding**

### Row dimensions

- Height: 64px
- Top/bottom padding: 12px (content area is 40px tall)
- Left padding after stripe: 8px
- Right padding: 8px
- Gap between rows: 4px

### Tier color stripes

Use these exact colors for the 4px-wide stripe at the left edge of each row:
- T1 (Beginner): `#A07050` (warm bronze)
- T2 (Standard): `#B0B8C0` (cool silver)
- T3 (Premium): `#D4AF37` (gold)
- T4 (Elite): `#5FC8D8` (cyan)

These same colors should appear in the tier badge images, but if they don't match exactly, the stripe is the primary tier signal.

### Row state variants

**Default (qty = 0):**
- Background: `rgba(26, 32, 72, 0.85)` (slightly translucent card navy)
- Tier stripe at full color
- Text at normal brightness

**Selected (qty > 0):**
- Background: `rgba(26, 32, 72, 0.95)` (more opaque)
- Tier stripe at full color (no change)
- Quantity number turns gold (`#FFD700`)
- Cost preview visible in gold
- 1px subtle gold border across full row (optional — test both ways)

**Hover (mouse over row):**
- Background: `rgba(42, 48, 85, 0.9)` (brighter)
- All other elements unchanged

**Unaffordable (qty selected exceeds cash):**
- Background: `rgba(18, 24, 56, 0.7)` (dimmer)
- Tier stripe desaturated 50%
- All text muted to `cream_muted`
- [+] button disabled

**Locked (tier not yet unlocked at current zone):**
- Background: `rgba(18, 24, 56, 0.5)` (very dim)
- Tier stripe replaced with lock icon (16×16)
- All text dim cream (`#4A4838`)
- No quantity controls — replaced with text "Unlocks at Zone X"

### Result

8-10 fireworks visible per scroll viewport (instead of 2-3 cards). Players scan a list with clear tier color identification at the left edge.

---

## PART 2: BUTTON STYLING SYSTEM

All buttons in the game use this consistent system. Implement via Godot's StyleBoxFlat in the theme.

### Primary Button (Run Show, Confirm, major actions)

**Dimensions:**
- Height: 48px
- Min width: 160px
- Horizontal padding: 32px
- Border radius: 0 (sharp pixel corners — no rounding)

**Default state:**
- Background: `rgba(26, 32, 72, 0.6)` (translucent night_near)
- Text: `#FFD700` (gold), 22px m6x11plus
- Border: 1px solid `#FFD700` (gold)
- Cursor: pointer

**Hover state:**
- Background: `#FFD700` (solid gold fill)
- Text: `#0A1028` (dark navy)
- Border: `#FFD700` (matches background)
- Subtle "press down" effect: text shifts down 1px

**Pressed state (mid-click):**
- Background: `#D4AF37` (slightly darker gold)
- Text: `#0A1028`
- Inset appearance (1-2px content offset)

**Disabled state:**
- Background: `rgba(18, 24, 56, 0.5)` (dim translucent)
- Text: `#4A4838` (dim cream)
- Border: none
- Cursor: not-allowed

### Secondary Button (Cancel, Back, settings actions)

**Dimensions:**
- Height: 40px
- Min width: 120px
- Horizontal padding: 24px

**Default state:**
- Background: transparent
- Text: `#8A8570` (cream_muted), 20px
- Border: 1px solid `#4A4838` (dim cream)

**Hover state:**
- Background: `rgba(18, 24, 56, 0.6)` (subtle fill)
- Text: `#F5E6D0` (cream_bright)
- Border: 1px solid `#8A8570`

**Pressed state:**
- Background: `rgba(42, 48, 85, 0.7)`
- Text: `#FFD700` (gold momentarily)

**Disabled state:**
- Background: transparent
- Text: `#4A4838`
- Border: 1px dotted `#4A4838`

### Quantity Buttons ([-] and [+])

**Dimensions:**
- 32×28px square-ish
- Used in tight quantity steppers

**Default state:**
- Background: `rgba(10, 16, 40, 0.7)` (dark)
- Text/symbol: `#F5E6D0` (cream), 18px
- Border: 1px solid `#2A3055` (edge navy)

**Hover state:**
- Background: `rgba(42, 48, 85, 0.9)`
- Text: `#FFD700` (gold)
- Border: 1px solid `#FFD700`

**Disabled state (e.g., [-] when qty = 0, [+] when can't afford more):**
- Background: `rgba(18, 24, 56, 0.4)`
- Text: `#4A4838` (dim)
- Border: 1px solid `#2A3055`
- Cursor: not-allowed

### Buy Button (on Upgrade cards)

**Dimensions:**
- 80×32px
- Sits at bottom-right of upgrade card

**Default state (affordable):**
- Background: `rgba(26, 32, 72, 0.6)`
- Text: `#FFD700`, 18px, "BUY" (uppercase)
- Border: 1px solid `#FFD700`

**Hover state:**
- Background: `#FFD700`
- Text: `#0A1028`

**Disabled state (unaffordable):**
- Background: `rgba(18, 24, 56, 0.5)`
- Text: `#4A4838`
- Border: none

### Pill Buttons (for Enhancements selection)

These are NEW — replacing the current checkbox approach for enhancements.

**Dimensions:**
- Height: 32px
- Horizontal padding: 12px
- Inline horizontal layout, multiple per row

**Default state (unselected):**
- Background: transparent
- Text: `#8A8570` (cream_muted), 18px
- Border: 1px solid `#4A4838` (dim cream)

**Hover state:**
- Background: `rgba(42, 48, 85, 0.4)`
- Text: `#F5E6D0`
- Border: 1px solid `#8A8570`

**Selected state:**
- Background: `rgba(255, 215, 0, 0.15)` (gold tint)
- Text: `#FFD700`
- Border: 1px solid `#FFD700`

**Selected + hover:**
- Background: `rgba(255, 215, 0, 0.25)` (slightly brighter)
- Text: `#FFD700`

### Icon-only Button (eye preview, pause menu, etc.)

**Dimensions:**
- 40×40px square
- Icon centered, 24×24

**Default state:**
- Background: transparent
- Border: 1px solid `#4A4838`
- Icon tint: `#8A8570`

**Hover state:**
- Background: `rgba(18, 24, 56, 0.6)`
- Border: 1px solid `#8A8570`
- Icon tint: `#F5E6D0`

**Active (when modal open or feature toggled):**
- Background: `rgba(255, 215, 0, 0.2)`
- Border: 1px solid `#FFD700`
- Icon tint: `#FFD700`

---

## PART 3: ICON INTEGRATION

### Tier badges in firework rows

Each firework row shows the appropriate tier badge:

```gdscript
# Pseudocode
var tier_badge = $Row/TierBadge  # TextureRect
match firework.tier:
    1: tier_badge.texture = load("res://assets/images/t1.png")
    2: tier_badge.texture = load("res://assets/images/t2.png")
    3: tier_badge.texture = load("res://assets/images/t3.png")
    4: tier_badge.texture = load("res://assets/images/t4.png")
tier_badge.size = Vector2(24, 24)  # Downscale from 64 source
```

**Display size: 24×24** (downscaled from 64 source). This works because the source pixels are large and downscale cleanly to integer divisions.

**Position:** Right of the firework name, separated by 8px gap.

### Money icon in top bar

Replace text-only "$10" cash display with icon + value:

```
[money.png 24×24]  $1,247,500
```

- Icon: 24×24 (downscaled from 64)
- Value: 32px gold m6x11plus, 8px to the right of icon
- Position: Top-right of top bar

### Fans icon in top bar

Replace text-only "Fans: 0" display with icon + value + progress:

```
[fans.png 16×16]  0 / 20  ▰▰▱▱▱▱▱▱▱▱
                            next: Neighborhood
```

- Icon: 16×16 (downscaled from 64)
- Count text: 18px cream_muted m6x11plus
- Progress bar: 80px wide, 4px tall, gold fill
- "next: X" label: 16px cream_dim, italic feel

### Category icons on Upgrade cards

For each upgrade card, show its category icon next to the category text:

```gdscript
match upgrade.category:
    "marketing": $CategoryIcon.texture = load("res://assets/images/speaker.png")
    "infrastructure": $CategoryIcon.texture = load("res://assets/images/house.png")
    # crew and revenue need icons too — currently we have:
    # speaker.png = marketing
    # house.png = infrastructure
    # NEED: crew icon (people), revenue icon (dollar sign)
    # Money.png could double as revenue
    # Fans.png could double as crew
```

**Note for asset planning:** We have `speaker.png` (marketing) and `house.png` (infrastructure), but need icons for "crew" and "revenue" categories. For now:
- Marketing → `speaker.png`
- Infrastructure → `house.png`
- Crew → use `fans.png` (people = crew, conceptually)
- Revenue → use `money.png` (dollar sign = revenue)

This reuses existing assets with logical mappings. Later we can generate dedicated crew/revenue icons if needed.

**Display size: 20×20** for inline category indicators on cards.

**Position:** Right of the category name on upgrade cards, replacing the current "[MKT]" text badge.

### Lock icon for locked items

Use `lock.png` wherever items/upgrades/fireworks are locked.

**Locations:**
- Locked firework rows: replace tier color stripe with lock icon (16×16)
- Locked upgrade rows: at the start of the row (16×16)
- Anywhere else "this is locked" needs to be communicated

**Display size:** 16×16 (downscaled from 64) inline with text

**Tint:** No tint needed — image is already the right muted color. If tinting is desired for emphasis, use `cream_dim` (`#4A4838`).

### Check icon for owned upgrades

Use `check.png` to indicate purchased/owned upgrades and completed enhancements.

**Locations:**
- Owned upgrade rows: at the start of the row (16×16)
- Selected enhancement pills: small check inside the pill next to the name
- "Selected" indicator on firework rows when qty > 0 (optional — could be tier stripe glow alternative)

**Display size:** 16×16 inline with text

**Tint:** Already gold in source. If tint applied, use `gold` (`#FFD700`).

### Right arrow icon

Use `rightarrow.png` for "next/advance/forward" actions.

**Locations:**
- **Run Show button:** prepend to the button text — `[rightarrow.png 20×20] RUN SHOW`
- **Next unlock callout in Locked section:** prepend to the callout — `[rightarrow.png 16×16] Next unlock at Zone 2: Website`
- **Future use:** Continue/Next buttons on results screen, ending screens

**Display size:** 16×16 inline with text, 20×20 inside large buttons

**Tint:** Match surrounding text color (gold in Run Show button, cream_bright in Locked callout)

### Plus icon (optional)

Use `plus.png` for [+] quantity buttons or "add" actions.

**Locations:**
- Could replace the text "+" character on quantity stepper buttons
- Could be used on "Add upgrade" type actions

**Recommendation:** Test both approaches — text "+" vs `plus.png`. Text "+" is simpler and renders cleanly via m6x11plus. Use the icon only if it adds visual clarity. For Stage 2, text "+" is probably fine.

**Display size if used:** 12×12 (inside small quantity buttons) or 16×16 (larger buttons)

### Star icons (Results screen, not Planning)

`starfull.png` and `starempty.png` are not used on the Planning Screen. They're for the **Results Screen** quality rating display — showing 1-5 stars based on show quality.

**Save these for the Results screen implementation.** Don't integrate them on the Planning Screen.

---

## PART 4: ENHANCEMENT PILL BUTTONS

Replace the current checkbox approach with horizontal pill button selection.

### Layout per category

```
Snacks:  [None ✓]  [Candy $20 · +5% tips]  [Premium $50 · +12% tips]

Sound:   [None ✓]  [Boombox $50 · +5% eng]  [PA $300 · +15% eng]

Host:    [None ✓]  [Local MC $50 · +5% eng]  [Pro Host $200 · +20% eng]
```

### Implementation

- Each category renders as a horizontal flex row
- Category label "Snacks:" / "Sound:" / "Host:" — 18px cream_muted, m6x11plus
- Pills (described in Part 2 Pill Buttons section) flex horizontally
- "None" pill is always present and selected by default
- Selecting another pill auto-deselects "None" and any other pills in the same category (mutex)
- Click "None" to deselect all and revert to no enhancement

### Pill content format

For each enhancement: `[Name $cost · +effect]`

Example: `[Candy $20 · +5% tips]`

If the pill is too wide, truncate description with ellipsis. Keep name and cost always visible.

---

## PART 5: UPGRADES PANEL HIERARCHY FIX

Current problem: Too much gray text everywhere. No clear hierarchy.

### Three-section visual hierarchy

**OWNED section:**
- Section label "OWNED" — 16px **cream_bright** (NOT muted — this is real info)
- Owned items use **bright text** because they're active/working
- Format: `✓ Flyer Printer ........ owned`
  - Checkmark icon (gold) — 16×16
  - Item name — 22px cream_bright
  - "owned" tag — 16px cream_muted (right-aligned, the only muted thing here)

**AVAILABLE section:**
- Section label "AVAILABLE" — 16px **cream_bright**
- Available cards use bright text and gold accents — these are exciting purchases
- Card layout (96px tall):
  ```
  [icon] Local Assistant          [Crew icon 20×20]
         $1,500
         +10% engagement on all shows
                                     [BUY]
  ```
  - Name — 22px cream_bright
  - Cost — 22px gold
  - Description — 18px cream_muted (description is OK to mute)
  - Buy button — gold border, gold text

**LOCKED section:**
- Section label "LOCKED" — 16px **cream_dim** (only THIS section's label is dim because contents are unreachable)
- Locked items use dim text because they're not yet meaningful
- Format: `🔒 Pyrotechnic Crew ........ Zone 3+`
  - Lock icon (cream_muted) — 16×16
  - Item name — 18px cream_dim (smaller and dimmer than available items)
  - Zone requirement — 16px cream_muted (right-aligned)

### Add: Next milestone callout

At the top of the LOCKED section (between section divider and first locked item):

```
─── LOCKED ───
↗ Next unlock at Zone 2: Website (+50 attendees permanent)

🔒 Pyrotechnic Crew    Zone 3+
🔒 Drone Coordination  Zone 5+
```

The callout uses cream_bright color with a small arrow icon, drawing the eye to the immediately upcoming unlock so players have a near-term goal.

---

## PART 6: HEADER ZONE PROGRESS

Update top bar fans display to show progress to next zone:

**Current:**
```
$10
Fans: 0
```

**New:**
```
[money.png] $10
[fans.png] 0 / 20  [▰▰▱▱▱▱▱▱▱▱]
                     next: Neighborhood
```

Components:
- Money icon (24×24) + cash value (32px gold)
- Fans icon (16×16) + count text "current / threshold" (18px cream_muted)
- Mini progress bar (80px × 4px), `night_deep` track, `gold` fill
- "next: [zone name]" label (16px cream_dim)

---

## PART 7: FOOTER MONEY TREATMENT

Differentiate Spend vs. Cash visually:

```
Spend: $0  →  Cash after: $10                         [▶ Run Show]
^^^^^^      ^^^^^^^^^^^^^^^^
white if 0   always cream_bright
gold if > 0
red if > cash
```

Logic:
- "Spend: $X" — value color depends on state:
  - $0 selected: white/`cream_bright`
  - $X > 0 (within budget): `gold` (`#FFD700`)
  - $X > cash (overspending): `pink_red` (`#FF5A6A`) and slightly bolder
- "Cash after: $X" — always `cream_bright`, calculated as cash - spend
- Arrow between (→) — small `cream_muted`

**Implementation note:** Cash after only appears if Spend > 0. When Spend is $0, just show "Cash: $X".

---

## PART 8: RUN SHOW BUTTON ENHANCEMENT

Use Primary Button styling from Part 2.

**Active state additional polish:**
- Subtle pulse animation when active and player hasn't run a show in 30+ seconds (gentle attention pull)
- Show keyboard shortcut: `▶ RUN SHOW (Enter)` in the button text

**Disabled state additional clarity:**
- Tooltip on hover explaining why it's disabled:
  - "Pick at least one firework" if no fireworks selected
  - "Exceeds available cash" if overspending

---

## PART 9: MICROCOPY UPDATES

Replace current text with these warmer variants:

- "Select at least one firework to run a show." → **"Pick at least one firework to fire your show."**
- "(none)" in Owned section → **"No upgrades yet — buy your first below."**
- Locked upgrade hover tooltip: **"Unlocks at Zone N: [upgrade description]"**
- Empty marketing list at Zone 1: **"Only flyers available at this zone. More marketing options unlock as you grow."**
- Empty firework section: **"All Tier 1 fireworks shown. Higher tiers unlock by zone."**

---

## PART 10: SCROLL AFFORDANCES

**Scrollbar updates:**
- Width: 10px (was 8px)
- Track: `rgba(10, 16, 40, 0.3)`
- Thumb default: `cream_muted` (`#8A8570`)
- Thumb hover/active: `cream_bright` (`#F5E6D0`)
- Always visible (not auto-hide)

**Fade gradient at scrollable edges:**
- Top of scrollable area: 16px tall fade from panel background to transparent (suggests "more content above")
- Bottom of scrollable area: 16px tall fade from transparent to panel background (suggests "more content below")
- Only show fades when content actually overflows (no fade if list fits in viewport)

---

## IMPLEMENTATION PRIORITY

For tonight, in order:

1. **Compact firework rows with tier color stripes** (Part 1) — biggest visual change, ~60 min
2. **Button styling system** (Part 2) — affects everything, get it right once, ~45 min
3. **Icon integration** (Part 3) — all 13 icons (t1-t4, money, fans, house, speaker, lock, check, rightarrow, plus, stars saved for Results) — ~60 min
4. **Enhancement pill buttons** (Part 4) — replace checkboxes, ~30 min
5. **Upgrades hierarchy fix** (Part 5) — clarity win, ~30 min
6. **Header zone progress** (Part 6) — pacing visibility, ~20 min
7. **Footer money treatment** (Part 7) — affordability clarity, ~20 min
8. **Run Show button enhancement** (Part 8) — polish, ~15 min
9. **Microcopy** (Part 9) — quick polish, ~10 min
10. **Scroll affordances** (Part 10) — polish, ~15 min

Total: ~5 hours for the full overhaul. Items 1-5 (~3.5 hours) deliver 80% of the perceived improvement.

---

## VERIFICATION CHECKLIST

After implementation, the screen should show:

- [ ] 8-10 firework rows visible per scroll viewport (compact rows working)
- [ ] Each firework row has visible tier color stripe at left edge
- [ ] Each firework row shows tier badge image (t1.png/t2.png/etc) inline
- [ ] Selected fireworks (qty > 0) have visual emphasis (background, gold quantity)
- [ ] Locked fireworks show lock.png icon (replacing tier stripe) and "Unlocks at Zone X" text
- [ ] Top bar shows money.png + cash, fans.png + count + progress bar to next zone
- [ ] Marketing section shows pill buttons for enhancements (not checkboxes)
- [ ] Selected enhancement pills show check.png inline (or distinct gold styling)
- [ ] Upgrades panel: Owned items show check.png at start, bright text
- [ ] Upgrades panel: Available items have category icon (speaker/house/fans/money) on the right
- [ ] Upgrades panel: Locked items show lock.png at start, dim text
- [ ] Upgrades panel shows rightarrow.png + "Next unlock at Zone X: [name]" callout in Locked section
- [ ] Run Show button shows rightarrow.png + "RUN SHOW" text
- [ ] Run Show has clear active vs. disabled states
- [ ] Footer shows "Spend: $X → Cash after: $Y" with appropriate colors
- [ ] All buttons follow the styling system (consistent hover, pressed, disabled states)
- [ ] No off-palette colors anywhere
- [ ] Atmospheric background still visible through translucent panels
- [ ] All icons render crisp pixel art (no smoothing — Filter set to Off in Godot import)

---

## REFERENCE FILES

- `wireframe_planning_screen.md` — original wireframe spec
- `visual_language.md` — palette and typography
- `assets/images/t1.png` through `t4.png` — tier badges (4 files)
- `assets/images/money.png`, `fans.png`, `house.png`, `speaker.png` — category and stat icons (4 files)
- `assets/images/lock.png`, `check.png` — state indicators (2 files)
- `assets/images/rightarrow.png`, `plus.png` — action icons (2 files)
- `assets/images/starfull.png`, `starempty.png` — quality rating (2 files, save for Results screen)
- `assets/backgrounds/zone_1_backyard.png` — atmospheric background

**Total icons available:** 14 PNGs at 64×64 source resolution with transparent backgrounds.

If anything is ambiguous, default to "compact, scannable, clearly hierarchical" over "spacious, decorative, flat."
