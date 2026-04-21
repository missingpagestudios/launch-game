# LAUNCH Stage 2 — Planning Screen Visual Refinement

**Goal:** Transform the Planning Screen from "functional UI" to "atmospheric game screen" by integrating the zone background as a layered system and refining panel sizing.

**Asset already in project:** `assets/backgrounds/zone_1_backyard.png` (the dark version we approved — backyard scene with tree, house, lit window, fence, fire pit, stars)

---

## Part 1: Layered Background System

The zone background needs to render as TWO layers with the firework particle system between them. For Stage 2, we won't have particles yet, but we set up the layering correctly so Stage 3 just slots in.

### Step 1: Split the background image

The single `zone_1_backyard.png` needs to become two separate images:
- `zone_1_sky.png` — sky portion only (top of image, with stars), silhouette area is transparent
- `zone_1_silhouettes.png` — silhouettes only (tree, house, chimney, lit window, fence, fire pit, hills), sky area is transparent

**Manual approach (recommended for stage 2):**
1. Open `zone_1_backyard.png` in Photopea (browser-based, free)
2. Use the Magic Wand to select the dark sky area (everything above the silhouettes)
3. Save selection
4. Create new image `zone_1_sky.png`: paste only the sky/stars area, transparent below
5. Create new image `zone_1_silhouettes.png`: paste only the silhouettes (tree, house, fence, fire pit, hills), transparent sky above

If we don't have time to manually split, fallback: use the full image as a single background layer. We'll lose the proper foreground occlusion but get the atmospheric effect.

### Step 2: Scene structure in Godot

The Planning Screen scene tree should be:

```
PlanningScreen (Control)
├── BackgroundLayer (CanvasLayer, layer = -2)
│   └── SkyTexture (TextureRect, full screen, contains zone_1_sky.png)
├── ParticleLayer (CanvasLayer, layer = -1)
│   └── [Empty for stage 2 — Stage 3 will add fireworks demo here]
├── ForegroundLayer (CanvasLayer, layer = 0)
│   └── SilhouetteTexture (TextureRect, full screen, contains zone_1_silhouettes.png)
├── UILayer (CanvasLayer, layer = 1)
│   ├── TopBar
│   ├── ContentArea (3 panels)
│   └── BottomBar
```

**Critical:** UI Layer is LAYER 1 (on top of silhouettes). The silhouettes draw over the sky and behind the UI. UI is fully on top.

When Stage 3 adds particles to the ParticleLayer, they'll automatically render between sky and silhouettes — fireworks behind the house but in front of the sky.

### Step 3: Texture stretching

Both `zone_1_sky.png` and `zone_1_silhouettes.png` should stretch to fit the 1280×720 viewport:
- `TextureRect.stretch_mode = STRETCH_KEEP_ASPECT_COVERED` (fills viewport, crops if needed)
- `TextureRect.expand_mode = EXPAND_IGNORE_SIZE`
- Anchors set to fill parent (full screen)

If the source image is wider than 1280×720 (e.g., 1792×1024), it will be cropped at the sides — that's fine, the center action area is what matters.

---

## Part 2: Panel Layout Adjustments

### Vertical layout

The Planning Screen currently has panels filling almost the entire vertical space. We need to shorten them so atmosphere is visible above and below.

**New vertical breakdown for 1280×720:**

```
y=0   → 60   Top bar (full width, 60px tall)
y=60  → 76   Atmospheric strip — 16px (sky/stars visible)
y=76  → 520  UI panels — 444px tall (down from 548)
y=520 → 640  Atmospheric strip — 120px (foreground silhouettes visible — fence, house bottom, fire pit, tree base)
y=640 → 720  Bottom bar (full width, 80px tall)
```

The 444px panel height is **not negotiable** — that's what creates the atmospheric breathing room. Adjust content to fit.

### Horizontal layout (unchanged)

```
x=0   → 32    Edge padding (background visible at left edge)
x=32  → 432   Fireworks panel (400px wide)
x=432 → 448   Column gap (16px — background visible)
x=448 → 832   Marketing/Enhancements panel (384px wide)
x=832 → 848   Column gap (16px)
x=848 → 1248  Upgrades panel (400px wide)
x=1248→ 1280  Edge padding (32px)
```

Total: 32 + 400 + 16 + 384 + 16 + 400 + 32 = 1280 ✓

---

## Part 3: Panel Translucency

All panels and bars need slight transparency so the atmospheric background bleeds through.

### Opacity targets

- **UI panels (Fireworks, Marketing, Upgrades):** 85% opaque
  - Background color: `Color(0.071, 0.094, 0.220, 0.85)` (= #121838 with 85% alpha)
- **Top bar:** 90% opaque
  - Background color: `Color(0.039, 0.063, 0.157, 0.90)` (= #0A1028 with 90% alpha)
- **Bottom bar:** 92% opaque  
  - Background color: `Color(0.039, 0.063, 0.157, 0.92)` (= #0A1028 with 92% alpha)
- **Card backgrounds (within panels):** 90% opaque
  - Background color: `Color(0.102, 0.125, 0.282, 0.90)` (= #1A2048 with 90% alpha)

### Implementation

In Godot, set Panel/PanelContainer's StyleBoxFlat:
```gdscript
var style = StyleBoxFlat.new()
style.bg_color = Color(0.071, 0.094, 0.220, 0.85)
style.border_color = Color(0.165, 0.188, 0.333, 1.0)  # #2A3055 fully opaque
style.border_width_left = 1
style.border_width_top = 1
style.border_width_right = 1
style.border_width_bottom = 1
panel.add_theme_stylebox_override("panel", style)
```

Border stays fully opaque — gives panels a clean defined edge against the atmospheric background.

---

## Part 4: Font Sizes (Final Spec)

Body text needs to scale appropriately for the 444px-tall panels:

- **Display:** 48px — Title screens, ending screens (rarely used on Planning Screen)
- **Header:** 28px — Panel headers (FIREWORKS, MARKETING, UPGRADES) — note: reduced from 32px to fit shorter panels
- **Header_top_bar:** 32px — Top bar elements (Night counter, Zone, Cash) — keep larger here for prominence
- **Body:** 22px — Card names, primary content
- **Body_small:** 20px — Secondary card content, button labels, sub-section labels  
- **Body_smaller:** 18px — Stats lines, descriptions, helper text
- **Caption:** 16px — Truly secondary info (Fans count, helper text like "one per category")

### Apply via theme

Set up theme variants in `themes/default.tres` for these size tokens, then apply via theme overrides on individual labels as needed.

### Font import settings

Critical for m6x11plus.ttf — verify in import settings:
- Antialiasing: Disabled
- Hinting: None
- Force Autohinter: Off
- Subpixel Positioning: Disabled
- Oversampling: 0
- MSDF: 0

If text is rendering blurry/soft, these settings are wrong.

### Line spacing

For 22px body text, set line_separation to 4-6px (gives total 26-28px line height):
```gdscript
label.add_theme_constant_override("line_separation", 6)
```

---

## Part 5: Card Styling Refinement

### Firework cards

**Dimensions:** 92px tall (was 80px)
**Padding:** 12px on left/right, 12px top, 12px bottom

**Layout (within 92px height):**
- y=12: Name (22px cream_bright) + Tier badge (right-aligned, 22×22px)
- y=42: Stats line (18px) — `[$cost · N eng · tags]` with cost in gold, eng in cream, tags in muted
- y=68: Quantity controls — [-] [N] [+] with cost preview right-aligned

**Selected state:**
- 1px gold border on card (#FFD700)
- Slight background brightness boost
- Quantity number turns gold when > 0

**Card visual states:**
- Default: `rgba(26, 32, 72, 0.90)` background, no border
- Hover: brighter background
- Selected (qty > 0): 1px gold border, slightly brighter background
- Unaffordable: dimmer background, text muted
- Locked: very dim background, all text dim cream

### Marketing cards

**Dimensions:** 70px tall
**Layout:**
- y=10: Name (20px) + cost (16px) on right
- y=30: Effect (16px muted) — "+10 attendees"
- y=52: Quantity controls

### Upgrade cards (Available state)

**Dimensions:** 96px tall
**Layout:**
- y=12: Name (20px) + Category badge (right)
- y=36: Cost (20px gold)
- y=60: Description (16px muted)
- Buy button: 72×28px at bottom right

### Upgrade rows (Owned/Locked state)

**Dimensions:** 36px tall, no background
- Icon (20px) + Name (20px) + Status tag (16px right-aligned)

---

## Part 6: Filter Logic (Critical bug fix from earlier)

Confirm that the Fireworks panel uses the GameEngine's filtered list, not the full 50-item array.

```gdscript
# CORRECT
var available = GameEngine.available_fireworks(state)
for fw in available:
    create_firework_card(fw)

# WRONG  
for fw in config.fireworks:  # This shows all 50
    create_firework_card(fw)
```

Same for upgrades — use the filtered/categorized list, not the full config.

---

## Part 7: Icon Integration

The previously generated graphics need to be integrated:

### Tier badges

`assets/icons/tier_badges.png` contains 4 tier badges in a horizontal row. Slice into individual textures or use AtlasTexture with regions:
- Tier 1: x=0, y=0, w=256, h=256 (or wherever the first badge is in the source)
- Tier 2: x=256, y=0, w=256, h=256
- Tier 3: x=512, y=0
- Tier 4: x=768, y=0

Display each at 22×22px on firework cards (aggressive downscale, but the chunky pixel art will hold up).

### Category icons  

`assets/icons/category_icons.png` contains 4 icons. Same approach — slice and display at 16×16px on upgrade cards.

### Small UI icons

`assets/icons/ui_icons.png` contains 6 icons (lock, check, filled star, empty star, arrow, plus). Slice and use as needed:
- Lock icon → on locked upgrade rows
- Check icon → on owned upgrade rows  
- Plus icon → could replace text "+" on quantity buttons (optional)

For Stage 2, if integrating sliced graphics is complex, leave text placeholders ("T1", "✓", "🔒") and integrate the actual graphics later. Don't block on this.

---

## Part 8: What the End Result Should Look Like

After all these changes, the Planning Screen at Night 1 / Zone 1 / Backyard should show:

1. **Background:** Dark Zone 1 backyard image visible across the full screen
2. **Top atmospheric strip:** Stars visible above the panels in a thin band
3. **Panels:** Three panels at 85% opacity, dark navy with the background bleeding through subtly
4. **Bottom atmospheric strip:** Tree silhouette on left, house with chimney on right, lit window glowing warm orange, picket fence across the bottom, fire pit glowing in the center
5. **Top bar:** Night counter, Zone name centered, Cash in gold, Fans count below cash
6. **Fireworks panel:** Only Tier 1 fireworks visible (8-10 items), each card 92px tall with name/stats/quantity
7. **Marketing panel:** 1-2 marketing options at top, enhancements section below with subsections
8. **Upgrades panel:** Owned section, Available section with cards, Locked section with grayed-out rows
9. **Bottom bar:** Summary text on left, "RUN SHOW" button + pause icon on right
10. **Selected fireworks (qty > 0):** Gold border on card, quantity number in gold

The overall effect: the player feels like they're standing in a backyard at night, planning their fireworks show. The UI is present and functional but the world is alive around it.

---

## Part 9: Testing Checklist

Once integrated, verify:

- [ ] Zone 1 background is visible across the full screen
- [ ] Stars are visible above the panels
- [ ] Tree, house, fence, fire pit are visible below the panels
- [ ] Lit window glow is visible (small warm orange glow on the house)
- [ ] Panels are clearly translucent — you can see hints of background through them
- [ ] Borders on panels are clean 1px lines
- [ ] Body text is comfortably readable at normal viewing distance
- [ ] Headers (FIREWORKS, MARKETING, UPGRADES) are prominent
- [ ] Only Tier 1 fireworks show in the Fireworks panel
- [ ] Selecting a firework adds gold border and turns quantity gold
- [ ] Run Show button is visually prominent in the bottom right
- [ ] No text appears blurry or soft (font import settings correct)
- [ ] No off-palette colors anywhere

---

## Part 10: Priority

If time is tight, prioritize in this order:

1. **Background layering with translucent panels** (the biggest visual win)
2. **Font import settings** (text must be crisp)
3. **Font sizes per spec** (everything legible)
4. **Panel sizing to 444px** (creates atmospheric strips)
5. **Firework filtering bug fix** (Tier 1 only at Zone 1)
6. **Card styling refinement** (selected state, color hierarchy)
7. **Icon integration** (can use text placeholders if blocked)

If 1-5 are done, the screen will look dramatically better. Card and icon refinements can land in a follow-up pass.

---

## Reference Files

- `wireframe_planning_screen.md` — original wireframe spec with exact dimensions
- `planning_screen_v2.html` — high-fidelity HTML mockup of target appearance
- `font_size_revision.md` — font size rationale
- `visual_language.md` — palette, typography, component specs
- `assets/backgrounds/zone_1_backyard.png` — the source background to split

Build it, get a screenshot, send back. We iterate from there.
