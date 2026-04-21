# LAUNCH Stage 2 — Early Corrections

**Context:** First playable of Planning Screen revealed several issues. This doc addresses them.

---

## Issue 1: Font Not Loaded (Critical)

The m6x11plus.ttf font referenced in the PRD was never actually provided to Claude Code. The default Godot font is being used, which is why text appears small and generic.

### Fix:

1. Download `m6x11plus.ttf` from https://managore.itch.io/m6x11 (free font by Daniel Linssen)
2. Place the file at: `assets/fonts/m6x11plus.ttf`
3. Update `themes/default.tres` to:
   - Set DefaultFont to `res://assets/fonts/m6x11plus.ttf`
   - Set DefaultFontSize to `16`
4. Apply font size overrides where appropriate:
   - Screen headers and major labels: font size 32
   - Screen titles (title screen "THE LAST SHOW", ending screen headers): font size 48
   - Everything else: font size 16 (default)

### Why these specific sizes:

m6x11 is a pixel-perfect bitmap-style font. It renders cleanly only at integer multiples of its base cell height. The three valid sizes are:
- 16 (body text, most UI)
- 32 (headers, large labels, stat values on top bar)
- 48 (screen titles only)

**Do NOT use non-integer multiples** (e.g., 18, 20, 24) — the font will render with uneven pixel sampling and look broken.

---

## Issue 2: All 50 Fireworks Showing at Zone 1 (Bug)

At Zone 1, the player should only see Tier 1 fireworks. Tier 2 unlocks at Zone 2, Tier 3 at Zone 3, Tier 4 at Zone 4. Additionally, unlockable fireworks should only appear if the player has earned the unlock.

### Fix:

The Fireworks panel's list should call `GameEngine.available_fireworks(state)` which returns the properly filtered list based on:
- Current zone (tier gating)
- MetaState.unlocked_fireworks (achievement gating)

Current code is probably iterating over the full `fireworks` array in config. Replace with the engine's filter method.

### Expected results per zone:

- **Zone 1 (Backyard):** Only Tier 1 fireworks visible (about 8-10 items)
- **Zone 2 (Neighborhood):** Tier 1 + Tier 2 (about 18-20 items)
- **Zone 3 (Town):** Tier 1-3 (about 38-40 items)
- **Zone 4+ (City, Regional, World):** All tiers available based on unlock status

---

## Issue 3: No Atmospheric Background (Major Visual Fix)

Current Planning Screen has pure dark navy void behind the UI panels. This works mechanically but loses the game's atmospheric identity. Players should SEE hints of the world they're building their fireworks career in.

### Fix: Add a zone-specific atmospheric background layer

**Layer structure (back to front):**

1. **Background: Night sky gradient**
   - Fills entire screen
   - Simple vertical gradient using palette: `#0A1028` (top, deep night) to `#2A3055` (bottom, slightly lighter near horizon)
   - Optional: very sparse scattered stars (single 1-pixel cream dots, maybe 20-30 total across screen)
   - This layer is always visible through the UI

2. **Middle: Zone-specific silhouette band**
   - Horizontal band in the lower half of the screen, roughly y=360 to y=620
   - Dark silhouette shape in `#050815` (even darker than night_deep to read as foreground)
   - Shape varies by zone (see per-zone specs below)

3. **Foreground: UI panels with slight transparency**
   - Panels currently use `#121838` solid background
   - Change to `#121838` with 92% opacity (8% transparency), so background is subtly visible
   - Panel borders `#2A3055` stay solid
   - This gives the UI weight while letting the world breathe through at panel edges and gaps between panels

### Per-zone silhouette content:

Stage 2 should stub these with simple placeholder silhouettes. Actual art comes later. For now, simple pixel-art shapes in `#050815`:

- **Zone 1 (Backyard):** A simple peaked-roof house shape on the right, a tree silhouette on the left, a fence line across the bottom
- **Zone 2 (Neighborhood):** 3-4 houses of varying heights, a streetlight or two
- **Zone 3 (Town):** Small civic building (courthouse shape), church steeple, rowhouses
- **Zone 4 (City):** Blocky mid-rise skyline with varying building heights
- **Zone 5 (Regional):** Larger skyline with recognizable "tall building" shapes
- **Zone 6 (World):** Massive stadium or iconic venue shape with skyline behind

These can be simple CanvasLayer nodes with hand-drawn rectangles in Godot for now. Claude Code doesn't need to create pixel-art assets — just use primitive shapes to establish the visual language. Real art comes in a later pass.

### Important: UI panel backgrounds need slight opacity

Even with 92% opaque panels, the difference is subtle but noticeable:
- Panels read as "floating above" the scene, not pasted onto it
- The gap between panels (16px spacing) lets slivers of background through
- Bottom bar and top bar backgrounds should also become 92% opaque

### Horizon glow (optional polish)

Between the sky and silhouette, a thin horizontal band of slightly warmer dark color (like a 20-30px tall gradient from `#0A1028` to `#1A1525`) can suggest city light pollution. Increases with zone progression:
- Zone 1: no glow (rural)
- Zone 2: barely visible
- Zone 3: subtle orange tint
- Zone 4-6: stronger orange glow

Stage 2 can ship without this. Add if time allows.

---

## Issue 4: Firework Cards Too Cramped (From Screenshot)

The current firework list renders each firework as a single compact text line. The wireframe spec called for 80px tall cards with Name / Stats line / Tags / Quantity controls.

### Fix:

Each firework should render as a card at 80px tall:

```
┌─────────────────────────────────────────────────────┐ 
│  Sparkler                                    [T1]  │  y=12 (name + tier badge)
│  $2 · 1 eng · classic, beginner                    │  y=34 (combined stats+tags)
│  [ - ]  [ 0 ]  [ + ]                      $0       │  y=54 (quantity + cost preview)
└─────────────────────────────────────────────────────┘
```

- Card background: `#1A2048` (affordable) or `#121838` (unaffordable/locked)
- Card padding: 12px
- Name: 16px cream_bright, left-aligned
- Tier badge: 16×16px, right-aligned (placeholder: use colored square with tier number in it)
- Stats line: 16px cream_bright "cost · engagement · tags" combined with middle-dot separator
- Quantity controls: [-] [qty] [+] at bottom left
- Cost preview: right-aligned at bottom, 16px gold (shows "$N" when qty > 0, empty when 0)

Reference the wireframe doc (`wireframe_planning_screen.md`) for exact dimensions.

### Also: Selected state visual

When a firework has qty > 0, add a 1-pixel gold border around the card (`#FFD700`). This tells the player at a glance what's in their show.

---

## Issue 5: Upgrade List Behavior (From Screenshot)

Current screenshot shows the Upgrades column listing ALL upgrades including ones locked by zone requirements. They're shown with "(locked)" prefix. This is functional but doesn't match the wireframe spec.

### Fix:

Upgrades column should have three sections with dividers:

```
─── OWNED ───
✓ Flyer Printer               (owned)

─── AVAILABLE ───
┌────────────────────────────────┐
│ Website                   [Mkt]│
│ $1,500                         │
│ +50 attendees permanent        │
│                          [Buy] │
└────────────────────────────────┘
[more available upgrades as cards]

─── LOCKED ───
🔒 Production Team          Zone 4+
🔒 Pyrotechnic Crew         Zone 3+
```

- Owned upgrades: compact 44px row with checkmark
- Available upgrades: full 88px cards with Buy button
- Locked upgrades: compact 44px row with lock icon, dimmed, showing zone requirement

Reference wireframe doc for full spec.

Also: the sub-tabs (All / Crew / Infra / Rev / Mkt) filter the list. These should be visible at the top of the upgrades panel.

---

## Issue 6: "Fire Show" Button Label (Minor)

The screenshot shows "Fire Show →" as the primary button. Per spec and wireframe, it should be "▶ Run Show" (play arrow + label).

The word "Fire" is fine narratively but "Run Show" matches the incremental game convention of "running" an action. Minor but worth standardizing now.

---

## Issue 7: Top Bar Cash/Fans Positioning (Minor)

The screenshot shows:
- "Cash: $10" at top right
- "Fans: 0" to its left

Per spec:
- Cash should be 32px gold top-right
- Fans should be 16px muted cream BELOW the cash (stacked vertically, not side-by-side)

This gives cash more prominence (it's the primary resource) and fans secondary status.

---

## Priority Order for Fixes

1. **Font** (everything else looks wrong until this is right) — CRITICAL
2. **Firework filtering** (game is broken at Zone 1 without this) — CRITICAL
3. **Firework card rendering** (affects playability) — HIGH
4. **Atmospheric background** (affects game feel) — HIGH
5. **Upgrade column sections** (affects usability) — MEDIUM
6. **Top bar positioning** (affects polish) — LOW
7. **Button label text** (minor consistency) — LOW

Fixes 1, 2, 3 should happen immediately. Fix 4 (background) is the biggest visual improvement and should happen before further screens are built so the pattern carries across Results, Donation, etc.

---

## Verification

After these fixes, the Planning Screen at Night 1 / Zone 1 / Backyard should show:

- 8-10 Tier 1 firework cards visible in the left column (not 50 items)
- Text rendered in m6x11 pixel font at correct sizes (16/32/48)
- Backyard silhouette visible behind the semi-transparent UI panels (house, tree, fence)
- Dark night sky gradient behind everything
- Properly styled firework cards at 80px tall with quantity controls
- Upgrades column showing Owned (Flyer Printer maybe), Available (a couple of cheap Tier 1 upgrades), and Locked (everything else)
- Clean top bar with Night/Zone/Cash/Fans properly positioned

If that matches, we're ready to move to the next screen (Results).
