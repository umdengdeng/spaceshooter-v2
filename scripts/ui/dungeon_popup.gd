extends Panel

signal closed
signal dungeon_entered(config: Dictionary)

const ELEMENT_NAMES: Dictionary = {
	"fire": "불", "water": "물", "wind": "풍", "light": "빛", "dark": "암흑",
}
const ELEMENTS: Array[String] = ["fire", "water", "wind", "light", "dark"]
const DIFFICULTY_NAMES: Array[String] = ["Beginner", "Intermediate", "Advanced"]

var _story_tab: Control = null
var _awakening_tab: Control = null
var _story_content: VBoxContainer = null
var _awakening_content: VBoxContainer = null


func _ready() -> void:
	_build_ui()
	_show_story_tab()


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
	root_vbox.add_theme_constant_override("separation", 10)
	margin.add_child(root_vbox)

	var title_bar: HBoxContainer = HBoxContainer.new()
	root_vbox.add_child(title_bar)
	var title: Label = Label.new()
	title.text = "Dungeon"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 36)
	title_bar.add_child(title)
	var close_btn: Button = Button.new()
	close_btn.text = "X"
	close_btn.custom_minimum_size = Vector2(70, 50)
	close_btn.pressed.connect(_on_close)
	title_bar.add_child(close_btn)

	var tab_bar: HBoxContainer = HBoxContainer.new()
	tab_bar.add_theme_constant_override("separation", 10)
	root_vbox.add_child(tab_bar)
	var story_btn: Button = Button.new()
	story_btn.text = "Story"
	story_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	story_btn.custom_minimum_size = Vector2(0, 50)
	story_btn.pressed.connect(_show_story_tab)
	tab_bar.add_child(story_btn)
	var awaken_btn: Button = Button.new()
	awaken_btn.text = "Awakening"
	awaken_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	awaken_btn.custom_minimum_size = Vector2(0, 50)
	awaken_btn.pressed.connect(_show_awakening_tab)
	tab_bar.add_child(awaken_btn)

	_story_tab = Control.new()
	_story_tab.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root_vbox.add_child(_story_tab)

	var story_scroll: ScrollContainer = ScrollContainer.new()
	story_scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	_story_tab.add_child(story_scroll)
	_story_content = VBoxContainer.new()
	_story_content.add_theme_constant_override("separation", 10)
	_story_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	story_scroll.add_child(_story_content)

	_awakening_tab = Control.new()
	_awakening_tab.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_awakening_tab.visible = false
	root_vbox.add_child(_awakening_tab)

	var awaken_scroll: ScrollContainer = ScrollContainer.new()
	awaken_scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	_awakening_tab.add_child(awaken_scroll)
	_awakening_content = VBoxContainer.new()
	_awakening_content.add_theme_constant_override("separation", 10)
	_awakening_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	awaken_scroll.add_child(_awakening_content)


func _show_story_tab() -> void:
	_story_tab.visible = true
	_awakening_tab.visible = false
	_refresh_story()


func _show_awakening_tab() -> void:
	_story_tab.visible = false
	_awakening_tab.visible = true
	_refresh_awakening()


func _refresh_story() -> void:
	for child: Node in _story_content.get_children():
		child.queue_free()

	var save: Dictionary = SaveManager.data
	var progress: int = int(save.get("dungeon_story_progress", 1))
	var stars_data: Dictionary = save.get("dungeon_story_stars", {}) as Dictionary
	var entries: int = int(save.get("dungeon_story_entries", 0))

	var entry_label: Label = Label.new()
	entry_label.text = "Daily entries: " + str(entries) + "/5"
	entry_label.add_theme_font_size_override("font_size", 22)
	_story_content.add_child(entry_label)

	for stage: int in range(1, progress + 1):
		var hbox: HBoxContainer = HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 10)
		_story_content.add_child(hbox)

		var stage_lbl: Label = Label.new()
		stage_lbl.text = "Stage " + str(stage)
		stage_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		stage_lbl.add_theme_font_size_override("font_size", 22)
		hbox.add_child(stage_lbl)

		var star_count: int = int(stars_data.get(str(stage), 0))
		var star_lbl: Label = Label.new()
		var star_text: String = ""
		for s: int in range(3):
			if s < star_count:
				star_text += "★"
			else:
				star_text += "☆"
		star_lbl.text = star_text
		star_lbl.add_theme_font_size_override("font_size", 22)
		star_lbl.add_theme_color_override("font_color", Color.YELLOW)
		hbox.add_child(star_lbl)

		var enter_btn: Button = Button.new()
		enter_btn.text = "Enter"
		enter_btn.custom_minimum_size = Vector2(100, 45)
		enter_btn.pressed.connect(_on_enter_story.bind(stage))
		if entries >= 5 or stage > progress:
			enter_btn.disabled = true
		hbox.add_child(enter_btn)

	if progress <= 20:
		var locked_lbl: Label = Label.new()
		locked_lbl.text = "Stage " + str(progress + 1) + " - Locked"
		locked_lbl.add_theme_font_size_override("font_size", 20)
		locked_lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		_story_content.add_child(locked_lbl)


func _refresh_awakening() -> void:
	for child: Node in _awakening_content.get_children():
		child.queue_free()

	var save: Dictionary = SaveManager.data
	var entries: int = int(save.get("dungeon_awakening_entries", 0))

	var entry_label: Label = Label.new()
	entry_label.text = "Daily entries: " + str(entries) + "/3"
	entry_label.add_theme_font_size_override("font_size", 22)
	_awakening_content.add_child(entry_label)

	for elem: String in ELEMENTS:
		var elem_label: Label = Label.new()
		elem_label.text = ELEMENT_NAMES.get(elem, elem) + " Awakening Dungeon"
		elem_label.add_theme_font_size_override("font_size", 24)
		elem_label.add_theme_color_override("font_color", Color(0.8, 0.8, 1.0))
		_awakening_content.add_child(elem_label)

		for diff: int in range(3):
			var hbox: HBoxContainer = HBoxContainer.new()
			hbox.add_theme_constant_override("separation", 10)
			_awakening_content.add_child(hbox)

			var diff_lbl: Label = Label.new()
			diff_lbl.text = "  " + DIFFICULTY_NAMES[diff]
			diff_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			diff_lbl.add_theme_font_size_override("font_size", 20)
			hbox.add_child(diff_lbl)

			var reward_lbl: Label = Label.new()
			match diff:
				0:
					reward_lbl.text = "3~5 stones"
				1:
					reward_lbl.text = "5~10 stones"
				2:
					reward_lbl.text = "10~20 stones"
			reward_lbl.add_theme_font_size_override("font_size", 18)
			reward_lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
			hbox.add_child(reward_lbl)

			var enter_btn: Button = Button.new()
			enter_btn.text = "Enter"
			enter_btn.custom_minimum_size = Vector2(100, 40)
			enter_btn.pressed.connect(_on_enter_awakening.bind(elem, diff))
			if entries >= 3:
				enter_btn.disabled = true
			hbox.add_child(enter_btn)


func _on_enter_story(stage: int) -> void:
	var save: Dictionary = SaveManager.data
	var entries: int = int(save.get("dungeon_story_entries", 0))
	if entries >= 5:
		return
	save["dungeon_story_entries"] = entries + 1
	SaveManager.save_game()
	var config: Dictionary = {"type": "story", "stage": stage}
	dungeon_entered.emit(config)
	queue_free()


func _on_enter_awakening(elem: String, diff: int) -> void:
	var save: Dictionary = SaveManager.data
	var entries: int = int(save.get("dungeon_awakening_entries", 0))
	if entries >= 3:
		return
	save["dungeon_awakening_entries"] = entries + 1
	SaveManager.save_game()
	var config: Dictionary = {"type": "awakening", "element": elem, "difficulty": diff}
	dungeon_entered.emit(config)
	queue_free()


func _on_close() -> void:
	closed.emit()
	queue_free()
