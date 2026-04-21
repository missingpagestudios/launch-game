# THE LAST SHOW — Session Addendum (April 21, 2026)

**Read this AFTER `planning_screen_modern_pivot.md`. This document captures decisions made in today's session that update or clarify the main spec.**

---

## ZONE BACKGROUNDS — ALL 6 COMPLETE

All six zone backgrounds have been generated and approved. Expected file names in `assets/backgrounds/`:

1. `zone_1_backyard.png` — Rural backyard with tree, house, fence, fire pit
2. `zone_2_neighborhood.png` — Suburban street with multiple houses
3. `zone_3_town.png` — Small town center with church/civic buildings
4. `zone_4_city.png` — Mid-city urban skyline
5. `zone_5_stadium.png` — **Performer's view from stage looking across stadium** to far stands and sky
6. `zone_6_mountain_vista.png` — Elevated mountainside vista overlooking distant valley city with mountains behind

**Important:** Zone 5 and Zone 6 were conceptually swapped from earlier discussions. Zone 5 is now the stadium performer's view (regional venue). Zone 6 is now the mountain vista (THE LAST SHOW finale, worldwide scale).

### Background import settings in Godot

- Filter: **Enabled** (slight smoothing when scaled — pixel art tolerates this well for backgrounds)
- Mipmaps: Off
- Compression: Lossless

### Displaying backgrounds

```gdscript
# Map zone number to background file
var zone_backgrounds = {
    1: "res://assets/backgrounds/zone_1_backyard.png",
    2: "res://assets/backgrounds/zone_2_neighborhood.png",
    3: "res://assets/backgrounds/zone_3_town.png",
    4: "res://assets/backgrounds/zone_4_city.png",
    5: "res://assets/backgrounds/zone_5_stadium.png",
    6: "res://assets/backgrounds/zone_6_mountain_vista.png"
}

$BackgroundLayer/ZoneBackground.texture = load(zone_backgrounds[current_zone])
```

Use `STRETCH_KEEP_ASPECT_COVERED` to fill the 1280×720 viewport (crops edges if needed).

---

## CROWD RENDERING (FUTURE — STAGE 3)

Zones 5 and 6 were deliberately generated WITHOUT people/crowds in the image. Crowds will be added at runtime in Godot for flexibility.

**For Zone 5 (stadium):** Crowds populate the far stands. Render as small silhouettes across the distant stand rows. Stadium rim geometry accommodates this.

**For Zone 6 (mountain vista):** Crowds populate the hillside foreground. Render as silhouettes facing away from viewer, toward the valley. Varied poses (standing, sitting).

Don't implement crowds in Stage 2. Planning screen just shows backgrounds. Crowd rendering is a Stage 3 concern when show visualization is built.

---

## FONTS — WHAT TO DOWNLOAD

Rob is downloading during errand. Expected in `assets/fonts/`:

### Inter (primary UI font — everything except logo)
- Source: https://rsms.me/inter/ or https://fonts.google.com/specimen/Inter
- Weights needed: Regular (400), Medium (500), SemiBold (600), Bold (700)
- Import settings:
  - Antialiasing: **Grayscale** (smooth font, needs AA)
  - Hinting: Light
  - Subpixel Positioning: Auto
  - MSDF: Enabled

### VT323 (pixel font — logo ONLY)
- Source: https://fonts.google.com/specimen/VT323
- Weight: Regular only
- Used ONLY for "THE LAST SHOW" logo in top bar
- Import settings:
  - Antialiasing: **Disabled**
  - Hinting: None
  - Subpixel Positioning: Disabled
  - Oversampling: 0

### Retained but not used
- m6x11plus — keep in project, don't delete, may use later
- Pixel Operator — keep in project, don't delete, may use later

---

## ICONS — PLACEHOLDER PLAN

Current pixel icons in `assets/images/` (t1-t4, money, fans, house, speaker, lock, check, rightarrow, plus, starfull, starempty) are pixel art and don't match the new modern UI direction.

### For Stage 2 implementation (now)

Use existing pixel icons temporarily OR unicode/text placeholders:
- Money: `$` or existing `money.png`
- Fans: `👥` unicode or existing `fans.png`
- Lock: `🔒` unicode or existing `lock.png`
- Check: `✓` unicode or existing `check.png`
- Arrow right: `→` unicode or existing `rightarrow.png`
- Info: `i` letter styled as italic
- Menu: `☰` unicode

Render these with Inter font at appropriate size. They'll look acceptable during development.

### Replacement coming (Rob generating after errand)

Rob will generate a new modern line-style icon set (Lucide/Feather style, amber colored) to replace pixel icons. When those are ready, simply swap the icon textures — the UI layout and sizing doesn't need to change.

Icon slots to expect:
- money, fans, marketing (megaphone), infrastructure (building), crew (people), revenue (chart)
- lock, check, arrow_right, info, star_full, star_empty, menu, close

Design sizes: 14-28px depending on context.

---

## GAME TITLE: "THE LAST SHOW"

Update player-facing text throughout:

- Top bar logo: "THE LAST SHOW" in VT323 (if it doesn't fit, try "LAST SHOW" or smaller font size)
- Window title (when built): "The Last Show"
- Title screen (when built): "THE LAST SHOW"

**Internal code** (filenames, variable names, classes) can stay as `launch_*` or similar dev conventions. No need to rename `launch_game.gd` to `last_show_game.gd`. The rename is player-facing only.

---

## PRIORITY ORDER FOR CLAUDE CODE

Work through the main spec (`planning_screen_modern_pivot.md`) in the order listed in Part 14. The first 5 items deliver 80% of the visual improvement:

1. Install fonts and set Inter as default theme font (20 min)
2. Update color palette constants (10 min)
3. Redesign top bar with "THE LAST SHOW" logo in VT323 (30 min)
4. Update panel containers to translucent + rounded + subtle border (20 min)
5. Rebuild firework rows as compact 52px with tier stripes (45 min)

After these 5, screenshot and we can evaluate progress before continuing. The remaining items (marketing rows, enhancement rows, upgrade rows, bottom bar, etc.) are more incremental.

---

## WHAT NOT TO TOUCH

- Gameplay logic (balance sim, zone unlocks, firework selection rules)
- Save/load system
- Stage data structure
- File organization
- Core scene structure (scenes, node hierarchy)

This is purely a visual/UI overhaul. All game mechanics and data flow unchanged.

---

## WHEN SCREENSHOT COMES BACK

After the first pass (~2 hours of work), we'll look at a screenshot together. The question is whether the screen now feels like a polished indie game UI or still needs iteration. If it's close to `planning_screen_modern.html` in feel, we're on track.

If it comes back looking wrong:
- **If fonts look fuzzy:** Antialiasing/MSDF settings need adjustment
- **If colors look wrong:** Double-check amber is `#FFB84D` (not old gold `#FFD700`)
- **If panels look "boxed":** Verify backdrop blur is working, borders are 1px at 8% alpha
- **If rows look cramped:** Check padding (12px vertical, 14px horizontal)

Don't perfect-polish first pass. Get structure and styling in place, then iterate on details.
