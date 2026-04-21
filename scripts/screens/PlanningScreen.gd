extends Control
## THE LAST SHOW — Planning screen with modern Inter UI + pixel backdrop.
## Implements docs/planning_screen_modern_pivot.md.

const ZoneBackgroundScript := preload("res://scripts/components/ZoneBackground.gd")

# --- fonts -------------------------------------------------------------------

const FONT_REGULAR := preload("res://assets/fonts/Inter-Regular.ttf")
const FONT_MEDIUM := preload("res://assets/fonts/Inter-Medium.ttf")
const FONT_SEMIBOLD := preload("res://assets/fonts/Inter-SemiBold.ttf")
const FONT_BOLD := preload("res://assets/fonts/Inter-Bold.ttf")
const FONT_LOGO := preload("res://assets/fonts/VT323-Regular.ttf")

# --- palette -----------------------------------------------------------------

const NIGHT_DEEP := Color("0F1423")
const PANEL_BG := Color(0.059, 0.078, 0.137, 0.55)           # #0F1423 @ 0.55
const TOP_BAR_BG := Color(0.059, 0.078, 0.137, 0.85)         # #0F1423 @ 0.85
const BOTTOM_BAR_BG := Color(0.059, 0.078, 0.137, 0.85)

const CARD_BG := Color(1.0, 1.0, 1.0, 0.03)
const CARD_BG_HOVER := Color(1.0, 1.0, 1.0, 0.06)
const CARD_BG_SELECTED := Color(1.0, 0.722, 0.302, 0.08)     # amber tint
const CARD_BG_LOCKED := Color(1.0, 1.0, 1.0, 0.02)

const BORDER_SUBTLE := Color(1.0, 1.0, 1.0, 0.08)
const BORDER_HOVER := Color(1.0, 1.0, 1.0, 0.12)
const BORDER_AMBER := Color(1.0, 0.722, 0.302, 0.40)
const BORDER_AMBER_STRONG := Color(1.0, 0.722, 0.302, 1.0)

const TEXT_PRIMARY := Color(0.941, 0.941, 0.941)
const TEXT_SECONDARY := Color(0.722, 0.722, 0.722)
const TEXT_MUTED := Color(0.533, 0.533, 0.533)
const TEXT_DIM := Color(0.333, 0.333, 0.333)

const ACCENT_AMBER := Color(1.0, 0.722, 0.302)               # #FFB84D
const ACCENT_AMBER_HOVER := Color(1.0, 0.784, 0.392)         # #FFC864
const ACCENT_AMBER_DIM := Color(1.0, 0.722, 0.302, 0.15)
const ACCENT_AMBER_TRACK := Color(1.0, 0.722, 0.302, 0.10)

const STATE_WARN := Color(0.843, 0.227, 0.227)               # #D73A3A

const TIER_STRIPE := {
	1: Color("A07050"),
	2: Color("B0B8C0"),
	3: Color("D4AF37"),
	4: Color("5FC8D8"),
}

# --- sizes -------------------------------------------------------------------

const SIZE_LOGO := 24
const SIZE_H1 := 24
const SIZE_H2 := 18
const SIZE_BODY_LG := 16
const SIZE_BODY := 14
const SIZE_BODY_SM := 13
const SIZE_META := 12
const SIZE_LABEL := 11

const UPGRADE_CATEGORIES := ["All", "crew", "infrastructure", "revenue", "marketing"]
const UPGRADE_CATEGORY_LABELS := {
	"All": "All", "crew": "Crew", "infrastructure": "Infra",
	"revenue": "Rev", "marketing": "Mkt",
}

# --- icon paths (existing pixel icons as temp placeholders) ------------------

const TIER_ICONS := {
	1: "res://assets/images/t1.png",
	2: "res://assets/images/t2.png",
	3: "res://assets/images/t3.png",
	4: "res://assets/images/t4.png",
}
const ICON_MONEY := "res://assets/images/money.png"
const ICON_FANS := "res://assets/images/fans.png"
const ICON_LOCK := "res://assets/images/lock.png"
const ICON_CHECK := "res://assets/images/check.png"
const ICON_ARROW := "res://assets/images/rightarrow.png"
const ICON_INFO := "res://assets/images/info.png"
const ICON_MENU := "res://assets/images/hamburger.png"
const ICON_PLUS := "res://assets/images/plus.png"
const ICON_MINUS := "res://assets/images/minus.png"
const ICON_CLOSE := "res://assets/images/c.png"
const CATEGORY_ICONS := {
	"marketing": "res://assets/images/marketing.png",
	"infrastructure": "res://assets/images/house.png",
	"crew": "res://assets/images/people2.png",
	"revenue": "res://assets/images/money.png",
}

# --- state -------------------------------------------------------------------

var _fireworks_qty: Dictionary = {}
var _marketing_qty: Dictionary = {}
var _enhancements: Dictionary = {}
var _upgrade_buys: Array[String] = []
var _upgrade_category_filter: String = "All"
var _firework_info_dialog: AcceptDialog

var _cash_label: Label
var _fans_label: Label
var _fans_fill: ColorRect
var _run_show_button: Button
var _summary_hint: Label
var _summary_main: Label
var _upgrade_body: VBoxContainer


# ---------------------------------------------------------------------------
func _ready() -> void:
	_add_backdrop()

	var root := VBoxContainer.new()
	root.anchor_right = 1.0
	root.anchor_bottom = 1.0
	root.add_theme_constant_override("separation", 0)
	add_child(root)

	root.add_child(_build_top_bar())
	root.add_child(_strip(16))
	root.add_child(_build_panels())
	root.add_child(_strip(16))
	root.add_child(_build_bottom_bar())

	_refresh_totals()


# --- backdrop ---------------------------------------------------------------

func _add_backdrop() -> void:
	var zone_id: int = GameState.current_zone
	var sky_path: String = "res://assets/backgrounds/zone%d.png" % zone_id
	var fg_path: String = "res://assets/backgrounds/zone%d-foreground.png" % zone_id
	if ResourceLoader.exists(sky_path):
		add_child(_fill_texture(sky_path))
	var particle_slot := Control.new()
	particle_slot.anchor_right = 1.0
	particle_slot.anchor_bottom = 1.0
	particle_slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	particle_slot.name = "ParticleSlot"
	add_child(particle_slot)
	if ResourceLoader.exists(fg_path):
		add_child(_fill_texture(fg_path))
	elif not ResourceLoader.exists(sky_path):
		var bg: Control = ZoneBackgroundScript.new()
		bg.zone_id = zone_id
		add_child(bg)


func _fill_texture(path: String) -> TextureRect:
	var t := TextureRect.new()
	t.texture = load(path)
	t.anchor_right = 1.0
	t.anchor_bottom = 1.0
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return t


# --- top bar ----------------------------------------------------------------

func _build_top_bar() -> Control:
	var bar := PanelContainer.new()
	bar.custom_minimum_size = Vector2(0, 56)
	bar.add_theme_stylebox_override("panel", _flat_bar_style(TOP_BAR_BG, true))

	var pad := MarginContainer.new()
	pad.add_theme_constant_override("margin_left", 24)
	pad.add_theme_constant_override("margin_right", 24)
	pad.add_theme_constant_override("margin_top", 0)
	pad.add_theme_constant_override("margin_bottom", 0)
	bar.add_child(pad)

	var h := HBoxContainer.new()
	h.alignment = BoxContainer.ALIGNMENT_CENTER
	h.add_theme_constant_override("separation", 24)
	pad.add_child(h)

	h.add_child(_logo_label())
	h.add_child(_night_info_block())
	h.add_child(_zone_pill())

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(spacer)

	h.add_child(_fans_block())
	h.add_child(_cash_block())
	return bar


func _logo_label() -> Label:
	var l := Label.new()
	l.text = "THE LAST SHOW"
	l.add_theme_font_override("font", FONT_LOGO)
	l.add_theme_font_size_override("font_size", SIZE_LOGO)
	l.add_theme_color_override("font_color", ACCENT_AMBER)
	return l


func _night_info_block() -> Control:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 8)
	h.alignment = BoxContainer.ALIGNMENT_CENTER
	var label := _inter_label("NIGHT", SIZE_LABEL, FONT_SEMIBOLD, TEXT_MUTED)
	var value := _inter_label(str(GameState.night), SIZE_BODY_LG, FONT_SEMIBOLD, TEXT_PRIMARY)
	h.add_child(label)
	h.add_child(value)
	return h


func _zone_pill() -> Control:
	var wrap := PanelContainer.new()
	var style := _rounded_style(ACCENT_AMBER_DIM, BORDER_AMBER, 4)
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	wrap.add_theme_stylebox_override("panel", style)

	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	h.alignment = BoxContainer.ALIGNMENT_CENTER
	wrap.add_child(h)

	var zone_label := _inter_label(
		"ZONE %d" % GameState.current_zone, SIZE_LABEL, FONT_SEMIBOLD, ACCENT_AMBER)
	h.add_child(zone_label)
	var zone_name := String(BalanceConfig.get_zone(GameState.current_zone).get("name", ""))
	var name_label := _inter_label(zone_name, SIZE_BODY, FONT_MEDIUM, TEXT_PRIMARY)
	h.add_child(name_label)
	return wrap


func _fans_block() -> Control:
	var h := HBoxContainer.new()
	h.alignment = BoxContainer.ALIGNMENT_CENTER
	h.add_theme_constant_override("separation", 8)
	h.add_child(_icon(ICON_FANS, 14))

	var next_zone: Dictionary = BalanceConfig.get_zone(GameState.current_zone + 1)
	var threshold: int = 0 if next_zone.is_empty() else int(next_zone.get("threshold_repeat_fans", 0))
	var text: String = ""
	if threshold > 0:
		text = "%s / %s fans" % [_fmt_num(GameState.repeat_fans), _fmt_num(threshold)]
	else:
		text = "%s fans" % _fmt_num(GameState.repeat_fans)
	_fans_label = _inter_label(text, SIZE_BODY, FONT_MEDIUM, TEXT_SECONDARY)
	h.add_child(_fans_label)

	# 60×4 progress bar, vertically centered in the top bar.
	var track_center := CenterContainer.new()
	track_center.custom_minimum_size = Vector2(60, 0)
	var track := Control.new()
	track.custom_minimum_size = Vector2(60, 4)
	var track_bg := ColorRect.new()
	track_bg.color = Color(1.0, 1.0, 1.0, 0.1)
	track_bg.anchor_right = 1.0
	track_bg.anchor_bottom = 1.0
	track.add_child(track_bg)
	_fans_fill = ColorRect.new()
	_fans_fill.color = ACCENT_AMBER
	_fans_fill.anchor_bottom = 1.0
	var pct: float = 0.0 if threshold <= 0 else clampf(float(GameState.repeat_fans) / float(threshold), 0.0, 1.0)
	_fans_fill.size = Vector2(60.0 * pct, 4.0)
	track.add_child(_fans_fill)
	track_center.add_child(track)
	h.add_child(track_center)
	return h


func _cash_block() -> Control:
	var h := HBoxContainer.new()
	h.alignment = BoxContainer.ALIGNMENT_CENTER
	h.add_theme_constant_override("separation", 8)
	h.add_child(_icon(ICON_MONEY, 14))
	_cash_label = _inter_label(
		"$%s" % _fmt_num(int(GameState.money)), SIZE_H2, FONT_SEMIBOLD, ACCENT_AMBER)
	h.add_child(_cash_label)
	return h


# --- panel row --------------------------------------------------------------

func _build_panels() -> Control:
	var margin := MarginContainer.new()
	margin.custom_minimum_size = Vector2(0, 560)
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)

	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 16)
	margin.add_child(h)

	h.add_child(_panel("FIREWORKS", _build_fireworks_list(), 400))
	h.add_child(_panel("MARKETING & ENHANCEMENTS", _build_marketing_and_enhancements(), 384))
	h.add_child(_panel("UPGRADES", _build_upgrades_panel_body(), 400))
	return margin


func _panel(title: String, body: Control, width: int) -> Control:
	var wrap := PanelContainer.new()
	wrap.custom_minimum_size = Vector2(width, 0)
	wrap.size_flags_horizontal = 0
	wrap.size_flags_vertical = Control.SIZE_EXPAND_FILL
	wrap.add_theme_stylebox_override("panel", _rounded_style(PANEL_BG, BORDER_SUBTLE, 6))

	var pad := MarginContainer.new()
	pad.add_theme_constant_override("margin_left", 20)
	pad.add_theme_constant_override("margin_right", 20)
	pad.add_theme_constant_override("margin_top", 20)
	pad.add_theme_constant_override("margin_bottom", 20)
	wrap.add_child(pad)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	pad.add_child(v)

	var header := _inter_label(title, SIZE_LABEL, FONT_SEMIBOLD, TEXT_MUTED)
	v.add_child(header)

	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(body)
	return wrap


# --- firework rows ----------------------------------------------------------

func _build_fireworks_list() -> Control:
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	v.alignment = BoxContainer.ALIGNMENT_BEGIN
	v.add_theme_constant_override("separation", 6)
	scroll.add_child(v)

	var fireworks: Array = GameEngine.available_fireworks().duplicate()
	fireworks.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if int(a.get("tier", 1)) != int(b.get("tier", 1)):
			return int(a.get("tier", 1)) < int(b.get("tier", 1))
		return int(a.get("cost", 0)) < int(b.get("cost", 0)))
	for fw in fireworks:
		v.add_child(_build_firework_row(fw))
	return scroll


func _build_firework_row(fw: Dictionary) -> Control:
	var tier: int = int(fw.get("tier", 1))
	var cost: int = int(fw.get("cost", 0))

	var wrap := PanelContainer.new()
	wrap.custom_minimum_size = Vector2(0, 44)
	wrap.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var style := _rounded_style(CARD_BG, BORDER_SUBTLE, 4)
	style.content_margin_left = 0
	wrap.add_theme_stylebox_override("panel", style)

	var outer := HBoxContainer.new()
	outer.add_theme_constant_override("separation", 0)
	wrap.add_child(outer)

	# Full-height tier stripe, 4px wide.
	var stripe := ColorRect.new()
	stripe.color = TIER_STRIPE.get(tier, TIER_STRIPE[1])
	stripe.custom_minimum_size = Vector2(4, 0)
	outer.add_child(stripe)

	var pad := MarginContainer.new()
	pad.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pad.add_theme_constant_override("margin_left", 12)
	pad.add_theme_constant_override("margin_right", 12)
	pad.add_theme_constant_override("margin_top", 8)
	pad.add_theme_constant_override("margin_bottom", 8)
	outer.add_child(pad)

	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	pad.add_child(h)

	# One-line: name (flex) then meta ("$cost · N eng") right-aligned, then
	# stepper, then info button.
	var name_lbl := _inter_label(String(fw.name), SIZE_BODY, FONT_MEDIUM, TEXT_PRIMARY)
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_lbl.clip_text = true
	name_lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	h.add_child(name_lbl)

	var cost_lbl := _inter_label("$%s" % _fmt_num(cost), SIZE_META, FONT_MEDIUM, ACCENT_AMBER)
	h.add_child(cost_lbl)
	var dot := _inter_label("·", SIZE_META, FONT_REGULAR, TEXT_DIM)
	h.add_child(dot)
	var eng_lbl := _inter_label(
		"%d eng" % int(fw.get("engagement", 0)), SIZE_META, FONT_REGULAR, TEXT_MUTED)
	h.add_child(eng_lbl)

	var minus := _qty_button("-")
	var qty_lbl := _inter_label("0", SIZE_BODY, FONT_MEDIUM, TEXT_MUTED)
	qty_lbl.custom_minimum_size = Vector2(28, 0)
	qty_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var plus := _qty_button("+")
	h.add_child(minus)
	h.add_child(qty_lbl)
	h.add_child(plus)

	var info_btn := _info_button()
	info_btn.pressed.connect(func() -> void: _show_firework_info(fw))
	h.add_child(info_btn)

	var entry := {
		"fw": fw, "wrap": wrap, "style": style,
		"qty_label": qty_lbl,
	}
	minus.pressed.connect(func() -> void: _nudge_firework(fw, -1, entry))
	plus.pressed.connect(func() -> void: _nudge_firework(fw, 1, entry))
	return wrap


# --- marketing + enhancements -----------------------------------------------

func _build_marketing_and_enhancements() -> Control:
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	v.alignment = BoxContainer.ALIGNMENT_BEGIN
	v.add_theme_constant_override("separation", 6)
	scroll.add_child(v)

	v.add_child(_divided_section_label("MARKETING"))
	var mk_available: Array = GameEngine.available_marketing()
	if mk_available.is_empty():
		v.add_child(_inter_label(
			"Only flyers available at this zone. More unlock as you grow.",
			SIZE_META, FONT_REGULAR, TEXT_MUTED))
	else:
		for mk in mk_available:
			v.add_child(_build_marketing_row(mk))

	v.add_child(_strip(12))
	v.add_child(_divided_section_label("ENHANCEMENTS", "one per category"))

	var groups: Dictionary = GameEngine.available_enhancements()
	for category in groups.keys():
		v.add_child(_strip(2))
		v.add_child(_inter_label(
			String(category).capitalize(), SIZE_LABEL, FONT_REGULAR, TEXT_SECONDARY))
		v.add_child(_build_enhancement_row(String(category), "None", {}, true))
		for eh in groups[category]:
			v.add_child(_build_enhancement_row(
				String(category), String(eh.name), eh, false))
	return scroll


func _build_marketing_row(mk: Dictionary) -> Control:
	var cost: int = int(mk.get("cost", 0))
	var wrap := PanelContainer.new()
	wrap.custom_minimum_size = Vector2(0, 44)
	wrap.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var style := _rounded_style(CARD_BG, BORDER_SUBTLE, 4)
	wrap.add_theme_stylebox_override("panel", style)

	var pad := MarginContainer.new()
	pad.add_theme_constant_override("margin_left", 14)
	pad.add_theme_constant_override("margin_right", 14)
	pad.add_theme_constant_override("margin_top", 8)
	pad.add_theme_constant_override("margin_bottom", 8)
	wrap.add_child(pad)

	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 8)
	pad.add_child(h)

	# One line: name (flex) · amber cost · muted effect · stepper
	var name_lbl := _inter_label(String(mk.name), SIZE_BODY, FONT_MEDIUM, TEXT_PRIMARY)
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_lbl.clip_text = true
	name_lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	h.add_child(name_lbl)

	h.add_child(_inter_label("$%s" % _fmt_num(cost), SIZE_META, FONT_MEDIUM, ACCENT_AMBER))
	h.add_child(_inter_label("·", SIZE_META, FONT_REGULAR, TEXT_DIM))
	h.add_child(_inter_label(
		"+%s att" % _fmt_num(int(mk.get("attendees", 0))),
		SIZE_META, FONT_REGULAR, TEXT_MUTED))

	var minus := _qty_button("-")
	var qty_lbl := _inter_label("0", SIZE_BODY, FONT_MEDIUM, TEXT_MUTED)
	qty_lbl.custom_minimum_size = Vector2(32, 0)
	qty_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var plus := _qty_button("+")
	h.add_child(minus)
	h.add_child(qty_lbl)
	h.add_child(plus)

	minus.pressed.connect(func() -> void: _nudge_marketing(mk, -1, qty_lbl, style))
	plus.pressed.connect(func() -> void: _nudge_marketing(mk, 1, qty_lbl, style))
	return wrap


func _build_enhancement_row(category: String, name: String, eh: Dictionary, is_none: bool) -> Control:
	var selected: bool = (is_none and not _enhancements.has(category)) \
		or (not is_none and String(_enhancements.get(category, "")) == name)
	var wrap := PanelContainer.new()
	wrap.custom_minimum_size = Vector2(0, 32)
	wrap.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var bg: Color = CARD_BG_SELECTED if selected else CARD_BG
	var border: Color = BORDER_AMBER if selected else BORDER_SUBTLE
	wrap.add_theme_stylebox_override("panel", _rounded_style(bg, border, 4))

	var pad := MarginContainer.new()
	pad.add_theme_constant_override("margin_left", 12)
	pad.add_theme_constant_override("margin_right", 12)
	pad.add_theme_constant_override("margin_top", 6)
	pad.add_theme_constant_override("margin_bottom", 6)
	wrap.add_child(pad)

	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	pad.add_child(h)

	h.add_child(_checkbox_tile(selected))

	# Single-line layout so the row hits 32px cleanly.
	var name_lbl := _inter_label(name, SIZE_BODY_SM, FONT_MEDIUM, TEXT_PRIMARY)
	h.add_child(name_lbl)

	var effect_text: String = ""
	if not is_none:
		if eh.has("eng_mult"):
			effect_text += "+%d%% eng" % int(float(eh.eng_mult) * 100)
		if eh.has("tip_mult"):
			if effect_text != "":
				effect_text += " · "
			effect_text += "+%d%% tips" % int(float(eh.tip_mult) * 100)
	var effect_lbl := _inter_label(effect_text, SIZE_LABEL, FONT_REGULAR, TEXT_MUTED)
	effect_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	effect_lbl.clip_text = true
	effect_lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	h.add_child(effect_lbl)

	if not is_none:
		h.add_child(_inter_label(
			"$%s" % _fmt_num(int(eh.get("cost", 0))),
			SIZE_BODY_SM, FONT_MEDIUM, ACCENT_AMBER))

	# Row-level click via overlay button
	var click := Button.new()
	click.flat = true
	click.anchor_right = 1.0
	click.anchor_bottom = 1.0
	click.focus_mode = Control.FOCUS_NONE
	click.mouse_filter = Control.MOUSE_FILTER_PASS
	wrap.add_child(click)
	var target_name: String = "" if is_none else name
	click.pressed.connect(func() -> void: _select_enhancement(category, target_name))
	return wrap


func _checkbox_tile(checked: bool) -> Control:
	var tile := PanelContainer.new()
	tile.custom_minimum_size = Vector2(16, 16)
	if checked:
		tile.add_theme_stylebox_override("panel", _rounded_style(
			ACCENT_AMBER, BORDER_AMBER_STRONG, 3))
	else:
		tile.add_theme_stylebox_override("panel", _rounded_style(
			Color(0, 0, 0, 0), Color(1.0, 1.0, 1.0, 0.2), 3))
	if checked:
		var check := _icon(ICON_CHECK, 12)
		check.modulate = NIGHT_DEEP
		tile.add_child(check)
	return tile


# --- upgrades panel ---------------------------------------------------------

func _build_upgrades_panel_body() -> Control:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)

	# Tab filter pill
	var tab_wrap := PanelContainer.new()
	tab_wrap.add_theme_stylebox_override("panel", _rounded_style(
		Color(0, 0, 0, 0.25), Color(0, 0, 0, 0), 4))
	var tab_pad := MarginContainer.new()
	tab_pad.add_theme_constant_override("margin_left", 3)
	tab_pad.add_theme_constant_override("margin_right", 3)
	tab_pad.add_theme_constant_override("margin_top", 3)
	tab_pad.add_theme_constant_override("margin_bottom", 3)
	tab_wrap.add_child(tab_pad)
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 0)
	tab_pad.add_child(tabs)

	var category_group: Array[Button] = []
	for cat in UPGRADE_CATEGORIES:
		var b := _tab_button(String(UPGRADE_CATEGORY_LABELS.get(cat, cat)), cat == "All")
		var cat_str: String = cat
		b.pressed.connect(func() -> void:
			_upgrade_category_filter = cat_str
			for btn in category_group:
				_tab_button_set_active(btn, btn == b)
			_rebuild_upgrades())
		category_group.append(b)
		tabs.add_child(b)
	v.add_child(tab_wrap)

	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_upgrade_body = VBoxContainer.new()
	_upgrade_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_upgrade_body.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	_upgrade_body.alignment = BoxContainer.ALIGNMENT_BEGIN
	_upgrade_body.add_theme_constant_override("separation", 6)
	scroll.add_child(_upgrade_body)
	v.add_child(scroll)
	_rebuild_upgrades()
	return v


func _rebuild_upgrades() -> void:
	for child in _upgrade_body.get_children():
		child.queue_free()

	var cat_match := func(up: Dictionary) -> bool:
		if _upgrade_category_filter == "All":
			return true
		return String(up.get("category", "")) == _upgrade_category_filter

	var owned: Array = []
	for up_name in GameState.owned_upgrades:
		var up: Dictionary = BalanceConfig.get_upgrade(up_name)
		if cat_match.call(up):
			owned.append(up)

	var available: Array = []
	var locked: Array = []
	for up in BalanceConfig.upgrades():
		var up_dict: Dictionary = up
		if GameState.owned_upgrades.has(String(up_dict.name)):
			continue
		if not cat_match.call(up_dict):
			continue
		if GameState.current_zone < int(up_dict.get("min_zone", 1)):
			locked.append(up_dict)
		else:
			available.append(up_dict)

	_upgrade_body.add_child(_divided_section_label("OWNED", "%d" % owned.size()))
	if owned.is_empty():
		_upgrade_body.add_child(_inter_label(
			"No upgrades yet — buy your first below.",
			SIZE_META, FONT_REGULAR, TEXT_MUTED))
	for up in owned:
		_upgrade_body.add_child(_build_owned_upgrade_row(up))

	_upgrade_body.add_child(_strip(8))
	_upgrade_body.add_child(_divided_section_label("AVAILABLE", "%d" % available.size()))
	if available.is_empty():
		_upgrade_body.add_child(_inter_label(
			"Nothing purchasable this zone.", SIZE_META, FONT_REGULAR, TEXT_MUTED))
	for up in available:
		_upgrade_body.add_child(_build_available_upgrade_row(up))

	if not locked.is_empty():
		locked.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
			return int(a.get("min_zone", 1)) < int(b.get("min_zone", 1)))
		_upgrade_body.add_child(_strip(8))
		_upgrade_body.add_child(_next_unlock_callout(locked[0]))
		_upgrade_body.add_child(_divided_section_label("LOCKED", "%d" % locked.size()))
		for up in locked:
			_upgrade_body.add_child(_build_locked_upgrade_row(up))


func _build_owned_upgrade_row(up: Dictionary) -> Control:
	var wrap := PanelContainer.new()
	wrap.custom_minimum_size = Vector2(0, 44)
	wrap.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	wrap.add_theme_stylebox_override("panel", _rounded_style(
		Color(1.0, 0.722, 0.302, 0.05), Color(1.0, 0.722, 0.302, 0.2), 4))

	var pad := MarginContainer.new()
	pad.add_theme_constant_override("margin_left", 14)
	pad.add_theme_constant_override("margin_right", 14)
	pad.add_theme_constant_override("margin_top", 8)
	pad.add_theme_constant_override("margin_bottom", 8)
	wrap.add_child(pad)

	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	pad.add_child(h)

	h.add_child(_category_tile(String(up.get("category", "")), true))

	var name_lbl := _inter_label(String(up.name), SIZE_BODY_SM, FONT_MEDIUM, TEXT_PRIMARY)
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_lbl.clip_text = true
	name_lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	h.add_child(name_lbl)

	h.add_child(_inter_label(
		_effect_summary(up.get("effect", {})),
		SIZE_LABEL, FONT_REGULAR, TEXT_MUTED))
	h.add_child(_icon_tinted(ICON_CHECK, 14, ACCENT_AMBER))
	return wrap


func _build_available_upgrade_row(up: Dictionary) -> Control:
	var cost: int = int(up.get("cost", 0))
	var affordable: bool = float(cost) <= GameState.money
	var wrap := PanelContainer.new()
	wrap.custom_minimum_size = Vector2(0, 48)
	wrap.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	wrap.add_theme_stylebox_override("panel", _rounded_style(CARD_BG, BORDER_SUBTLE, 4))

	var pad := MarginContainer.new()
	pad.add_theme_constant_override("margin_left", 14)
	pad.add_theme_constant_override("margin_right", 14)
	pad.add_theme_constant_override("margin_top", 8)
	pad.add_theme_constant_override("margin_bottom", 8)
	wrap.add_child(pad)

	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	pad.add_child(h)

	h.add_child(_category_tile(String(up.get("category", "")), false))

	var name_lbl := _inter_label(
		String(up.name), SIZE_BODY_SM, FONT_MEDIUM,
		TEXT_PRIMARY if affordable else TEXT_MUTED)
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_lbl.clip_text = true
	name_lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	h.add_child(name_lbl)

	h.add_child(_inter_label(
		"$%s" % _fmt_num(cost),
		SIZE_BODY_SM, FONT_SEMIBOLD,
		ACCENT_AMBER if affordable else TEXT_MUTED))

	var buy_btn := _buy_button()
	buy_btn.disabled = not affordable
	var name_str: String = String(up.name)
	if _upgrade_buys.has(name_str):
		buy_btn.text = "UNDO"
	buy_btn.pressed.connect(func() -> void:
		if _upgrade_buys.has(name_str):
			_upgrade_buys.erase(name_str)
		else:
			_upgrade_buys.append(name_str)
		_rebuild_upgrades()
		_refresh_totals())
	h.add_child(buy_btn)
	return wrap


func _build_locked_upgrade_row(up: Dictionary) -> Control:
	var wrap := PanelContainer.new()
	wrap.custom_minimum_size = Vector2(0, 40)
	wrap.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	wrap.add_theme_stylebox_override("panel", _rounded_style(CARD_BG_LOCKED, BORDER_SUBTLE, 4))
	wrap.modulate = Color(1, 1, 1, 0.55)

	var pad := MarginContainer.new()
	pad.add_theme_constant_override("margin_left", 14)
	pad.add_theme_constant_override("margin_right", 14)
	pad.add_theme_constant_override("margin_top", 8)
	pad.add_theme_constant_override("margin_bottom", 8)
	wrap.add_child(pad)

	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	pad.add_child(h)

	h.add_child(_icon(ICON_LOCK, 14))
	var name_lbl := _inter_label(String(up.name), SIZE_BODY_SM, FONT_REGULAR, TEXT_MUTED)
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_lbl.clip_text = true
	name_lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	h.add_child(name_lbl)
	h.add_child(_inter_label(
		"Zone %d+" % int(up.get("min_zone", 1)),
		SIZE_LABEL, FONT_SEMIBOLD, TEXT_MUTED))
	return wrap


func _next_unlock_callout(up: Dictionary) -> Control:
	var wrap := PanelContainer.new()
	var style := _rounded_style(
		Color(1.0, 0.722, 0.302, 0.05),
		Color(1.0, 0.722, 0.302, 0.15), 3)
	style.border_width_left = 3
	style.border_color = ACCENT_AMBER
	wrap.add_theme_stylebox_override("panel", style)
	wrap.custom_minimum_size = Vector2(0, 36)

	var pad := MarginContainer.new()
	pad.add_theme_constant_override("margin_left", 12)
	pad.add_theme_constant_override("margin_right", 12)
	pad.add_theme_constant_override("margin_top", 8)
	pad.add_theme_constant_override("margin_bottom", 8)
	wrap.add_child(pad)

	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 8)
	pad.add_child(h)
	var arrow := _icon(ICON_ARROW, 12)
	arrow.modulate = ACCENT_AMBER
	h.add_child(arrow)
	var lbl := _inter_label(
		"Next: %s at Zone %d" % [String(up.name), int(up.get("min_zone", 1))],
		SIZE_META, FONT_MEDIUM, TEXT_PRIMARY)
	h.add_child(lbl)
	return wrap


func _category_tile(cat: String, amber: bool) -> Control:
	var bg: Color = Color(1.0, 0.722, 0.302, 0.1) if amber else Color(1.0, 1.0, 1.0, 0.05)
	var wrap := PanelContainer.new()
	wrap.custom_minimum_size = Vector2(28, 28)
	wrap.add_theme_stylebox_override("panel", _rounded_style(bg, Color(0, 0, 0, 0), 4))
	if CATEGORY_ICONS.has(cat):
		var center := CenterContainer.new()
		wrap.add_child(center)
		var icon := _icon(CATEGORY_ICONS[cat], 18)
		icon.modulate = ACCENT_AMBER if amber else TEXT_SECONDARY
		center.add_child(icon)
	return wrap


func _icon_tinted(path: String, px: int, tint: Color) -> TextureRect:
	var t := _icon(path, px)
	t.modulate = tint
	return t


func _category_short(cat: String) -> String:
	match cat:
		"crew": return "Crew"
		"infrastructure": return "Infra"
		"revenue": return "Rev"
		"marketing": return "Mkt"
	return cat.capitalize()


# --- bottom bar -------------------------------------------------------------

func _build_bottom_bar() -> Control:
	var bar := PanelContainer.new()
	bar.custom_minimum_size = Vector2(0, 72)
	bar.add_theme_stylebox_override("panel", _flat_bar_style(BOTTOM_BAR_BG, false))

	var pad := MarginContainer.new()
	pad.add_theme_constant_override("margin_left", 24)
	pad.add_theme_constant_override("margin_right", 24)
	pad.add_theme_constant_override("margin_top", 0)
	pad.add_theme_constant_override("margin_bottom", 0)
	bar.add_child(pad)

	var h := HBoxContainer.new()
	h.alignment = BoxContainer.ALIGNMENT_CENTER
	h.add_theme_constant_override("separation", 20)
	pad.add_child(h)

	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.add_theme_constant_override("separation", 4)
	_summary_hint = _inter_label(
		"SELECT FIREWORKS TO CONTINUE", SIZE_LABEL, FONT_SEMIBOLD, TEXT_MUTED)
	_summary_main = _inter_label(
		"Spend $0 · Cash $%s" % _fmt_num(int(GameState.money)),
		SIZE_BODY, FONT_MEDIUM, TEXT_PRIMARY)
	left.add_child(_summary_hint)
	left.add_child(_summary_main)
	h.add_child(left)

	h.add_child(_menu_button())

	_run_show_button = _run_show_primary()
	_run_show_button.pressed.connect(_on_run_show_pressed)
	h.add_child(_run_show_button)
	return bar


# --- handlers ---------------------------------------------------------------

func _nudge_firework(fw: Dictionary, delta: int, entry: Dictionary) -> void:
	var name_str: String = String(fw.name)
	var current: int = int(_fireworks_qty.get(name_str, 0))
	var cap: int = int(BalanceConfig.get_zone(GameState.current_zone).get("firework_cap", 300))
	var new_qty: int = maxi(current + delta, 0)
	new_qty = mini(new_qty, cap)
	_fireworks_qty[name_str] = new_qty

	var qty_label: Label = entry.qty_label
	qty_label.text = str(new_qty)
	qty_label.add_theme_color_override("font_color", ACCENT_AMBER if new_qty > 0 else TEXT_MUTED)

	var style: StyleBoxFlat = entry.style
	if new_qty > 0:
		style.bg_color = CARD_BG_SELECTED
		style.border_color = BORDER_AMBER
	else:
		style.bg_color = CARD_BG
		style.border_color = BORDER_SUBTLE
	_refresh_totals()


func _nudge_marketing(mk: Dictionary, delta: int, qty_label: Label, style: StyleBoxFlat) -> void:
	var name_str: String = String(mk.name)
	var current: int = int(_marketing_qty.get(name_str, 0))
	var cap: int = int(mk.get("cap", 0))
	var new_qty: int = maxi(current + delta, 0)
	if cap > 0:
		new_qty = mini(new_qty, cap)
	_marketing_qty[name_str] = new_qty
	qty_label.text = str(new_qty)
	qty_label.add_theme_color_override("font_color", ACCENT_AMBER if new_qty > 0 else TEXT_MUTED)
	if new_qty > 0:
		style.bg_color = CARD_BG_SELECTED
		style.border_color = BORDER_AMBER
	else:
		style.bg_color = CARD_BG
		style.border_color = BORDER_SUBTLE
	_refresh_totals()


func _select_enhancement(category: String, name: String) -> void:
	if name == "":
		_enhancements.erase(category)
	else:
		_enhancements[category] = name
	_rebuild_planning()
	_refresh_totals()


func _rebuild_planning() -> void:
	for child in get_children():
		if child is VBoxContainer:
			child.queue_free()
	var root := VBoxContainer.new()
	root.anchor_right = 1.0
	root.anchor_bottom = 1.0
	root.add_theme_constant_override("separation", 0)
	add_child(root)
	root.add_child(_build_top_bar())
	root.add_child(_strip(16))
	root.add_child(_build_panels())
	root.add_child(_strip(16))
	root.add_child(_build_bottom_bar())


# --- totals -----------------------------------------------------------------

func _refresh_totals() -> void:
	var spend: float = 0.0
	var fw_count: int = 0
	for name_str in _fireworks_qty.keys():
		var qty: int = int(_fireworks_qty[name_str])
		if qty <= 0:
			continue
		spend += float(BalanceConfig.get_firework(name_str).get("cost", 0)) * qty
		fw_count += qty
	for name_str in _marketing_qty.keys():
		var qty: int = int(_marketing_qty[name_str])
		if qty <= 0:
			continue
		spend += float(BalanceConfig.get_marketing(name_str).get("cost", 0)) * qty
	for category in _enhancements.keys():
		var eh: Dictionary = BalanceConfig.get_enhancement(
			String(category), String(_enhancements[category]))
		spend += float(eh.get("cost", 0))
	for up_name in _upgrade_buys:
		spend += float(BalanceConfig.get_upgrade(up_name).get("cost", 0))

	var overspend: bool = spend > GameState.money
	var cash_after := GameState.money - spend

	if fw_count <= 0:
		_summary_hint.text = "SELECT FIREWORKS TO CONTINUE"
		_summary_main.text = "Spend $0 · Cash $%s" % _fmt_num(int(GameState.money))
		_summary_main.add_theme_color_override("font_color", TEXT_PRIMARY)
	else:
		_summary_hint.text = "READY TO RUN SHOW"
		if overspend:
			_summary_main.text = "Spend $%s exceeds cash $%s" % [
				_fmt_num(int(spend)), _fmt_num(int(GameState.money))]
			_summary_main.add_theme_color_override("font_color", STATE_WARN)
		else:
			_summary_main.text = "Spend $%s · Cash after $%s" % [
				_fmt_num(int(spend)), _fmt_num(int(cash_after))]
			_summary_main.add_theme_color_override("font_color", TEXT_PRIMARY)

	_run_show_button.disabled = overspend or (fw_count <= 0)


func _on_run_show_pressed() -> void:
	var decisions := {
		"fireworks": _fireworks_qty,
		"marketing": _marketing_qty,
		"enhancements": _enhancements_as_array(),
		"upgrades_to_buy": _upgrade_buys,
	}
	var result: Dictionary = GameEngine.resolve_night(decisions)
	Router.commit_night(result)


func _enhancements_as_array() -> Array:
	var out: Array = []
	for category in _enhancements.keys():
		out.append({"category": String(category), "name": String(_enhancements[category])})
	return out


# --- info popup -------------------------------------------------------------

func _show_firework_info(fw: Dictionary) -> void:
	if _firework_info_dialog == null:
		_firework_info_dialog = AcceptDialog.new()
		_firework_info_dialog.min_size = Vector2(460, 0)
		add_child(_firework_info_dialog)

	var tier: int = int(fw.get("tier", 1))
	var cost: int = int(fw.get("cost", 0))
	var engagement: int = int(fw.get("engagement", 0))
	var tags: Array = fw.get("tags", [])
	var tag_str: String = ", ".join(tags) if not tags.is_empty() else "—"
	var unlock_desc: String = String(fw.get("unlock_description", ""))

	var body := "[b]%s[/b]\n" % String(fw.name)
	body += "Tier %d  ·  $%s per unit  ·  %d engagement per unit\n\n" % [
		tier, _fmt_num(cost), engagement]
	body += "[b]Tags:[/b] %s\n\n" % tag_str
	body += ("[b]Engagement[/b] is how much excitement each firework adds to the show. "
			+ "Total engagement feeds the quality multiplier, which drives both "
			+ "star rating and how many attendees become repeat fans.")
	if unlock_desc != "":
		body += "\n\n[b]Unlock:[/b] %s" % unlock_desc

	_firework_info_dialog.title = String(fw.name)
	for child in _firework_info_dialog.get_children():
		if child is RichTextLabel:
			child.queue_free()
	var rt := RichTextLabel.new()
	rt.bbcode_enabled = true
	rt.fit_content = true
	rt.custom_minimum_size = Vector2(420, 0)
	rt.add_theme_font_size_override("normal_font_size", SIZE_BODY_SM)
	rt.add_theme_font_size_override("bold_font_size", SIZE_BODY_SM)
	rt.add_theme_color_override("default_color", TEXT_PRIMARY)
	rt.text = body
	_firework_info_dialog.add_child(rt)
	_firework_info_dialog.popup_centered()


func _effect_summary(effect: Dictionary) -> String:
	var parts: Array[String] = []
	if effect.has("attendees_permanent"):
		parts.append("+%s att perm" % _fmt_num(int(effect.attendees_permanent)))
	if effect.has("tip_mult_permanent"):
		parts.append("+%d%% tips" % int(float(effect.tip_mult_permanent) * 100))
	if effect.has("eng_mult_permanent"):
		parts.append("+%d%% eng" % int(float(effect.eng_mult_permanent) * 100))
	if effect.has("show_quality_mult"):
		parts.append("+%d%% quality" % int(float(effect.show_quality_mult) * 100))
	if effect.has("unlocks_donation") or effect.has("unlocks_zone_6_finale") or effect.has("unlocks_tier_4_research"):
		parts.append("endgame")
	return ", ".join(parts)


# --- primitives --------------------------------------------------------------

func _inter_label(text: String, font_size: int, font: FontFile, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", font)
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	return l


func _divided_section_label(text: String, hint: String = "") -> Control:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	var lbl := _inter_label(text, SIZE_LABEL, FONT_SEMIBOLD, TEXT_MUTED)
	h.add_child(lbl)
	if hint != "":
		var sep := _inter_label("·", SIZE_LABEL, FONT_REGULAR, TEXT_DIM)
		h.add_child(sep)
		var hint_lbl := _inter_label(hint, SIZE_LABEL, FONT_REGULAR, TEXT_DIM)
		h.add_child(hint_lbl)
	return h


func _icon(path: String, px: int) -> TextureRect:
	var t := TextureRect.new()
	t.texture = load(path)
	t.custom_minimum_size = Vector2(px, px)
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return t


func _qty_button(kind: String) -> Button:
	var b := Button.new()
	b.icon = load(ICON_MINUS if kind == "-" else ICON_PLUS)
	b.expand_icon = true
	b.add_theme_color_override("icon_normal_color", TEXT_SECONDARY)
	b.add_theme_color_override("icon_hover_color", ACCENT_AMBER)
	b.add_theme_color_override("icon_pressed_color", ACCENT_AMBER)
	b.add_theme_color_override("icon_disabled_color", TEXT_DIM)
	b.add_theme_stylebox_override("normal", _rounded_style(
		Color(1.0, 1.0, 1.0, 0.06), Color(1.0, 1.0, 1.0, 0.1), 3))
	b.add_theme_stylebox_override("hover", _rounded_style(
		ACCENT_AMBER_DIM, BORDER_AMBER, 3))
	b.add_theme_stylebox_override("pressed", _rounded_style(
		ACCENT_AMBER_DIM, BORDER_AMBER, 3))
	b.add_theme_stylebox_override("disabled", _rounded_style(
		Color(1.0, 1.0, 1.0, 0.03), BORDER_SUBTLE, 3))
	b.custom_minimum_size = Vector2(24, 24)
	return b


func _info_button() -> Button:
	var b := Button.new()
	b.icon = load(ICON_INFO)
	b.expand_icon = true
	b.add_theme_color_override("icon_normal_color", TEXT_DIM)
	b.add_theme_color_override("icon_hover_color", ACCENT_AMBER)
	b.add_theme_stylebox_override("normal", _rounded_style(
		Color(0, 0, 0, 0), Color(1.0, 1.0, 1.0, 0.1), 12))
	b.add_theme_stylebox_override("hover", _rounded_style(
		ACCENT_AMBER_DIM, BORDER_AMBER, 12))
	b.add_theme_stylebox_override("pressed", _rounded_style(
		ACCENT_AMBER_DIM, BORDER_AMBER, 12))
	b.custom_minimum_size = Vector2(24, 24)
	b.tooltip_text = "Details"
	return b


func _buy_button() -> Button:
	var b := Button.new()
	b.text = "BUY"
	b.add_theme_font_override("font", FONT_SEMIBOLD)
	b.add_theme_font_size_override("font_size", SIZE_LABEL)
	b.add_theme_color_override("font_color", ACCENT_AMBER)
	b.add_theme_color_override("font_hover_color", NIGHT_DEEP)
	b.add_theme_color_override("font_pressed_color", NIGHT_DEEP)
	b.add_theme_color_override("font_disabled_color", TEXT_DIM)
	b.add_theme_stylebox_override("normal", _button_style_padded(
		ACCENT_AMBER_DIM, BORDER_AMBER, 3, 6, 14))
	b.add_theme_stylebox_override("hover", _button_style_padded(
		ACCENT_AMBER, BORDER_AMBER_STRONG, 3, 6, 14))
	b.add_theme_stylebox_override("pressed", _button_style_padded(
		ACCENT_AMBER_HOVER, BORDER_AMBER_STRONG, 3, 6, 14))
	b.add_theme_stylebox_override("disabled", _button_style_padded(
		Color(1.0, 1.0, 1.0, 0.03), BORDER_SUBTLE, 3, 6, 14))
	return b


func _run_show_primary() -> Button:
	var b := Button.new()
	b.text = "RUN SHOW →"
	b.add_theme_font_override("font", FONT_SEMIBOLD)
	b.add_theme_font_size_override("font_size", SIZE_BODY)
	b.add_theme_color_override("font_color", NIGHT_DEEP)
	b.add_theme_color_override("font_hover_color", NIGHT_DEEP)
	b.add_theme_color_override("font_pressed_color", NIGHT_DEEP)
	# Disabled state keeps the amber shape visible — it should still
	# read as "this is the primary action" even when not clickable.
	b.add_theme_color_override("font_disabled_color", Color(NIGHT_DEEP.r, NIGHT_DEEP.g, NIGHT_DEEP.b, 0.6))
	b.add_theme_stylebox_override("normal", _button_style_padded(
		ACCENT_AMBER, ACCENT_AMBER, 4, 12, 32))
	b.add_theme_stylebox_override("hover", _button_style_padded(
		ACCENT_AMBER_HOVER, ACCENT_AMBER_HOVER, 4, 12, 32))
	b.add_theme_stylebox_override("pressed", _button_style_padded(
		ACCENT_AMBER, ACCENT_AMBER, 4, 12, 32))
	b.add_theme_stylebox_override("disabled", _button_style_padded(
		Color(1.0, 0.722, 0.302, 0.35), Color(1.0, 0.722, 0.302, 0.5), 4, 12, 32))
	b.custom_minimum_size = Vector2(160, 40)
	return b


func _menu_button() -> Button:
	var b := Button.new()
	b.icon = load(ICON_MENU)
	b.expand_icon = true
	b.add_theme_color_override("icon_normal_color", TEXT_MUTED)
	b.add_theme_color_override("icon_hover_color", TEXT_PRIMARY)
	b.add_theme_stylebox_override("normal", _rounded_style(
		Color(0, 0, 0, 0), Color(1.0, 1.0, 1.0, 0.15), 4))
	b.add_theme_stylebox_override("hover", _rounded_style(
		Color(1.0, 1.0, 1.0, 0.05), Color(1.0, 1.0, 1.0, 0.25), 4))
	b.add_theme_stylebox_override("pressed", _rounded_style(
		Color(1.0, 1.0, 1.0, 0.1), Color(1.0, 1.0, 1.0, 0.25), 4))
	b.custom_minimum_size = Vector2(40, 40)
	return b


func _tab_button(text: String, active: bool) -> Button:
	var b := Button.new()
	b.text = text.to_upper()
	b.toggle_mode = true
	b.button_pressed = active
	b.add_theme_font_override("font", FONT_SEMIBOLD)
	b.add_theme_font_size_override("font_size", SIZE_LABEL)
	b.custom_minimum_size = Vector2(0, 26)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_tab_button_set_active(b, active)
	return b


func _tab_button_set_active(b: Button, active: bool) -> void:
	b.button_pressed = active
	if active:
		b.add_theme_color_override("font_color", ACCENT_AMBER)
		b.add_theme_color_override("font_hover_color", ACCENT_AMBER)
		b.add_theme_stylebox_override("normal", _rounded_style(
			ACCENT_AMBER_DIM, Color(0, 0, 0, 0), 3))
		b.add_theme_stylebox_override("hover", _rounded_style(
			Color(1.0, 0.722, 0.302, 0.22), Color(0, 0, 0, 0), 3))
		b.add_theme_stylebox_override("pressed", _rounded_style(
			Color(1.0, 0.722, 0.302, 0.28), Color(0, 0, 0, 0), 3))
	else:
		b.add_theme_color_override("font_color", TEXT_MUTED)
		b.add_theme_color_override("font_hover_color", TEXT_PRIMARY)
		b.add_theme_stylebox_override("normal", _rounded_style(
			Color(0, 0, 0, 0), Color(0, 0, 0, 0), 3))
		b.add_theme_stylebox_override("hover", _rounded_style(
			Color(1.0, 1.0, 1.0, 0.04), Color(0, 0, 0, 0), 3))
		b.add_theme_stylebox_override("pressed", _rounded_style(
			Color(1.0, 1.0, 1.0, 0.08), Color(0, 0, 0, 0), 3))


func _strip(height: int) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, height)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c


func _rounded_style(bg: Color, border: Color, radius: int) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.border_width_left = 1
	sb.border_width_right = 1
	sb.border_width_top = 1
	sb.border_width_bottom = 1
	sb.corner_radius_top_left = radius
	sb.corner_radius_top_right = radius
	sb.corner_radius_bottom_left = radius
	sb.corner_radius_bottom_right = radius
	return sb


func _flat_bar_style(bg: Color, is_top: bool) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = BORDER_SUBTLE
	if is_top:
		sb.border_width_bottom = 1
	else:
		sb.border_width_top = 1
	return sb


func _button_style_padded(bg: Color, border: Color, radius: int, v_pad: int, h_pad: int) -> StyleBoxFlat:
	var sb := _rounded_style(bg, border, radius)
	sb.content_margin_left = h_pad
	sb.content_margin_right = h_pad
	sb.content_margin_top = v_pad
	sb.content_margin_bottom = v_pad
	return sb


func _fmt_num(n: int) -> String:
	if n >= 1_000_000_000:
		return "%.2fB" % (n / 1_000_000_000.0)
	if n >= 1_000_000:
		return "%.2fM" % (n / 1_000_000.0)
	if n >= 1_000:
		return "%.1fK" % (n / 1_000.0)
	return _comma(n)


func _comma(n: int) -> String:
	var s := str(n)
	var out := ""
	var count := 0
	for i in range(s.length() - 1, -1, -1):
		out = s[i] + out
		count += 1
		if count % 3 == 0 and i > 0:
			out = "," + out
	return out
