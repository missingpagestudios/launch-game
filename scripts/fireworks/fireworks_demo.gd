extends Control
## Smoke-test harness for the ported firework engine.
## Hosts a FireworkField + FireworkHost and exposes a button row that
## cycles through FireworkBursts.catalog(). Not user-facing gameplay —
## reachable from the Title screen's debug menu and useful for verifying
## the port before wiring firework bursts into the real Run Show flow.

const FireworkFieldScene := preload("res://scripts/fireworks/firework_field.gd")
const FireworkHostScene := preload("res://scripts/fireworks/firework_host.gd")

var _field: Node2D
var _host: FireworkHost
var _catalog: Array = []
var _index: int = 0
var _name_label: Label


func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.01, 0.01, 0.04)
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	add_child(bg)

	_host = FireworkHostScene.new()
	_host.name = "FireworkHost"
	add_child(_host)

	_field = FireworkFieldScene.new()
	_field.name = "FireworkField"
	_field.set("host_ref", _host)
	add_child(_field)
	_host.shake_target = _field

	_catalog = FireworkBursts.catalog()
	_build_controls()


func _build_controls() -> void:
	var bar := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.07, 0.14, 0.85)
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	bar.add_theme_stylebox_override("panel", style)
	bar.anchor_right = 1.0
	bar.anchor_top = 1.0
	bar.anchor_bottom = 1.0
	bar.offset_top = -80
	add_child(bar)

	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 12)
	bar.add_child(h)

	h.add_child(_debug_button("◀ PREV", func() -> void: _step(-1)))
	h.add_child(_debug_button("FIRE ▶", func() -> void: _fire_current()))
	h.add_child(_debug_button("NEXT ▶", func() -> void: _step(1)))
	h.add_child(_debug_button("CLEAR", func() -> void: _field.call("clear_all")))
	h.add_child(_debug_button("BACK", func() -> void: Router.go_title()))

	_name_label = Label.new()
	_name_label.text = _catalog_line()
	_name_label.add_theme_color_override("font_color", Color(1.0, 0.722, 0.302))
	_name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	h.add_child(_name_label)


func _debug_button(text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 40)
	b.pressed.connect(cb)
	return b


func _fire_current() -> void:
	if _catalog.is_empty():
		return
	var fw: Dictionary = _catalog[_index]
	var ground: Vector2 = Vector2(get_viewport_rect().size.x * 0.5, get_viewport_rect().size.y - 120)
	_field.call("launch", fw, ground)


func _step(delta: int) -> void:
	if _catalog.is_empty():
		return
	_index = (_index + delta + _catalog.size()) % _catalog.size()
	_name_label.text = _catalog_line()


func _catalog_line() -> String:
	var fw: Dictionary = _catalog[_index]
	return "%d / %d  ·  %s  ·  %s" % [
		_index + 1, _catalog.size(),
		String(fw.get("name", "?")),
		String(fw.get("category", "—")),
	]
