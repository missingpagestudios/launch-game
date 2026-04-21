extends Control
## Four variants based on GameState.ending_type:
##   "true_ending" — asteroid funded
##   "wrong_cause" — non-asteroid cause funded
##   "skipped"     — donation phase reached, player declined
##   "zone_N_finale" — never qualified for donation

const BG := Color(0.04, 0.06, 0.16)
const TEXT := Color(0.96, 0.90, 0.82)
const MUTED := Color(0.54, 0.52, 0.44)
const GOLD := Color(1.0, 0.84, 0.0)


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
	v.add_theme_constant_override("separation", 18)
	m.add_child(v)

	var ending := GameState.ending_type
	var header_text := _header_for(ending)
	var body_text := _body_for(ending)
	var signal_pct := _signal_integrity(ending)

	var header := _label(header_text, 48, TEXT)
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(header)

	v.add_child(_spacer(8))

	var body := _label(body_text, 16, TEXT)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(body)

	v.add_child(_spacer(12))

	v.add_child(_stat("Signal integrity", "%d%%" % signal_pct))
	var cause_label := "none"
	if GameState.donation_choice != "":
		cause_label = String(BalanceConfig.get_cause(GameState.donation_choice).get("name", GameState.donation_choice))
	v.add_child(_stat("Causes supported", cause_label))
	v.add_child(_stat("Final career revenue", "$%s" % _fmt(GameState.total_money_earned)))
	v.add_child(_stat("Final zone reached", "%d — %s" % [GameState.current_zone, String(BalanceConfig.get_zone(GameState.current_zone).get("name", ""))]))
	v.add_child(_stat("Total fireworks fired", str(GameState.total_fireworks_fired_this_run)))
	v.add_child(_stat("Repeat fans at end", _fmt(float(GameState.repeat_fans))))

	var unlock_list: Array = GameState.pending_newspaper.get("ending_unlocks", [])
	if not unlock_list.is_empty():
		v.add_child(_spacer(8))
		v.add_child(_label("NEW FIREWORKS UNLOCKED:", 32, GOLD))
		for u in unlock_list:
			v.add_child(_label("  • %s" % String(u), 16, GOLD))

	v.add_child(_spacer(24))

	var btn_row := HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 24)

	var title_btn := Button.new()
	title_btn.text = "Return to Title"
	title_btn.add_theme_font_size_override("font_size", 16)
	title_btn.custom_minimum_size = Vector2(220, 44)
	title_btn.pressed.connect(func() -> void: Router.return_to_title_from_ending())
	btn_row.add_child(title_btn)

	var again_btn := Button.new()
	again_btn.text = "Start New Run"
	again_btn.add_theme_font_size_override("font_size", 16)
	again_btn.custom_minimum_size = Vector2(220, 44)
	again_btn.pressed.connect(func() -> void: Router.start_new_run())
	btn_row.add_child(again_btn)

	v.add_child(btn_row)


func _header_for(ending: String) -> String:
	match ending:
		"true_ending": return "ARCHIVE — SIGNAL RECOVERED"
		"wrong_cause": return "ARCHIVE — SIGNAL INCOMPLETE"
		"skipped": return "ARCHIVE — SIGNAL FADED"
		_: return "ARCHIVE — CAREER COMPLETE"


func _body_for(ending: String) -> String:
	match ending:
		"true_ending":
			return "Dr. Chen's research succeeded. The intercept system deployed in time. The crowd never knew what you prevented — they saw a fireworks show. You saw something else."
		"wrong_cause":
			var c := String(BalanceConfig.get_cause(GameState.donation_choice).get("name", "the cause"))
			return "You funded %s. Your generosity mattered.\n\nOn the final night, something fell from the sky." % c
		"skipped":
			return "You kept your money. Your career was your own.\n\nOn the final night, something fell from the sky."
		_:
			var zone_name := String(BalanceConfig.get_zone(GameState.current_zone).get("name", ""))
			return "You built a career in %s.\n\nNight 100 came and went. Fireworks filled the sky." % zone_name


func _signal_integrity(ending: String) -> int:
	match ending:
		"true_ending": return 80
		"wrong_cause": return 70
		"skipped": return 50
		_: return 30 + 5 * max(GameState.current_zone - 1, 0)


func _stat(label: String, value: String) -> Control:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 24)
	var l := _label(label, 16, MUTED)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(l)
	h.add_child(_label(value, 16, GOLD))
	return h


func _label(text: String, size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l


func _spacer(h: int) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, h)
	return c


func _fmt(n: float) -> String:
	if n >= 1_000_000_000:
		return "%.2fB" % (n / 1_000_000_000.0)
	if n >= 1_000_000:
		return "%.2fM" % (n / 1_000_000.0)
	if n >= 1_000:
		return "%.1fK" % (n / 1_000.0)
	return "%.0f" % n
