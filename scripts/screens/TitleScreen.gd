extends Control
## Title screen per docs/title_screen_spec.md.
## Full-bleed Zone 6 mountain-vista backdrop (falls back to an existing
## zone art asset until the hero image is in the repo). Right-aligned
## 560px column holds title + subtitle + menu. Entrance animation
## fades title → subtitle → cascades the menu in from the right.

const FONT_TITLE_VARIABLE := preload("res://assets/fonts/CormorantGaramond-VariableFont_wght.ttf")
const FONT_REGULAR := preload("res://assets/fonts/Inter-Regular.ttf")
const FONT_MEDIUM := preload("res://assets/fonts/Inter-Medium.ttf")
const FONT_SEMIBOLD := preload("res://assets/fonts/Inter-SemiBold.ttf")
const FONT_ITALIC := preload("res://assets/fonts/Inter-Italic.ttf")

# Spec hero image — fallback chain if it isn't in the repo yet.
const BG_CANDIDATES: Array[String] = [
	"res://assets/backgrounds/zone_6_mountain_vista.png",
	"res://assets/backgrounds/zone2.png",
	"res://assets/backgrounds/zone1.png",
]

const TEXT_PRIMARY := Color(0.941, 0.941, 0.941)
const TEXT_SECONDARY := Color(0.722, 0.722, 0.722)
const TEXT_MUTED := Color(0.533, 0.533, 0.533)
const TEXT_DIM := Color(0.268, 0.268, 0.268)
const ACCENT_AMBER := Color(1.0, 0.722, 0.302)

const MENU_LABELS := [
	"New Game",
	"Continue",
	"Unlockables",
	"Settings",
	"Credits",
	"Quit",
]

var _menu_buttons: Array[Button] = []
var _title_label: Label
var _subtitle_label: Label
var _tweens: Array[Tween] = []
var _entrance_done: bool = false


func _ready() -> void:
	# Headless smoke path: run scripted strategies + scene-parse check and quit.
	if "--smoke" in OS.get_cmdline_user_args():
		_run_smoke_and_quit()
		return

	_build_background()
	_build_right_column()
	_build_bottom_bar()
	_prime_and_animate_entrance()


# --- layout -----------------------------------------------------------------

func _build_background() -> void:
	var bg_path: String = ""
	for p in BG_CANDIDATES:
		if ResourceLoader.exists(p):
			bg_path = p
			break
	if bg_path != "":
		var tex := TextureRect.new()
		tex.texture = load(bg_path)
		tex.anchor_right = 1.0
		tex.anchor_bottom = 1.0
		tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(tex)
	else:
		var fill := ColorRect.new()
		fill.color = Color(0.039, 0.055, 0.102)
		fill.anchor_right = 1.0
		fill.anchor_bottom = 1.0
		add_child(fill)


func _build_right_column() -> void:
	var col := VBoxContainer.new()
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.custom_minimum_size = Vector2(560, 520)
	col.anchor_left = 1.0
	col.anchor_right = 1.0
	col.anchor_top = 0.5
	col.anchor_bottom = 0.5
	col.offset_left = -(560 + int(1280 * 0.07))
	col.offset_top = -260
	col.offset_right = -int(1280 * 0.07)
	col.offset_bottom = 260
	col.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(col)

	_title_label = _build_title()
	col.add_child(_title_label)

	col.add_child(_spacer(6))

	_subtitle_label = _build_subtitle()
	col.add_child(_subtitle_label)

	col.add_child(_spacer(88))

	var menu := VBoxContainer.new()
	menu.alignment = BoxContainer.ALIGNMENT_END
	menu.add_theme_constant_override("separation", 4)
	col.add_child(menu)

	var unlocked_count: int = MetaState.unlocked_fireworks.size()
	var active_index: int = _primary_menu_index()
	for i in range(MENU_LABELS.size()):
		var base: String = String(MENU_LABELS[i])
		var label_text: String = base
		if base == "Unlockables" and unlocked_count > 0:
			label_text = "Unlockables · %d" % unlocked_count
		var btn := _build_menu_button(label_text, i == active_index, i)
		_menu_buttons.append(btn)
		menu.add_child(btn)


func _build_title() -> Label:
	var l := Label.new()
	l.text = "The Last Show"
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	# Variable font weight — spec asks for SemiBold (wght 600).
	var fv := FontVariation.new()
	fv.base_font = FONT_TITLE_VARIABLE
	fv.variation_opentype = {"wght": 600}
	l.add_theme_font_override("font", fv)
	l.add_theme_font_size_override("font_size", 76)
	l.add_theme_color_override("font_color", TEXT_PRIMARY)
	# Soft amber glow via thick, translucent outline. Approximates the
	# double drop-shadow from the HTML mockup.
	l.add_theme_constant_override("outline_size", 36)
	l.add_theme_color_override(
		"font_outline_color", Color(1.0, 0.722, 0.302, 0.14))
	return l


func _build_subtitle() -> Label:
	var l := Label.new()
	l.text = "a game about fireworks"
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	l.add_theme_font_override("font", FONT_ITALIC)
	l.add_theme_font_size_override("font_size", 14)
	l.add_theme_color_override("font_color", TEXT_SECONDARY)
	return l


func _build_menu_button(text: String, primary: bool, idx: int) -> Button:
	var b := Button.new()
	b.text = text.to_upper()
	b.flat = true
	b.custom_minimum_size = Vector2(280, 0)
	b.focus_mode = Control.FOCUS_ALL
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.size_flags_horizontal = Control.SIZE_SHRINK_END
	b.add_theme_font_override("font", FONT_SEMIBOLD if primary else FONT_MEDIUM)
	b.add_theme_font_size_override("font_size", 15)

	var disabled: bool = (text.to_upper() == "CONTINUE" and not _continue_available())
	var base_color: Color = TEXT_MUTED
	if disabled:
		base_color = TEXT_DIM
	elif primary:
		base_color = TEXT_SECONDARY
	b.add_theme_color_override("font_color", base_color)
	b.add_theme_color_override("font_hover_color", ACCENT_AMBER)
	b.add_theme_color_override("font_focus_color", ACCENT_AMBER)
	b.add_theme_color_override("font_pressed_color", ACCENT_AMBER)
	b.add_theme_color_override("font_disabled_color", TEXT_DIM)
	var empty := StyleBoxEmpty.new()
	empty.content_margin_left = 0
	empty.content_margin_right = 0
	empty.content_margin_top = 10
	empty.content_margin_bottom = 10
	b.add_theme_stylebox_override("normal", empty)
	b.add_theme_stylebox_override("hover", empty)
	b.add_theme_stylebox_override("pressed", empty)
	b.add_theme_stylebox_override("focus", empty)
	b.add_theme_stylebox_override("disabled", empty)
	b.disabled = disabled

	# Hover slide-right via pivot_offset + tween on `position.x`.
	b.mouse_entered.connect(func() -> void: _menu_hover(b, true))
	b.mouse_exited.connect(func() -> void: _menu_hover(b, false))
	b.focus_entered.connect(func() -> void: _menu_hover(b, true))
	b.focus_exited.connect(func() -> void: _menu_hover(b, false))

	b.pressed.connect(func() -> void: _on_menu_select(idx))
	return b


func _build_bottom_bar() -> void:
	var bar := HBoxContainer.new()
	bar.anchor_left = 0.0
	bar.anchor_right = 1.0
	bar.anchor_top = 1.0
	bar.anchor_bottom = 1.0
	bar.offset_left = 40
	bar.offset_right = -40
	bar.offset_top = -32
	bar.offset_bottom = -20
	add_child(bar)

	var left := Label.new()
	left.text = "MISSING PAGE STUDIOS"
	left.add_theme_font_override("font", FONT_REGULAR)
	left.add_theme_font_size_override("font_size", 11)
	left.add_theme_color_override("font_color", TEXT_DIM)
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.add_child(left)

	var right := Label.new()
	right.text = "v0.1.0"
	right.add_theme_font_override("font", FONT_REGULAR)
	right.add_theme_font_size_override("font_size", 11)
	right.add_theme_color_override("font_color", TEXT_DIM)
	right.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	bar.add_child(right)


# --- helpers ----------------------------------------------------------------

func _spacer(h: int) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, h)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c


func _continue_available() -> bool:
	# Session-only saves (stage 2). Continue stays disabled until a real
	# save-system lands in stage 3.
	return false


func _primary_menu_index() -> int:
	return 1 if _continue_available() else 0  # Continue > New Game


func _menu_hover(b: Button, on: bool) -> void:
	if b.disabled:
		return
	var target: float = 12.0 if on else 0.0
	var t := create_tween()
	t.set_ease(Tween.EASE_OUT)
	t.set_trans(Tween.TRANS_CUBIC)
	t.tween_property(b, "position:x", target + b.get_meta("_rest_x", 0.0), 0.18)


# --- entrance animation -----------------------------------------------------

func _prime_and_animate_entrance() -> void:
	_title_label.modulate.a = 0.0
	_subtitle_label.modulate.a = 0.0
	for b in _menu_buttons:
		b.modulate.a = 0.0
		# Record initial x so hover tween can return to it cleanly.
		b.set_meta("_rest_x", b.position.x)
		b.position.x += 60.0

	var t_title := create_tween()
	t_title.tween_property(_title_label, "modulate:a", 1.0, 0.8)
	_tweens.append(t_title)

	var t_sub := create_tween()
	t_sub.tween_interval(0.4)
	t_sub.tween_property(_subtitle_label, "modulate:a", 1.0, 0.4)
	_tweens.append(t_sub)

	var menu_delay := 0.8
	for i in range(_menu_buttons.size()):
		var b: Button = _menu_buttons[i]
		var rest_x: float = b.get_meta("_rest_x", 0.0)
		var t := create_tween()
		t.set_parallel(false)
		t.tween_interval(menu_delay + i * 0.06)
		t.tween_callback(func() -> void: pass)
		var t_inner := create_tween()
		t_inner.tween_interval(menu_delay + i * 0.06)
		t_inner.set_ease(Tween.EASE_OUT)
		t_inner.set_trans(Tween.TRANS_CUBIC)
		t_inner.tween_property(b, "position:x", rest_x, 0.3).set_ease(Tween.EASE_OUT)
		_tweens.append(t_inner)
		var t_alpha := create_tween()
		t_alpha.tween_interval(menu_delay + i * 0.06)
		t_alpha.tween_property(b, "modulate:a", 1.0, 0.3)
		_tweens.append(t_alpha)

	var t_done := create_tween()
	t_done.tween_interval(menu_delay + _menu_buttons.size() * 0.06 + 0.3)
	t_done.tween_callback(func() -> void: _entrance_done = true)
	_tweens.append(t_done)


func _input(event: InputEvent) -> void:
	if _entrance_done:
		return
	if event is InputEventMouseButton and event.pressed:
		_skip_entrance()
	elif event is InputEventKey and event.pressed:
		_skip_entrance()


func _skip_entrance() -> void:
	_entrance_done = true
	for t in _tweens:
		if t != null and t.is_valid():
			t.kill()
	_tweens.clear()
	_title_label.modulate.a = 1.0
	_subtitle_label.modulate.a = 1.0
	for b in _menu_buttons:
		b.modulate.a = 1.0
		b.position.x = b.get_meta("_rest_x", 0.0)


# --- actions ----------------------------------------------------------------

func _on_menu_select(idx: int) -> void:
	if not _entrance_done:
		_skip_entrance()
	match idx:
		0: Router.start_new_run()
		1:
			if _continue_available():
				Router.start_new_run()  # TODO: load save when stage 3 adds save/load.
		2: _fireworks_demo_stub()  # TODO: Unlockables browser when designed.
		3: pass  # TODO: Settings screen.
		4: pass  # TODO: Credits screen.
		5: get_tree().quit()


func _fireworks_demo_stub() -> void:
	# Unlockables screen doesn't exist yet. Keep the debug fireworks demo
	# reachable from this slot so Rob can still hit the particle test.
	Router.go_fireworks_demo()


# --- smoke ------------------------------------------------------------------

func _run_smoke_and_quit() -> void:
	print("--- LAUNCH smoke test ---")
	for strategy in ["Mogul", "Rush", "Spectacle", "Completionist", "Cheapskate"]:
		DebugAutoRun.run_batch(strategy, 5, "asteroid")
	DebugAutoRun.run_batch("Mogul", 2, "")
	DebugAutoRun.run_batch("Mogul", 2, "library")

	GameState.start_new_run()
	GameState.last_night_results = {
		"resolved_at_night": 1, "resolved_at_zone": 1,
		"total_attendees": 10, "walkup": 10, "repeat_attendees": 0,
		"engagement": 30, "quality_stars": 3, "new_fans": 2, "fans_lost": 0,
		"revenue": 30, "money_spent": 10, "night_profit": 20,
		"zone_advanced": false, "zone_6_clear_triggered": false,
		"synergies_triggered": [], "unlocks_earned": [],
	}
	GameState.pending_newspaper = NewspaperContent.build_article(GameState.last_night_results)
	GameState.ending_type = "zone_1_finale"
	for path in [Router.PLANNING, Router.SHOW, Router.NEWSPAPER, Router.DONATION, Router.ENDING, Router.FIREWORKS_DEMO]:
		var packed: PackedScene = load(path)
		assert(packed != null, "failed to load %s" % path)
		var instance: Node = packed.instantiate()
		assert(instance != null, "failed to instantiate %s" % path)
		instance.free()
		print("  scene OK: %s" % path)

	print("--- smoke test complete ---")
	get_tree().quit(0)
