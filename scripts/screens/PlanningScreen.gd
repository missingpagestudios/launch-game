extends Control
## Planning screen — everything selectable is a 64px unified row.
## See docs/planning_screen_unified_rows.md.

const ZoneBackgroundScript := preload("res://scripts/components/ZoneBackground.gd")

# --- palette -----------------------------------------------------------------

const PANEL_BG := Color(0.071, 0.094, 0.220, 0.85)
const TOP_BAR_BG := Color(0.039, 0.063, 0.157, 0.90)
const BOTTOM_BAR_BG := Color(0.039, 0.063, 0.157, 0.92)

const ROW_BG := Color(0.102, 0.125, 0.282, 0.85)
const ROW_BG_HOVER := Color(0.165, 0.188, 0.333, 0.92)
const ROW_BG_SELECTED := Color(0.102, 0.125, 0.282, 0.95)
const ROW_BG_UNAFFORD := Color(0.071, 0.094, 0.220, 0.70)
const ROW_BG_LOCKED := Color(0.071, 0.094, 0.220, 0.50)

const PANEL_BORDER := Color(0.165, 0.188, 0.333)
const DIVIDER := Color(0.165, 0.188, 0.333, 0.8)
const GOLD_BORDER := Color(1.0, 0.84, 0.0, 0.85)

const TEXT := Color(0.960, 0.902, 0.816)
const MUTED := Color(0.540, 0.521, 0.439)
const DIM := Color(0.290, 0.282, 0.220)
const GOLD := Color(1.0, 0.84, 0.0)
const RED := Color(1.0, 0.35, 0.42)

const TIER_STRIPE := {
	1: Color(0.627, 0.439, 0.314),
	2: Color(0.690, 0.721, 0.753),
	3: Color(0.831, 0.686, 0.216),
	4: Color(0.373, 0.784, 0.847),
}
const STRIPE_MARKETING := Color(0.540, 0.521, 0.439)
const STRIPE_ENHANCEMENT := Color(0.290, 0.282, 0.220)
const STRIPE_OWNED := Color(1.0, 0.84, 0.0)
const STRIPE_AFFORDABLE := Color(0.960, 0.902, 0.816)
const STRIPE_UNAFFORDABLE := Color(0.540, 0.521, 0.439)
const STRIPE_LOCKED := Color(0.290, 0.282, 0.220)
const STRIPE_SELECTED := Color(1.0, 0.84, 0.0)

# --- sizes -------------------------------------------------------------------

const SIZE_DISPLAY := 48
const SIZE_TOPBAR := 32
const SIZE_HEADER := 28
const SIZE_SECTION := 20
const SIZE_BODY := 22
const SIZE_SMALL := 20
const SIZE_STATS := 18
const SIZE_CAPTION := 16
const ROW_HEIGHT := 56

# --- icon paths --------------------------------------------------------------

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
const CATEGORY_ICONS := {
	"marketing": "res://assets/images/speaker.png",
	"infrastructure": "res://assets/images/house.png",
	"crew": "res://assets/images/fans.png",
	"revenue": "res://assets/images/money.png",
}

const UPGRADE_CATEGORIES := ["All", "crew", "infrastructure", "revenue", "marketing"]
const UPGRADE_CATEGORY_LABELS := {
	"All": "All", "crew": "Crew", "infrastructure": "Infra",
	"revenue": "Rev", "marketing": "Mkt",
}

# --- state -------------------------------------------------------------------

var _fireworks_qty: Dictionary = {}
var _marketing_qty: Dictionary = {}
var _enhancements: Dictionary = {}     # category -> name
var _upgrade_buys: Array[String] = []
var _upgrade_category_filter: String = "All"

var _firework_info_dialog: AcceptDialog
var _cash_label: Label
var _fans_label: Label
var _run_show_button: Button
var _summary_label: Label
var _spend_label: Label
var _cash_arrow_label: Label
var _cash_after_label: Label
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
	root.add_child(_strip(10))
	root.add_child(_build_panels())
	root.add_child(_strip(12))
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
	v.custom_minimum_size = Vector2(200, 0)
	v.add_theme_constant_override("separation", 2)

	var cash_row := HBoxContainer.new()
	cash_row.alignment = BoxContainer.ALIGNMENT_END
	cash_row.add_theme_constant_override("separation", 8)
	cash_row.add_child(_icon(ICON_MONEY, 24))
	_cash_label = _label_sized(_fmt_num(int(GameState.money)), SIZE_STATS, GOLD)
	cash_row.add_child(_cash_label)
	v.add_child(cash_row)

	var fans_row := HBoxContainer.new()
	fans_row.alignment = BoxContainer.ALIGNMENT_END
	fans_row.add_theme_constant_override("separation", 8)
	fans_row.add_child(_icon(ICON_FANS, 20))
	_fans_label = _label_sized(_fmt_num(GameState.repeat_fans), SIZE_STATS, GOLD)
	fans_row.add_child(_fans_label)
	v.add_child(fans_row)
	return v


# --- panels row --------------------------------------------------------------

func _build_panels() -> Control:
	var margin := MarginContainer.new()
	margin.custom_minimum_size = Vector2(0, 568)
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


# --- unified row factory -----------------------------------------------------
# Returns { wrap, style, content }. Caller populates `content` (HBoxContainer).
func _row_shell(stripe_color: Color, bg: Color) -> Dictionary:
	var wrap := PanelContainer.new()
	wrap.custom_minimum_size = Vector2(0, ROW_HEIGHT)
	# Rows live in VBoxes whose parent ScrollContainer can stretch them to
	# fill unused space. SHRINK_CENTER forces each row to stay at min height.
	wrap.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var style := _row_style(bg)
	wrap.add_theme_stylebox_override("panel", style)

	var outer := HBoxContainer.new()
	outer.add_theme_constant_override("separation", 0)
	wrap.add_child(outer)

	var stripe := ColorRect.new()
	stripe.color = stripe_color
	stripe.custom_minimum_size = Vector2(4, 0)
	outer.add_child(stripe)

	var pad := MarginContainer.new()
	pad.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pad.add_theme_constant_override("margin_left", 12)
	pad.add_theme_constant_override("margin_right", 12)
	pad.add_theme_constant_override("margin_top", 12)
	pad.add_theme_constant_override("margin_bottom", 12)
	outer.add_child(pad)

	var content := HBoxContainer.new()
	content.custom_minimum_size = Vector2(0, 32)
	content.add_theme_constant_override("separation", 8)
	pad.add_child(content)

	return {"wrap": wrap, "style": style, "content": content, "stripe": stripe}


# --- firework rows -----------------------------------------------------------

func _build_fireworks_list() -> Control:
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	v.alignment = BoxContainer.ALIGNMENT_BEGIN
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
	var stripe_color: Color = TIER_STRIPE.get(tier, TIER_STRIPE[1])
	var bg: Color = ROW_BG if affordable else ROW_BG_UNAFFORD
	var shell := _row_shell(stripe_color, bg)
	var content: HBoxContainer = shell.content

	content.add_child(_icon(TIER_ICONS.get(tier, TIER_ICONS[1]), 24))

	var name_lbl := _label_sized(String(fw.name), SIZE_BODY, TEXT if affordable else MUTED)
	name_lbl.clip_text = true
	name_lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(name_lbl)

	var price_lbl := _label_sized("$%s" % _fmt_num(cost), SIZE_STATS, GOLD if affordable else MUTED)
	price_lbl.custom_minimum_size = Vector2(60, 0)
	price_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	content.add_child(price_lbl)

	var minus := _qty_button("-")
	var qty_lbl := _label_sized("0", SIZE_STATS, MUTED)
	qty_lbl.custom_minimum_size = Vector2(24, 0)
	qty_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var plus := _qty_button("+")
	content.add_child(minus)
	content.add_child(qty_lbl)
	content.add_child(plus)

	var info_btn := _info_button()
	info_btn.pressed.connect(func() -> void: _show_firework_info(fw))
	content.add_child(info_btn)

	var entry := {"fw": fw, "style": shell.style, "stripe": shell.stripe,
			"stripe_default": stripe_color, "qty_label": qty_lbl}
	minus.pressed.connect(func() -> void: _nudge_firework(fw, -1, entry))
	plus.pressed.connect(func() -> void: _nudge_firework(fw, 1, entry))
	return shell.wrap


# --- marketing + enhancements panel ------------------------------------------

func _build_marketing_and_enhancements() -> Control:
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	v.alignment = BoxContainer.ALIGNMENT_BEGIN
	v.add_theme_constant_override("separation", 4)
	scroll.add_child(v)

	v.add_child(_section_label("MARKETING"))
	var mk_available: Array = GameEngine.available_marketing()
	if mk_available.is_empty():
		v.add_child(_label_sized(
			"Only flyers available at this zone. More unlock as you grow.",
			SIZE_CAPTION, MUTED))
	else:
		for mk in mk_available:
			v.add_child(_build_marketing_row(mk))

	v.add_child(_spacer(4))
	v.add_child(_section_label("ENHANCEMENTS"))
	v.add_child(_label_sized("(one per category)", SIZE_CAPTION, DIM))

	var groups: Dictionary = GameEngine.available_enhancements()
	for category in groups.keys():
		v.add_child(_spacer(4))
		v.add_child(_label_sized(String(category).capitalize(), SIZE_STATS, MUTED))
		v.add_child(_build_enhancement_row(String(category), "None", {}, true))
		for eh in groups[category]:
			var eh_dict: Dictionary = eh
			v.add_child(_build_enhancement_row(String(category), String(eh_dict.name), eh_dict, false))

	return scroll


func _build_marketing_row(mk: Dictionary) -> Control:
	var cost: int = int(mk.get("cost", 0))
	var stripe_color: Color = STRIPE_MARKETING
	var shell := _row_shell(stripe_color, ROW_BG)
	var content: HBoxContainer = shell.content

	var name_lbl := _label_sized(String(mk.name), SIZE_BODY, TEXT)
	content.add_child(name_lbl)

	var effect := _label_sized("+%s att · cap %d" % [
		_fmt_num(int(mk.get("attendees", 0))),
		int(mk.get("cap", 0))], SIZE_STATS, MUTED)
	effect.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	effect.clip_text = true
	effect.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	content.add_child(effect)

	var price_lbl := _label_sized("$%s" % _fmt_num(cost), SIZE_STATS, GOLD)
	price_lbl.custom_minimum_size = Vector2(56, 0)
	price_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	content.add_child(price_lbl)

	var minus := _qty_button("-")
	var qty_lbl := _label_sized("0", SIZE_STATS, MUTED)
	qty_lbl.custom_minimum_size = Vector2(24, 0)
	qty_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var plus := _qty_button("+")
	content.add_child(minus)
	content.add_child(qty_lbl)
	content.add_child(plus)

	minus.pressed.connect(func() -> void: _nudge_marketing(
		mk, -1, qty_lbl, shell.stripe, stripe_color))
	plus.pressed.connect(func() -> void: _nudge_marketing(
		mk, 1, qty_lbl, shell.stripe, stripe_color))
	return shell.wrap


func _build_enhancement_row(category: String, name: String, eh: Dictionary, is_none: bool) -> Control:
	var selected: bool = (is_none and not _enhancements.has(category)) \
		or (not is_none and String(_enhancements.get(category, "")) == name)
	var stripe_color: Color = STRIPE_SELECTED if selected else STRIPE_ENHANCEMENT
	var shell := _row_shell(stripe_color, ROW_BG_SELECTED if selected else ROW_BG)
	var content: HBoxContainer = shell.content

	var name_lbl := _label_sized(name, SIZE_BODY, GOLD if selected else TEXT)
	content.add_child(name_lbl)

	var effect_text: String = ""
	if not is_none:
		if eh.has("eng_mult"):
			effect_text += "+%d%% eng" % int(float(eh.eng_mult) * 100)
		if eh.has("tip_mult"):
			if effect_text != "":
				effect_text += " · "
			effect_text += "+%d%% tips" % int(float(eh.tip_mult) * 100)
	var effect := _label_sized(effect_text, SIZE_STATS, MUTED)
	effect.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	effect.clip_text = true
	effect.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	content.add_child(effect)

	if not is_none:
		var price_lbl := _label_sized(
			"$%s" % _fmt_num(int(eh.get("cost", 0))), SIZE_STATS, GOLD)
		price_lbl.custom_minimum_size = Vector2(60, 0)
		price_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		content.add_child(price_lbl)
	else:
		var empty := Label.new()
		empty.custom_minimum_size = Vector2(60, 0)
		content.add_child(empty)

	if selected:
		content.add_child(_icon(ICON_CHECK, 20))
	else:
		var slot := Control.new()
		slot.custom_minimum_size = Vector2(20, 0)
		content.add_child(slot)

	# Row-level click. Use a transparent Button overlay? Simpler: use a Button
	# wrapper as the whole row. But that disrupts our nested layout. Instead,
	# add a small select button on the right.
	var select_btn := _small_select_button(selected)
	content.add_child(select_btn)
	var target_name: String = "" if is_none else name
	select_btn.pressed.connect(func() -> void: _select_enhancement(category, target_name))
	return shell.wrap


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
		b.add_theme_font_size_override("font_size", SIZE_STATS)
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
	_upgrade_body.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	_upgrade_body.alignment = BoxContainer.ALIGNMENT_BEGIN
	_upgrade_body.add_theme_constant_override("separation", 4)
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

	_upgrade_body.add_child(_section_label("OWNED"))
	if owned.is_empty():
		_upgrade_body.add_child(_label_sized(
			"No upgrades yet — buy your first below.", SIZE_CAPTION, MUTED))
	for up in owned:
		_upgrade_body.add_child(_build_owned_upgrade_row(up))

	_upgrade_body.add_child(_spacer(4))
	_upgrade_body.add_child(_section_label("AVAILABLE"))
	if available.is_empty():
		_upgrade_body.add_child(_label_sized(
			"  (nothing purchasable this zone)", SIZE_CAPTION, MUTED))
	for up in available:
		_upgrade_body.add_child(_build_available_upgrade_row(up))

	_upgrade_body.add_child(_spacer(4))
	_upgrade_body.add_child(_section_label("LOCKED", DIM))
	if locked.is_empty():
		_upgrade_body.add_child(_label_sized("  (everything unlocked)", SIZE_CAPTION, MUTED))
	else:
		locked.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
			return int(a.get("min_zone", 1)) < int(b.get("min_zone", 1)))
		_upgrade_body.add_child(_next_unlock_callout(locked[0]))
		for up in locked:
			_upgrade_body.add_child(_build_locked_upgrade_row(up))


func _build_owned_upgrade_row(up: Dictionary) -> Control:
	var shell := _row_shell(STRIPE_OWNED, ROW_BG_SELECTED)
	var content: HBoxContainer = shell.content

	content.add_child(_icon(ICON_CHECK, 20))

	var name_lbl := _label_sized(String(up.name), SIZE_BODY, TEXT)
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_lbl.clip_text = true
	name_lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	content.add_child(name_lbl)

	var cat: String = String(up.get("category", ""))
	if CATEGORY_ICONS.has(cat):
		content.add_child(_icon(CATEGORY_ICONS[cat], 20))

	content.add_child(_label_sized("owned", SIZE_CAPTION, DIM))
	return shell.wrap


func _build_available_upgrade_row(up: Dictionary) -> Control:
	var cost: int = int(up.get("cost", 0))
	var affordable: bool = float(cost) <= GameState.money
	var selected: bool = _upgrade_buys.has(String(up.name))
	var stripe_color: Color = STRIPE_SELECTED if selected else \
			(STRIPE_AFFORDABLE if affordable else STRIPE_UNAFFORDABLE)
	var bg: Color = ROW_BG_SELECTED if selected else \
			(ROW_BG if affordable else ROW_BG_UNAFFORD)
	var shell := _row_shell(stripe_color, bg)
	var content: HBoxContainer = shell.content

	var cat: String = String(up.get("category", ""))
	if CATEGORY_ICONS.has(cat):
		content.add_child(_icon(CATEGORY_ICONS[cat], 24))

	var name_lbl := _label_sized(
		String(up.name), SIZE_BODY, TEXT if affordable else MUTED)
	name_lbl.clip_text = true
	name_lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	content.add_child(name_lbl)

	var effect_lbl := _label_sized(
		_effect_summary(up.get("effect", {})),
		SIZE_STATS, MUTED)
	effect_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	effect_lbl.clip_text = true
	effect_lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	content.add_child(effect_lbl)

	var price_lbl := _label_sized(
		"$%s" % _fmt_num(cost), SIZE_STATS, GOLD if affordable else MUTED)
	price_lbl.custom_minimum_size = Vector2(60, 0)
	price_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	content.add_child(price_lbl)

	var buy_btn := _buy_button()
	buy_btn.text = "UNDO" if selected else "BUY"
	buy_btn.disabled = not affordable and not selected
	var name_str: String = String(up.name)
	buy_btn.pressed.connect(func() -> void:
		if _upgrade_buys.has(name_str):
			_upgrade_buys.erase(name_str)
		else:
			_upgrade_buys.append(name_str)
		_rebuild_upgrades()
		_refresh_totals())
	content.add_child(buy_btn)
	return shell.wrap


func _build_locked_upgrade_row(up: Dictionary) -> Control:
	var shell := _row_shell(STRIPE_LOCKED, ROW_BG_LOCKED)
	var content: HBoxContainer = shell.content

	content.add_child(_icon(ICON_LOCK, 20))

	var name_lbl := _label_sized(String(up.name), SIZE_STATS, DIM)
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_lbl.clip_text = true
	name_lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	content.add_child(name_lbl)

	var cat: String = String(up.get("category", ""))
	if CATEGORY_ICONS.has(cat):
		content.add_child(_icon(CATEGORY_ICONS[cat], 20))

	content.add_child(_label_sized("Zone %d+" % int(up.get("min_zone", 1)), SIZE_CAPTION, MUTED))
	return shell.wrap


func _next_unlock_callout(up: Dictionary) -> Control:
	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(0, 28)
	row.add_theme_constant_override("separation", 8)
	row.add_child(_icon(ICON_ARROW, 16))
	var effect := _effect_summary(up.get("effect", {}))
	var text := "Next unlock at Zone %d: %s" % [int(up.get("min_zone", 1)), String(up.name)]
	if effect != "":
		text += " (%s)" % effect
	var lbl := _label_sized(text, SIZE_CAPTION, TEXT)
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	row.add_child(lbl)
	return row


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


# --- bottom bar --------------------------------------------------------------

func _build_bottom_bar() -> Control:
	var bar := PanelContainer.new()
	bar.custom_minimum_size = Vector2(0, 70)
	bar.add_theme_stylebox_override("panel", _panel_style(BOTTOM_BAR_BG))

	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", 32)
	m.add_theme_constant_override("margin_right", 32)
	m.add_theme_constant_override("margin_top", 10)
	m.add_theme_constant_override("margin_bottom", 10)
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
	var qty_label: Label = entry.qty_label
	qty_label.text = str(new_qty)
	qty_label.add_theme_color_override("font_color", GOLD if new_qty > 0 else MUTED)

	var stripe: ColorRect = entry.stripe
	var style: StyleBoxFlat = entry.style
	if new_qty > 0:
		stripe.color = STRIPE_SELECTED
		style.bg_color = ROW_BG_SELECTED
	else:
		stripe.color = entry.stripe_default
		style.bg_color = ROW_BG
	_refresh_totals()


func _nudge_marketing(mk: Dictionary, delta: int, qty_label: Label,
		stripe: ColorRect, stripe_default: Color) -> void:
	var name_str: String = String(mk.name)
	var current: int = int(_marketing_qty.get(name_str, 0))
	var cap: int = int(mk.get("cap", 0))
	var new_qty: int = maxi(current + delta, 0)
	if cap > 0:
		new_qty = mini(new_qty, cap)
	_marketing_qty[name_str] = new_qty
	qty_label.text = str(new_qty)
	qty_label.add_theme_color_override("font_color", GOLD if new_qty > 0 else MUTED)
	stripe.color = STRIPE_SELECTED if new_qty > 0 else stripe_default
	_refresh_totals()


func _select_enhancement(category: String, name: String) -> void:
	if name == "":
		_enhancements.erase(category)
	else:
		_enhancements[category] = name
	_rebuild_planning()
	_refresh_totals()


func _rebuild_planning() -> void:
	# Re-rendering the whole panel tree is overkill for one enhancement change,
	# but it keeps the selected-state visuals accurate without per-row tracking.
	# Cheap enough at stage 2 resolution.
	for child in get_children():
		if child is VBoxContainer:
			child.queue_free()
	var root := VBoxContainer.new()
	root.anchor_right = 1.0
	root.anchor_bottom = 1.0
	root.add_theme_constant_override("separation", 0)
	add_child(root)
	root.add_child(_build_top_bar())
	root.add_child(_strip(10))
	root.add_child(_build_panels())
	root.add_child(_strip(12))
	root.add_child(_build_bottom_bar())


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
		_cash_after_label.text = "Cash after: $%s" % _fmt_num(int(GameState.money - spend))
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


# --- info popup --------------------------------------------------------------

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
	body += "Tier %d   ·   $%s per unit   ·   %d engagement per unit\n\n" % [
		tier, _fmt_num(cost), engagement]
	body += "[b]Tags:[/b] %s\n\n" % tag_str
	body += ("[b]Engagement[/b] is how much excitement each firework adds to the "
			+ "show. Total engagement across all fireworks fired feeds the quality "
			+ "multiplier, which drives both star rating and how many attendees "
			+ "become repeat fans.")
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
	rt.add_theme_font_size_override("normal_font_size", SIZE_STATS)
	rt.add_theme_font_size_override("bold_font_size", SIZE_STATS)
	rt.add_theme_color_override("default_color", TEXT)
	rt.text = body
	_firework_info_dialog.add_child(rt)
	_firework_info_dialog.popup_centered()


# --- primitives --------------------------------------------------------------

func _label_sized(text: String, font_size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	return l


func _section_label(text: String, color: Color = TEXT) -> Control:
	return _label_sized(text, SIZE_SECTION, color)


func _icon(path: String, px: int) -> TextureRect:
	var t := TextureRect.new()
	t.texture = load(path)
	t.custom_minimum_size = Vector2(px, px)
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return t


func _info_button() -> Button:
	var b := Button.new()
	b.icon = load(ICON_INFO)
	b.expand_icon = true
	b.add_theme_stylebox_override("normal", _button_style(
		Color(0.039, 0.063, 0.157, 0.5), Color(DIM.r, DIM.g, DIM.b, 0.9)))
	b.add_theme_stylebox_override("hover", _button_style(
		Color(0.165, 0.188, 0.333, 0.8), GOLD_BORDER))
	b.add_theme_stylebox_override("pressed", _button_style(
		Color(0.165, 0.188, 0.333, 0.95), GOLD_BORDER))
	b.custom_minimum_size = Vector2(28, 28)
	b.tooltip_text = "Details"
	return b


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


func _small_select_button(selected: bool) -> Button:
	var b := Button.new()
	b.text = "•" if selected else "○"
	b.add_theme_font_size_override("font_size", SIZE_STATS)
	b.add_theme_color_override("font_color", GOLD if selected else MUTED)
	b.add_theme_color_override("font_hover_color", GOLD)
	b.add_theme_stylebox_override("normal", _button_style(
		Color(0.039, 0.063, 0.157, 0.4), Color(DIM.r, DIM.g, DIM.b, 0.8)))
	b.add_theme_stylebox_override("hover", _button_style(
		Color(0.165, 0.188, 0.333, 0.8), GOLD_BORDER))
	b.add_theme_stylebox_override("pressed", _button_style(
		Color(0.165, 0.188, 0.333, 0.95), GOLD_BORDER))
	b.custom_minimum_size = Vector2(32, 28)
	b.tooltip_text = "Select"
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
	b.custom_minimum_size = Vector2(64, 28)
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


func _spacer(height: int) -> Control:
	return _strip(height)


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
	sb.content_margin_left = 10
	sb.content_margin_right = 10
	sb.content_margin_top = 2
	sb.content_margin_bottom = 2
	return sb


func _fmt_num(n: int) -> String:
	if n >= 1_000_000_000:
		return "%.2fB" % (n / 1_000_000_000.0)
	if n >= 1_000_000:
		return "%.2fM" % (n / 1_000_000.0)
	if n >= 1_000:
		return "%.1fK" % (n / 1_000.0)
	return str(n)
