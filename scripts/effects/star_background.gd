extends Control

var _stars_far: Array = []
var _stars_mid: Array = []
var _stars_near: Array = []
var _nebula_pos: Vector2 = Vector2(500.0, -200.0)
var _nebula_color: Color = Color(0.2, 0.1, 0.4, 0.04)


func _ready() -> void:
	for i: int in range(50):
		_stars_far.append(Vector2(randf_range(0.0, 1080.0), randf_range(0.0, 1920.0)))
	for i: int in range(35):
		_stars_mid.append(Vector2(randf_range(0.0, 1080.0), randf_range(0.0, 1920.0)))
	for i: int in range(20):
		_stars_near.append(Vector2(randf_range(0.0, 1080.0), randf_range(0.0, 1920.0)))


func _process(delta: float) -> void:
	_scroll_layer(_stars_far, 15.0 * delta)
	_scroll_layer(_stars_mid, 35.0 * delta)
	_scroll_layer(_stars_near, 60.0 * delta)
	_nebula_pos.y += 12.0 * delta
	if _nebula_pos.y > 2200.0:
		_nebula_pos = Vector2(randf_range(100.0, 980.0), -300.0)
		_nebula_color = Color(randf_range(0.1, 0.3), randf_range(0.05, 0.2), randf_range(0.2, 0.5), 0.03)
	queue_redraw()


func _scroll_layer(layer: Array, amount: float) -> void:
	for i: int in range(layer.size()):
		var star: Vector2 = layer[i] as Vector2
		star.y += amount
		if star.y > 1920.0:
			star = Vector2(randf_range(0.0, 1080.0), -5.0)
		layer[i] = star


func _draw() -> void:
	draw_circle(_nebula_pos, 180.0, _nebula_color)
	draw_circle(_nebula_pos, 100.0, Color(_nebula_color.r, _nebula_color.g, _nebula_color.b, _nebula_color.a * 1.5))
	for star: Variant in _stars_far:
		var s: Vector2 = star as Vector2
		draw_circle(s, 1.0, Color(0.5, 0.5, 0.6, 0.4))
	for star: Variant in _stars_mid:
		var s: Vector2 = star as Vector2
		draw_circle(s, 1.5, Color(0.7, 0.7, 0.8, 0.6))
	for star: Variant in _stars_near:
		var s: Vector2 = star as Vector2
		draw_circle(s, 2.5, Color(1.0, 1.0, 1.0, 0.85))
