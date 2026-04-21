# THE LAST SHOW — Planning Screen Polish Round 2

**Context:** Major UI pivot work is done and landing well. This document covers the remaining targeted fixes to eliminate consistency issues and finish the polish pass.

**Scope:** ~2-3 hours of focused work on 10 specific items.

---

## FIX 1: RUN SHOW BUTTON STATES

**Problem:** The Run Show button currently looks semi-disabled even when conditions aren't met to be enabled. It needs three visually distinct states.

**Required states:**

**Disabled** (no fireworks selected, or overspending):
- Background: `rgba(255, 184, 77, 0.08)` (very subtle amber tint)
- Border: 1px `rgba(255, 184, 77, 0.2)`
- Text: `#8A7555` (dim amber)
- Cursor: not-allowed
- Tooltip on hover: "Pick at least one firework" or "Exceeds available cash"

**Enabled** (ready to run):
- Background: **solid** `#FFB84D` amber
- Border: none
- Text: `#0F1423` (dark navy)
- Font: Inter 14px semibold, uppercase, letter-spacing 1px
- Arrow icon in dark navy too
- Cursor: pointer
- Subtle shadow: `0 2px 8px rgba(255, 184, 77, 0.2)`

**Hover (when enabled):**
- Background: `#FFC864` (slightly brighter amber)
- Transform: `translateY(-1px)`
- Shadow: `0 4px 12px rgba(255, 184, 77, 0.4)`

**Pressed (when enabled):**
- Background: `#E6A340` (slightly darker amber)
- Transform: `translateY(1px)`
- Shadow: reduced

The enabled state MUST feel commanding and primary. Currently it looks like any other button.

---

## FIX 2: HAMBURGER MENU BUTTON

**Problem:** The hamburger button competes visually with Run Show. Both have amber accents fighting for attention.

**Fix:** Make the hamburger recede.

- Background: transparent
- Border: 1px `rgba(255, 255, 255, 0.1)` (subtle neutral, NOT amber)
- Icon: `TEXT_MUTED` (#888888) — neutral gray, not amber
- Size: 36x36
- Border-radius: 4px

**Hover only:**
- Background: `rgba(255, 255, 255, 0.05)`
- Border: `rgba(255, 255, 255, 0.2)`
- Icon: `TEXT_PRIMARY` (#F0F0F0)

The Run Show button is the primary action. Hamburger is secondary. Only Run Show should wear the amber crown.

---

## FIX 3: "NIGHT 1" FONT UNIFICATION

**Problem:** "NIGHT" and "1" appear to use different font styles or weights.

**Fix:** Both must use Inter, differentiated only by size and color:

```
"NIGHT" → Inter 11px, weight 600 (semibold), uppercase,
          letter-spacing 1.5px, color TEXT_MUTED (#888888)

"1"     → Inter 16px, weight 600 (semibold), color TEXT_PRIMARY (#F0F0F0)
```

Same font family. Same weight. Only size and color differ. If they look different typeface-wise, something is wrong with font loading or theme overrides — investigate.

---

## FIX 4: AMBER COLOR AUDIT

**Problem:** Multiple elements use "amber" but appear in slightly different shades. All should be the SAME amber.

**Target amber:** `#FFB84D` exactly.

**Audit these elements to confirm they all render at #FFB84D:**

1. "THE LAST SHOW" logo text
2. Zone indicator badge text and border
3. Firework cost values ($2, $3, $4, etc.) in rows
4. Top bar cash value ($10)
5. BUY button text
6. Selected firework row borders
7. Quantity value when > 0
8. Next unlock callout arrow and border
9. Run Show button background (when enabled)
10. Zone 1 indicator pill

**Check for causes of variance:**
- Opacity stacking (amber at 60% opacity on 60% panel = ~36% effective)
- Font rendering (subpixel AA can shift hue slightly)
- Inconsistent color constants in theme

**Fix by verifying:** every amber element explicitly references the `ACCENT_AMBER` constant, not a hardcoded hex or a variation.

---

## FIX 5: QUANTITY "0" COLOR CONSISTENCY

**Problem:** The "0" quantity values in firework rows appear washed out — different color than the row name text.

**Fix:**

**When quantity = 0:**
- Color: `TEXT_PRIMARY` (#F0F0F0) — same as row name, fully visible
- Font: Inter 14px medium, tabular-nums

**When quantity > 0:**
- Color: `ACCENT_AMBER` (#FFB84D)
- Font: Inter 14px semibold, tabular-nums
- Slight emphasis (bolder weight) signals "this is actively selected"

Currently the 0 looks dimmer than it should — players should see it as a ready input field, not disabled text.

---

## FIX 6: NEXT UNLOCK CALLOUT — MAKE IT CLICKABLE

**Problem:** The "Next: Website at Zone 2" callout has a bright amber border that looks clickable, but currently doesn't do anything. That's frustrating UI — visual affordance without function.

**Fix:** Make it actually clickable.

**Behavior:**
- Click → scrolls the Upgrades panel content so the "Website" row is visible at the top
- Highlight "Website" row with a brief amber pulse animation (500ms) to draw attention
- Tooltip on hover: "Show details about Website"

**Styling:**
- Keep current amber border treatment — now it has meaning (clickable)
- Add hover state: background brightens slightly, border becomes fully opaque amber
- Add cursor: pointer

**Alternative if clickability is too much work:**
- Remove the full border
- Keep only the left-side amber accent stripe (3px wide)
- Treat it as a highlighted label, not a button-like element

Either solution works. Clickable version is preferred because it provides real utility.

---

## FIX 7: ENHANCEMENT PILLS — SHOW EFFECTS INLINE

**Problem:** Current pills show only name and cost ("Candy from Store $20"). Players don't know what each enhancement does.

**Fix:** Include the effect in each pill.

**Target format:**

```
SNACKS    [ None ]  [ Candy +5% tips $20 ]  [ Vending +10% tips $100 ]

SOUND     [ None ]  [ Boombox +5% quality $50 ]  [ PA +15% quality $300 ]

HOST      [ None ]  [ Local MC +5% quality $50 ]  [ Pro Host +15% quality $500 ]
```

**Pill content structure:**

```
[Name] [effect] [cost]
```

Example: `Candy from Store +5% tips $20`

- Name: 13px medium, varies by state
- Effect: 11px regular, `TEXT_MUTED` — shows what it does
- Cost: 13px medium amber

**If it doesn't fit horizontally**, use shorter names:
- "Candy from Store" → "Candy"
- "Vending Machines" → "Vending"
- "Food Vendors" → "Food Vendors" (fits)
- "Catering Team" → "Catering"
- "Basic PA System" → "PA System"
- "Premium Sound" → "Premium"

Full names can show on hover tooltip if needed.

**Note on terminology:** Use "quality" as the display label for retention/engagement boosts. The three underlying stats are Tips/Reach/Retention, but "retention" is too technical for inline pill display. "Quality" is an approachable umbrella term for the retention-boosting enhancements.

Or if you prefer to match exact stat names: use "retention" directly. Pick one and be consistent.

---

## FIX 8: TAB ICONS — MAKE THEM DISTINCT

**Problem:** Category tabs now show icons but they're all solid amber with similar silhouettes — hard to distinguish Crew vs Rev vs Mkt at a glance.

**Fix options (choose one):**

**Option A: Icons + short text labels**

```
[All] [👥 Crew] [🏢 Infra] [💰 Rev] [📢 Mkt]
```

Icons still readable via shape, text disambiguates. Uses more horizontal space.

**Option B: Icons only with clear distinct silhouettes**

Make sure each icon is shape-distinct:
- All: grid/menu icon
- Crew: two people (not one)
- Infra: building with distinct windows
- Revenue: chart with clear upward angle
- Marketing: megaphone (distinct shape from building)

If current icons look too similar, regenerate specific ones to be more differentiated.

**Option C: Hover tooltips**

Keep icons-only, add tooltip on hover showing full category name. Accept that new players won't know icons until they learn them.

**My recommendation: Option A.** Short text labels are the clearest. Five tabs at 400px panel width can fit "All Crew Infra Rev Mkt" if kept compact.

---

## FIX 9: "SELECT FIREWORKS TO CONTINUE" HINT

**Problem:** The hint text is slightly too prominent. It competes with the Run Show button for attention when Run Show should be the primary focus.

**Fix:**

- Font: Inter 11px regular (not semibold), uppercase, letter-spacing 1.5px
- Color: `TEXT_DIM` (#555555) — dimmer than current
- Position: still left-aligned in bottom bar

The spend/cash line below it should stay readable:
- "Spend $0 · Cash $10" — Inter 13px regular, `TEXT_SECONDARY` (#B8B8B8)

This creates clear hierarchy:
- Hint (dim, small) ← tertiary info
- Spend/Cash (medium, readable) ← secondary info
- Run Show button (prominent, amber) ← primary action

---

## FIX 10: BOTTOM BAR VISUAL HIERARCHY

**Problem:** The bottom bar's three visual elements don't have clear hierarchy. Hamburger and Run Show both attention-grab.

**Fix:** Explicit hierarchy:

**Left side (informational):**
- "SELECT FIREWORKS TO CONTINUE" hint — small, dim
- "Spend $0 · Cash $10" summary — medium, secondary
- Block width: auto-sized to content, stays on left

**Center: empty space** (or optional "Night 1/100" progress indicator if desired)

**Right side (actions):**
- Hamburger menu — 36x36, neutral/transparent, tertiary priority
- Run Show button — 160-200px wide, solid amber when enabled, primary priority
- Gap between them: 12px

Hamburger's role is "additional options available" — it should whisper, not shout. Run Show's role is "THE main action" — it should command attention when ready.

The gap between hamburger and Run Show should be consistent. Currently they look squeezed together.

---

## VERIFICATION CHECKLIST

After these fixes, verify:

- [ ] Run Show button is clearly DISABLED when no fireworks selected (subtle, dim)
- [ ] Run Show button is clearly ENABLED when ready (solid amber, prominent)
- [ ] Hamburger button is visually secondary to Run Show
- [ ] "NIGHT 1" renders as same typeface, size-differentiated only
- [ ] All amber elements render identical #FFB84D color
- [ ] Quantity "0" is as bright as surrounding text
- [ ] Quantity "N" (where N > 0) is amber
- [ ] Next unlock callout either clickable OR treated as non-interactive label (not ambiguous)
- [ ] Enhancement pills show effect text ("+5% tips") inline
- [ ] Category tabs are visually distinct (labels or shape-differentiated icons)
- [ ] Bottom bar hint text is dimmer than spend/cash line
- [ ] Clear visual hierarchy in bottom bar: hint < summary < hamburger < Run Show

---

## IMPLEMENTATION TIME

All 10 fixes: ~2-3 hours total. Most are small targeted changes to existing styling.

Priority order (biggest visual impact first):

1. Run Show button states (Fix 1)
2. Hamburger de-emphasis (Fix 2)
3. Amber color audit (Fix 4)
4. Enhancement pills with effects (Fix 7)
5. Quantity color fix (Fix 5)
6. Next unlock clickability (Fix 6)
7. Tab icon distinctness (Fix 8)
8. Night 1 font unification (Fix 3)
9. Hint text dimming (Fix 9)
10. Bottom bar hierarchy polish (Fix 10)

Can be tackled all at once or spread across sessions. None of these block other work.

---

## NOT ADDRESSED HERE

These items are being handled elsewhere:

- **New modern icons** — you're generating these, will replace placeholders
- **Firework stats (Tips/Reach/Retention)** — balance agent working in parallel
- **Firework info modal** — part of the main UI spec being implemented
- **Background readability on locked rows** — should be addressed in main UI spec

This polish pass focuses on consistency and hierarchy finishing touches.
