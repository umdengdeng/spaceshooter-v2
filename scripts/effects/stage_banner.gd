extends Label


func setup(stage_num: int, is_boss: bool) -> void:
	if is_boss:
		text = "BOSS Stage " + str(stage_num)
		add_theme_color_override("font_color", Color.RED)
		add_theme_font_size_override("font_size", 72)
	else:
		text = "Stage " + str(stage_num)
		add_theme_color_override("font_color", Color.WHITE)
		add_theme_font_size_override("font_size", 64)

	position = Vector2(140.0, 860.0)
	size = Vector2(800.0, 200.0)
	horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	pivot_offset = size / 2.0
	scale = Vector2(0.3, 0.3)

	var tween: Tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.3, 1.3), 0.25).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.15)

	if is_boss:
		var base_x: float = position.x
		for i: int in range(4):
			tween.tween_property(self, "position:x", base_x + 15.0, 0.04)
			tween.tween_property(self, "position:x", base_x - 15.0, 0.04)
		tween.tween_property(self, "position:x", base_x, 0.04)

	tween.tween_interval(2.0)
	tween.tween_property(self, "modulate:a", 0.0, 0.5)
	tween.tween_callback(queue_free)
