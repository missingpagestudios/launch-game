extends Control
## Single-shot donation phase. 8 causes are presented neutrally with the same
## $2.5B cost; only "Asteroid Research Program" is the true ending.

const BG := Color(0.04, 0.06, 0.16)
const CARD_BG := Color(0.09, 0.12, 0.24)
const TEXT := Color(0.96, 0.90, 0.82)
const MUTED := Color(0.54, 0.52, 0.44)
const GOLD := Color(1.0, 0.84, 0.0)


func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = BG
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	add_child(bg)

	var margin := MarginContainer.new()
	margin.anchor_right = 1.0
	margin.anchor_bottom = 1.0
	margin.add_theme_constant_override("margin_left", 60)
	margin.add_theme_constant_override("margin_right", 60)
	margin.add_theme_constant_override("margin_top", 40)
	margin.add_theme_constant_override("margin_bottom", 40)
	add_child(margin)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 16)
	margin.add_child(v)

	var title := _label("AN UNUSUAL MORNING", 48, TEXT)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(title)

	var sub := _label("Eight requests have arrived at your office. You have the means to fund one.", 16, MUTED)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(sub)

	var info := _label("Cash on hand: $%s    Donation cost: $%s" % [
		_fmt(GameState.money),
		_fmt(float(BalanceConfig.game_params().get("donation_cost", 2_500_000_000)))], 16, GOLD)
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(info)

	v.add_child(_spacer(12))

	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(scroll)

	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(grid)

	for cause in BalanceConfig.donation_causes():
		grid.add_child(_build_cause_card(cause))

	v.add_child(_spacer(8))

	var skip := Button.new()
	skip.text = "Skip donation — keep $%s" % _fmt(float(BalanceConfig.game_params().get("donation_cost", 2_500_000_000)))
	skip.custom_minimum_size = Vector2(400, 40)
	skip.pressed.connect(func() -> void: Router.donation_chosen(""))
	var skip_wrap := HBoxContainer.new()
	skip_wrap.alignment = BoxContainer.ALIGNMENT_CENTER
	skip_wrap.add_child(skip)
	v.add_child(skip_wrap)


func _build_cause_card(cause: Dictionary) -> Control:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(260, 240)
	card.add_theme_stylebox_override("panel", _stylebox(CARD_BG))

	var pad := MarginContainer.new()
	pad.add_theme_constant_override("margin_left", 16)
	pad.add_theme_constant_override("margin_right", 16)
	pad.add_theme_constant_override("margin_top", 16)
	pad.add_theme_constant_override("margin_bottom", 16)
	card.add_child(pad)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	pad.add_child(v)

	v.add_child(_label(String(cause.name), 16, TEXT))
	v.add_child(_label("— %s" % String(cause.character), 16, MUTED))

	var plea := _label("\"%s\"" % String(cause.plea), 16, TEXT)
	plea.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	plea.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(plea)

	var btn := Button.new()
	btn.text = "Fund This Cause"
	btn.custom_minimum_size = Vector2(0, 36)
	var cause_id := String(cause.id)
	btn.pressed.connect(func() -> void: Router.donation_chosen(cause_id))
	v.add_child(btn)
	return card


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


func _stylebox(color: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	return sb


func _fmt(n: float) -> String:
	if n >= 1_000_000_000:
		return "%.2fB" % (n / 1_000_000_000.0)
	if n >= 1_000_000:
		return "%.2fM" % (n / 1_000_000.0)
	if n >= 1_000:
		return "%.1fK" % (n / 1_000.0)
	return "%.0f" % n
