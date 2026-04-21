extends Control
## Planning screen — compact rows, tier color stripes, icon integration,
## pill buttons, and the owned / available / locked hierarchy per
## docs/planning_screen_final_spec.md.

const ZoneBackgroundScript := preload("res://scripts/components/ZoneBackground.gd")

# --- palette ------------------------------------------------------------------

const PANEL_BG := Color(0.071, 0.094, 0.220, 0.85)
const TOP_BAR_BG := Color(0.039, 0.063, 0.157, 0.90)
const BOTTOM_BAR_BG := Color(0.039, 0.063, 0.157, 0.92)
const ROW_BG := Color(0.102, 0.125, 0.282, 0.85)       # #1A2048 @ 0.85
const ROW_BG_SELECTED := Color(0.102, 0.125, 0.282, 0.95)
const ROW_BG_UNAFFORD := Color(0.071, 0.094, 0.220, 0.70)
const ROW_BG_LOCKED := Color(0.071, 0.094, 0.220, 0.50)
const CARD_AFFORDABLE := Color(0.102, 0.125, 0.282, 0.90)
const PANEL_BORDER := Color(0.165, 0.188, 0.333)
const DIVIDER := Color(0.165, 0.188, 0.333, 0.8)
const GOLD_BORDER := Color(1.0, 0.84, 0.0, 0.85)

const TEXT := Color(0.960, 0.902, 0.816)    # cream_bright
const MUTED := Color(0.540, 0.521, 0.439)   # cream_muted
const DIM := Color(0.290, 0.282, 0.220)     # cream_dim
const GOLD := Color(1.0, 0.84, 0.0)
const RED := Color(1.0, 0.35, 0.42)

const TIER_STRIPE := {
	1: Color(0.627, 0.439, 0.314),   # #A07050 bronze
	2: Color(0.690, 0.721, 0.753),   # #B0B8C0 silver
	3: Color(0.831, 0.686, 0.216),   # #D4AF37 gold
	4: Color(0.373, 0.784, 0.847),   # #5FC8D8 cyan
}

# --- sizes --------------------------------------------------------------------

const SIZE_DISPLAY := 48
const SIZE_TOPBAR := 32
const SIZE_HEADER := 28
const SIZE_BODY := 22
const SIZE_SMALL := 20
const SIZE_STATS := 18
const SIZE_CAPTION := 16

# --- icon paths ---------------------------------------------------------------

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
const ICON_SPEAKER := "res://assets/images/speaker.png"
const ICON_HOUSE := "res://assets/images/house.png"
const ICON_HOUSE_KEY := "res://assets/images/house.png"  # infrastructure
const CATEGORY_ICONS := {
	"marketing": "res://assets/images/speaker.png",
	"infrastructure": "res://assets/images/house.png",
	"crew": "res://assets/images/fans.png",
	"revenue": "res://assets/images/money.png",
}

const UPGRADE_CATEGORIES := ["All", "crew", "infrastructure", "revenue", "marketing"]
const UPGRADE_CATEGORY_LABELS := {
	"All": "All",
	"crew": "Crew",
	"infrastructure": "Infra",
	"revenue": "Rev",
	"marketing": "Mkt",
}

# --- state --------------------------------------------------------------------

var _fireworks_qty: Dictionary = {}
var _marketing_qty: Dictionary = {}
var _enhancements: Dictionary = {}   # category -> name
var _upgrade_buys: Array[String] = []
var _upgrade_category_filter: String = "All"

var _cash_label: Label
var _fans_label: Label
var _fans_progress: Control
var _fans_next_label: Label
var _run_show_button: Button
var _summary_label: Label
var _spend_label: Label
var _cash_after_label: Label
var _cash_arrow_label: Label
var _upgrade_body: VBoxContainer
var _firework_rows: Array = []       # {fw, wrap, style, stripe, qty_label, cost_preview, plus, minus}


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
	root.add_child(_strip(120))
	root.add_child(_build_bottom_bar())

	_refresh_totals()


# --- backdrop ----------------------------------------------------------------

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


# --- top bar -----------------------------------------------------------------

func _build_top_bar() -> Control:
	var bar := PanelContainer.new()
	bar.custom_minimum_size = Vector2(0, 60)
	bar.add_theme_stylebox_override("panel", _panel_style(TOP_BAR_BG))

	var outer := MarginContainer.new()
	outer.add_theme_constant_override("margin_left", 32)
	outer.add_theme_constant_override("margin_right", 32)
	outer.add_theme_constant_override("margin_top", 6)
	outer.add_theme_constant_override("margin_bottom", 6)
	bar.add_child(outer)

	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 32)
	h.alignment = BoxContainer.ALIGNMENT_CENTER
	outer.add_child(h)

	h.add_child(_label_sized("Night %d" % GameState.night, SIZE_TOPBAR, TEXT))

	var zone_wrap := VBoxContainer.new()
	zone_wrap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	zone_wrap.alignment = BoxContainer.ALIGNMENT_CENTER
	var zone_name: String = String(BalanceConfig.get_zone(GameState.current_zone).get("name", ""))
	var zone_title := _label_sized(
		"Zone %d: %s" % [GameState.current_zone, zone_name], SIZE_TOPBAR, TEXT)
	zone_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	zone_wrap.add_child(zone_title)
	h.add_child(zone_wrap)

	h.add_child(_build_top_bar_stats())
	return bar


func _build_top_bar_stats() -> Control:
	var v := VBoxContainer.new()
	v.custom_minimum_size = Vector2(280, 0)
	v.add_theme_constant_override("separation", 4)

	# Cash row: money icon + amount, right-aligned
	var cash_row := HBoxContainer.new()
	cash_row.alignment = BoxContainer.ALIGNMENT_END
	cash_row.add_theme_constant_override("separation", 8)
	cash_row.add_child(_icon(ICON_MONEY, 24))
	_cash_label = _label_sized("$%s" % _fmt_num(int(GameState.money)), SIZE_TOPBAR, GOLD)
	cash_row.add_child(_cash_label)
	v.add_child(cash_row)

	# Fans row: icon + current/threshold + progress + next-zone hint
	var fans_row := HBoxContainer.new()
	fans_row.alignment = BoxContainer.ALIGNMENT_END
	fans_row.add_theme_constant_override("separation", 6)
	fans_row.add_child(_icon(ICON_FANS, 16))

	var next_zone: Dictionary = BalanceConfig.get_zone(GameState.current_zone + 1)
	var next_threshold: int = int(next_zone.get("threshold_repeat_fans", 0)) if not next_zone.is_empty() else 0
	var fans_text: String = ""
	if next_threshold > 0:
		fans_text = "%s / %s" % [_fmt_num(GameState.repeat_fans), _fmt_num(next_threshold)]
	else:
		fans_text = "%s" % _fmt_num(GameState.repeat_fans)
	_fans_label = _label_sized(fans_text, SIZE_STATS, MUTED)
	fans_row.add_child(_fans_label)

	_fans_progress = _build_progress_bar(next_threshold, GameState.repeat_fans)
	fans_row.add_child(_fans_progress)
	v.add_child(fans_row)

	var next_name := String(next_zone.get("name", "")) if not next_zone.is_empty() else ""
	var next_label: String = "next: %s" % next_name if next_name != "" else "final zone"
	_fans_next_label = _label_sized(next_label, SIZE_CAPTION, DIM)
	_fans_next_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	v.add_child(_fans_next_label)
	return v


func _build_progress_bar(threshold: int, current: int) -> Control:
	var holder := Control.new()
	holder.custom_minimum_size = Vector2(80, 4)
	var track := ColorRect.new()
	track.color = Color(0.039, 0.063, 0.157, 0.9)
	track.anchor_right = 1.0
	track.anchor_bottom = 1.0
	holder.add_child(track)
	var fill := ColorRect.new()
	fill.color = GOLD
	fill.anchor_bottom = 1.0
	fill.anchor_right = 0.0
	var pct: float = 0.0
	if threshold > 0:
		pct = clampf(float(current) / float(threshold), 0.0, 1.0)
	fill.size = Vector2(80.0 * pct, 4.0)
	holder.add_child(fill)
	return holder


# --- panels row --------------------------------------------------------------

func _build_panels() -> Control:
	var margin := MarginContainer.new()
	margin.custom_minimum_size = Vector2(0, 444)
	margin.add_theme_constant_override("margin_left", 32)
	margin.add_theme_constant_override("margin_right", 32)

	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 16)
	margin.add_child(h)

	h.add_child(_panel("FIREWORKS", _build_fireworks_list(), 400))
	h.add_child(_panel("MARKETING / ENHANCEMENTS", _build_marketing_and_enhancements(), 384))
	h.add_child(_panel("UPGRADES", _build_upgrades_panel_body(), 400))
	return margin


func _panel(title: String, body: Control, width: int) -> Control:
	var wrap := PanelContainer.new()
	wrap.custom_minimum_size = Vector2(width, 0)
	wrap.size_flags_horizontal = 0
	wrap.size_flags_vertical = Control.SIZE_EXPAND_FILL
	wrap.add_theme_stylebox_override("panel", _panel_style(PANEL_BG))

	var pad := MarginContainer.new()
	pad.add_theme_constant_override("margin_left", 16)
	pad.add_theme_constant_override("margin_right", 16)
	pad.add_theme_constant_override("margin_top", 12)
	pad.add_theme_constant_override("margin_bottom", 12)
	wrap.add_child(pad)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	pad.add_child(v)

	v.add_child(_label_sized(title, SIZE_HEADER, TEXT))
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(body)
	return wrap


# --- firework compact rows ---------------------------------------------------

func _build_fireworks_list() -> Control:
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_theme_constant_override("separation", 4)
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
	var affordable: bool = float(cost) <= GameState.money

	var wrap := PanelContainer.new()
	wrap.custom_minimum_size = Vector2(0, 64)
	var style := _row_style(ROW_BG if affordable else ROW_BG_UNAFFORD)
	wrap.add_theme_stylebox_override("panel", style)

	var outer := HBoxContainer.new()
	outer.add_theme_constant_override("separation", 0)
	wrap.add_child(outer)

	# 4px tier color stripe
	var stripe := ColorRect.new()
	stripe.color = TIER_STRIPE.get(tier, TIER_STRIPE[1])
	stripe.custom_minimum_size = Vector2(4, 0)
	outer.add_child(stripe)

	var pad := MarginContainer.new()
	pad.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pad.add_theme_constant_override("margin_left", 8)
	pad.add_theme_constant_override("margin_right", 8)
	pad.add_theme_constant_override("margin_top", 12)
	pad.add_theme_constant_override("margin_bottom", 12)
	outer.add_child(pad)

	var content := HBoxContainer.new()
	content.add_theme_constant_override("separation", 8)
	pad.add_child(content)

	# name
	var name_color: Color = TEXT if affordable else MUTED
	var name_lbl := _label_sized(String(fw.name), SIZE_BODY, name_color)
	name_lbl.clip_text = true
	name_lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	content.add_child(name_lbl)

	# tier icon
	var tier_icon := _icon(TIER_ICONS.get(tier, TIER_ICONS[1]), 24)
	content.add_child(tier_icon)

	# stats line (cost + engagement only — tags are too wide for 400px rows)
	var stats_text: String = "$%s · %d eng" % [
		_fmt_num(cost), int(fw.get("engagement", 0))]
	var stats_lbl := _label_sized(stats_text, SIZE_STATS, MUTED if affordable else DIM)
	stats_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stats_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	stats_lbl.clip_text = true
	stats_lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	content.add_child(stats_lbl)

	# stepper
	var minus := _qty_button("-")
	var qty_lbl := _label_sized("0", SIZE_STATS, MUTED)
	qty_lbl.custom_minimum_size = Vector2(28, 0)
	qty_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var plus := _qty_button("+")
	content.add_child(minus)
	content.add_child(qty_lbl)
	content.add_child(plus)

	# cost preview
	var cost_preview := _label_sized("", SIZE_STATS, GOLD)
	cost_preview.custom_minimum_size = Vector2(64, 0)
	cost_preview.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	cost_preview.clip_text = true
	content.add_child(cost_preview)

	var entry := {
		"fw": fw, "wrap": wrap, "style": style, "stripe": stripe,
		"qty_label": qty_lbl, "cost_preview": cost_preview,
		"name_label": name_lbl, "plus": plus, "minus": minus,
	}
	_firework_rows.append(entry)
	minus.pressed.connect(func() -> void: _nudge_firework(fw, -1, entry))
	plus.pressed.connect(func() -> void: _nudge_firework(fw, 1, entry))
	return wrap


# --- marketing + enhancements ------------------------------------------------

func _build_marketing_and_enhancements() -> Control:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)

	v.add_child(_label_sized("Marketing", SIZE_CAPTION, MUTED))
	var mk_scroll := ScrollContainer.new()
	mk_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	mk_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var mk_v := VBoxContainer.new()
	mk_v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mk_v.add_theme_constant_override("separation", 10)
	mk_scroll.add_child(mk_v)
	v.add_child(mk_scroll)

	var mk_available: Array = GameEngine.available_marketing()
	if mk_available.is_empty():
		mk_v.add_child(_label_sized(
			"Only flyers available at this zone. More marketing options unlock as you grow.",
			SIZE_CAPTION, MUTED))
	else:
		for mk in mk_available:
			mk_v.add_child(_build_marketing_card(mk))

	v.add_child(_divider())
	v.add_child(_label_sized("Enhancements — one per category", SIZE_CAPTION, MUTED))

	var eh_scroll := ScrollContainer.new()
	eh_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	eh_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var eh_v := VBoxContainer.new()
	eh_v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	eh_v.add_theme_constant_override("separation", 10)
	eh_scroll.add_child(eh_v)
	v.add_child(eh_scroll)

	var groups: Dictionary = GameEngine.available_enhancements()
	for category in groups.keys():
		eh_v.add_child(_build_enhancement_category(String(category), groups[category]))
	return v


func _build_marketing_card(mk: Dictionary) -> Control:
	var wrap := PanelContainer.new()
	wrap.custom_minimum_size = Vector2(0, 88)
	wrap.add_theme_stylebox_override("panel", _card_style(CARD_AFFORDABLE))

	var pad := MarginContainer.new()
	pad.add_theme_constant_override("margin_left", 16)
	pad.add_theme_constant_override("margin_right", 16)
	pad.add_theme_constant_override("margin_top", 16)
	pad.add_theme_constant_override("margin_bottom", 16)
	wrap.add_child(pad)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	pad.add_child(v)

	var row_top := HBoxContainer.new()
	var name_lbl := _label_sized(String(mk.name), SIZE_SMALL, TEXT)
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row_top.add_child(name_lbl)
	row_top.add_child(_label_sized("$%s" % _fmt_num(int(mk.get("cost", 0))), SIZE_CAPTION, GOLD))
	v.add_child(row_top)

	var effect_text := "+%s attendees (cap %d)" % [
		_fmt_num(int(mk.get("attendees", 0))), int(mk.get("cap", 0))]
	v.add_child(_label_sized(effect_text, SIZE_CAPTION, MUTED))
	v.add_child(_strip(2))

	var row_ctrl := HBoxContainer.new()
	row_ctrl.add_theme_constant_override("separation", 6)
	var minus := _qty_button("-")
	var qty_label := _label_sized("0", SIZE_SMALL, MUTED)
	qty_label.custom_minimum_size = Vector2(32, 0)
	qty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var plus := _qty_button("+")
	minus.pressed.connect(func() -> void: _nudge_marketing(mk, -1, qty_label))
	plus.pressed.connect(func() -> void: _nudge_marketing(mk, 1, qty_label))
	row_ctrl.add_child(minus)
	row_ctrl.add_child(qty_label)
	row_ctrl.add_child(plus)
	v.add_child(row_ctrl)
	return wrap


func _build_enhancement_category(category: String, options: Array) -> Control:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	v.add_child(_label_sized(category.capitalize() + ":", SIZE_STATS, MUTED))

	# HFlowContainer wraps pills to the next row when the panel width runs out.
	var flow := HFlowContainer.new()
	flow.add_theme_constant_override("h_separation", 6)
	flow.add_theme_constant_override("v_separation", 6)

	var pills: Array[Button] = []
	var none_pill := _pill("None", true)
	flow.add_child(none_pill)
	pills.append(none_pill)
	none_pill.pressed.connect(func() -> void:
		_select_enhancement(category, "", pills, none_pill))

	for eh in options:
		var eh_dict: Dictionary = eh
		var label: String = "%s $%s" % [String(eh_dict.name), _fmt_num(int(eh_dict.get("cost", 0)))]
		if eh_dict.has("eng_mult"):
			label += " · +%d%% eng" % int(float(eh_dict.eng_mult) * 100)
		if eh_dict.has("tip_mult"):
			label += " · +%d%% tips" % int(float(eh_dict.tip_mult) * 100)
		var p := _pill(label, false)
		flow.add_child(p)
		pills.append(p)
		var eh_name: String = String(eh_dict.name)
		p.pressed.connect(func() -> void:
			_select_enhancement(category, eh_name, pills, p))

	v.add_child(flow)
	return v


# --- upgrades panel ----------------------------------------------------------

func _build_upgrades_panel_body() -> Control:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)

	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 4)
	var category_group: Array[Button] = []
	for cat in UPGRADE_CATEGORIES:
		var b := Button.new()
		b.text = String(UPGRADE_CATEGORY_LABELS.get(cat, cat))
		b.clip_text = true
		b.toggle_mode = true
		b.button_pressed = (cat == "All")
		b.add_theme_font_size_override("font_size", SIZE_CAPTION)
		b.custom_minimum_size = Vector2(0, 32)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var cat_str: String = cat
		b.pressed.connect(func() -> void:
			_upgrade_category_filter = cat_str
			for btn in category_group:
				btn.button_pressed = btn == b
			_rebuild_upgrades())
		category_group.append(b)
		tabs.add_child(b)
	v.add_child(tabs)

	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_upgrade_body = VBoxContainer.new()
	_upgrade_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_upgrade_body.add_theme_constant_override("separation", 12)
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

	# OWNED
	_upgrade_body.add_child(_section_header("OWNED", TEXT))
	if owned.is_empty():
		_upgrade_body.add_child(_label_sized(
			"No upgrades yet — buy your first below.", SIZE_CAPTION, MUTED))
	for up in owned:
		_upgrade_body.add_child(_owned_row(up))

	# AVAILABLE
	_upgrade_body.add_child(_section_header("AVAILABLE", TEXT))
	if available.is_empty():
		_upgrade_body.add_child(_label_sized(
			"  (nothing purchasable this zone)", SIZE_CAPTION, MUTED))
	for up in available:
		_upgrade_body.add_child(_upgrade_card(up))

	# LOCKED
	_upgrade_body.add_child(_section_header("LOCKED", DIM))
	if locked.is_empty():
		_upgrade_body.add_child(_label_sized("  (everything unlocked)", SIZE_CAPTION, MUTED))
	else:
		# Next-unlock callout: the soonest locked item.
		locked.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
			return int(a.get("min_zone", 1)) < int(b.get("min_zone", 1)))
		var next_up: Dictionary = locked[0]
		_upgrade_body.add_child(_next_unlock_callout(next_up))
		for up in locked:
			_upgrade_body.add_child(_locked_row(up))


func _section_header(text: String, color: Color) -> Control:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 2)
	v.add_child(_divider())
	v.add_child(_label_sized(text, SIZE_CAPTION, color))
	v.add_child(_divider())
	return v


func _owned_row(up: Dictionary) -> Control:
	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(0, 36)
	row.add_theme_constant_override("separation", 8)
	row.add_child(_icon(ICON_CHECK, 16))
	var name_lbl := _label_sized(String(up.name), SIZE_BODY, TEXT)
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(name_lbl)
	row.add_child(_label_sized("owned", SIZE_CAPTION, MUTED))
	return row


func _locked_row(up: Dictionary) -> Control:
	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(0, 36)
	row.add_theme_constant_override("separation", 8)
	row.add_child(_icon(ICON_LOCK, 16))
	var name_lbl := _label_sized(String(up.name), SIZE_STATS, DIM)
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(name_lbl)
	row.add_child(_label_sized("Zone %d+" % int(up.get("min_zone", 1)), SIZE_CAPTION, MUTED))
	return row


func _next_unlock_callout(up: Dictionary) -> Control:
	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(0, 32)
	row.add_theme_constant_override("separation", 8)
	row.add_child(_icon(ICON_ARROW, 16))
	var effect: String = _effect_summary(up.get("effect", {}))
	var text: String = "Next unlock at Zone %d: %s" % [int(up.get("min_zone", 1)), String(up.name)]
	if effect != "":
		text += " (%s)" % effect
	var lbl := _label_sized(text, SIZE_CAPTION, TEXT)
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	row.add_child(lbl)
	return row


func _upgrade_card(up: Dictionary) -> Control:
	var cost: int = int(up.get("cost", 0))
	var affordable: bool = float(cost) <= GameState.money
	var wrap := PanelContainer.new()
	wrap.custom_minimum_size = Vector2(0, 110)
	var style := _card_style(CARD_AFFORDABLE)
	wrap.add_theme_stylebox_override("panel", style)

	var pad := MarginContainer.new()
	pad.add_theme_constant_override("margin_left", 16)
	pad.add_theme_constant_override("margin_right", 16)
	pad.add_theme_constant_override("margin_top", 16)
	pad.add_theme_constant_override("margin_bottom", 16)
	wrap.add_child(pad)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	pad.add_child(v)

	# Row 1: name + category icon
	var row_name := HBoxContainer.new()
	row_name.add_theme_constant_override("separation", 8)
	var name_lbl := _label_sized(String(up.name), SIZE_BODY, TEXT if affordable else MUTED)
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row_name.add_child(name_lbl)
	var cat: String = String(up.get("category", ""))
	if CATEGORY_ICONS.has(cat):
		row_name.add_child(_icon(CATEGORY_ICONS[cat], 20))
	v.add_child(row_name)

	# Row 2: cost (bigger, bold gold)
	v.add_child(_label_sized("$%s" % _fmt_num(cost), SIZE_BODY, GOLD if affordable else MUTED))

	# Row 3: effect + buy
	var row_end := HBoxContainer.new()
	row_end.add_theme_constant_override("separation", 8)
	var effect_lbl := _label_sized(
		_effect_summary(up.get("effect", {})), SIZE_STATS, MUTED)
	effect_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	effect_lbl.clip_text = true
	effect_lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	row_end.add_child(effect_lbl)

	var buy_btn := _buy_button()
	var name_str: String = String(up.name)
	if _upgrade_buys.has(name_str):
		buy_btn.text = "UNDO"
	buy_btn.disabled = not affordable and not _upgrade_buys.has(name_str)
	buy_btn.pressed.connect(func() -> void:
		if _upgrade_buys.has(name_str):
			_upgrade_buys.erase(name_str)
		else:
			_upgrade_buys.append(name_str)
		_rebuild_upgrades()
		_refresh_totals())
	row_end.add_child(buy_btn)
	v.add_child(row_end)
	return wrap


func _effect_summary(effect: Dictionary) -> String:
	var parts: Array[String] = []
	if effect.has("attendees_permanent"):
		parts.append("+%s attendees perm" % _fmt_num(int(effect.attendees_permanent)))
	if effect.has("tip_mult_permanent"):
		parts.append("+%d%% tips perm" % int(float(effect.tip_mult_permanent) * 100))
	if effect.has("eng_mult_permanent"):
		parts.append("+%d%% eng perm" % int(float(effect.eng_mult_permanent) * 100))
	if effect.has("show_quality_mult"):
		parts.append("+%d%% show quality" % int(float(effect.show_quality_mult) * 100))
	if effect.has("unlocks_donation") or effect.has("unlocks_zone_6_finale") or effect.has("unlocks_tier_4_research"):
		parts.append("unlocks endgame content")
	return ", ".join(parts)


# --- bottom bar --------------------------------------------------------------

func _build_bottom_bar() -> Control:
	var bar := PanelContainer.new()
	bar.custom_minimum_size = Vector2(0, 80)
	bar.add_theme_stylebox_override("panel", _panel_style(BOTTOM_BAR_BG))

	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", 32)
	m.add_theme_constant_override("margin_right", 32)
	m.add_theme_constant_override("margin_top", 12)
	m.add_theme_constant_override("margin_bottom", 12)
	bar.add_child(m)

	var h := HBoxContainer.new()
	h.alignment = BoxContainer.ALIGNMENT_CENTER
	h.add_theme_constant_override("separation", 24)
	m.add_child(h)

	_summary_label = _label_sized(
		"Pick at least one firework to fire your show.", SIZE_CAPTION, MUTED)
	_summary_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(_summary_label)

	_spend_label = _label_sized("Spend: $0", SIZE_BODY, TEXT)
	h.add_child(_spend_label)
	_cash_arrow_label = _label_sized("→", SIZE_BODY, MUTED)
	_cash_arrow_label.visible = false
	h.add_child(_cash_arrow_label)
	_cash_after_label = _label_sized("", SIZE_BODY, TEXT)
	_cash_after_label.visible = false
	h.add_child(_cash_after_label)

	_run_show_button = _primary_button("RUN SHOW")
	_run_show_button.icon = load(ICON_ARROW)
	_run_show_button.expand_icon = true
	_run_show_button.pressed.connect(_on_run_show_pressed)
	h.add_child(_run_show_button)
	return bar


# --- handlers ----------------------------------------------------------------

func _nudge_firework(fw: Dictionary, delta: int, entry: Dictionary) -> void:
	var name_str: String = String(fw.name)
	var current: int = int(_fireworks_qty.get(name_str, 0))
	var cap: int = int(BalanceConfig.get_zone(GameState.current_zone).get("firework_cap", 300))
	var new_qty: int = maxi(current + delta, 0)
	new_qty = mini(new_qty, cap)
	_fireworks_qty[name_str] = new_qty
	(entry.qty_label as Label).text = str(new_qty)
	(entry.qty_label as Label).add_theme_color_override(
		"font_color", GOLD if new_qty > 0 else MUTED)
	var cost_preview_lbl: Label = entry.cost_preview
	if new_qty > 0:
		cost_preview_lbl.text = "$%s" % _fmt_num(new_qty * int(fw.get("cost", 0)))
	else:
		cost_preview_lbl.text = ""
	_apply_row_selected(entry, new_qty > 0)
	_refresh_totals()


func _apply_row_selected(entry: Dictionary, selected: bool) -> void:
	var style: StyleBoxFlat = entry.style
	if selected:
		style.bg_color = ROW_BG_SELECTED
		style.border_color = GOLD_BORDER
		style.border_width_left = 1
		style.border_width_right = 1
		style.border_width_top = 1
		style.border_width_bottom = 1
	else:
		style.bg_color = ROW_BG
		style.border_width_left = 0
		style.border_width_right = 0
		style.border_width_top = 0
		style.border_width_bottom = 0


func _nudge_marketing(mk: Dictionary, delta: int, qty_label: Label) -> void:
	var name_str: String = String(mk.name)
	var current: int = int(_marketing_qty.get(name_str, 0))
	var cap: int = int(mk.get("cap", 0))
	var new_qty: int = maxi(current + delta, 0)
	if cap > 0:
		new_qty = mini(new_qty, cap)
	_marketing_qty[name_str] = new_qty
	qty_label.text = str(new_qty)
	qty_label.add_theme_color_override("font_color", GOLD if new_qty > 0 else MUTED)
	_refresh_totals()


func _select_enhancement(category: String, name: String, pills: Array[Button], clicked: Button) -> void:
	for p in pills:
		_set_pill_selected(p, p == clicked)
	if name == "":
		_enhancements.erase(category)
	else:
		_enhancements[category] = name
	_refresh_totals()


# --- totals ------------------------------------------------------------------

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

	var cash_after: float = GameState.money - spend
	var overspend: bool = spend > GameState.money
	var color: Color = TEXT
	if spend > 0 and not overspend:
		color = GOLD
	elif overspend:
		color = RED
	_spend_label.text = "Spend: $%s" % _fmt_num(int(spend))
	_spend_label.add_theme_color_override("font_color", color)
	var show_after := spend > 0
	_cash_arrow_label.visible = show_after
	_cash_after_label.visible = show_after
	if show_after:
		_cash_after_label.text = "Cash after: $%s" % _fmt_num(int(cash_after))
		_cash_after_label.add_theme_color_override(
			"font_color", RED if overspend else TEXT)

	if fw_count <= 0:
		_summary_label.text = "Pick at least one firework to fire your show."
	else:
		_summary_label.text = "%d fireworks · %d marketing · %d enhancements · %d upgrades" % [
			fw_count, _marketing_total(), _enhancements.size(), _upgrade_buys.size(),
		]
	_run_show_button.disabled = overspend or (fw_count <= 0)


func _marketing_total() -> int:
	var t: int = 0
	for v in _marketing_qty.values():
		t += int(v)
	return t


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


# --- primitives --------------------------------------------------------------

func _label_sized(text: String, font_size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	return l


func _icon(path: String, px: int) -> TextureRect:
	var t := TextureRect.new()
	t.texture = load(path)
	t.custom_minimum_size = Vector2(px, px)
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return t


func _qty_button(text: String) -> Button:
	var b := Button.new()
	b.text = text
	b.add_theme_font_size_override("font_size", SIZE_STATS)
	b.add_theme_color_override("font_color", TEXT)
	b.add_theme_stylebox_override("normal", _button_style(
		Color(0.039, 0.063, 0.157, 0.7), PANEL_BORDER))
	b.add_theme_stylebox_override("hover", _button_style(
		Color(0.165, 0.188, 0.333, 0.9), GOLD_BORDER))
	b.add_theme_stylebox_override("pressed", _button_style(
		Color(0.165, 0.188, 0.333, 0.95), GOLD_BORDER))
	b.add_theme_stylebox_override("disabled", _button_style(
		Color(0.071, 0.094, 0.220, 0.4), PANEL_BORDER))
	b.custom_minimum_size = Vector2(32, 28)
	return b


func _buy_button() -> Button:
	var b := Button.new()
	b.text = "BUY"
	b.add_theme_font_size_override("font_size", SIZE_STATS)
	b.add_theme_color_override("font_color", GOLD)
	b.add_theme_color_override("font_pressed_color", Color(0.039, 0.063, 0.157))
	b.add_theme_color_override("font_hover_color", Color(0.039, 0.063, 0.157))
	b.add_theme_color_override("font_disabled_color", DIM)
	b.add_theme_stylebox_override("normal", _button_style(
		Color(0.102, 0.125, 0.282, 0.6), GOLD_BORDER))
	b.add_theme_stylebox_override("hover", _button_style(GOLD, GOLD_BORDER))
	b.add_theme_stylebox_override("pressed", _button_style(
		Color(0.831, 0.686, 0.216), GOLD_BORDER))
	b.add_theme_stylebox_override("disabled", _button_style(
		Color(0.071, 0.094, 0.220, 0.5), PANEL_BORDER))
	b.custom_minimum_size = Vector2(80, 32)
	return b


func _primary_button(text: String) -> Button:
	var b := Button.new()
	b.text = text
	b.add_theme_font_size_override("font_size", SIZE_BODY)
	b.add_theme_color_override("font_color", GOLD)
	b.add_theme_color_override("font_hover_color", Color(0.039, 0.063, 0.157))
	b.add_theme_color_override("font_pressed_color", Color(0.039, 0.063, 0.157))
	b.add_theme_color_override("font_disabled_color", DIM)
	b.add_theme_stylebox_override("normal", _button_style(
		Color(0.102, 0.125, 0.282, 0.6), GOLD_BORDER))
	b.add_theme_stylebox_override("hover", _button_style(GOLD, GOLD_BORDER))
	b.add_theme_stylebox_override("pressed", _button_style(
		Color(0.831, 0.686, 0.216), GOLD_BORDER))
	b.add_theme_stylebox_override("disabled", _button_style(
		Color(0.071, 0.094, 0.220, 0.5), PANEL_BORDER))
	b.custom_minimum_size = Vector2(180, 48)
	return b


func _pill(text: String, starts_selected: bool) -> Button:
	var b := Button.new()
	b.text = text
	b.toggle_mode = true
	b.button_pressed = starts_selected
	b.add_theme_font_size_override("font_size", SIZE_STATS)
	b.custom_minimum_size = Vector2(0, 32)
	_set_pill_selected(b, starts_selected)
	return b


func _set_pill_selected(b: Button, selected: bool) -> void:
	b.button_pressed = selected
	if selected:
		b.add_theme_color_override("font_color", GOLD)
		b.add_theme_color_override("font_hover_color", GOLD)
		b.add_theme_stylebox_override("normal", _button_style(
			Color(1.0, 0.84, 0.0, 0.15), GOLD_BORDER))
		b.add_theme_stylebox_override("hover", _button_style(
			Color(1.0, 0.84, 0.0, 0.25), GOLD_BORDER))
		b.add_theme_stylebox_override("pressed", _button_style(
			Color(1.0, 0.84, 0.0, 0.25), GOLD_BORDER))
	else:
		b.add_theme_color_override("font_color", MUTED)
		b.add_theme_color_override("font_hover_color", TEXT)
		var dim_border := Color(DIM.r, DIM.g, DIM.b, 0.9)
		b.add_theme_stylebox_override("normal", _button_style(
			Color(0, 0, 0, 0), dim_border))
		b.add_theme_stylebox_override("hover", _button_style(
			Color(0.165, 0.188, 0.333, 0.4), MUTED))
		b.add_theme_stylebox_override("pressed", _button_style(
			Color(0.165, 0.188, 0.333, 0.7), MUTED))


func _strip(height: int) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, height)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c


func _hspacer(width: int) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(width, 0)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c


func _divider() -> Control:
	var c := ColorRect.new()
	c.color = DIVIDER
	c.custom_minimum_size = Vector2(0, 1)
	return c


func _panel_style(color: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.border_color = PANEL_BORDER
	sb.border_width_left = 1
	sb.border_width_right = 1
	sb.border_width_top = 1
	sb.border_width_bottom = 1
	return sb


func _card_style(color: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	return sb


func _row_style(color: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	return sb


func _button_style(fill: Color, border: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = fill
	sb.border_color = border
	sb.border_width_left = 1
	sb.border_width_right = 1
	sb.border_width_top = 1
	sb.border_width_bottom = 1
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	sb.content_margin_top = 6
	sb.content_margin_bottom = 6
	return sb


func _fmt_num(n: int) -> String:
	if n >= 1_000_000_000:
		return "%.2fB" % (n / 1_000_000_000.0)
	if n >= 1_000_000:
		return "%.2fM" % (n / 1_000_000.0)
	if n >= 1_000:
		return "%.1fK" % (n / 1_000.0)
	return str(n)
