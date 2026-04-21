extends Control
class_name ZoneBackground

## Stage 2 atmospheric stub: sky gradient + sparse stars + a zone-specific
## silhouette strip drawn with primitives. Replaces the old flat ColorRect
## behind every screen so the world reads through the (92% opaque) panels.
## Real pixel art lands in a later pass.

const NIGHT_DEEP := Color(0.039, 0.063, 0.157)    # #0A1028
const NIGHT_NEAR := Color(0.165, 0.188, 0.333)    # #2A3055
const SILHOUETTE := Color(0.020, 0.031, 0.082)    # #050815
const STAR_COLOR := Color(0.960, 0.902, 0.816, 0.55)

# Optional warm horizon tint per zone (low → no glow, high → urban light).
const HORIZON_BY_ZONE := {
	1: Color(0, 0, 0, 0),
	2: Color(0.12, 0.09, 0.14, 0.35),
	3: Color(0.20, 0.12, 0.08, 0.45),
	4: Color(0.28, 0.15, 0.08, 0.55),
	5: Color(0.32, 0.17, 0.09, 0.60),
	6: Color(0.38, 0.19, 0.09, 0.65),
}

@export var zone_id: int = 0:
	set(value):
		zone_id = value
		queue_redraw()


func _ready() -> void:
	anchor_right = 1.0
	anchor_bottom = 1.0
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)


func _draw() -> void:
	var w: float = size.x
	var h: float = size.y
	_draw_sky(w, h)
	_draw_stars(w, h)
	_draw_horizon(w, h)
	_draw_silhouette(w, h)


func _draw_sky(w: float, h: float) -> void:
	# Approximation of a vertical gradient via thin banded rects.
	var bands: int = 24
	for i in bands:
		var t: float = float(i) / float(bands)
		var col: Color = NIGHT_DEEP.lerp(NIGHT_NEAR, t)
		draw_rect(Rect2(0, t * h, w, h / bands + 1), col)


func _draw_stars(w: float, h: float) -> void:
	# Deterministic star layout — seed by zone so it's stable between redraws.
	var rng := RandomNumberGenerator.new()
	rng.seed = maxi(zone_id, 1) * 7919 + 11
	for i in 24:
		var x: float = rng.randf_range(4.0, w - 4.0)
		var y: float = rng.randf_range(8.0, h * 0.45)
		draw_rect(Rect2(x, y, 1.0, 1.0), STAR_COLOR)


func _draw_horizon(w: float, h: float) -> void:
	var tint: Color = HORIZON_BY_ZONE.get(zone_id, Color(0, 0, 0, 0))
	if tint.a <= 0.01:
		return
	var y: float = h * 0.73
	var strip_height: float = 30.0
	var bands: int = 8
	for i in bands:
		var t: float = float(i) / float(bands)
		var band_col: Color = tint
		band_col.a *= 1.0 - t
		draw_rect(Rect2(0, y + t * strip_height, w, strip_height / bands + 1), band_col)


func _draw_silhouette(w: float, h: float) -> void:
	var ground_y: float = h * 0.78
	draw_rect(Rect2(0, ground_y, w, h - ground_y), SILHOUETTE)
	match zone_id:
		1: _draw_backyard(w, ground_y)
		2: _draw_neighborhood(w, ground_y)
		3: _draw_town(w, ground_y)
		4: _draw_city(w, ground_y)
		5: _draw_regional(w, ground_y)
		6: _draw_world(w, ground_y)
		_: pass


func _draw_backyard(w: float, ground_y: float) -> void:
	# Tree silhouette on the left: trunk + crown (triangle).
	var trunk_x: float = w * 0.12
	draw_rect(Rect2(trunk_x - 4, ground_y - 40, 8, 40), SILHOUETTE)
	var crown: PackedVector2Array = [
		Vector2(trunk_x - 40, ground_y - 40),
		Vector2(trunk_x, ground_y - 120),
		Vector2(trunk_x + 40, ground_y - 40),
	]
	draw_colored_polygon(crown, SILHOUETTE)

	# House: rectangle + triangular roof on the right.
	var house_x: float = w * 0.75
	draw_rect(Rect2(house_x, ground_y - 90, 160, 90), SILHOUETTE)
	var roof: PackedVector2Array = [
		Vector2(house_x - 10, ground_y - 90),
		Vector2(house_x + 80, ground_y - 160),
		Vector2(house_x + 170, ground_y - 90),
	]
	draw_colored_polygon(roof, SILHOUETTE)

	# Fence line (small vertical posts).
	for i in 14:
		var fx: float = w * 0.25 + i * 40
		draw_rect(Rect2(fx, ground_y - 18, 3, 18), SILHOUETTE)


func _draw_neighborhood(w: float, ground_y: float) -> void:
	var x: float = w * 0.08
	for heights in [90, 120, 70, 110, 95, 130, 85]:
		draw_rect(Rect2(x, ground_y - heights, 110, heights), SILHOUETTE)
		var roof: PackedVector2Array = [
			Vector2(x - 6, ground_y - heights),
			Vector2(x + 55, ground_y - heights - 30),
			Vector2(x + 116, ground_y - heights),
		]
		draw_colored_polygon(roof, SILHOUETTE)
		x += 128
	# Streetlamp
	draw_rect(Rect2(w * 0.55, ground_y - 80, 3, 80), SILHOUETTE)
	draw_rect(Rect2(w * 0.55 - 10, ground_y - 80, 23, 4), SILHOUETTE)


func _draw_town(w: float, ground_y: float) -> void:
	# Civic building (domed, center)
	var cx: float = w * 0.5
	draw_rect(Rect2(cx - 120, ground_y - 140, 240, 140), SILHOUETTE)
	# Dome approximated by a triangle
	var dome: PackedVector2Array = [
		Vector2(cx - 80, ground_y - 140),
		Vector2(cx, ground_y - 200),
		Vector2(cx + 80, ground_y - 140),
	]
	draw_colored_polygon(dome, SILHOUETTE)
	# Steeple on left
	draw_rect(Rect2(w * 0.15, ground_y - 140, 60, 140), SILHOUETTE)
	var steeple: PackedVector2Array = [
		Vector2(w * 0.15, ground_y - 140),
		Vector2(w * 0.15 + 30, ground_y - 220),
		Vector2(w * 0.15 + 60, ground_y - 140),
	]
	draw_colored_polygon(steeple, SILHOUETTE)
	# Rowhouses on right
	var x: float = w * 0.72
	for heights in [80, 100, 90, 110]:
		draw_rect(Rect2(x, ground_y - heights, 70, heights), SILHOUETTE)
		x += 74


func _draw_city(w: float, ground_y: float) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 4001
	var x: float = 0.0
	while x < w:
		var bw: float = rng.randf_range(40.0, 90.0)
		var bh: float = rng.randf_range(120.0, 300.0)
		draw_rect(Rect2(x, ground_y - bh, bw, bh), SILHOUETTE)
		# Simulated lit windows (dim ochre) for city feel
		for row in int(bh / 24.0):
			for col in int(bw / 18.0):
				if rng.randf() < 0.18:
					var lit_color := Color(1.0, 0.84, 0.0, 0.35)
					draw_rect(Rect2(x + col * 18 + 5, ground_y - bh + row * 24 + 6, 4, 4), lit_color)
		x += bw + rng.randf_range(2.0, 6.0)


func _draw_regional(w: float, ground_y: float) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 5001
	var x: float = 0.0
	while x < w:
		var bw: float = rng.randf_range(50.0, 140.0)
		var bh: float = rng.randf_range(180.0, 420.0)
		draw_rect(Rect2(x, ground_y - bh, bw, bh), SILHOUETTE)
		# Antenna on some
		if rng.randf() < 0.35:
			draw_rect(Rect2(x + bw * 0.5 - 1, ground_y - bh - 30, 2, 30), SILHOUETTE)
		for row in int(bh / 22.0):
			for col in int(bw / 16.0):
				if rng.randf() < 0.22:
					var lit_color := Color(1.0, 0.84, 0.0, 0.35)
					draw_rect(Rect2(x + col * 16 + 4, ground_y - bh + row * 22 + 5, 3, 3), lit_color)
		x += bw + rng.randf_range(2.0, 5.0)


func _draw_world(w: float, ground_y: float) -> void:
	# Stadium silhouette center, skyline behind.
	var rng := RandomNumberGenerator.new()
	rng.seed = 6001
	var x: float = 0.0
	while x < w:
		var bw: float = rng.randf_range(45.0, 110.0)
		var bh: float = rng.randf_range(150.0, 350.0)
		draw_rect(Rect2(x, ground_y - bh, bw, bh), SILHOUETTE)
		x += bw + rng.randf_range(2.0, 6.0)

	var cx: float = w * 0.5
	var base_y: float = ground_y
	var dome_top: float = ground_y - 220
	var stadium_w: float = 520.0
	var left: float = cx - stadium_w * 0.5
	draw_rect(Rect2(left, ground_y - 140, stadium_w, 140), SILHOUETTE)
	# Arched top — 5 triangles to approximate curvature.
	var steps: int = 5
	for i in steps:
		var t0: float = float(i) / float(steps)
		var t1: float = float(i + 1) / float(steps)
		var x0: float = left + t0 * stadium_w
		var x1: float = left + t1 * stadium_w
		var arc0: float = sin(t0 * PI)
		var arc1: float = sin(t1 * PI)
		var y0: float = base_y - 140 - arc0 * 80
		var y1: float = base_y - 140 - arc1 * 80
		var tri: PackedVector2Array = [
			Vector2(x0, base_y - 140),
			Vector2(x0, y0),
			Vector2(x1, y1),
			Vector2(x1, base_y - 140),
		]
		draw_colored_polygon(tri, SILHOUETTE)
	# Flag pole
	draw_rect(Rect2(cx - 1, dome_top - 40, 2, 40), SILHOUETTE)
