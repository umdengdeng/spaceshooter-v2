extends Node2D


func setup(color: Color) -> void:
	var circle: Polygon2D = $Circle
	circle.color = color
	_spawn_particles(color)


func _ready() -> void:
	var tween: Tween = create_tween()
	tween.tween_property(self, "scale", Vector2(3.0, 3.0), 0.3)
	tween.parallel().tween_property(self, "modulate:a", 0.0, 0.3)
	tween.tween_callback(queue_free)


func _spawn_particles(color: Color) -> void:
	for i: int in range(10):
		var p: ColorRect = ColorRect.new()
		p.size = Vector2(6.0, 6.0)
		p.color = color
		add_child(p)
		var angle: float = (float(i) / 10.0) * TAU
		var dist: float = randf_range(40.0, 90.0)
		var target: Vector2 = Vector2(cos(angle), sin(angle)) * dist
		var tw: Tween = create_tween()
		tw.tween_property(p, "position", target, 0.35).set_ease(Tween.EASE_OUT)
		tw.parallel().tween_property(p, "modulate:a", 0.0, 0.4)
		tw.tween_callback(p.queue_free)
