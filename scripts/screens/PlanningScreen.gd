extends Control
## Three-panel planning screen. Text-only — labels, buttons, steppers.

const BG := Color(0.04, 0.06, 0.16)
const PANEL_BG := Color(0.07, 0.10, 0.22)
const TEXT := Color(0.96, 0.90, 0.82)
const MUTED := Color(0.54, 0.52, 0.44)
const GOLD := Color(1.0, 0.84, 0.0)
const RED := Color(1.0, 0.35, 0.42)
const AFFORDABLE := Color(0.10, 0.13, 0.28)
const DISABLED := Color(0.04, 0.04, 0.10)

var _fireworks_qty: Dictionary = {}  # name -> int
var _marketing_qty: Dictionary = {}  # name -> int
var _enhancements: Dictionary = {}   # category -> name
var _upgrade_buys: Array[String] = []

var _total_spend_label: Label
var _cash_label: Label
var _fans_label: Label
var _fire_show_button: Button
var _summary_label: Label

var _firework_rows: Array = []
var _marketing_rows: Array = []
var _upgrade_rows: Array = []


func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = BG
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	add_child(bg)

	var root := VBoxContainer.new()
	root.anchor_right = 1.0
	root.anchor_bottom = 1.0
	root.add_theme_constant_override("separation", 8)
	add_child(root)

	root.add_child(_build_top_bar())
	root.add_child(_build_panels())
	root.add_child(_build_bottom_bar())

	_refresh_totals()


# --- top bar ------------------------------------------------------------------

func _build_top_bar() -> Control:
	var bar := PanelContainer.new()
	bar.custom_minimum_size = Vector2(0, 64)
	bar.add_theme_stylebox_override("panel", _stylebox(PANEL_BG))

	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 40)
	h.alignment = BoxContainer.ALIGNMENT_CENTER
	bar.add_child(h)

	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", 32)
	m.add_theme_constant_override("margin_right", 32)
	m.add_theme_constant_override("margin_top", 8)
	m.add_theme_constant_override("margin_bottom", 8)
	m.add_child(h)
	bar.add_child(m)

	var nights := _label("Night %d / %d" % [GameState.night, int(BalanceConfig.game_params().get("total_nights", 100))], 24, TEXT)
	h.add_child(nights)

	var zone := _label("Zone %d: %s" % [GameState.current_zone, String(BalanceConfig.get_zone(GameState.current_zone).get("name", ""))], 24, TEXT)
	h.add_child(zone)

	_cash_label = _label("Cash: $%s" % _fmt_dollars(GameState.money), 24, GOLD)
	h.add_child(_cash_label)

	_fans_label = _label("Fans: %s" % _fmt_num(GameState.repeat_fans), 20, MUTED)
	h.add_child(_fans_label)
	return bar


# --- three panels -------------------------------------------------------------

func _build_panels() -> Control:
	var h := HBoxContainer.new()
	h.size_flags_vertical = Control.SIZE_EXPAND_FILL
	h.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_theme_constant_override("separation", 8)
	h.add_child(_panel("FIREWORKS", _build_fireworks_list()))
	h.add_child(_panel("MARKETING / ENHANCEMENTS", _build_marketing_and_enhancements()))
	h.add_child(_panel("UPGRADES", _build_upgrades_list()))
	return h


func _panel(title: String, body: Control) -> Control:
	var wrap := PanelContainer.new()
	wrap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	wrap.size_flags_vertical = Control.SIZE_EXPAND_FILL
	wrap.add_theme_stylebox_override("panel", _stylebox(PANEL_BG))

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", 16)
	m.add_theme_constant_override("margin_right", 16)
	m.add_theme_constant_override("margin_top", 12)
	m.add_theme_constant_override("margin_bottom", 12)
	m.add_child(v)
	wrap.add_child(m)

	var header := _label(title, 22, TEXT)
	v.add_child(header)

	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(body)
	return wrap


func _build_fireworks_list() -> Control:
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_theme_constant_override("separation", 2)
	scroll.add_child(v)

	var fireworks_sorted := GameEngine.available_fireworks().duplicate()
	fireworks_sorted.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if int(a.get("tier", 1)) != int(b.get("tier", 1)):
			return int(a.get("tier", 1)) < int(b.get("tier", 1))
		return String(a.name) < String(b.name))
	for fw in fireworks_sorted:
		var row := _build_firework_row(fw)
		v.add_child(row)
		_firework_rows.append({"fw": fw, "row": row})
	return scroll


func _build_firework_row(fw: Dictionary) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)

	var name_label := _label("[T%d] %s — $%s, eng %d" % [
		int(fw.get("tier", 1)),
		String(fw.name),
		_fmt_num(int(fw.get("cost", 0))),
		int(fw.get("engagement", 0))],
		16, TEXT)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(name_label)

	var minus := _small_button("-")
	var qty_label := _label("0", 16, GOLD)
	qty_label.custom_minimum_size = Vector2(36, 0)
	qty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var plus := _small_button("+")

	minus.pressed.connect(func() -> void: _nudge_firework(fw, -1, qty_label))
	plus.pressed.connect(func() -> void: _nudge_firework(fw, 1, qty_label))
	row.add_child(minus)
	row.add_child(qty_label)
	row.add_child(plus)
	return row


func _build_marketing_and_enhancements() -> Control:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)

	# Marketing
	var mk_header := _label("Marketing", 18, TEXT)
	v.add_child(mk_header)
	var mk_scroll := ScrollContainer.new()
	mk_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	mk_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var mk_v := VBoxContainer.new()
	mk_v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mk_scroll.add_child(mk_v)
	v.add_child(mk_scroll)

	for mk in GameEngine.available_marketing():
		var row := _build_marketing_row(mk)
		mk_v.add_child(row)
		_marketing_rows.append({"mk": mk, "row": row})

	# Enhancements (one pick per category)
	v.add_child(_label("Enhancements (one per category)", 18, TEXT))
	var eh_scroll := ScrollContainer.new()
	eh_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	eh_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var eh_v := VBoxContainer.new()
	eh_v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	eh_v.add_theme_constant_override("separation", 4)
	eh_scroll.add_child(eh_v)
	v.add_child(eh_scroll)

	var groups := GameEngine.available_enhancements()
	for category in groups.keys():
		eh_v.add_child(_label(String(category).capitalize(), 16, MUTED))
		var group_container := VBoxContainer.new()
		eh_v.add_child(group_container)

		var none_btn := CheckBox.new()
		none_btn.text = "None"
		none_btn.button_pressed = true
		group_container.add_child(none_btn)
		var buttons: Array[CheckBox] = [none_btn]
		none_btn.pressed.connect(func() -> void:
			_select_enhancement(String(category), "", buttons, none_btn))

		for eh in groups[category]:
			var eh_dict: Dictionary = eh
			var cb := CheckBox.new()
			cb.text = "%s — $%s" % [String(eh_dict.name), _fmt_num(int(eh_dict.get("cost", 0)))]
			if eh_dict.has("eng_mult"):
				cb.text += " (+%d%% eng)" % int(float(eh_dict.eng_mult) * 100)
			if eh_dict.has("tip_mult"):
				cb.text += " (+%d%% tips)" % int(float(eh_dict.tip_mult) * 100)
			group_container.add_child(cb)
			buttons.append(cb)
			var eh_name: String = String(eh_dict.name)
			var cat_name: String = String(category)
			cb.pressed.connect(func() -> void:
				_select_enhancement(cat_name, eh_name, buttons, cb))

	return v


func _build_marketing_row(mk: Dictionary) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)

	var label := _label("%s — $%s, +%s attendees  (cap %d)" % [
		String(mk.name),
		_fmt_num(int(mk.get("cost", 0))),
		_fmt_num(int(mk.get("attendees", 0))),
		int(mk.get("cap", 0))],
		16, TEXT)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label)

	var minus := _small_button("-")
	var qty_label := _label("0", 16, GOLD)
	qty_label.custom_minimum_size = Vector2(36, 0)
	qty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var plus := _small_button("+")

	minus.pressed.connect(func() -> void: _nudge_marketing(mk, -1, qty_label))
	plus.pressed.connect(func() -> void: _nudge_marketing(mk, 1, qty_label))
	row.add_child(minus)
	row.add_child(qty_label)
	row.add_child(plus)
	return row


func _build_upgrades_list() -> Control:
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_theme_constant_override("separation", 2)
	scroll.add_child(v)

	# Owned first (muted)
	for up_name in GameState.owned_upgrades:
		v.add_child(_label("[OWNED] %s" % up_name, 16, MUTED))

	for up in GameEngine.available_upgrades():
		var row := _build_upgrade_row(up)
		v.add_child(row)
		_upgrade_rows.append({"up": up, "row": row})

	# Locked preview (not yet in current zone)
	for up in BalanceConfig.upgrades():
		if GameState.owned_upgrades.has(String(up.name)):
			continue
		if GameState.current_zone < int(up.get("min_zone", 1)):
			v.add_child(_label("(locked) %s — unlocks at Zone %d" % [String(up.name), int(up.get("min_zone", 1))], 14, MUTED))
	return scroll


func _build_upgrade_row(up: Dictionary) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var desc := "%s — $%s  (%s)" % [
		String(up.name),
		_fmt_num(int(up.get("cost", 0))),
		String(up.get("category", ""))]
	var label := _label(desc, 16, TEXT)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label)

	var buy_btn := _small_button("Buy")
	buy_btn.custom_minimum_size = Vector2(60, 30)
	buy_btn.pressed.connect(func() -> void:
		var name_str := String(up.name)
		if _upgrade_buys.has(name_str):
			_upgrade_buys.erase(name_str)
			buy_btn.text = "Buy"
			label.remove_theme_color_override("font_color")
			label.add_theme_color_override("font_color", TEXT)
		else:
			_upgrade_buys.append(name_str)
			buy_btn.text = "Undo"
			label.add_theme_color_override("font_color", GOLD)
		_refresh_totals())
	row.add_child(buy_btn)
	return row


# --- bottom bar ---------------------------------------------------------------

func _build_bottom_bar() -> Control:
	var bar := PanelContainer.new()
	bar.custom_minimum_size = Vector2(0, 80)
	bar.add_theme_stylebox_override("panel", _stylebox(PANEL_BG))

	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", 24)
	m.add_theme_constant_override("margin_right", 24)
	m.add_theme_constant_override("margin_top", 12)
	m.add_theme_constant_override("margin_bottom", 12)
	bar.add_child(m)

	var h := HBoxContainer.new()
	h.alignment = BoxContainer.ALIGNMENT_CENTER
	h.add_theme_constant_override("separation", 24)
	m.add_child(h)

	_summary_label = _label("0 fireworks selected", 16, MUTED)
	_summary_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(_summary_label)

	_total_spend_label = _label("Spend: $0", 20, GOLD)
	h.add_child(_total_spend_label)

	_fire_show_button = Button.new()
	_fire_show_button.text = "Fire Show →"
	_fire_show_button.add_theme_font_size_override("font_size", 22)
	_fire_show_button.custom_minimum_size = Vector2(200, 48)
	_fire_show_button.pressed.connect(_on_fire_show_pressed)
	h.add_child(_fire_show_button)
	return bar


# --- stepper handlers ---------------------------------------------------------

func _nudge_firework(fw: Dictionary, delta: int, qty_label: Label) -> void:
	var name_str: String = String(fw.name)
	var current: int = int(_fireworks_qty.get(name_str, 0))
	var cap: int = int(BalanceConfig.get_zone(GameState.current_zone).get("firework_cap", 300))
	var new_qty: int = maxi(current + delta, 0)
	new_qty = mini(new_qty, cap)
	_fireworks_qty[name_str] = new_qty
	qty_label.text = str(new_qty)
	_refresh_totals()


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


# --- totals & fire show -------------------------------------------------------

func _refresh_totals() -> void:
	var spend := 0.0
	var fw_count := 0
	for name_str in _fireworks_qty.keys():
		var qty := int(_fireworks_qty[name_str])
		if qty <= 0:
			continue
		spend += float(BalanceConfig.get_firework(name_str).get("cost", 0)) * qty
		fw_count += qty
	for name_str in _marketing_qty.keys():
		var qty := int(_marketing_qty[name_str])
		if qty <= 0:
			continue
		spend += float(BalanceConfig.get_marketing(name_str).get("cost", 0)) * qty
	for category in _enhancements.keys():
		var eh := BalanceConfig.get_enhancement(String(category), String(_enhancements[category]))
		spend += float(eh.get("cost", 0))
	for up_name in _upgrade_buys:
		spend += float(BalanceConfig.get_upgrade(up_name).get("cost", 0))

	_total_spend_label.text = "Spend: $%s / Cash: $%s" % [_fmt_dollars(spend), _fmt_dollars(GameState.money)]
	_total_spend_label.add_theme_color_override("font_color", RED if spend > GameState.money else GOLD)
	_summary_label.text = "%d fireworks selected, %d marketing, %d enhancements, %d upgrades" % [
		fw_count,
		_marketing_total(),
		_enhancements.size(),
		_upgrade_buys.size(),
	]

	_fire_show_button.disabled = (spend > GameState.money) or (fw_count <= 0)


func _marketing_total() -> int:
	var t := 0
	for v in _marketing_qty.values():
		t += int(v)
	return t


func _on_fire_show_pressed() -> void:
	var decisions := {
		"fireworks": _fireworks_qty,
		"marketing": _marketing_qty,
		"enhancements": _enhancements_as_array(),
		"upgrades_to_buy": _upgrade_buys,
	}
	var result := GameEngine.resolve_night(decisions)
	Router.commit_night(result)


func _enhancements_as_array() -> Array:
	var out: Array = []
	for category in _enhancements.keys():
		out.append({"category": String(category), "name": String(_enhancements[category])})
	return out


# --- helpers ------------------------------------------------------------------

func _label(text: String, font_size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	return l


func _small_button(text: String) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(32, 28)
	return b


func _stylebox(color: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.border_width_left = 0
	sb.border_width_right = 0
	sb.border_width_top = 0
	sb.border_width_bottom = 0
	return sb


func _fmt_dollars(n) -> String:
	return _fmt_num(int(n))


func _fmt_num(n: int) -> String:
	if n >= 1_000_000_000:
		return "%.2fB" % (n / 1_000_000_000.0)
	if n >= 1_000_000:
		return "%.2fM" % (n / 1_000_000.0)
	if n >= 1_000:
		return "%.1fK" % (n / 1_000.0)
	return str(n)
