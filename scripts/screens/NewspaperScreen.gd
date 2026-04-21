extends Control
## Interstitial between shows. Displays a generated front-page headline +
## body + meteor sub-column + occasional cause mention. Click to continue.

const BG := Color(0.04, 0.06, 0.16)
const PAPER := Color(0.10, 0.12, 0.22)
const TEXT := Color(0.96, 0.90, 0.82)
const MUTED := Color(0.54, 0.52, 0.44)
const GOLD := Color(1.0, 0.84, 0.0)


func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = BG
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	add_child(bg)

	var article := GameState.pending_newspaper
	if article.is_empty():
		# Should not happen under normal flow; fallback to a spacer.
		article = {
			"paper_name": "THE DAILY LEDGER",
			"date_line": "",
			"headline": "EDITION DELAYED",
			"body": "Tomorrow's stories run today.",
			"meteor_column": "",
			"cause_mention": "",
			"synergy_callout": "",
		}

	var m := MarginContainer.new()
	m.anchor_right = 1.0
	m.anchor_bottom = 1.0
	m.add_theme_constant_override("margin_left", 100)
	m.add_theme_constant_override("margin_right", 100)
	m.add_theme_constant_override("margin_top", 60)
	m.add_theme_constant_override("margin_bottom", 60)
	add_child(m)

	var frame := PanelContainer.new()
	frame.add_theme_stylebox_override("panel", _stylebox(PAPER))
	m.add_child(frame)

	var pad := MarginContainer.new()
	pad.add_theme_constant_override("margin_left", 40)
	pad.add_theme_constant_override("margin_right", 40)
	pad.add_theme_constant_override("margin_top", 32)
	pad.add_theme_constant_override("margin_bottom", 24)
	frame.add_child(pad)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 18)
	pad.add_child(v)

	var paper_name := _label(String(article.paper_name), 32, TEXT)
	paper_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(paper_name)

	var date := _label(String(article.date_line), 16, MUTED)
	date.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(date)

	v.add_child(_spacer(6))

	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 32)
	v.add_child(columns)

	# Main column
	var main := VBoxContainer.new()
	main.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main.add_theme_constant_override("separation", 12)
	columns.add_child(main)

	var headline := _label(String(article.headline), 32, TEXT)
	headline.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	main.add_child(headline)

	var body := _label(String(article.body), 16, TEXT)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	main.add_child(body)

	var synergy: String = String(article.get("synergy_callout", ""))
	if synergy != "":
		main.add_child(_label(synergy, 16, GOLD))

	var cause: String = String(article.get("cause_mention", ""))
	if cause != "":
		main.add_child(_spacer(8))
		main.add_child(_label("— SECONDARY NOTICE —", 16, MUTED))
		var cause_lbl := _label(cause, 16, TEXT)
		cause_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		main.add_child(cause_lbl)

	# Sub-column (meteor)
	var meteor: String = String(article.get("meteor_column", ""))
	if meteor != "":
		var sub := VBoxContainer.new()
		sub.custom_minimum_size = Vector2(280, 0)
		sub.add_theme_constant_override("separation", 6)
		columns.add_child(sub)
		sub.add_child(_label("NIGHT SKY COLUMN", 16, MUTED))
		var line := _label(meteor, 16, TEXT)
		line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		sub.add_child(line)
		sub.add_child(_label("— E. Chen, observatory", 16, MUTED))

	v.add_child(_spacer(12))

	var cont := Button.new()
	cont.text = "Continue to Planning →"
	cont.custom_minimum_size = Vector2(260, 44)
	cont.pressed.connect(func() -> void: Router.after_newspaper())
	var btn_wrap := HBoxContainer.new()
	btn_wrap.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_wrap.add_child(cont)
	v.add_child(btn_wrap)


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
