# THE LAST SHOW — UI Polish Pass & Firework Info Modal

**Context:** The planning screen pivot to modern UI worked well. This spec covers the polish pass to fix remaining issues plus the design for the firework info modal.

**Two major deliverables:**
1. Polish pass on existing planning screen (fix critiqued issues)
2. New firework info modal (large animation area + stats display)

---

## PART 1: PLANNING SCREEN POLISH

### 1.1 Panel transparency — the background barely shows through

**Current:** Panels are ~85% opaque. Atmospheric Zone 1 background is barely visible.

**Fix:** Drop panel opacity to 55-60%.

```gdscript
# Update panel background
PANEL_BG = Color("#0F1423", 0.55)  # Was 0.70 or higher
```

Expected result: the backyard silhouette, tree, house, fire pit, and stars should all be clearly visible through the panels. The UI should feel layered over the world, not pasted on top.

### 1.2 Locked row readability issue (Social Media Accounts)

**Current:** Locked upgrade rows have low opacity and the bright window in the background bleeds through, making text unreadable.

**Fix:** Add a consistent dark backing to locked rows specifically.

```gdscript
# Locked row styling:
background: Color("#0A0E1A", 0.75)  # Darker, more opaque than regular rows
# Text remains dim cream
# Lock icon at start
```

Locked rows get their own solid-ish backdrop so text is always readable regardless of what's behind the panel. Regular available rows can stay translucent; locked rows get the readability treatment.

### 1.3 Top bar spacing issues

**Current problems:**
- Empty gray box between fans display and cash (placeholder that didn't render?)
- Dollar icon duplicated (we have $ icon AND "$10")
- Fans icon is smaller than other elements
- "NIGHT 1" looks like two different fonts/styles

**Fixes:**

**Remove duplicate dollar sign.** Just show the value in amber:
```
[fans icon 18px]  0 / 20 fans  [▰▱▱▱▱]    $10
```
No money icon. The amber color + right-aligned position + context is enough.

**Fans icon sizing:** Match 18px consistently with other top-bar icons. Currently looks smaller than it should be.

**Investigate the empty gray box:** Probably a progress bar that didn't render, or a placeholder for something. Either fill it with actual content (fans progress bar) or remove it entirely.

**"NIGHT 1" font consistency:** 
- "NIGHT" — Inter 11px semibold, uppercase, letter-spacing 1.5px, color TEXT_MUTED
- "1" — Inter 16px semibold, same font family, color TEXT_PRIMARY
- Same font family throughout. "1" is just bigger and brighter, not a different typeface.

### 1.4 Enhancement checkbox → toggle button system

**Current:** Enhancement options use checkboxes, taking up lots of vertical space.

**Fix:** Replace with horizontal toggle row per category. Each category is ONE row with all options as inline pills.

```
SNACKS    [ None ]  [ Candy $20 ]  [ Premium $50 ]
SOUND     [ None ]  [ Boombox $50 ]  [ Basic PA $300 ]
HOST      [ None ]  [ Local MC $50 ]  [ Pro Host $200 ]
```

**Pill styling:**
- Height: 32px
- Padding: 6px 14px
- Border-radius: 4px
- Inter 13px medium
- Default: transparent background, subtle border (`rgba(255,255,255,0.1)`), text `TEXT_MUTED`
- Selected: amber-tinted background `rgba(255, 184, 77, 0.15)`, amber border, amber text
- Hover: slightly brighter background, subtle border brighten
- One pill per category can be selected (radio-style, mutex within category)
- "None" is selected by default in each category

**Category label styling:**
- Inter 11px semibold, uppercase, letter-spacing 1.5px
- Color: TEXT_MUTED
- Left-aligned, 12px space before pills

**Benefits:**
- Takes ~40% less vertical space than current checkbox rows
- Clearer that it's a choice between options (pills are inherently comparative)
- Matches the compact modern aesthetic
- All enhancement categories visible at once without scrolling

### 1.5 Tab labels — full words or icons, not abbreviations

**Current:** "ALL / CREW / INFRA / REV / MKT" — players don't know what "MKT" or "INFRA" mean.

**Fix options:**

**Option A (recommended): Icons only with hover tooltips**

Replace text labels with category icons (once new icons arrive):
```
[📋 all]  [👥 crew]  [🏢 infra]  [💰 rev]  [📢 mkt]
```

Show full name in tooltip on hover. Saves space, looks cleaner, teaches icons over time.

**Option B: Full words if space permits**

```
[ All ] [ Crew ] [ Infrastructure ] [ Revenue ] [ Marketing ]
```

Might overflow on 400px panel. Test fitting.

**Option C: Hybrid — icon + short word**

```
[👥 Crew] [🏢 Infra] [💰 Rev] [📢 Mkt]
```

Still uses abbreviations but with clarifying icons. Compromise.

**My vote: Option A.** Icons + tooltips. Cleanest and scales to future if we add more categories.

### 1.6 Button styling consistency

**Current:** Plus/minus quantity buttons, BUY button, hamburger menu, info buttons all have inconsistent styling.

**Fix:** Establish a single button design system.

**Quantity buttons (±):**
- Size: 24×24
- Background: transparent
- Border: 1px solid `rgba(255,255,255,0.15)`
- Border-radius: 3px
- Icon: Inter 14px or icon font, color TEXT_SECONDARY
- Hover: amber border, amber icon, subtle amber background
- Active/pressed: amber background, dark icon

**BUY button:**
- Size: ~64x26
- Background: `rgba(255, 184, 77, 0.15)` amber tint
- Border: 1px solid `rgba(255, 184, 77, 0.4)`
- Text: "BUY" in Inter 11px semibold, amber, uppercase, letter-spacing 1px
- Border-radius: 3px
- Hover: solid amber background, dark navy text
- Disabled: transparent background, muted border, dim text

**Info button (i):**
- Size: 24×24
- Circular border: 1px `rgba(255,255,255,0.2)`
- Icon: "i" character OR info.png (once available), color TEXT_MUTED
- Hover: amber border, amber icon
- Should look intentional, not glitched

**Hamburger menu button:**
- Size: 36×36
- Background: transparent
- Border: 1px solid `rgba(255,255,255,0.15)`
- Border-radius: 4px
- Icon: ☰ or menu.png (once available), color TEXT_MUTED
- Hover: amber border, amber icon

All buttons share the same design language: transparent default, subtle border, amber on hover. Consistency across the whole UI.

### 1.7 Info icons — fix the weird pixel artifacts

**Current:** Info buttons look glitched, with weird pixels above and below the "i" character.

**Diagnosis:** Likely a font rendering issue — the "i" character's dot is being clipped or the descender space shows artifacts. Could also be leftover pixel icons being downscaled incorrectly.

**Fix:**
- Use the new info.png icon when it arrives (modern line-style)
- Temporarily: use a clean "i" character in Inter font, italic, 11px semibold, center-aligned inside the circular button
- Verify no other rendering artifacts (padding, line-height)

### 1.8 Font consistency across item names

**Current:** Firework names appear bold; upgrade names appear in a different style (more muted).

**Fix:** All list item names use identical typography.

```
Firework row name: Inter 14px medium, TEXT_PRIMARY
Marketing row name: Inter 14px medium, TEXT_PRIMARY
Enhancement pill name: Inter 13px medium, varies by state
Upgrade row name: Inter 14px medium, TEXT_PRIMARY
```

Same weight, same color, same size for all item names across the three panels. The visual hierarchy comes from row styling (backgrounds, borders), not from inconsistent typography.

### 1.9 Remove or hide the "eng" abbreviation

**Current:** Rows show `$2 · 1 eng` — players don't know what "eng" means.

**Per your decision:** Remove stats from firework rows entirely. Rows become minimal:

```
▌ Sparkler                      $2    [−] 0 [+]  (i)
▌ Firecracker                   $3    [−] 0 [+]  (i)
▌ Snake                         $4    [−] 0 [+]  (i)
```

Just: tier stripe, name, cost, quantity, info button. All detailed stats live in the info modal.

Marketing rows also simplify:
```
▌ Flyers                  $10 · +5 att    [−] 0 [+]
```

Marketing keeps its effect description (+5 att) because marketing's effect is simple and worth showing inline.

### 1.10 Panel and section headers — hierarchy fix

**Current:** Section headers (OWNED, AVAILABLE, LOCKED) are smaller than subsection headers (Snacks, Sound, Host) in the Enhancements column. Visual hierarchy is backwards.

**Correct hierarchy (top to bottom in importance):**
1. Panel titles (FIREWORKS, MARKETING & ENHANCEMENTS, UPGRADES): 11px semibold uppercase, letter-spacing 2px, TEXT_MUTED
2. Section headers (MARKETING, ENHANCEMENTS, OWNED, AVAILABLE, LOCKED): same style as panel titles
3. Category/subsection labels (Snacks, Sound, Host): 11px semibold uppercase, letter-spacing 1.5px, TEXT_MUTED — SAME SIZE as sections, slightly less letter-spacing
4. Row content: 14px medium, TEXT_PRIMARY

All header levels are similar size. Hierarchy comes from letter-spacing differences and vertical spacing, not size jumps.

---

## PART 2: FIREWORK INFO MODAL

### 2.1 Trigger behavior

Modal opens when:
- Player clicks the (i) info button on a firework row
- Player clicks anywhere on the firework row body (not the +/− buttons, not the info button — they have their own handlers)

Modal dismisses when:
- Player clicks the X close button
- Player presses ESC key
- Player clicks outside the modal (on the dimmed backdrop)

All three methods should work. Standard modal behavior.

### 2.2 Modal structure and layout

**Modal dimensions:**
- Width: 720px
- Height: 480px
- Centered in the 1280×720 canvas
- Backdrop: `rgba(0, 0, 0, 0.6)` dark overlay covering whole screen
- Modal background: `rgba(15, 20, 35, 0.95)` — nearly opaque, slightly translucent
- Border: 1px `rgba(255, 255, 255, 0.1)`
- Border-radius: 8px (slightly more rounded than panels for modal presence)
- Box-shadow: `0 8px 32px rgba(0, 0, 0, 0.5)` — dramatic drop shadow to float above UI

**Layout: two-column split**

Left half (animation area): ~350px wide
Right half (stats and details): ~370px wide

```
┌────────────────────────────────────────────────────────────────┐
│  [X]                                                            │
│                                                                  │
│  ┌──────────────────────┐  SPARKLER         Tier 1       │
│  │                      │                                  │
│  │                      │  A humble handheld sparkler.     │
│  │  [ANIMATION          │  Nostalgic but unimpressive.     │
│  │   AREA - looping     │                                  │
│  │   particle effect]   │  Cost: $2                        │
│  │                      │                                  │
│  │                      │  Tips       ★☆☆☆☆              │
│  │                      │  Reach      ★☆☆☆☆              │
│  │                      │  Retention  ★★☆☆☆              │
│  │                      │                                  │
│  │                      │  Effectiveness in Zone 1: ●●●●● │
│  └──────────────────────┘                                  │
│                                                                  │
│                                            [ Close ]            │
└────────────────────────────────────────────────────────────────┘
```

### 2.3 Animation area (left side)

**Dimensions:** ~340px × 340px, positioned in the left half with 20px padding on all sides.

**Stage 2 approach:** Static pixel art illustration or placeholder image. Since we don't have particle effects implemented yet, use a simple representation:
- Zone-atmospheric mini-background (dark sky)
- Pixel art tier indicator or simple firework silhouette centered
- Firework name overlay
- Animated using simple CSS/Godot motion (gentle pulse or glow)

**Stage 3 approach (future):** Replace static image with actual particle animation of the firework. Loops continuously while modal is open. Uses the same particle system as the in-game show rendering.

**For Stage 2 implementation:**
- Use a container with dark background matching the sky color
- Display a stylized pixel art representation of the firework type (can be placeholder)
- Add text: "Preview animation coming in Stage 3" or just show a simple effect
- Pulse/glow animation via CSS/Godot transform for visual interest

**Container styling:**
- Background: `rgba(10, 14, 28, 0.8)` — dark navy, slightly translucent
- Border: 1px `rgba(255, 255, 255, 0.08)`
- Border-radius: 6px
- Overflow: hidden (clips animation content)

### 2.4 Details area (right side)

**Header section:**

Firework name: Inter 24px bold, TEXT_PRIMARY
Tier indicator: amber pill badge inline with name — "Tier 1" in 11px semibold amber, uppercase

Example:
```
SPARKLER     [Tier 1]
```

**Description:**

Inter 14px regular, TEXT_SECONDARY
2-3 sentences of flavor text describing the firework
~48px tall area for description

Example:
```
"A humble handheld sparkler. Quiet and safe — 
perfect for beginners or adding atmosphere to 
low-key events."
```

**Cost display:**

Inter 18px semibold, amber color
Label "Cost:" in 12px uppercase, TEXT_MUTED
Example:
```
Cost:  $2
```

**Stats display (Tips / Reach / Retention):**

Each stat shown as:
- Stat name: Inter 13px medium, TEXT_PRIMARY (e.g., "Tips")
- Star rating: 5 stars, filled with amber or empty outline
- Optional: brief effect description in smaller text below

```
Tips        ★☆☆☆☆       Low money return
Reach       ★☆☆☆☆       Barely spreads word
Retention   ★★☆☆☆       Simple but pleasant
```

Star rendering uses the star_full.png and star_empty.png icons we're generating. Each star is 14px, spaced 2px apart.

**Effectiveness indicator:**

Shows how effective this firework is at the current zone (because of the zone relevance falloff mechanic).

```
Effectiveness in Zone 1:  ●●●●● Full
Effectiveness in Zone 4:  ●●◯◯◯ Diminished
```

5-dot visualization: filled dots represent current effectiveness level. At the firework's native tier, all 5 dots filled. Further from native tier, fewer dots filled.

Label text:
- "Full" at native tier
- "Strong" at 1 zone ahead
- "Moderate" at 2 zones ahead
- "Diminished" at 3 zones ahead
- "Minimal" at 4+ zones ahead

Inter 12px medium, colored based on level:
- Full: TEXT_PRIMARY
- Strong/Moderate: TEXT_SECONDARY
- Diminished/Minimal: TEXT_DIM

### 2.5 Modal close button

Top-right corner of modal, 16px from edges.
- Size: 24×24
- Icon: X shape (close.png once available, or Unicode "×")
- Color: TEXT_MUTED default
- Hover: amber
- Background: transparent
- No border

### 2.6 Bottom of modal

Optional "Close" button centered at bottom for users who prefer explicit action.
- Inter 12px medium, TEXT_MUTED
- Transparent background
- 1px border `rgba(255,255,255,0.15)`
- Padding 8px 24px
- Border-radius: 4px
- Hover: subtle background, text primary

Optional — ESC and X close handle primary dismissal. This is a redundancy for accessibility.

### 2.7 Modal animations

**Open:**
- Backdrop fades in over 150ms
- Modal scales from 95% to 100% while fading in (150ms ease-out)

**Close:**
- Reverse of open (150ms ease-in)
- Modal scales down slightly while fading out

Gentle, not dramatic. Modal should feel responsive, not flashy.

### 2.8 Data population

Modal reads from the firework data structure:

```gdscript
# Example firework data
{
    "id": "sparkler",
    "name": "Sparkler",
    "tier": 1,
    "cost": 2,
    "tips": 1,          # 0-5 integer star rating (displayed)
    "reach": 1,
    "retention": 2,
    "tips_raw": 0.01,   # underlying probability (used in calculation)
    "reach_raw": 0.02,
    "retention_raw": 0.05,
    "description": "A humble handheld sparkler...",
    "style": "handheld_sparkle"  # used for rendering in Stage 3
}
```

For Stage 2, the `_raw` values might not be needed yet (we'll plug them in during balance rework). Star ratings can display with placeholder values until balance is finalized.

### 2.9 Implementation notes

**State management:**
- Modal should be a single reusable component that takes a firework_id parameter
- Shows when a signal is emitted with the firework_id
- Hides on close signal

**Z-index:**
- Modal and backdrop must render above everything else
- Main UI continues to display but is visually dimmed by the backdrop

**Performance:**
- Stage 2 animation is CPU-cheap (static image or simple transform)
- Stage 3 animation will use the shared particle system
- Modal doesn't need to redraw constantly — only when data changes

---

## PART 3: IMPLEMENTATION PRIORITY

### Phase 1: Critical polish fixes (do first)

1. Panel transparency reduction to 55-60%
2. Locked row darker backdrop for readability
3. Remove duplicate dollar icon in top bar
4. Fix top bar spacing (empty box investigation)
5. NIGHT 1 font consistency
6. Enhancement row redesign (checkboxes → pills)
7. Remove "eng" from firework rows (per your decision: remove stats entirely from rows)
8. Font consistency across item names

Estimated: ~4-5 hours

### Phase 2: UI system consistency

9. Button styling system (quantity, BUY, info, menu)
10. Tab label treatment (icons + tooltips when icons arrive)
11. Info icon artifact fix
12. Section header hierarchy

Estimated: ~3-4 hours

### Phase 3: Firework info modal

13. Modal component structure and sizing
14. Animation area placeholder (Stage 2 version)
15. Stats display with star ratings
16. Effectiveness indicator
17. Open/close animations
18. Integration with firework rows (click handlers)

Estimated: ~4-5 hours

**Total: ~11-14 hours**

Can be split across multiple sessions. Phase 1 delivers the biggest visible improvement, Phase 2 tightens consistency, Phase 3 adds the new modal functionality.

---

## PART 4: WHAT'S BLOCKED ON OTHER WORK

These items depend on work happening elsewhere:

**Blocked on new modern icon set (Rob generating):**
- Tab labels as icons (currently placeholder text)
- Info button icon (currently character placeholder)
- Hamburger menu icon (currently character placeholder)
- Star ratings in info modal (uses star_full.png, star_empty.png)
- Category icons in upgrade rows
- Money/fans icons in top bar

**Blocked on balance rework (happening in parallel):**
- Firework stat values (tips/reach/retention star ratings)
- Zone effectiveness curve values
- Description text for each firework
- Star thresholds for show rating

Claude Code can implement all the UI structure with placeholder data and icons. As icons arrive and balance values are determined, the data plugs into the existing UI without structural changes.

---

## PART 5: VERIFICATION CHECKLIST

After implementation:

**Top bar:**
- [ ] No duplicate dollar icons
- [ ] All icons same size (18px)
- [ ] "NIGHT 1" uses consistent font family
- [ ] No empty placeholder boxes
- [ ] Cash display reads cleanly

**Panels:**
- [ ] Atmospheric background clearly visible through panels
- [ ] Panel translucency feels layered, not opaque
- [ ] Consistent 1px subtle borders

**Firework rows:**
- [ ] No stats visible on rows (just name + cost + qty + info)
- [ ] Tier color stripe clearly visible
- [ ] Info button looks intentional (no pixel artifacts)
- [ ] Row height compact (~52px)

**Enhancements:**
- [ ] Toggle pill system replaces checkboxes
- [ ] Three rows (Snacks/Sound/Host), not multiple rows per category
- [ ] Selected pill has clear amber treatment
- [ ] Takes significantly less vertical space than before

**Upgrades:**
- [ ] Locked rows readable despite background
- [ ] Tab labels either icons or full words (no abbreviations)
- [ ] Owned / Available / Locked sections have consistent hierarchy
- [ ] Font weight matches firework rows

**Buttons:**
- [ ] Plus/minus buttons have consistent style
- [ ] BUY buttons feel intentional (not generic)
- [ ] Hamburger menu looks clean, not glitched
- [ ] All buttons share design language (transparent → amber on hover)

**Info modal:**
- [ ] Opens on row click and (i) button click
- [ ] Closes via X, ESC, and backdrop click
- [ ] Left half has animation area (placeholder acceptable in Stage 2)
- [ ] Right half shows name, tier, description, cost, 3 stat ratings, effectiveness
- [ ] Smooth open/close animation
- [ ] Dark backdrop dims main UI

---

## NOTES FOR CLAUDE CODE

The planning screen structure is solid. Most of this work is refining what exists rather than rebuilding. Focus on:

1. **Small details compound.** Button inconsistency, font hierarchy, and padding issues individually look small but together make the UI feel "unpolished." Be thorough on the consistency items.

2. **Translucency is about layering.** The atmospheric background is the game's personality — don't hide it. Panels should sit ON the world, not in front of a wall.

3. **The modal is the first real "second screen" in the game.** Its quality sets expectations for other modals (donation screen, ending screens). Get the component right so it's reusable.

4. **When icons arrive, they slot in cleanly.** All icon placements are defined in this spec. Icon files drop in, code references them, done.

Hand off as a single polish + feature PR. Total work is ~11-14 hours. Should result in a planning screen that feels genuinely polished and a modal foundation usable for other screens.
