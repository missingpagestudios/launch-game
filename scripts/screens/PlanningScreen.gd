extends Control
## Three-panel planning screen on a layered atmospheric backdrop.
## See docs/planning_screen_integration_instructions.md for the spec.
##
## Layout (1280×720):
##   y=0..60    top bar (90% opaque)
##   y=60..76   atmospheric strip — sky bleeds through
##   y=76..520  panels (85% opaque)
##   y=520..640 atmospheric strip — foreground silhouettes show through
##   y=640..720 bottom bar (92% opaque)
##
## Horizontal: 32 edge + 400 FW + 16 gap + 384 MK/EN + 16 gap + 400 UP + 32 edge

const ZoneBackgroundScript := preload("res://scripts/components/ZoneBackground.gd")

# Panel + card colors carry per-element alpha per integration doc.
const PANEL_BG := Color(0.071, 0.094, 0.220, 0.85)    # #121838 @ 85%
const TOP_BAR_BG := Color(0.039, 0.063, 0.157, 0.90)  # #0A1028 @ 90%
const BOTTOM_BAR_BG := Color(0.039, 0.063, 0.157, 0.92)
const CARD_AFFORDABLE := Color(0.102, 0.125, 0.282, 0.90) # #1A2048 @ 90%
const CARD_UNAFFORDABLE := Color(0.071, 0.094, 0.220, 0.90)
const CARD_SELECTED_BORDER := Color(1.0, 0.84, 0.0)
const PANEL_BORDER := Color(0.165, 0.188, 0.333)
const DIVIDER := Color(0.165, 0.188, 0.333, 0.8)

const TEXT := Color(0.960, 0.902, 0.816)
const MUTED := Color(0.540, 0.521, 0.439)
const GOLD := Color(1.0, 0.84, 0.0)
const RED := Color(1.0, 0.35, 0.42)

const TIER_COLORS := {
	1: Color(0.55, 0.60, 0.70),
	2: Color(0.55, 0.80, 0.55),
	3: Color(0.85, 0.55, 0.75),
	4: Color(1.00, 0.84, 0.00),
}

const UPGRADE_CATEGORIES := ["All", "crew", "infrastructure", "revenue", "marketing"]

# Size tokens (per integration doc Part 4).
const SIZE_DISPLAY := 48
const SIZE_TOPBAR := 32
const SIZE_HEADER := 28
const SIZE_BODY := 22
const SIZE_SMALL := 20
const SIZE_STATS := 18
const SIZE_CAPTION := 16

var _fireworks_qty: Dictionary = {}
var _marketing_qty: Dictionary = {}
var _enhancements: Dictionary = {}
var _upgrade_buys: Array[String] = []

var _total_spend_label: Label
var _cash_label: Label
var _fans_label: Label
var _run_show_button: Button
var _summary_label: Label
var _upgrade_category_filter: String = "All"
var _firework_rows: Array = []
var _upgrade_body: VBoxContainer


func _ready() -> void:
	_add_backdrop()

	# UI layer — vertical chain with fixed-height atmospheric strips.
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


# --- backdrop -----------------------------------------------------------------

func _add_backdrop() -> void:
	# If zone-specific images exist, layer sky (behind) and foreground (above
	# the future particles slot, but below the UI). Else fall back to the
	# primitive-drawn ZoneBackground.
	var zone_id: int = GameState.current_zone
	var sky_path: String = "res://assets/backgrounds/zone%d.png" % zone_id
	var fg_path: String = "res://assets/backgrounds/zone%d-foreground.png" % zone_id

	if ResourceLoader.exists(sky_path):
		var sky := TextureRect.new()
		sky.texture = load(sky_path)
		sky.anchor_right = 1.0
		sky.anchor_bottom = 1.0
		sky.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		sky.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		sky.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(sky)

	# Particle slot — empty in stage 2, stage 3 drops the demo here.
	var particle_slot := Control.new()
	particle_slot.anchor_right = 1.0
	particle_slot.anchor_bottom = 1.0
	particle_slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	particle_slot.name = "ParticleSlot"
	add_child(particle_slot)

	if ResourceLoader.exists(fg_path):
		var fg := TextureRect.new()
		fg.texture = load(fg_path)
		fg.anchor_right = 1.0
		fg.anchor_bottom = 1.0
		fg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		fg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		fg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(fg)
	elif not ResourceLoader.exists(sky_path):
		# Nothing to show from PNGs — use the primitive backdrop fallback.
		var bg: Control = ZoneBackgroundScript.new()
		bg.zone_id = zone_id
		add_child(bg)


# --- top bar ------------------------------------------------------------------

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

	var zone_name: String = String(BalanceConfig.get_zone(GameState.current_zone).get("name", ""))

	h.add_child(_label_sized("Night %d" % GameState.night, SIZE_TOPBAR, TEXT))

	var zone_wrap := VBoxContainer.new()
	zone_wrap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	zone_wrap.alignment = BoxContainer.ALIGNMENT_CENTER
	var zone_title := _label_sized(
		"Zone %d: %s" % [GameState.current_zone, zone_name], SIZE_TOPBAR, TEXT)
	zone_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	zone_wrap.add_child(zone_title)
	h.add_child(zone_wrap)

	var right := VBoxContainer.new()
	right.alignment = BoxContainer.ALIGNMENT_CENTER
	right.custom_minimum_size = Vector2(220, 0)
	_cash_label = _label_sized("$%s" % _fmt_num(int(GameState.money)), SIZE_TOPBAR, GOLD)
	_cash_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_cash_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_child(_cash_label)
	_fans_label = _label_sized(
		"Fans: %s" % _fmt_num(GameState.repeat_fans), SIZE_CAPTION, MUTED)
	_fans_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_fans_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_child(_fans_label)
	h.add_child(right)

	return bar


# --- panels row ---------------------------------------------------------------

func _build_panels() -> Control:
	# Fixed horizontal layout: 32 | 400 | 16 | 384 | 16 | 400 | 32
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


# --- firework cards -----------------------------------------------------------

func _build_fireworks_list() -> Control:
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_theme_constant_override("separation", 12)
	scroll.add_child(v)

	var fireworks: Array = GameEngine.available_fireworks().duplicate()
	fireworks.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if int(a.get("tier", 1)) != int(b.get("tier", 1)):
			return int(a.get("tier", 1)) < int(b.get("tier", 1))
		return int(a.get("cost", 0)) < int(b.get("cost", 0)))
	for fw in fireworks:
		v.add_child(_build_firework_card(fw))
	return scroll


func _build_firework_card(fw: Dictionary) -> Control:
	var cost: int = int(fw.get("cost", 0))
	var affordable: bool = float(cost) <= GameState.money
	var wrap := PanelContainer.new()
	wrap.custom_minimum_size = Vector2(0, 118)
	var style := _card_style(CARD_AFFORDABLE if affordable else CARD_UNAFFORDABLE)
	wrap.add_theme_stylebox_override("panel", style)

	var pad := MarginContainer.new()
	pad.add_theme_constant_override("margin_left", 16)
	pad.add_theme_constant_override("margin_right", 16)
	pad.add_theme_constant_override("margin_top", 16)
	pad.add_theme_constant_override("margin_bottom", 16)
	wrap.add_child(pad)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 0)
	pad.add_child(v)

	var row_name := HBoxContainer.new()
	row_name.add_theme_constant_override("separation", 8)
	var name_lbl: Label = _label_sized(String(fw.name), SIZE_BODY, TEXT if affordable else MUTED)
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row_name.add_child(name_lbl)
	row_name.add_child(_tier_badge(int(fw.get("tier", 1))))
	v.add_child(row_name)

	v.add_child(_strip(8))

	var tags: Array = fw.get("tags", [])
	var stats_line: String = "$%s · %d eng" % [_fmt_num(cost), int(fw.get("engagement", 0))]
	if not tags.is_empty():
		stats_line += " · " + ", ".join(tags)
	var stats_lbl: Label = _label_sized(stats_line, SIZE_STATS, TEXT if affordable else MUTED)
	v.add_child(stats_lbl)

	v.add_child(_strip(10))

	var row_ctrl := HBoxContainer.new()
	row_ctrl.add_theme_constant_override("separation", 6)
	var minus := _small_button("-")
	var qty_lbl := _label_sized("0", SIZE_BODY, GOLD)
	qty_lbl.custom_minimum_size = Vector2(36, 0)
	qty_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var plus := _small_button("+")
	row_ctrl.add_child(minus)
	row_ctrl.add_child(qty_lbl)
	row_ctrl.add_child(plus)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row_ctrl.add_child(spacer)
	var cost_preview := _label_sized("", SIZE_BODY, GOLD)
	cost_preview.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row_ctrl.add_child(cost_preview)
	v.add_child(row_ctrl)

	var entry := {
		"fw": fw,
		"wrap": wrap,
		"style": style,
		"qty_label": qty_lbl,
		"cost_preview": cost_preview,
	}
	_firework_rows.append(entry)
	minus.pressed.connect(func() -> void: _nudge_firework(fw, -1, entry))
	plus.pressed.connect(func() -> void: _nudge_firework(fw, 1, entry))
	return wrap


func _tier_badge(tier: int) -> Control:
	var badge := PanelContainer.new()
	badge.custom_minimum_size = Vector2(52, 22)
	var style := _card_style(TIER_COLORS.get(tier, TIER_COLORS[1]))
	badge.add_theme_stylebox_override("panel", style)

	var pad := MarginContainer.new()
	pad.add_theme_constant_override("margin_left", 6)
	pad.add_theme_constant_override("margin_right", 6)
	badge.add_child(pad)
	var lbl := _label_sized("T%d" % tier, SIZE_CAPTION, Color(0, 0, 0, 0.85))
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pad.add_child(lbl)
	return badge


# --- marketing + enhancements -------------------------------------------------

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

	for mk in GameEngine.available_marketing():
		mk_v.add_child(_build_marketing_card(mk))

	v.add_child(_divider())
	v.add_child(_label_sized("Enhancements — one per category", SIZE_CAPTION, MUTED))

	var eh_scroll := ScrollContainer.new()
	eh_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	eh_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var eh_v := VBoxContainer.new()
	eh_v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	eh_v.add_theme_constant_override("separation", 6)
	eh_scroll.add_child(eh_v)
	v.add_child(eh_scroll)

	var groups: Dictionary = GameEngine.available_enhancements()
	for category in groups.keys():
		eh_v.add_child(_label_sized(String(category).capitalize(), SIZE_CAPTION, MUTED))
		var group_container := VBoxContainer.new()
		group_container.add_theme_constant_override("separation", 10)
		eh_v.add_child(group_container)

		var none_btn := CheckBox.new()
		none_btn.text = "None"
		none_btn.button_pressed = true
		none_btn.add_theme_font_size_override("font_size", SIZE_SMALL)
		group_container.add_child(none_btn)
		var buttons: Array[CheckBox] = [none_btn]
		var cat_str: String = String(category)
		none_btn.pressed.connect(func() -> void:
			_select_enhancement(cat_str, "", buttons, none_btn))

		for eh in groups[category]:
			var eh_dict: Dictionary = eh
			var cb := CheckBox.new()
			cb.text = "%s — $%s" % [String(eh_dict.name), _fmt_num(int(eh_dict.get("cost", 0)))]
			if eh_dict.has("eng_mult"):
				cb.text += " (+%d%% eng)" % int(float(eh_dict.eng_mult) * 100)
			if eh_dict.has("tip_mult"):
				cb.text += " (+%d%% tips)" % int(float(eh_dict.tip_mult) * 100)
			cb.add_theme_font_size_override("font_size", SIZE_SMALL)
			group_container.add_child(cb)
			buttons.append(cb)
			var eh_name: String = String(eh_dict.name)
			cb.pressed.connect(func() -> void:
				_select_enhancement(cat_str, eh_name, buttons, cb))

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
		_fmt_num(int(mk.get("attendees", 0))),
		int(mk.get("cap", 0)),
	]
	v.add_child(_label_sized(effect_text, SIZE_CAPTION, MUTED))
	v.add_child(_strip(2))

	var row_ctrl := HBoxContainer.new()
	row_ctrl.add_theme_constant_override("separation", 6)
	var minus := _small_button("-")
	var qty_label := _label_sized("0", SIZE_SMALL, GOLD)
	qty_label.custom_minimum_size = Vector2(32, 0)
	qty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var plus := _small_button("+")
	minus.pressed.connect(func() -> void: _nudge_marketing(mk, -1, qty_label))
	plus.pressed.connect(func() -> void: _nudge_marketing(mk, 1, qty_label))
	row_ctrl.add_child(minus)
	row_ctrl.add_child(qty_label)
	row_ctrl.add_child(plus)
	v.add_child(row_ctrl)
	return wrap


# --- upgrades panel -----------------------------------------------------------

func _build_upgrades_panel_body() -> Control:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)

	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 4)
	var category_group: Array[Button] = []
	for cat in UPGRADE_CATEGORIES:
		var b := Button.new()
		b.text = String(cat).capitalize()
		b.toggle_mode = true
		b.button_pressed = (cat == "All")
		b.add_theme_font_size_override("font_size", SIZE_SMALL)
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

	_upgrade_body.add_child(_section_header("OWNED"))
	if owned.is_empty():
		_upgrade_body.add_child(_label_sized("  (none)", SIZE_CAPTION, MUTED))
	for up in owned:
		_upgrade_body.add_child(_owned_row(up))

	_upgrade_body.add_child(_section_header("AVAILABLE"))
	if available.is_empty():
		_upgrade_body.add_child(_label_sized("  (nothing purchasable this zone)", SIZE_CAPTION, MUTED))
	for up in available:
		_upgrade_body.add_child(_upgrade_card(up))

	_upgrade_body.add_child(_section_header("LOCKED"))
	if locked.is_empty():
		_upgrade_body.add_child(_label_sized("  (everything unlocked)", SIZE_CAPTION, MUTED))
	for up in locked:
		_upgrade_body.add_child(_locked_row(up))


func _section_header(text: String) -> Control:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 2)
	v.add_child(_divider())
	v.add_child(_label_sized(text, SIZE_CAPTION, MUTED))
	v.add_child(_divider())
	return v


func _owned_row(up: Dictionary) -> Control:
	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(0, 36)
	row.add_theme_constant_override("separation", 8)
	row.add_child(_label_sized("  ✓ %s" % String(up.name), SIZE_SMALL, MUTED))
	return row


func _locked_row(up: Dictionary) -> Control:
	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(0, 36)
	row.add_theme_constant_override("separation", 8)
	var left := _label_sized("  🔒 %s" % String(up.name), SIZE_SMALL, MUTED)
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(left)
	row.add_child(_label_sized("Zone %d+" % int(up.get("min_zone", 1)), SIZE_CAPTION, MUTED))
	return row


func _upgrade_card(up: Dictionary) -> Control:
	var cost: int = int(up.get("cost", 0))
	var affordable: bool = float(cost) <= GameState.money
	var wrap := PanelContainer.new()
	wrap.custom_minimum_size = Vector2(0, 110)
	var style := _card_style(CARD_AFFORDABLE if affordable else CARD_UNAFFORDABLE)
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

	var row_name := HBoxContainer.new()
	row_name.add_theme_constant_override("separation", 8)
	var name_lbl: Label = _label_sized(String(up.name), SIZE_SMALL, TEXT if affordable else MUTED)
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row_name.add_child(name_lbl)
	row_name.add_child(_label_sized("[%s]" % String(up.get("category", "")), SIZE_CAPTION, MUTED))
	v.add_child(row_name)

	v.add_child(_label_sized("$%s" % _fmt_num(cost), SIZE_SMALL, GOLD if affordable else MUTED))

	var row_end := HBoxContainer.new()
	row_end.add_theme_constant_override("separation", 8)
	var effect_lbl := _label_sized(
		_effect_summary(up.get("effect", {})), SIZE_CAPTION, TEXT if affordable else MUTED)
	effect_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row_end.add_child(effect_lbl)

	var buy_btn := Button.new()
	buy_btn.text = "Buy"
	buy_btn.add_theme_font_size_override("font_size", SIZE_SMALL)
	buy_btn.custom_minimum_size = Vector2(72, 28)
	buy_btn.disabled = not affordable
	var name_str: String = String(up.name)
	if _upgrade_buys.has(name_str):
		buy_btn.text = "Undo"
	buy_btn.pressed.connect(func() -> void:
		if _upgrade_buys.has(name_str):
			_upgrade_buys.erase(name_str)
		else:
			_upgrade_buys.append(name_str)
		_rebuild_upgrades()
		_refresh_totals())
	row_end.add_child(buy_btn)
	v.add_child(row_end)

	if _upgrade_buys.has(name_str):
		var sel_style := _card_style(CARD_AFFORDABLE)
		sel_style.border_color = CARD_SELECTED_BORDER
		sel_style.border_width_left = 1
		sel_style.border_width_right = 1
		sel_style.border_width_top = 1
		sel_style.border_width_bottom = 1
		wrap.add_theme_stylebox_override("panel", sel_style)

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
	if parts.is_empty():
		return ""
	return ", ".join(parts)


# --- bottom bar ---------------------------------------------------------------

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
		"Select at least one firework to run a show.", SIZE_CAPTION, MUTED)
	_summary_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(_summary_label)

	_total_spend_label = _label_sized("Spend: $0", SIZE_TOPBAR, GOLD)
	h.add_child(_total_spend_label)

	_run_show_button = Button.new()
	_run_show_button.text = "▶ Run Show"
	_run_show_button.add_theme_font_size_override("font_size", SIZE_SMALL)
	_run_show_button.custom_minimum_size = Vector2(200, 48)
	_run_show_button.pressed.connect(_on_run_show_pressed)
	h.add_child(_run_show_button)
	return bar


# --- handlers -----------------------------------------------------------------

func _nudge_firework(fw: Dictionary, delta: int, entry: Dictionary) -> void:
	var name_str: String = String(fw.name)
	var current: int = int(_fireworks_qty.get(name_str, 0))
	var cap: int = int(BalanceConfig.get_zone(GameState.current_zone).get("firework_cap", 300))
	var new_qty: int = maxi(current + delta, 0)
	new_qty = mini(new_qty, cap)
	_fireworks_qty[name_str] = new_qty
	(entry.qty_label as Label).text = str(new_qty)
	var cost_preview_lbl: Label = entry.cost_preview
	if new_qty > 0:
		cost_preview_lbl.text = "$%s" % _fmt_num(new_qty * int(fw.get("cost", 0)))
	else:
		cost_preview_lbl.text = ""
	_apply_selected_border(entry, new_qty > 0)
	_refresh_totals()


func _apply_selected_border(entry: Dictionary, selected: bool) -> void:
	var style: StyleBoxFlat = entry.style
	if selected:
		style.border_color = CARD_SELECTED_BORDER
		style.border_width_left = 1
		style.border_width_right = 1
		style.border_width_top = 1
		style.border_width_bottom = 1
	else:
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
	_refresh_totals()


func _select_enhancement(category: String, name: String, buttons: Array[CheckBox], clicked: CheckBox) -> void:
	for b in buttons:
		b.button_pressed = b == clicked
	if name == "":
		_enhancements.erase(category)
	else:
		_enhancements[category] = name
	_refresh_totals()


# --- totals + run show --------------------------------------------------------

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
		var eh: Dictionary = BalanceConfig.get_enhancement(String(category), String(_enhancements[category]))
		spend += float(eh.get("cost", 0))
	for up_name in _upgrade_buys:
		spend += float(BalanceConfig.get_upgrade(up_name).get("cost", 0))

	_total_spend_label.text = "Spend: $%s / Cash: $%s" % [_fmt_num(int(spend)), _fmt_num(int(GameState.money))]
	_total_spend_label.add_theme_color_override("font_color", RED if spend > GameState.money else GOLD)
	if fw_count <= 0:
		_summary_label.text = "Select at least one firework to run a show."
	else:
		_summary_label.text = "%d fireworks · %d marketing · %d enhancements · %d upgrades" % [
			fw_count, _marketing_total(), _enhancements.size(), _upgrade_buys.size(),
		]
	_run_show_button.disabled = (spend > GameState.money) or (fw_count <= 0)


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


# --- primitives ---------------------------------------------------------------

func _label_sized(text: String, font_size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	return l


func _small_button(text: String) -> Button:
	var b := Button.new()
	b.text = text
	b.add_theme_font_size_override("font_size", SIZE_SMALL)
	b.custom_minimum_size = Vector2(32, 32)
	return b


func _strip(height: int) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, height)
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
	sb.border_width_left = 0
	sb.border_width_right = 0
	sb.border_width_top = 0
	sb.border_width_bottom = 0
	return sb


func _fmt_num(n: int) -> String:
	if n >= 1_000_000_000:
		return "%.2fB" % (n / 1_000_000_000.0)
	if n >= 1_000_000:
		return "%.2fM" % (n / 1_000_000.0)
	if n >= 1_000:
		return "%.1fK" % (n / 1_000.0)
	return str(n)
