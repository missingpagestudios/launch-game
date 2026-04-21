# LAUNCH Stage 2 — Font Sizing Fix

Current screenshot shows font sizes are way too small throughout the Planning Screen. Body text appears to be 8-10px when spec requires 16px. Section headers are correct (32px), but everything else is wrong.

## The Rule

**Every piece of text in the game uses ONE of these three sizes. No exceptions. No in-between values.**

- **48px** — screen titles only (Title screen "THE LAST SHOW", Ending screen headers)
- **32px** — panel headers (FIREWORKS, MARKETING, UPGRADES), top bar elements (Night counter, Zone indicator, Cash display), major section labels
- **16px** — everything else (body text, card names, stat values, card content, buttons, labels, descriptions, costs, tags, rows)

## What Should Be 16px (currently too small)

Looking at the screenshot, these are ALL rendering smaller than 16px and need to be 16px:

**In Fireworks panel:**
- Firework names ("Sparkler", "Firecracker", "Snake", etc.) — should be 16px cream_bright
- Stats lines ("$2 · 1 eng · handheld, golden") — should be 16px cream_bright
- Tier badges (T1 text inside badges) — should be 16px
- Quantity display numbers — should be 16px
- [-] and [+] button labels — should be 16px

**In Marketing panel:**
- "Marketing" subsection label (currently smaller than the FIREWORKS header) — should be 16px cream_muted (or 24px if making it a subsection header, but 16px is the spec)
- "Flyers — $10, +5 attendees (cap 20)" — should be 16px
- "0" quantity display — should be 16px
- "Enhancements one per category" text — 16px
- "Snacks", "Sound", "Host" subsection labels — should be 16px
- Enhancement rows ("None", "Candy from Store — $20", etc.) — should be 16px

**In Upgrades panel:**
- Sub-tab labels (All, Crew, Infrastructure, Revenue, Marketing) — should be 16px
- Section dividers (OWNED, AVAILABLE, LOCKED) — should be 16px
- Upgrade row names ("Flyer Printer", "Website", etc.) — should be 16px
- Costs ("$500") — should be 16px
- "Zone 2+" requirements — should be 16px

**In top bar:**
- "Fans: 0" — should be 16px cream_muted

**In bottom bar:**
- "Select at least one firework to run a show" — should be 16px cream_muted
- "Spend: $0 / Cash: $10" — should be 16px (with cash value in gold)
- "Run Show" button label — should be 16px

## Possible Root Causes

### 1. Theme font size not being applied to child controls

In Godot, Theme inheritance can be finicky. Check:
- Theme has `Font/default_font` set to m6x11plus.ttf
- Theme has `Font/default_font_size` set to 16
- No parent control has a theme override that shrinks font size
- Individual Labels are NOT using `add_theme_font_size_override()` with smaller values

Remove any `add_theme_font_size_override()` calls unless they're setting 32 or 48 for headers.

### 2. Font metrics for m6x11plus may need manual configuration

m6x11plus is a bitmap-style TTF font. At 16px it should render as its intended pixel grid. If text is appearing smaller, the font import settings might need adjustment:

In Godot, select the .ttf file in FileSystem:
- **Rendering** section:
  - `Antialiasing`: **Disabled** (critical for pixel fonts)
  - `Hinting`: **None**
  - `Force Autohinter`: **Off**
  - `Subpixel Positioning`: **Disabled**
  - `MSDF Pixel Range`: 0
  - `MSDF Size`: 0 (don't use MSDF for pixel fonts)
  - `Oversampling`: 0 (disable oversampling)
- **Fallbacks**: empty

Re-import after changing these. The font should now render as crisp pixels at 16/32/48px.

### 3. DPI scaling in Godot

Check Project Settings:
- `Display > Window > Stretch > Mode`: should be **viewport** (for pixel-perfect UI)
- `Display > Window > Stretch > Aspect`: **keep**
- `Display > Window > Size > Viewport Width`: 1280
- `Display > Window > Size > Viewport Height`: 720

If stretch mode is `disabled` or `canvas_items`, fonts may scale unexpectedly.

### 4. Explicit size overrides on Labels

For critical labels where theme inheritance might fail, use explicit font size:

```gdscript
# For body text
label.add_theme_font_size_override("font_size", 16)

# For headers
header_label.add_theme_font_size_override("font_size", 32)

# For titles
title_label.add_theme_font_size_override("font_size", 48)
```

## Verification After Fix

After applying these fixes, the screenshot should show:

- Firework names CLEARLY readable, roughly same visual weight as "FIREWORKS" header but smaller
- Stats lines readable without squinting
- Tier badges showing clear "T1" text at chunky pixel size
- Sub-tabs in Upgrades column readable as individual words
- Section dividers (OWNED / AVAILABLE / LOCKED) readable at card-content-size
- Body text in cards has clear separation between lines

**Rough reference:** At 1280×720 viewing the full screen, 16px text should be roughly 1/45th of the screen height. You should be able to comfortably read any text in the UI from normal sitting distance without leaning in.

## Other Improvements in This Screenshot (while we're iterating)

Looking at the current screenshot, a few other things to note:

### Missing atmospheric background

Still a dark navy void. The corrections doc from earlier covered adding zone-specific silhouettes visible through semi-transparent panels. That work hasn't landed yet — prioritize font fix first, then atmosphere.

### Firework card layout is close but not quite right

Current layout shows:
```
Sparkler                    [T1]
$2 · 1 eng · handheld, golden
[-] [ 0 ] [+]
```

This is mostly right but:
- The tier badge on the right should be a pixel-art graphic (use the generated `tier_badges.png`), not a text placeholder
- The selected state (when qty > 0) should add a 1px gold border around the card

### Marketing panel feels empty

Only one marketing option shown ("Flyers"). At Zone 1 there should be 2-3 marketing options available. Check that marketing filtering isn't being over-aggressive. If only Flyers unlocks at Zone 1, that's fine — but verify with config.

### "Enhancements — one per category"

Good clarification text. Keep it.

### Upgrade column is working well

Three sections (Owned / Available / Locked) are properly separated. Category badges showing in brackets. Buy button on available. Lock icons on locked. This layout is correct.

## Priority

**Fix fonts first, verify with screenshot, then continue to next issues.** Font sizing is so foundational that nothing else can be properly evaluated until it's right.
