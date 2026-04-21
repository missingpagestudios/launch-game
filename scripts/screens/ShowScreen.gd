extends Control
## Stage 2 stand-in for the real show. No visuals — just a results summary.
## Stage 3 will insert the 30-second firework visualization before this screen.

const BG := Color(0.04, 0.06, 0.16)
const TEXT := Color(0.96, 0.90, 0.82)
const MUTED := Color(0.54, 0.52, 0.44)
const GOLD := Color(1.0, 0.84, 0.0)
const GREEN := Color(0.45, 0.88, 0.52)
const RED := Color(1.0, 0.35, 0.42)


func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = BG
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	add_child(bg)

	var m := MarginContainer.new()
	m.anchor_right = 1.0
	m.anchor_bottom = 1.0
	m.add_theme_constant_override("margin_left", 120)
	m.add_theme_constant_override("margin_right", 120)
	m.add_theme_constant_override("margin_top", 80)
	m.add_theme_constant_override("margin_bottom", 80)
	add_child(m)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 20)
	m.add_child(v)

	var r := GameState.last_night_results
	var zone_name := String(BalanceConfig.get_zone(int(r.get("resolved_at_zone", GameState.current_zone))).get("name", ""))

	var title := _label("YOUR SHOW IN %s" % zone_name.to_upper(), 32, TEXT)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(title)

	var sub := _label("Night %d" % int(r.get("resolved_at_night", GameState.night - 1)), 16, MUTED)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(sub)

	v.add_child(_spacer(20))

	v.add_child(_stat_row("Attendees", _fmt_num(int(r.get("total_attendees", 0))), TEXT))
	v.add_child(_stat_row("  walk-up", _fmt_num(int(r.get("walkup", 0))), MUTED))
	v.add_child(_stat_row("  repeat fans", _fmt_num(int(r.get("repeat_attendees", 0))), MUTED))
	v.add_child(_stat_row("Engagement", _fmt_num(int(r.get("engagement", 0))), TEXT))
	v.add_child(_stat_row("Quality", _stars(int(r.get("quality_stars", 0))), GOLD))

	var new_fans := int(r.get("new_fans", 0))
	v.add_child(_stat_row("New repeat fans", "+%d" % new_fans, GREEN if new_fans > 0 else MUTED))
	var fans_lost := int(r.get("fans_lost", 0))
	if fans_lost > 0:
		v.add_child(_stat_row("Fans lost", "-%d" % fans_lost, RED))

	v.add_child(_stat_row("Revenue", "$%s" % _fmt_num(int(r.get("revenue", 0))), GOLD))
	v.add_child(_stat_row("Spent", "$%s" % _fmt_num(int(r.get("money_spent", 0))), MUTED))
	var profit := int(r.get("night_profit", 0))
	v.add_child(_stat_row("Night profit", "$%s" % _fmt_signed(profit), GREEN if profit >= 0 else RED))

	var syns: Array = r.get("synergies_triggered", [])
	if not syns.is_empty():
		v.add_child(_spacer(8))
		v.add_child(_label("Synergies: %s" % ", ".join(syns), 24, GOLD))

	var unlocks: Array = r.get("unlocks_earned", [])
	if not unlocks.is_empty():
		v.add_child(_label("NEW FIREWORK UNLOCKED: %s" % ", ".join(unlocks), 24, GOLD))

	if bool(r.get("zone_advanced", false)):
		v.add_child(_label("ZONE CLEARED — now in %s" % String(BalanceConfig.get_zone(GameState.current_zone).get("name", "")), 32, GOLD))

	if bool(r.get("zone_6_clear_triggered", false)):
		v.add_child(_label("A letter arrives. Eight requests are waiting at your office.", 24, GOLD))

	v.add_child(_spacer(24))

	var cont := Button.new()
	cont.text = "Continue →"
	cont.add_theme_font_size_override("font_size", 24)
	cont.custom_minimum_size = Vector2(220, 56)
	cont.pressed.connect(func() -> void: Router.after_show())
	v.add_child(cont)


func _stat_row(label: String, value: String, color: Color) -> Control:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 24)
	var l := _label(label, 16, MUTED)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(l)
	h.add_child(_label(value, 24, color))
	return h


func _label(text: String, font_size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	return l


func _spacer(h: int) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, h)
	return c


func _stars(count: int) -> String:
	var s := ""
	for i in 5:
		s += "★" if i < count else "☆"
	return s


func _fmt_num(n: int) -> String:
	if n >= 1_000_000_000:
		return "%.2fB" % (n / 1_000_000_000.0)
	if n >= 1_000_000:
		return "%.2fM" % (n / 1_000_000.0)
	if n >= 1_000:
		return "%.1fK" % (n / 1_000.0)
	return str(n)


func _fmt_signed(n: int) -> String:
	if n >= 0:
		return _fmt_num(n)
	return "-%s" % _fmt_num(-n)
