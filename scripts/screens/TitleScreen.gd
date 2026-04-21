extends Control
## Stage 2 title screen: title text, New Run button, optional debug auto-run
## that simulates 100-night runs with scripted strategies for QA.

const BG := Color(0.04, 0.06, 0.16)
const ACCENT_TEXT := Color(0.96, 0.90, 0.82)
const MUTED := Color(0.54, 0.52, 0.44)
const GOLD := Color(1.0, 0.84, 0.0)


func _ready() -> void:
	# Headless smoke mode: `godot --headless -- --smoke` drives every strategy
	# through a full 100-night run and quits. Used for CI / sanity checks.
	if "--smoke" in OS.get_cmdline_user_args():
		_run_smoke_and_quit()
		return

	var bg := ColorRect.new()
	bg.color = BG
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	add_child(bg)

	var margin := MarginContainer.new()
	margin.anchor_right = 1.0
	margin.anchor_bottom = 1.0
	margin.add_theme_constant_override("margin_left", 120)
	margin.add_theme_constant_override("margin_right", 120)
	margin.add_theme_constant_override("margin_top", 80)
	margin.add_theme_constant_override("margin_bottom", 80)
	add_child(margin)

	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 24)
	margin.add_child(v)

	var title := Label.new()
	title.text = "LAUNCH"
	title.add_theme_font_size_override("font_size", 96)
	title.add_theme_color_override("font_color", ACCENT_TEXT)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "a 100-night fireworks career"
	subtitle.add_theme_font_size_override("font_size", 20)
	subtitle.add_theme_color_override("font_color", MUTED)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(subtitle)

	v.add_child(_spacer(40))

	var new_run := _menu_button("New Run")
	new_run.pressed.connect(func() -> void: Router.start_new_run())
	v.add_child(new_run)

	var debug := _menu_button("Debug: Auto-run (5× Mogul)")
	debug.pressed.connect(_on_debug_autorun_pressed)
	v.add_child(debug)

	var quit := _menu_button("Quit")
	quit.pressed.connect(func() -> void: get_tree().quit())
	v.add_child(quit)

	v.add_child(_spacer(40))

	var meta := Label.new()
	meta.text = _meta_summary()
	meta.add_theme_font_size_override("font_size", 16)
	meta.add_theme_color_override("font_color", MUTED)
	meta.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	meta.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(meta)


func _menu_button(label: String) -> Button:
	var b := Button.new()
	b.text = label
	b.add_theme_font_size_override("font_size", 24)
	b.custom_minimum_size = Vector2(360, 56)
	b.focus_mode = Control.FOCUS_ALL
	return b


func _spacer(h: int) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, h)
	return c


func _meta_summary() -> String:
	if MetaState.total_runs_completed == 0:
		return "No runs completed yet. Stage 2 smoke-test build."
	return "Runs: %d   True endings: %d   Wrong-cause: %d   Skipped: %d" % [
		MetaState.total_runs_completed,
		MetaState.true_endings_achieved,
		MetaState.wrong_endings_achieved,
		MetaState.skipped_endings,
	]


func _run_smoke_and_quit() -> void:
	print("--- LAUNCH smoke test ---")
	for strategy in ["Mogul", "Rush", "Spectacle", "Completionist", "Cheapskate"]:
		DebugAutoRun.run_batch(strategy, 5, "asteroid")
	DebugAutoRun.run_batch("Mogul", 2, "")
	DebugAutoRun.run_batch("Mogul", 2, "library")

	# Verify every screen scene parses + instantiates without runtime errors.
	# Reset GameState so the instantiated screens see sane values.
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
	for path in [Router.PLANNING, Router.SHOW, Router.NEWSPAPER, Router.DONATION, Router.ENDING]:
		var packed: PackedScene = load(path)
		assert(packed != null, "failed to load %s" % path)
		var instance: Node = packed.instantiate()
		assert(instance != null, "failed to instantiate %s" % path)
		instance.free()
		print("  scene OK: %s" % path)

	print("--- smoke test complete ---")
	get_tree().quit(0)


func _on_debug_autorun_pressed() -> void:
	# Run a few Mogul-style scripted runs; results print to stdout so Rob can
	# validate economy matches docs/BALANCE_FINAL.md without wiring a full UI.
	DebugAutoRun.run_batch("Mogul", 5)
	var label := find_child("DebugStatus", true, false) as Label
	if label == null:
		label = Label.new()
		label.name = "DebugStatus"
		label.text = "Debug auto-run complete — see stdout."
		label.add_theme_font_size_override("font_size", 16)
		label.add_theme_color_override("font_color", GOLD)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		add_child(label)
		label.position = Vector2(0, size.y - 40)
		label.size = Vector2(size.x, 32)
	else:
		label.text = "Debug auto-run complete — see stdout."
