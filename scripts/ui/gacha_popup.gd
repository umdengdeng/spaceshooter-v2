extends Panel

signal closed

var _main_container: VBoxContainer = null
var _result_container: VBoxContainer = null
var _anim_container: CenterContainer = null
var _info_label: Label = null
var _card_grid: GridContainer = null
var _pending_results: Array = []
var _reveal_index: int = 0
var _is_animating: bool = false
var _skip_pressed: bool = false

const GRADE_COLORS: Dictionary = {
	"N": Color(0.6, 0.6, 0.6),
	"R": Color(0.3, 0.7, 1.0),
	"SR": Color(0.2, 0.5, 1.0),
	"SSR": Color(1.0, 0.85, 0.0),
	"UR": Color(1.0, 0.3, 0.8),
}


func _ready() -> void:
	_build_ui()
	_show_main_screen()


func _build_ui() -> void:
	var margin: MarginContainer = MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 30)
	margin.add_theme_constant_override("margin_right", 30)
	margin.add_theme_constant_override("margin_top", 30)
	margin.add_theme_constant_override("margin_bottom", 30)
	add_child(margin)

	var root_vbox: VBoxContainer = VBoxContainer.new()
	root_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_child(root_vbox)

	var title_bar: HBoxContainer = HBoxContainer.new()
	root_vbox.add_child(title_bar)

	var title_label: Label = Label.new()
	title_label.text = "Gacha"
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_label.add_theme_font_size_override("font_size", 40)
	title_bar.add_child(title_label)

	var close_btn: Button = Button.new()
	close_btn.text = "X"
	close_btn.custom_minimum_size = Vector2(70, 50)
	close_btn.pressed.connect(_on_close)
	title_bar.add_child(close_btn)

	var spacer: Control = Control.new()
	spacer.custom_minimum_size = Vector2(0, 20)
	root_vbox.add_child(spacer)

	_main_container = VBoxContainer.new()
	_main_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root_vbox.add_child(_main_container)

	_anim_container = CenterContainer.new()
	_anim_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_anim_container.visible = false
	root_vbox.add_child(_anim_container)

	_result_container = VBoxContainer.new()
	_result_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_result_container.visible = false
	root_vbox.add_child(_result_container)


func _show_main_screen() -> void:
	_main_container.visible = true
	_anim_container.visible = false
	_result_container.visible = false
	for child: Node in _main_container.get_children():
		child.queue_free()

	var save: Dictionary = SaveManager.data
	var pity_ssr: int = int(save.get("gacha_pity_ssr", 0))
	var pity_ur: int = int(save.get("gacha_pity_ur", 0))
	var diamonds: int = int(save.get("diamond", 0))

	_info_label = Label.new()
	_info_label.text = "Diamonds: " + str(diamonds)
	_info_label.add_theme_font_size_override("font_size", 28)
	_main_container.add_child(_info_label)

	var spacer1: Control = Control.new()
	spacer1.custom_minimum_size = Vector2(0, 10)
	_main_container.add_child(spacer1)

	var rates_label: Label = Label.new()
	rates_label.text = "Rates: N 60% | R 25% | SR 10% | SSR 4% | UR 1%"
	rates_label.add_theme_font_size_override("font_size", 20)
	rates_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_main_container.add_child(rates_label)

	var pity_label: Label = Label.new()
	pity_label.text = "Pity - SSR: " + str(pity_ssr) + "/80  |  UR: " + str(pity_ur) + "/200"
	pity_label.add_theme_font_size_override("font_size", 20)
	_main_container.add_child(pity_label)

	var spacer2: Control = Control.new()
	spacer2.custom_minimum_size = Vector2(0, 40)
	_main_container.add_child(spacer2)

	var center: CenterContainer = CenterContainer.new()
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_main_container.add_child(center)

	var btn_box: VBoxContainer = VBoxContainer.new()
	btn_box.add_theme_constant_override("separation", 30)
	center.add_child(btn_box)

	var pull1_btn: Button = Button.new()
	pull1_btn.text = "Pull x1  (300 Diamonds)"
	pull1_btn.custom_minimum_size = Vector2(500, 80)
	pull1_btn.add_theme_font_size_override("font_size", 28)
	pull1_btn.pressed.connect(_on_pull_1)
	btn_box.add_child(pull1_btn)

	var pull10_btn: Button = Button.new()
	pull10_btn.text = "Pull x10  (2700 Diamonds)"
	pull10_btn.custom_minimum_size = Vector2(500, 80)
	pull10_btn.add_theme_font_size_override("font_size", 28)
	pull10_btn.pressed.connect(_on_pull_10)
	btn_box.add_child(pull10_btn)


func _on_pull_1() -> void:
	if _is_animating:
		return
	var result: Dictionary = GachaSystem.pull_single()
	if result.is_empty():
		_flash_message("Not enough diamonds!")
		return
	_pending_results = [result]
	_reveal_index = 0
	_skip_pressed = false
	_start_reveal()


func _on_pull_10() -> void:
	if _is_animating:
		return
	var results: Array = GachaSystem.pull_ten()
	if results.is_empty():
		_flash_message("Not enough diamonds!")
		return
	_pending_results = results
	_reveal_index = 0
	_skip_pressed = false
	_start_reveal()


func _flash_message(msg: String) -> void:
	var lbl: Label = Label.new()
	lbl.text = msg
	lbl.add_theme_font_size_override("font_size", 30)
	lbl.add_theme_color_override("font_color", Color.RED)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_main_container.add_child(lbl)
	var tw: Tween = create_tween()
	tw.tween_interval(1.5)
	tw.tween_property(lbl, "modulate:a", 0.0, 0.5)
	tw.tween_callback(lbl.queue_free)


func _start_reveal() -> void:
	_is_animating = true
	_main_container.visible = false
	_result_container.visible = false
	_anim_container.visible = true
	_reveal_next()


func _reveal_next() -> void:
	if _reveal_index >= _pending_results.size() or _skip_pressed:
		_show_result_screen()
		return
	for child: Node in _anim_container.get_children():
		child.queue_free()
	var char_data: Dictionary = _pending_results[_reveal_index] as Dictionary
	var grade: String = char_data.get("grade", "N") as String
	var card: PanelContainer = _create_reveal_card(char_data)
	card.scale = Vector2(0.0, 1.0)
	card.pivot_offset = Vector2(200, 250)
	_anim_container.add_child(card)

	var flip_duration: float = _get_flip_duration(grade)
	var tw: Tween = create_tween()
	tw.tween_property(card, "scale:x", 1.0, flip_duration).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

	if grade == "SSR":
		tw.tween_callback(_add_gold_particles.bind(card))
		tw.tween_callback(_add_card_shake.bind(card))
	elif grade == "UR":
		tw.tween_callback(_add_rainbow_effect.bind(card))
		tw.tween_callback(_add_card_shake.bind(card))

	tw.tween_interval(0.8)
	tw.tween_callback(_on_card_revealed)

	if _pending_results.size() > 1:
		var skip_btn: Button = Button.new()
		skip_btn.text = "SKIP"
		skip_btn.position = Vector2(350, 450)
		skip_btn.custom_minimum_size = Vector2(100, 50)
		skip_btn.pressed.connect(_on_skip)
		_anim_container.add_child(skip_btn)


func _get_flip_duration(grade: String) -> float:
	match grade:
		"SSR":
			return 0.6
		"UR":
			return 0.8
		_:
			return 0.3


func _create_reveal_card(char_data: Dictionary) -> PanelContainer:
	var card: PanelContainer = PanelContainer.new()
	card.custom_minimum_size = Vector2(400, 500)

	var style: StyleBoxFlat = StyleBoxFlat.new()
	var grade: String = char_data.get("grade", "N") as String
	var grade_color: Color = GRADE_COLORS.get(grade, Color.GRAY) as Color
	style.bg_color = Color(0.12, 0.12, 0.18, 1.0)
	style.border_color = grade_color
	style.set_border_width_all(4)
	style.set_corner_radius_all(12)
	card.add_theme_stylebox_override("panel", style)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 15)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	card.add_child(vbox)

	var grade_label: Label = Label.new()
	grade_label.text = grade
	grade_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	grade_label.add_theme_font_size_override("font_size", 50)
	grade_label.add_theme_color_override("font_color", grade_color)
	vbox.add_child(grade_label)

	var name_label: Label = Label.new()
	name_label.text = char_data.get("name", "???") as String
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 32)
	vbox.add_child(name_label)

	var element_label: Label = Label.new()
	element_label.text = str(char_data.get("element", ""))
	element_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	element_label.add_theme_font_size_override("font_size", 24)
	vbox.add_child(element_label)

	var weapon_label: Label = Label.new()
	weapon_label.text = str(char_data.get("weapon_type", ""))
	weapon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	weapon_label.add_theme_font_size_override("font_size", 20)
	weapon_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	vbox.add_child(weapon_label)

	var save: Dictionary = SaveManager.data
	var owned: Dictionary = save.get("owned_characters", {}) as Dictionary
	var char_id: String = str(char_data.get("id", ""))
	var is_new: bool = not owned.has(char_id)
	if not is_new:
		var info: Dictionary = owned[char_id] as Dictionary
		var dupes: int = int(info.get("dupes", 0))
		if dupes > 0:
			is_new = false

	var status_label: Label = Label.new()
	if is_new:
		status_label.text = "NEW!"
		status_label.add_theme_color_override("font_color", Color.YELLOW)
	else:
		status_label.text = "Duplicate"
		status_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.add_theme_font_size_override("font_size", 26)
	vbox.add_child(status_label)

	return card


func _add_gold_particles(card: PanelContainer) -> void:
	for i: int in range(6):
		var particle: ColorRect = ColorRect.new()
		particle.color = Color(1.0, 0.85, 0.0, 0.8)
		particle.size = Vector2(8, 8)
		particle.position = Vector2(randf_range(20, 380), randf_range(20, 480))
		card.add_child(particle)
		var tw: Tween = create_tween()
		tw.tween_property(particle, "position:y", particle.position.y - 60.0, 0.8)
		tw.parallel().tween_property(particle, "modulate:a", 0.0, 0.8)
		tw.tween_callback(particle.queue_free)


func _add_rainbow_effect(card: PanelContainer) -> void:
	var rainbow_colors: Array = [Color.RED, Color.ORANGE, Color.YELLOW, Color.GREEN, Color.CYAN, Color.BLUE, Color.PURPLE]
	for i: int in range(10):
		var particle: ColorRect = ColorRect.new()
		var c_idx: int = i % rainbow_colors.size()
		particle.color = rainbow_colors[c_idx] as Color
		particle.size = Vector2(10, 10)
		particle.position = Vector2(randf_range(10, 390), randf_range(10, 490))
		card.add_child(particle)
		var tw: Tween = create_tween()
		tw.tween_property(particle, "position:y", particle.position.y - 80.0, 1.0)
		tw.parallel().tween_property(particle, "modulate:a", 0.0, 1.0)
		tw.tween_callback(particle.queue_free)


func _add_card_shake(card: PanelContainer) -> void:
	card.pivot_offset = card.size / 2.0
	var shake_tw: Tween = create_tween()
	for _i: int in range(5):
		shake_tw.tween_property(card, "rotation", deg_to_rad(3.0), 0.04)
		shake_tw.tween_property(card, "rotation", deg_to_rad(-3.0), 0.04)
	shake_tw.tween_property(card, "rotation", 0.0, 0.04)


func _on_card_revealed() -> void:
	_reveal_index += 1
	_reveal_next()


func _on_skip() -> void:
	_skip_pressed = true


func _show_result_screen() -> void:
	_is_animating = false
	_anim_container.visible = false
	_result_container.visible = true
	for child: Node in _result_container.get_children():
		child.queue_free()

	var title: Label = Label.new()
	title.text = "Results"
	title.add_theme_font_size_override("font_size", 36)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_result_container.add_child(title)

	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_result_container.add_child(scroll)

	_card_grid = GridContainer.new()
	_card_grid.columns = 5
	_card_grid.add_theme_constant_override("h_separation", 10)
	_card_grid.add_theme_constant_override("v_separation", 10)
	_card_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_card_grid)

	for r: Variant in _pending_results:
		var rd: Dictionary = r as Dictionary
		var mini_card: PanelContainer = _create_mini_card(rd)
		_card_grid.add_child(mini_card)

	var spacer: Control = Control.new()
	spacer.custom_minimum_size = Vector2(0, 20)
	_result_container.add_child(spacer)

	var ok_btn: Button = Button.new()
	ok_btn.text = "OK"
	ok_btn.custom_minimum_size = Vector2(200, 60)
	ok_btn.add_theme_font_size_override("font_size", 28)
	ok_btn.pressed.connect(_on_result_ok)
	var center: CenterContainer = CenterContainer.new()
	center.add_child(ok_btn)
	_result_container.add_child(center)


func _create_mini_card(char_data: Dictionary) -> PanelContainer:
	var card: PanelContainer = PanelContainer.new()
	card.custom_minimum_size = Vector2(170, 130)

	var style: StyleBoxFlat = StyleBoxFlat.new()
	var grade: String = char_data.get("grade", "N") as String
	var grade_color: Color = GRADE_COLORS.get(grade, Color.GRAY) as Color
	style.bg_color = Color(0.1, 0.1, 0.15, 1.0)
	style.border_color = grade_color
	style.set_border_width_all(3)
	style.set_corner_radius_all(6)
	card.add_theme_stylebox_override("panel", style)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	card.add_child(vbox)

	var grade_lbl: Label = Label.new()
	grade_lbl.text = grade
	grade_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	grade_lbl.add_theme_font_size_override("font_size", 22)
	grade_lbl.add_theme_color_override("font_color", grade_color)
	vbox.add_child(grade_lbl)

	var name_lbl: Label = Label.new()
	name_lbl.text = char_data.get("name", "???") as String
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_size_override("font_size", 16)
	name_lbl.clip_text = true
	name_lbl.custom_minimum_size = Vector2(160, 0)
	vbox.add_child(name_lbl)

	var elem_lbl: Label = Label.new()
	elem_lbl.text = str(char_data.get("element", ""))
	elem_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	elem_lbl.add_theme_font_size_override("font_size", 14)
	vbox.add_child(elem_lbl)

	return card


func _on_result_ok() -> void:
	_pending_results.clear()
	_show_main_screen()


func _on_close() -> void:
	closed.emit()
	queue_free()
