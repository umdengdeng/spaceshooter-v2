extends Label


func setup(amount: int, is_crit: bool, pos: Vector2) -> void:
	position = pos
	if is_crit:
		text = str(amount) + "!"
		add_theme_font_size_override("font_size", 32)
		add_theme_color_override("font_color", Color.YELLOW)
	else:
		text = str(amount)
		add_theme_font_size_override("font_size", 20)
		add_theme_color_override("font_color", Color.WHITE)

	var tween: Tween = create_tween()
	tween.tween_property(self, "position:y", position.y - 60.0, 1.0)
	tween.parallel().tween_property(self, "modulate:a", 0.0, 1.0)
	tween.tween_callback(queue_free)
