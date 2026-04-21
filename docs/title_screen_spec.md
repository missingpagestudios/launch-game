# THE LAST SHOW — Title Screen Implementation Spec

**Context:** First screen players see when launching the game. Sets tone, communicates genre, provides entry point to the game. Companion document to `title_screen_v7.html` wireframe.

**Design north star:** A beautiful, slightly lonely poster for a fireworks-management story. Players should initially think "this is beautiful and a little sad" — not "this is an apocalypse game."

---

## FONTS REQUIRED

Two fonts for the title screen. One is new; the other is already in the project.

### 1. Cormorant Garamond (NEW — needs to be added)

**Source:** https://fonts.google.com/specimen/Cormorant+Garamond

**Weights needed:**
- 600 (SemiBold) — title only

**Files to download and add to project:**
- `assets/fonts/cormorant_garamond/CormorantGaramond-SemiBold.ttf`

**Godot import settings:**
- Antialiasing: **Grayscale** (serif font needs AA)
- Hinting: Light
- Subpixel Positioning: Auto
- Oversampling: 1.0
- MSDF: Enabled (for clean rendering at display size)

**Usage scope:** Title screen ONLY at this stage. Potentially ending screens and newspaper later, but not planning UI.

### 2. Inter (ALREADY IN PROJECT)

Already installed in `assets/fonts/inter/`. No action needed.

**Weights used on title screen:**
- 400 Regular — subtitle, version text
- 500 Medium — menu items
- 600 SemiBold — primary menu item (active/continue when applicable)

---

## LAYOUT SPECIFICATION

### Canvas

- Dimensions: 1280×720 (scales to 1920×1080 proportionally)
- Reference: `title_screen_v7.html` mockup

### Background

**Use the existing Zone 6 mountain vista background** — `assets/backgrounds/zone_6_mountain_vista.png`

- Scale to fill viewport: `STRETCH_KEEP_ASPECT_COVERED`
- Display at 100% opacity (this is our hero image)
- No additional tinting needed — the background already has the right mood

**Optional atmospheric additions in Godot:**
- Twinkling star particles in the upper sky (50-100 stars)
- Occasional firework bursts on the LEFT side of the screen (every 5-10 seconds, varied positions, varied colors)
- Small launch trails rising from below the horizon, left side

These should be implemented as particle systems or simple Sprite2D with animation — whatever's cleanest in Godot. Don't over-engineer.

### Content column placement

**Right-side information column:**
- Position: absolute, right 7% from edge, vertically centered (top 50%, translate y -50%)
- Width: 560px
- Internal alignment: RIGHT (all text right-aligned to the column's right edge)

### Title

- Font: Cormorant Garamond, weight 600
- Size: 76px
- Color: `#F0F0F0` (TEXT_PRIMARY)
- Letter-spacing: 0px (natural spacing)
- Line-height: 1.0
- Text: "The Last Show" (title case, single line)
- Text shadow (glow effect): 
  - `0 0 40px rgba(255, 184, 77, 0.25)`
  - `0 0 80px rgba(255, 184, 77, 0.12)`

### Subtitle

- Font: Inter, weight 400, italic
- Size: 14px
- Color: `#B8B8B8` (TEXT_SECONDARY)
- Letter-spacing: 1px
- Margin-top from title: 6px (tight spacing)
- Text: "a game about fireworks" (lowercase, italic)

### Menu

- Margin-top from subtitle: 88px (large gap — the title/subtitle is the branding block, menu is the interaction block)
- Layout: flex column, gap 4px, align-items: flex-end

**Menu items:**
- Font: Inter, weight 500 (600 for primary/active)
- Size: 15px
- Letter-spacing: 2px
- Text-transform: uppercase
- Padding: 10px 0
- Min-width: 280px
- Text-align: right
- Default color: `#888888` (TEXT_MUTED)
- Primary color: `#B8B8B8` (slightly brighter for the recommended action)
- Disabled color: `#444444`
- Active/hover color: `#FFB84D` (ACCENT_AMBER)
- Transition: all 200ms ease

**Active/hover state:**
- Color shifts to amber
- Padding-right shifts from 0 to 12px (item slides toward the right edge)
- No icon indicator needed — color + shift is sufficient

### Bottom bar

- Position: absolute, bottom 20px, left 0, right 0
- Padding: 0 40px
- Display: flex, space-between, center-aligned

**Studio credit (left):**
- Font: Inter, 11px
- Color: `#555555`
- Letter-spacing: 2px
- Text-transform: uppercase
- Text: "Missing Page Studios"

**Version (right):**
- Font: Inter, 11px
- Color: `#555555`
- Letter-spacing: 1px
- Text: "v0.1.0" (actual version pulled from project config)

---

## MENU STRUCTURE

### Menu items in order

1. **New Game** — start a fresh 100-night run
2. **Continue** — resume in-progress run (disabled if no save)
3. **Unlockables · N** — browse cross-run persistent unlocks (where N is count of unlocked fireworks, e.g., "Unlockables · 3")
4. **Settings** — audio, display, controls
5. **Credits** — team and acknowledgments
6. **Quit** — exit to desktop

### Menu state logic

**First-time player (no save exists):**
- New Game is the primary/highlighted item
- Continue is disabled (dimmed)

**Returning player (active run exists):**
- Continue is now the primary/highlighted item
- New Game becomes a normal menu item (not primary)
- Clicking New Game should prompt confirmation: "Start a new run? Your current progress will be lost."

**After run completes:**
- No active run, save deleted or marked complete
- Returns to "first-time player" state — New Game primary, Continue disabled

### Unlockables count display

Show `Unlockables · 3` (where 3 is the current unlocked count). Use middle-dot `·` separator.

Don't show the total (50). This preserves discovery — players know there's more to unlock without knowing the ceiling.

If nothing is unlocked yet, show just "Unlockables" (no count).

---

## MENU ENTRANCE ANIMATION

When the title screen loads, menu items should tween in from the right. Effect should be graceful but swift — elegant, not flashy.

### Timing

- Total animation duration: ~600ms from first to last item
- Per-item duration: 300ms
- Stagger between items: 60ms (so items cascade in rapid succession)

### Per-item motion

**Starting state:**
- Transform: translateX(60px) — offscreen to the right
- Opacity: 0

**Ending state:**
- Transform: translateX(0)
- Opacity: 1

**Easing:** `ease-out` (starts fast, slows at end — feels "placed" rather than "thrown")

### Stagger order

Items animate from top to bottom:
1. New Game (delay 0ms)
2. Continue (delay 60ms)
3. Unlockables (delay 120ms)
4. Settings (delay 180ms)
5. Credits (delay 240ms)
6. Quit (delay 300ms)

All complete by ~600ms after screen load.

### Title and subtitle animation

The title and subtitle should fade in BEFORE the menu starts animating.

- Title: fade in from 0 to 1 opacity over 800ms, starting at 0ms
- Subtitle: fade in from 0 to 1 opacity over 400ms, starting at 400ms
- Menu: starts animating at 800ms (after title has settled)

Total screen entrance: ~1.4 seconds from launch to fully loaded.

### Godot implementation

Use `Tween` nodes to drive the animation:

```gdscript
func _ready():
    # Start elements in their "off" state
    title.modulate.a = 0
    subtitle.modulate.a = 0
    for item in menu_items:
        item.modulate.a = 0
        item.position.x += 60  # offscreen to right
    
    # Title fade in
    var title_tween = create_tween()
    title_tween.tween_property(title, "modulate:a", 1.0, 0.8)
    
    # Subtitle fade in (delayed)
    var subtitle_tween = create_tween()
    subtitle_tween.tween_interval(0.4)
    subtitle_tween.tween_property(subtitle, "modulate:a", 1.0, 0.4)
    
    # Menu cascade
    var menu_delay = 0.8
    for i in range(menu_items.size()):
        var item = menu_items[i]
        var item_tween = create_tween()
        item_tween.set_ease(Tween.EASE_OUT)
        item_tween.set_trans(Tween.TRANS_CUBIC)
        item_tween.tween_interval(menu_delay + i * 0.06)
        item_tween.parallel().tween_property(item, "position:x", item.position.x - 60, 0.3)
        item_tween.parallel().tween_property(item, "modulate:a", 1.0, 0.3)
```

(Adjust syntax to match your Godot version and scene structure. Key point: simultaneous x-position tween and opacity tween per item, with staggered start times.)

### Skipping animation

If the player clicks or presses any key during the entrance animation, complete it immediately. Don't force them to wait.

---

## INTERACTION BEHAVIORS

### Mouse hover

- Menu item color transitions to amber
- Padding-right transitions from 0 to 12px (subtle slide-right)
- Cursor: pointer
- No sound effect at this stage (can add later)

### Click / select

- Menu item briefly flashes slightly brighter amber (100ms)
- Then executes the action:
  - **New Game**: if save exists, show confirmation modal. Otherwise, start new run
  - **Continue**: load existing save, go to planning screen
  - **Unlockables**: navigate to unlockables submenu (separate screen, to be designed)
  - **Settings**: navigate to settings submenu (separate screen, to be designed)
  - **Credits**: navigate to credits screen (separate screen, to be designed)
  - **Quit**: exit game

### Keyboard navigation

- Up/Down arrow keys: move between menu items
- Enter or Space: select current item
- Escape: no action on title screen (or optional: highlight Quit)

The keyboard-focused item should show the same amber color + padding-right shift as hover state.

---

## AMBIENT BACKGROUND EFFECTS (OPTIONAL)

If time permits after core implementation:

### Star twinkle

- 50-100 small white dots in upper 60% of screen
- Animate opacity between 0.3 and 0.9 on individual random cycles (3-5 second periods)
- Not synchronized — each star twinkles independently

### Ambient fireworks

- 2-3 firework "bursts" appear on the LEFT side of the screen over time
- Positions vary each time (but always in left 50% of screen)
- Colors vary: amber, blue-white, soft pink, soft green
- Each burst: appears, pulses outward, fades
- Total cycle: 5-10 seconds between any visible burst
- Sized to fit the scene — not dominating, just atmospheric

### Launch trails

- Occasionally a thin amber trail rises from below the horizon (bottom of screen) before a firework burst
- Appears roughly 0.5 seconds before each burst
- Rises 20-30% of screen height then fades
- Creates visual cause-and-effect with the bursts

These effects should feel sparse and melancholic — not a constant fireworks show. The idea is "a lone performer working on the mountain" — occasional bursts, not a celebration.

---

## IMPLEMENTATION PRIORITY

### Phase 1: Core layout (~1 hour)
1. Add Cormorant Garamond font to project with correct import settings
2. Build title screen scene with background, title, subtitle, menu
3. Match typography and positioning from wireframe
4. Verify with static screenshot before adding animation

### Phase 2: Menu logic (~45 min)
1. Implement save state detection
2. Wire menu items to their navigation targets (even if targets are placeholder scenes)
3. Implement Continue primary-state logic based on save existence
4. Add Unlockables count display

### Phase 3: Entrance animation (~30 min)
1. Title fade-in
2. Subtitle fade-in
3. Menu cascade from right
4. Skip-on-click

### Phase 4: Ambient effects (optional, ~45 min)
1. Star twinkle particles
2. Ambient firework bursts (left side only)
3. Launch trails

**Total estimated time: 2-3 hours.**

Phases 1-3 are the minimum viable implementation. Phase 4 is polish that makes the screen feel alive.

---

## VERIFICATION CHECKLIST

After implementation:

**Typography:**
- [ ] Title renders in Cormorant Garamond SemiBold
- [ ] Title is single line "The Last Show" (title case, not uppercase)
- [ ] Subtitle renders in Inter italic
- [ ] Menu items render in Inter uppercase
- [ ] All fonts render crisply (antialiasing correct)

**Layout:**
- [ ] Content column positioned on right side (7% from edge)
- [ ] Content column vertically centered
- [ ] Title, subtitle, and menu all right-aligned
- [ ] Title and subtitle tight together (~6px gap)
- [ ] Large gap (~88px) between subtitle and menu

**Background:**
- [ ] Zone 6 mountain vista fills viewport
- [ ] Background displays without distortion

**Menu logic:**
- [ ] First-time play: New Game primary, Continue disabled
- [ ] With save: Continue primary, New Game normal
- [ ] Unlockables shows count when applicable
- [ ] Clicking Quit exits game

**Animation:**
- [ ] Title fades in first
- [ ] Subtitle fades in shortly after
- [ ] Menu items cascade in from right, top to bottom
- [ ] Animation completes within ~1.4 seconds
- [ ] Clicking during animation completes it immediately
- [ ] Hover state transitions smoothly (amber + slide-right)

**Ambient (if implemented):**
- [ ] Stars twinkle independently in upper sky
- [ ] Occasional firework bursts on left side of screen
- [ ] Launch trails appear before bursts
- [ ] Effects are sparse — not overwhelming

---

## WHAT COMES NEXT

After title screen is done, we design the Unlockables submenu. That screen will:
- Display all 50 fireworks with unlock status
- Show unlock conditions for locked items
- Show preview animation for unlocked items
- Allow navigation back to title

Not part of this spec — will be a separate design session once title screen is in place.
