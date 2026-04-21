# THE LAST SHOW — Planning Screen Modern UI Pivot

**Major direction change:** Pivoting from pixel art UI to clean modern UI with pixel art backgrounds and gameplay elements. See `planning_screen_modern.html` for the visual target.

**The game title is now "THE LAST SHOW"** (not LAUNCH). Update references throughout where relevant.

**Rationale:** Pixel art UI was constantly fighting font sizing, readability, and scaling. Modern clean UI with pixel art BACKGROUND and GAMEPLAY ELEMENTS (fireworks, zone silhouettes) is the approach most successful indie games take (Hades, Celeste, Slay the Spire, the Black Hole game reference provided). Gameplay = pixel art, UI = functional clarity.

---

## PART 1: FONT INSTALLATION

Two new fonts have been added to the project:

### Inter (primary UI font)
- Location: `assets/fonts/inter/`
- Files: `Inter-Regular.ttf`, `Inter-Medium.ttf`, `Inter-SemiBold.ttf`, `Inter-Bold.ttf`
- Usage: ALL body UI text throughout the game

### VT323 (accent pixel font — limited use)
- Location: `assets/fonts/vt323/`
- Files: `VT323-Regular.ttf`
- Usage: ONLY for the "THE LAST SHOW" logo in the top bar. Nothing else currently. Adds pixel flavor as an identity marker without fighting readability.

### m6x11plus (retained)
- Location: `assets/fonts/m6x11plus/`
- Usage: RETAINED in project but not used in new UI direction. Don't delete — may be useful later for specific flavor elements.

### Godot import settings for fonts

**Critical:** Inter requires different import settings than the pixel fonts:
- Antialiasing: Grayscale (NOT disabled — this is a smooth font, needs antialiasing)
- Hinting: Light
- Subpixel Positioning: Auto
- Oversampling: 1.0 (default)
- MSDF: Enabled (for clean rendering at all sizes)

For VT323 (pixel font):
- Antialiasing: Disabled
- Hinting: None
- Subpixel Positioning: Disabled
- Oversampling: 0

---

## PART 2: COLOR PALETTE

Updated palette — warmer, cleaner:

### Core colors

```gdscript
# Dark backgrounds (slightly warmer than before)
const NIGHT_DEEP = Color("#0F1423")      # Main background (replaces #0A1028)
const PANEL_BG = Color("#0F1423", 0.70)  # Panel background with transparency
const CARD_BG = Color("#1A2036", 0.60)   # Card background with transparency
const BORDER_SUBTLE = Color("#FFFFFF", 0.08)  # Subtle borders on UI elements

# Text colors
const TEXT_PRIMARY = Color("#F0F0F0")    # Primary text
const TEXT_SECONDARY = Color("#B8B8B8")  # Secondary text
const TEXT_MUTED = Color("#888888")       # Muted text (labels, captions)
const TEXT_DIM = Color("#555555")        # Disabled text

# Accent (warm amber — new)
const ACCENT_AMBER = Color("#FFB84D")    # Primary accent (replaces #FFD700 gold)
const ACCENT_AMBER_DIM = Color("#FFB84D", 0.15)  # Subtle amber background
const ACCENT_AMBER_BORDER = Color("#FFB84D", 0.4)  # Amber borders

# State colors
const STATE_WARN = Color("#D73A3A")      # Warning/overspending
const STATE_SUCCESS = Color("#4DCC7C")   # Positive state (rarely used)

# Tier colors (unchanged)
const TIER_1 = Color("#A07050")  # Bronze
const TIER_2 = Color("#B0B8C0")  # Silver
const TIER_3 = Color("#D4AF37")  # Gold (still gold for tier identifier)
const TIER_4 = Color("#5FC8D8")  # Cyan
```

### Color job assignments (ONE color per job)

- **Amber** (`#FFB84D`): Money values, accent borders, active/selected states, Run Show button, interactive highlights
- **Red** (`#D73A3A`): Warnings only (overspending, errors)
- **Text primary** (`#F0F0F0`): Main content text
- **Text secondary** (`#B8B8B8`): Card meta info, supporting text
- **Text muted** (`#888888`): Labels, captions, small info
- **Text dim** (`#555555`): Disabled/locked items
- **Tier colors**: Only on tier indicator stripes in firework rows

---

## PART 3: TYPOGRAPHY SYSTEM

Inter renders crisply at any size. Use these specific sizes:

### Size tokens

| Token | Size | Usage |
|-------|-----:|-------|
| `size_display` | 48px | Game title on title screen, ending headers |
| `size_h1` | 24px | Major screen headers (rare) |
| `size_h2` | 18px | Bottom bar primary action, key values |
| `size_body_lg` | 16px | Large body text, cash display |
| `size_body` | 14px | Standard body, card names, button labels |
| `size_body_sm` | 13px | Card meta, enhancement rows |
| `size_label` | 11px | Uppercase section labels, panel titles |
| `size_caption` | 11px | Tags, status info, hints |

### Weight tokens

| Token | Weight | Usage |
|-------|-------:|-------|
| `weight_regular` | 400 | Default body text |
| `weight_medium` | 500 | Card names, emphasized body |
| `weight_semibold` | 600 | Section labels, buttons, values |
| `weight_bold` | 700 | Rare — major headers only |

### Typography rules

- **All caps + letter-spacing** for small labels (11px, weight 600, letter-spacing 1-2px)
- **Tabular numerals** (`font-variant-numeric: tabular-nums`) for ALL numbers — consistent alignment
- **Inter for everything** except the logo (VT323)

### Font loading in Godot

```gdscript
# In theme setup
var inter_regular = preload("res://assets/fonts/inter/Inter-Regular.ttf")
var inter_medium = preload("res://assets/fonts/inter/Inter-Medium.ttf")
var inter_semibold = preload("res://assets/fonts/inter/Inter-SemiBold.ttf")
var vt323 = preload("res://assets/fonts/vt323/VT323-Regular.ttf")

theme.default_font = inter_regular
theme.default_font_size = 14
```

For specific labels needing different weights, use theme overrides:
```gdscript
label.add_theme_font_override("font", inter_semibold)
label.add_theme_font_size_override("font_size", 11)
```

---

## PART 4: VERTICAL LAYOUT (1280×720)

### New layout breakdown

```
y=0   → 56    Top bar (56px — slightly shorter than before)
y=56  → 72    Atmospheric strip (16px — sky visible above panels)
y=72  → 632   UI panels (560px — taller than previous 444px)
y=632 → 648   Atmospheric strip (16px — tiny gap before bottom bar)
y=648 → 720   Bottom bar (72px — slightly taller for prominence)
```

---

## PART 5: TOP BAR

Height: 56px
Background: `rgba(15, 20, 35, 0.85)` with `backdrop_filter` if Godot supports it, otherwise solid at 85% opacity
Border bottom: 1px `rgba(255, 255, 255, 0.08)`
Padding: `0 24px` (horizontal)
Layout: flex horizontal, space-between, align-center

### Left section (grouped, gap 24px)

**Logo**
- Font: VT323 at 24px
- Color: `ACCENT_AMBER` (#FFB84D)
- Text: "THE LAST SHOW" or "LAST SHOW" if too long
- Letter-spacing: 1px

**Night info**
- Label "NIGHT" — Inter 11px semibold uppercase, letter-spacing 1.5px, color `TEXT_MUTED`
- Value "47 / 100" — Inter 16px semibold, color `TEXT_PRIMARY`, tabular-nums
- Layout: label and value on same line with 8px gap

**Zone indicator (pill)**
- Background: `rgba(255, 184, 77, 0.1)` (subtle amber tint)
- Border: 1px `rgba(255, 184, 77, 0.3)`
- Border-radius: 4px
- Padding: 6px 14px
- Content: "ZONE 3" (Inter 11px semibold amber, letter-spacing 1.5px) + "Town" (Inter 14px medium cream)

### Right section (grouped, gap 20px)

**Fans + progress**
- Icon: 14×14 fans icon (from new modern icon set)
- Text: "437 / 500 fans" — Inter 14px medium, `TEXT_SECONDARY`, tabular-nums
- Progress bar: 60×4px, track `rgba(255, 255, 255, 0.1)`, fill `ACCENT_AMBER`, 2px border-radius

**Cash display**
- Icon: 14×14 money icon
- Text: "$1,247,500" — Inter 18px semibold, color `ACCENT_AMBER`, tabular-nums

---

## PART 6: PANELS

Height: 560px
Width: 400px / 384px / 400px (unchanged column widths)
Gap between panels: 16px
Edge padding: 16px

### Panel styling

- Background: `rgba(15, 20, 35, 0.70)` with backdrop blur
- Border: 1px `rgba(255, 255, 255, 0.08)`
- Border-radius: 6px
- Padding: 20px
- Box-shadow: `0 2px 8px rgba(0, 0, 0, 0.2)` (subtle depth)

### Panel header

**Title** (small, uppercase, letter-spaced)
- Inter 11px semibold
- Color: `TEXT_MUTED`
- Letter-spacing: 2px
- Text-transform: uppercase
- Example: "FIREWORKS", "MARKETING & ENHANCEMENTS", "UPGRADES"

**Subtitle** (optional, below title)
- Inter 13px regular
- Color: `TEXT_SECONDARY`
- Margin-bottom: 16px
- Example: "Budget: $487,500"

---

## PART 7: FIREWORK ROWS

### Structure

```
[tier stripe] [name + meta (stacked)] [qty controls] [info button]
```

### Dimensions

- Height: 52px (compact, more visible)
- Padding: 12px 14px
- Gap between rows: 6px
- Border-radius: 4px

### Row styling

- Background: `rgba(255, 255, 255, 0.03)` default
- Border: 1px `rgba(255, 255, 255, 0.06)` default
- Hover: background `rgba(255, 255, 255, 0.06)`, border `rgba(255, 255, 255, 0.12)`
- Selected (qty > 0): background `rgba(255, 184, 77, 0.08)`, border `rgba(255, 184, 77, 0.4)`
- Locked: opacity 0.4

### Row contents

**Tier indicator stripe**
- Width: 3px
- Height: 28px (centered vertically)
- Color: tier color (bronze/silver/gold/cyan)
- Border-radius: 2px

**Name and meta (stacked, flex: 1)**
- Name: Inter 14px medium, `TEXT_PRIMARY`, 3px margin-bottom
- Meta: Inter 12px regular, `TEXT_MUTED`, tabular-nums
  - Cost prefix in `ACCENT_AMBER`: `<span class="cost">$2</span> · 1 eng · classic`

**Quantity controls**
- Layout: horizontal flex, gap 4px
- Minus button: 24×24, subtle background, `-` in 14px
- Qty value: 32px wide, centered text, 14px medium, tabular-nums
- Plus button: 24×24, matching minus
- Buttons: background `rgba(255, 255, 255, 0.06)`, border `rgba(255, 255, 255, 0.1)`, border-radius 3px
- Hover: background `rgba(255, 184, 77, 0.15)`, border amber, text amber
- Qty value active (when > 0): color `ACCENT_AMBER`

**Info button**
- 24×24 circle, `rgba(255, 255, 255, 0.1)` border
- "i" in italic 11px semibold, color `TEXT_DIM`
- Hover: border amber, text amber, background subtle amber
- Clicks open firework preview modal (future implementation)

---

## PART 8: MARKETING & ENHANCEMENTS PANEL

Mix of firework-style rows (Marketing) and enhancement rows (click to select).

### Section dividers

Between Marketing and Enhancements sections:
- Label: Inter 11px semibold uppercase, letter-spacing 2px, `TEXT_MUTED`
- Hint: Inter 11px italic, `TEXT_DIM` (right-aligned) — e.g., "one per category"
- Padding-top: 16px, border-top: 1px `rgba(255, 255, 255, 0.06)`

### Marketing rows (same as firework rows but without tier stripe)

Use firework row structure but omit the tier indicator.

### Subsection labels (Snacks / Sound / Host)

- Inter 12px medium, `TEXT_SECONDARY`, letter-spacing 0.5px
- Margin: 12px 0 6px

### Enhancement rows (click to select)

- Height: 40px
- Background/border same as firework rows
- Cursor: pointer
- Hover: background brightens
- Selected: background `rgba(255, 184, 77, 0.08)`, border amber

**Layout:**
- Checkbox (16×16 square, border `rgba(255, 255, 255, 0.2)`, border-radius 3px)
  - Selected: background amber, border amber, white checkmark
- Name + effect (stacked, flex: 1)
  - Name: Inter 13px medium primary
  - Effect: Inter 11px muted
- Cost: Inter 13px medium amber, tabular-nums

---

## PART 9: UPGRADES PANEL

Same overall structure but with tab filter and different row types.

### Tab filter (at top of panel)

- Background: `rgba(0, 0, 0, 0.25)` pill container
- Padding: 3px
- Border-radius: 4px
- Tabs: flex equal, padding 6px 4px, 11px semibold, uppercase, letter-spacing 0.3px
- Default: `TEXT_MUTED` color
- Hover: `TEXT_PRIMARY` color, subtle background
- Active: background `rgba(255, 184, 77, 0.15)`, color amber, border-radius 3px

### Section dividers

Use the labeled divider pattern:
```
OWNED · 1
```

Format: "OWNED" in 11px semibold uppercase, letter-spacing 2px, `TEXT_MUTED` + count in same style

Sections: OWNED, AVAILABLE, LOCKED

### Upgrade rows

**Owned row** (gold-tinted subtle highlight)
- Background: `rgba(255, 184, 77, 0.05)`, border `rgba(255, 184, 77, 0.2)`
- Icon: 28×28 square with amber-tinted background, category icon in amber
- Content: name (13px medium primary) + desc (11px muted)
- Right: category tag (11px muted) — e.g., "Mkt"

**Available row**
- Same styling as firework rows
- Icon: 28×28 square with `rgba(255, 255, 255, 0.05)` background, category icon
- Content: name + desc
- Right: cost in amber (13px semibold) + BUY button

**Buy button:**
- Padding: 6px 14px
- Background: `rgba(255, 184, 77, 0.15)`
- Border: 1px `rgba(255, 184, 77, 0.4)`
- Color: `ACCENT_AMBER`
- Font: Inter 11px semibold, uppercase, letter-spacing 1px
- Border-radius: 3px
- Hover: background solid amber, color `NIGHT_DEEP`, border amber
- Disabled: background subtle, border subtle, color dim

**Locked row**
- Opacity: 0.4
- Icon: lock icon (16×16) in place of category icon
- Name only (small, muted)
- Right: "Zone N+" tag

### Next unlock callout

Between Available and Locked sections:

- Display: flex, align-items center, gap 8px
- Padding: 8px 12px
- Background: `rgba(255, 184, 77, 0.05)`
- Border: 1px `rgba(255, 184, 77, 0.15)`
- Border-left: 3px solid amber (accent stripe)
- Border-radius: 3px
- Content: amber arrow icon + "Next: **Website** at Zone 2" (Inter 12px, amber arrow, bold upgrade name)

---

## PART 10: BOTTOM BAR

Height: 72px
Background: `rgba(15, 20, 35, 0.85)`
Border top: 1px `rgba(255, 255, 255, 0.08)`
Padding: 0 24px
Layout: flex, space-between, align-center

### Left (summary)

**Hint** (small label above main)
- Inter 11px semibold uppercase, letter-spacing 1.5px, `TEXT_MUTED`
- Example: "Ready to Run Show" or "Select fireworks to continue"

**Main** (primary info)
- Inter 14px medium, `TEXT_PRIMARY`
- Example: "Spend **$275** · Cash after **$1,247,225**"
- Spend value in amber, cash after in primary, both tabular-nums
- When spending exceeds cash: spend in `STATE_WARN` red

### Right (actions)

**Menu button** (icon)
- 40×40, transparent background, 1px `rgba(255, 255, 255, 0.15)` border
- "☰" icon in 18px, `TEXT_MUTED`
- Hover: background `rgba(255, 255, 255, 0.05)`, text primary
- Border-radius: 4px

**Run Show button** (primary CTA)
- Padding: 12px 32px
- Background: `ACCENT_AMBER` solid
- Color: `NIGHT_DEEP`
- Font: Inter 14px semibold, uppercase, letter-spacing 1px
- Border: none
- Border-radius: 4px
- Hover: background brighter amber (`#FFC864`), `translateY(-1px)`, shadow
- Transition: all 0.15s ease
- Disabled: background subtle, color dim, no hover
- Includes "→" arrow icon after text

---

## PART 11: BACKGROUND INTEGRATION

### Zone backgrounds (all 6 now generated)

Files expected in `assets/backgrounds/`:
- `zone_1_backyard.png`
- `zone_2_neighborhood.png`
- `zone_3_town.png`
- `zone_4_city.png`
- `zone_5_stadium.png`
- `zone_6_mountain_vista.png`

All are 1792×1024 or similar wide format.

### Godot import settings for backgrounds

- Filter: **Enabled** (smoothes the pixel art slightly when scaled — acceptable for backgrounds)
  - OR disable for strict pixel look — test both
- Mipmaps: Off
- Compression: Lossless

### Displaying backgrounds

Use TextureRect or ColorRect with texture fill:
```gdscript
$BackgroundLayer/ZoneBackground.texture = load("res://assets/backgrounds/zone_%d_%s.png" % [zone_num, zone_name])
```

Stretch mode: `STRETCH_KEEP_ASPECT_COVERED` (fills the 1280×720 viewport, crops sides if needed)

---

## PART 12: SCROLLBARS

Style scrollbars consistently:
- Width: 6px
- Track: transparent
- Thumb: `rgba(255, 255, 255, 0.1)` default, `rgba(255, 255, 255, 0.2)` hover
- Border-radius: 3px
- No arrows

---

## PART 13: ICONS

**Icons are being replaced with a modern icon set.** User is generating new icons after returning from errand.

Temporary placeholders acceptable:
- Unicode symbols: ✓ $ 👥 🔒 → i
- Or use existing pixel icons scaled down with antialiasing enabled

When new icons arrive, they will be 64×64 PNGs in `assets/images/` with transparent backgrounds:
- `money.png`, `fans.png`, `marketing.png`, `infrastructure.png`, `crew.png`, `revenue.png`
- `lock.png`, `check.png`, `arrow_right.png`, `info.png`
- `star_full.png`, `star_empty.png`
- `menu.png`, `close.png`

Display sizes vary per context (14-28px depending on use case).

---

## PART 14: IMPLEMENTATION ORDER

1. **Font installation and theme setup** (Inter as default, VT323 for logo) (~20 min)
2. **Color palette update** in constants/theme (~10 min)
3. **Top bar redesign** with new styling (~30 min)
4. **Panel container styling** (translucent, bordered, rounded) (~20 min)
5. **Firework rows compact format** with tier stripes (~45 min)
6. **Marketing rows** (similar to firework but no tier stripe) (~20 min)
7. **Enhancement rows** (click to select, mutex within category) (~30 min)
8. **Upgrade rows** (3 section variants: owned, available, locked) (~45 min)
9. **Next unlock callout** in Locked section (~15 min)
10. **Bottom bar** with Run Show primary button (~20 min)
11. **Scrollbar styling** (~10 min)
12. **Verify atmospheric background integration** with all panels translucent (~20 min)

Total: ~5 hours

---

## PART 15: REFERENCE FILE

`planning_screen_modern.html` is the visual target. Open it in a browser to see exactly what the UI should look like. Every color, size, spacing, and interaction pattern is demonstrated there.

Key things to match from the HTML mockup:
- Overall clean/modern feel
- Backdrop blur effect on panels and bars (if Godot supports)
- Subtle borders with low-opacity white
- Amber as the single accent color
- Tier color stripes on firework rows
- Rounded corners on interactive elements (3-6px)
- Tabular numerals everywhere
- Proper typographic hierarchy

---

## PART 16: WHAT STAYS THE SAME

- Three-column panel layout (Fireworks / Marketing+Enh / Upgrades)
- Zone-specific atmospheric background behind everything
- Firework filtering by zone (Tier 1 only at Zone 1)
- Upgrade category filtering via tabs
- Save system and state management
- All game mechanics unchanged

This is purely a visual/UI pivot. Gameplay systems untouched.

---

## PART 17: TITLE CHANGE

Game is now called **"THE LAST SHOW"** (not LAUNCH).

Update:
- Top bar logo to show "THE LAST SHOW" (or "LAST SHOW" if space is tight)
- Title screen (when built) to show "THE LAST SHOW"
- Any window titles or meta references
- Internal filenames, variable names, etc. can stay as "launch" — those are dev conventions, not player-facing

---

## VERIFICATION

After implementation, the screen should match the `planning_screen_modern.html` mockup closely:

- [ ] Inter font rendering crisply at all sizes (14px, 16px, 18px all readable)
- [ ] VT323 "THE LAST SHOW" logo in top-left
- [ ] Amber `#FFB84D` as primary accent color throughout
- [ ] Three translucent panels with subtle borders and rounded corners
- [ ] Firework rows at 52px with visible tier color stripes
- [ ] Gold border + amber background on selected firework rows
- [ ] Info buttons on each firework row (placeholder OK for now)
- [ ] Marketing section + Enhancement section with clear dividers
- [ ] Enhancement rows with click-to-select mutex behavior
- [ ] Upgrade tabs (All/Crew/Infra/Rev/Mkt) with amber active state
- [ ] Owned/Available/Locked sections with appropriate styling
- [ ] Next unlock callout with amber accent stripe
- [ ] Run Show button prominently styled with solid amber background
- [ ] Atmospheric zone background visible through translucent panels
- [ ] No pixel font used except for logo

If the result looks 80%+ like the HTML mockup, we're on the right track. Remaining refinements can happen in polish iterations.
