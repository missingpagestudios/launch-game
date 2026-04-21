extends Node2D
class_name FireworkHost
## Optional host for FireworkField.
##
## FireworkField checks `host_ref.has_method(...)` before firing camera
## shake / screen flash / fade-to-black / completion callbacks, so this
## class's contract is just "implement these methods if you want the
## effect, skip them for a dry render".
##
## Embed pattern:
##   var field := load("res://scripts/fireworks/firework_field.gd").new()
##   var host := FireworkHost.new()
##   add_child(host)
##   add_child(field)
##   field.host_ref = host
##
## Sound effects are a future concern. When they land, each burst will
## route through `_emit_sfx(event, payload)` — leaving the hook in place
## now so the port doesn't need restructuring later.

signal show_completed

# Target node whose `position` we shake. Defaults to self.
var shake_target: Node2D = null
# Overlay color used for screen flash + fade-to-black. Lazily created
# at _ready because we don't know the viewport size before then.
var overlay: ColorRect = null

var _shake_remaining: float = 0.0
var _shake_strength: float = 0.0
var _shake_origin: Vector2 = Vector2.ZERO

var _flash_tween: Tween
var _fade_tween: Tween


func _ready() -> void:
	if shake_target == null:
		shake_target = self
	_shake_origin = shake_target.position
	overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0)
	overlay.anchor_right = 1.0
	overlay.anchor_bottom = 1.0
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var layer := CanvasLayer.new()
	layer.layer = 100
	add_child(layer)
	layer.add_child(overlay)


func _process(delta: float) -> void:
	if _shake_remaining > 0.0:
		_shake_remaining -= delta
		if _shake_remaining <= 0.0:
			shake_target.position = _shake_origin
			_shake_remaining = 0.0
			_shake_strength = 0.0
			return
		var t: float = clampf(_shake_remaining / 0.35, 0.0, 1.0)
		var amp: float = _shake_strength * t
		shake_target.position = _shake_origin + Vector2(
			randf_range(-amp, amp), randf_range(-amp * 0.6, amp * 0.6))


# --- FireworkField callbacks ------------------------------------------------

func request_shake(strength: float) -> void:
	_shake_strength = maxf(_shake_strength, strength)
	_shake_remaining = maxf(_shake_remaining, 0.35)


func start_screen_flash(peak: float, duration: float, color: Color = Color(1, 1, 1), bias: float = 1.0) -> void:
	if overlay == null:
		return
	if _flash_tween != null and _flash_tween.is_valid():
		_flash_tween.kill()
	overlay.color = Color(color.r, color.g, color.b, clampf(peak, 0.0, 1.0))
	_flash_tween = create_tween()
	# bias just tunes the falloff shape; keep the simple linear fade —
	# the curve detail lives in the demo's original work and isn't
	# critical for stage 2.
	_flash_tween.tween_property(overlay, "color:a", 0.0, duration)


func start_fade_to_black(duration: float) -> void:
	if overlay == null:
		return
	if _fade_tween != null and _fade_tween.is_valid():
		_fade_tween.kill()
	overlay.color = Color(0, 0, 0, 0)
	_fade_tween = create_tween()
	_fade_tween.tween_property(overlay, "color", Color(0, 0, 0, 1), duration)


func on_show_complete() -> void:
	show_completed.emit()


# --- Future audio hook ------------------------------------------------------
# FireworkField doesn't call this yet; we expose it so later burst code can
# fire `_emit_sfx("launch", id)` / `"crack"` / `"pop"` / `"finale"` etc. and
# a future AudioStreamPlayer manager picks it up.
func _emit_sfx(_event: String, _payload: Variant = null) -> void:
	pass
