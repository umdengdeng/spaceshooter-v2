extends Control

var character_popup_scene: PackedScene = preload("res://scenes/ui/character_popup.tscn")
var gacha_popup_scene: PackedScene = preload("res://scenes/ui/gacha_popup.tscn")
var shop_popup_scene: PackedScene = preload("res://scenes/ui/shop_popup.tscn")
var dungeon_popup_scene: PackedScene = preload("res://scenes/ui/dungeon_popup.tscn")

var is_in_dungeon: bool = false
var dungeon_battle_node: Node = null
var _tutorial_active: bool = false
var _tutorial_layer: CanvasLayer = null
var _combo_count: int = 0
var _combo_timer: float = 0.0
var _combo_label: Label = null

@onready var stage_label: Label = %StageLabel
@onready var gold_label: Label = %GoldLabel
@onready var diamond_label: Label = %DiamondLabel
@onready var popup_panel: Panel = %PopupPanel
@onready var popup_title_label: Label = %PopupTitleLabel
@onready var player_party: Node2D = %PlayerParty
@onready var auto_button: Button = %AutoButton
@onready var stage_system: Node = %StageSystem
@onready var boss_hp_bar: ProgressBar = %BossHPBar
@onready var popup_layer: CanvasLayer = %PopupLayer

var current_boss: Area2D = null


func _ready() -> void:
	popup_panel.visible = false
	boss_hp_bar.visible = false
	player_party.auto_changed.connect(_on_auto_changed)
	player_party.party_wiped.connect(_on_party_wiped)
	stage_system.stage_changed.connect(_on_stage_changed)
	stage_system.boss_spawned.connect(_on_boss_spawned)
	stage_system.boss_defeated.connect(_on_boss_defeated)
	GameManager.gold_changed.connect(_on_gold_changed)
	GameManager.diamond_changed.connect(_on_diamond_changed)
	GameManager.enemy_killed.connect(_on_enemy_killed)
	UpgradeSystem.level_up_occurred.connect(_on_level_up)
	_setup_star_background()
	_setup_combo_label()
	_update_ui()
	_check_tutorial.call_deferred()


func _setup_star_background() -> void:
	var star_bg: Control = Control.new()
	star_bg.set_script(preload("res://scripts/effects/star_background.gd"))
	star_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	star_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(star_bg)
	move_child(star_bg, 1)


func _setup_combo_label() -> void:
	_combo_label = Label.new()
	_combo_label.position = Vector2(750.0, 150.0)
	_combo_label.size = Vector2(300.0, 60.0)
	_combo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_combo_label.visible = false
	_combo_label.add_theme_font_size_override("font_size", 32)
	add_child(_combo_label)


func _update_ui() -> void:
	var save_data: Dictionary = SaveManager.data
	stage_label.text = "Stage " + str(save_data.get("stage", 1))
	gold_label.text = "Gold: " + str(save_data.get("gold", 0))
	diamond_label.text = "💎: " + str(save_data.get("diamond", 0))


func _process(delta: float) -> void:
	if current_boss and is_instance_valid(current_boss):
		boss_hp_bar.value = (current_boss.current_hp / current_boss.max_hp) * 100.0
	elif boss_hp_bar.visible:
		boss_hp_bar.visible = false
	if _combo_timer > 0.0:
		_combo_timer -= delta
		if _combo_timer <= 0.0:
			_combo_count = 0
			_combo_label.visible = false


# ---- Tutorial ----

func _check_tutorial() -> void:
	var save: Dictionary = SaveManager.data
	if bool(save.get("tutorial_completed", false)):
		return
	var stage: int = int(save.get("stage", 1))
	var owned: Dictionary = save.get("owned_characters", {}) as Dictionary
	if stage > 1 or owned.size() > 1:
		save["tutorial_completed"] = true
		SaveManager.save_game()
		return
	_start_tutorial()


func _start_tutorial() -> void:
	_tutorial_active = true
	_tutorial_layer = CanvasLayer.new()
	_tutorial_layer.layer = 30
	_tutorial_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_tutorial_layer)
	_show_tutorial_msg("Drag the screen to move your ship!")


func _show_tutorial_msg(msg: String) -> void:
	if not _tutorial_layer or not is_instance_valid(_tutorial_layer):
		return
	for child: Node in _tutorial_layer.get_children():
		child.queue_free()
	var bg: ColorRect = ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.0, 0.0, 0.0, 0.4)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tutorial_layer.add_child(bg)
	var lbl: Label = Label.new()
	lbl.text = msg
	lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
	lbl.offset_top = 700.0
	lbl.offset_bottom = 900.0
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 34)
	lbl.add_theme_color_override("font_color", Color.WHITE)
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_tutorial_layer.add_child(lbl)
	var tw: Tween = create_tween()
	tw.tween_interval(3.5)
	tw.tween_property(bg, "modulate:a", 0.0, 0.5)
	tw.parallel().tween_property(lbl, "modulate:a", 0.0, 0.5)
	tw.tween_callback(bg.queue_free)
	tw.tween_callback(lbl.queue_free)


func _handle_tutorial_stage(stage_num: int) -> void:
	if stage_num == 3:
		_grant_tutorial_char("water_n_01")
		_show_tutorial_msg("New ally obtained!\nOpen Character to form your party!")
		_blink_character_button()
	elif stage_num == 4:
		_grant_tutorial_char("wind_n_01")
		_show_tutorial_msg("Party of 3 complete!\nGood luck, Commander!")
		_complete_tutorial()


func _grant_tutorial_char(char_id: String) -> void:
	var save: Dictionary = SaveManager.data
	var owned: Dictionary = save.get("owned_characters", {}) as Dictionary
	if not owned.has(char_id):
		owned[char_id] = {"level": 1, "current_exp": 0, "stars": 1, "awakening": 0, "dupes": 0}
		save["owned_characters"] = owned
		SaveManager.save_game()


func _blink_character_button() -> void:
	var char_btn: Node = get_node_or_null("BottomUI/BottomBar/CharacterButton")
	if not char_btn:
		return
	var tw: Tween = create_tween()
	tw.set_loops(6)
	tw.tween_property(char_btn, "modulate:a", 0.3, 0.3)
	tw.tween_property(char_btn, "modulate:a", 1.0, 0.3)


func _complete_tutorial() -> void:
	_tutorial_active = false
	SaveManager.data["tutorial_completed"] = true
	SaveManager.save_game()
	if _tutorial_layer and is_instance_valid(_tutorial_layer):
		var tw: Tween = create_tween()
		tw.tween_interval(5.0)
		tw.tween_callback(_remove_tutorial_layer)


func _remove_tutorial_layer() -> void:
	if _tutorial_layer and is_instance_valid(_tutorial_layer):
		_tutorial_layer.queue_free()
		_tutorial_layer = null


# ---- Combo ----

func _on_enemy_killed() -> void:
	_combo_count += 1
	_combo_timer = 2.0
	_update_combo_display()
	if _combo_count >= 2:
		var bonus_gold: int = _combo_count
		var save: Dictionary = SaveManager.data
		save["gold"] = int(save.get("gold", 0)) + bonus_gold
		GameManager.gold_changed.emit(int(save["gold"]))


func _update_combo_display() -> void:
	if _combo_count < 2:
		_combo_label.visible = false
		return
	_combo_label.visible = true
	_combo_label.text = "x" + str(_combo_count) + " COMBO!"
	if _combo_count >= 10:
		_combo_label.add_theme_font_size_override("font_size", 44)
		_combo_label.add_theme_color_override("font_color", Color.RED)
	elif _combo_count >= 5:
		_combo_label.add_theme_font_size_override("font_size", 38)
		_combo_label.add_theme_color_override("font_color", Color.YELLOW)
	else:
		_combo_label.add_theme_font_size_override("font_size", 32)
		_combo_label.add_theme_color_override("font_color", Color.WHITE)


# ---- Popups ----

func _open_popup(title: String) -> void:
	if GameManager.is_popup_open:
		return
	popup_title_label.text = title
	popup_panel.visible = true
	GameManager.open_popup()


func _close_popup() -> void:
	popup_panel.visible = false
	GameManager.close_popup()


func _on_character_button_pressed() -> void:
	if GameManager.is_popup_open:
		return
	var popup: Panel = character_popup_scene.instantiate()
	popup.closed.connect(_on_character_popup_closed)
	popup_layer.add_child(popup)
	GameManager.open_popup()


func _on_character_popup_closed() -> void:
	GameManager.close_popup()
	player_party.reload_party()
	_update_ui()


func _on_gacha_popup_closed() -> void:
	GameManager.close_popup()
	_update_ui()


func _on_shop_button_pressed() -> void:
	if GameManager.is_popup_open:
		return
	var popup: Panel = shop_popup_scene.instantiate()
	popup.closed.connect(_on_shop_popup_closed)
	popup_layer.add_child(popup)
	GameManager.open_popup()


func _on_gacha_button_pressed() -> void:
	if GameManager.is_popup_open:
		return
	var popup: Panel = gacha_popup_scene.instantiate()
	popup.closed.connect(_on_gacha_popup_closed)
	popup_layer.add_child(popup)
	GameManager.open_popup()


func _on_shop_popup_closed() -> void:
	GameManager.close_popup()
	_update_ui()


func _on_dungeon_button_pressed() -> void:
	if GameManager.is_popup_open:
		return
	var popup: Panel = dungeon_popup_scene.instantiate()
	popup.closed.connect(_on_dungeon_popup_closed)
	popup.dungeon_entered.connect(_on_dungeon_entered)
	popup_layer.add_child(popup)
	GameManager.open_popup()


func _on_close_button_pressed() -> void:
	_close_popup()


func _on_auto_button_pressed() -> void:
	player_party.toggle_auto()


func _on_auto_changed(is_on: bool) -> void:
	auto_button.text = "AUTO ON" if is_on else "AUTO"


func _on_gold_changed(total: int) -> void:
	gold_label.text = "Gold: " + str(total)


func _on_diamond_changed(total: int) -> void:
	diamond_label.text = "💎: " + str(total)


func _on_stage_changed(stage_num: int) -> void:
	stage_label.text = "Stage " + str(stage_num)
	if _tutorial_active:
		_handle_tutorial_stage(stage_num)


func _on_boss_spawned(boss_ref: Area2D) -> void:
	current_boss = boss_ref
	boss_hp_bar.visible = true
	boss_hp_bar.value = 100.0
	_flash_boss_warning()


func _flash_boss_warning() -> void:
	var flash: ColorRect = ColorRect.new()
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash.color = Color(1.0, 0.0, 0.0, 0.3)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(flash)
	var tw: Tween = create_tween()
	tw.set_loops(3)
	tw.tween_property(flash, "color:a", 0.0, 0.1)
	tw.tween_property(flash, "color:a", 0.3, 0.1)
	tw.tween_callback(flash.queue_free)


func _on_boss_defeated() -> void:
	current_boss = null
	boss_hp_bar.visible = false


func _on_party_wiped() -> void:
	if is_in_dungeon:
		_on_dungeon_party_wiped()
		return
	stage_system.restart_stage()
	current_boss = null
	boss_hp_bar.visible = false

	var banner: Label = Label.new()
	banner.text = "Game Over"
	banner.position = Vector2(140.0, 800.0)
	banner.size = Vector2(800.0, 300.0)
	banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	banner.add_theme_font_size_override("font_size", 72)
	banner.add_theme_color_override("font_color", Color.RED)
	add_child(banner)

	var tween: Tween = create_tween()
	tween.tween_interval(2.0)
	tween.tween_property(banner, "modulate:a", 0.0, 0.5)
	tween.tween_callback(banner.queue_free)
	tween.tween_callback(_restart_after_wipe)


func _restart_after_wipe() -> void:
	player_party.revive_all()
	stage_system.resume_stage()


# ---- Dungeon ----

func _on_dungeon_popup_closed() -> void:
	GameManager.close_popup()
	_update_ui()


func _on_dungeon_entered(config: Dictionary) -> void:
	GameManager.close_popup()
	is_in_dungeon = true
	stage_system.enter_dungeon_mode()

	var battle: Node = Node.new()
	battle.set_script(preload("res://scripts/battle/dungeon_battle.gd"))
	dungeon_battle_node = battle
	add_child(battle)

	var dtype: String = str(config.get("type", "story"))
	if dtype == "story":
		battle.setup_story(int(config.get("stage", 1)))
	else:
		battle.setup_awakening(str(config.get("element", "fire")), int(config.get("difficulty", 0)))

	battle.dungeon_completed.connect(_on_dungeon_completed)
	battle.start()


func _on_dungeon_party_wiped() -> void:
	if dungeon_battle_node and is_instance_valid(dungeon_battle_node):
		dungeon_battle_node.fail()


func _on_dungeon_completed(results: Dictionary) -> void:
	is_in_dungeon = false
	if dungeon_battle_node and is_instance_valid(dungeon_battle_node):
		dungeon_battle_node.queue_free()
		dungeon_battle_node = null

	for node: Node in get_tree().get_nodes_in_group("enemy"):
		node.queue_free()

	var success: bool = results.get("success", false) as bool

	if success:
		_apply_dungeon_rewards(results)

	_show_dungeon_result(results)


func _apply_dungeon_rewards(results: Dictionary) -> void:
	var dtype: String = str(results.get("dungeon_type", "story"))
	var save: Dictionary = SaveManager.data

	if dtype == "story":
		var stage: int = int(results.get("stage_num", 1))
		var gold_reward: int = 200 + stage * 50
		var diamond_reward: int = 20 + stage * 5
		var exp_reward: int = 100 + stage * 30

		save["gold"] = int(save.get("gold", 0)) + gold_reward
		save["diamond"] = int(save.get("diamond", 0)) + diamond_reward
		GameManager.gold_changed.emit(int(save["gold"]))
		GameManager.diamond_changed.emit(int(save["diamond"]))
		UpgradeSystem.grant_battle_exp(exp_reward)

		var total_hp: float = player_party.leader_unit.current_hp + player_party.left_unit.current_hp + player_party.right_unit.current_hp
		var max_total_hp: float = player_party.leader_unit.max_hp + player_party.left_unit.max_hp + player_party.right_unit.max_hp
		var hp_ratio: float = total_hp / maxf(max_total_hp, 1.0)
		var star_rating: int = 1
		if hp_ratio >= 1.0:
			star_rating = 3
		elif hp_ratio >= 0.5:
			star_rating = 2

		var progress: int = int(save.get("dungeon_story_progress", 1))
		if stage >= progress:
			save["dungeon_story_progress"] = stage + 1

		var stars_data: Dictionary = save.get("dungeon_story_stars", {}) as Dictionary
		var old_stars: int = int(stars_data.get(str(stage), 0))
		if star_rating > old_stars:
			stars_data[str(stage)] = star_rating
			save["dungeon_story_stars"] = stars_data

	elif dtype == "awakening":
		var elem: String = str(results.get("element", "fire"))
		var diff: int = int(results.get("difficulty", 0))
		var stone_min: int = 3
		var stone_max: int = 5
		match diff:
			1:
				stone_min = 5
				stone_max = 10
			2:
				stone_min = 10
				stone_max = 20
		var stone_reward: int = randi_range(stone_min, stone_max)
		var stones: Dictionary = save.get("awakening_stones", {}) as Dictionary
		stones[elem] = int(stones.get(elem, 0)) + stone_reward
		save["awakening_stones"] = stones

	SaveManager.save_game()


func _show_dungeon_result(results: Dictionary) -> void:
	var success: bool = results.get("success", false) as bool
	var panel: PanelContainer = PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(600, 400)
	panel.position = Vector2(-300, -200)

	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.15, 0.95)
	style.set_border_width_all(3)
	style.border_color = Color.GREEN if success else Color.RED
	style.set_corner_radius_all(12)
	panel.add_theme_stylebox_override("panel", style)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 15)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(vbox)

	var title: Label = Label.new()
	title.text = "CLEAR!" if success else "FAILED"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 44)
	title.add_theme_color_override("font_color", Color.GREEN if success else Color.RED)
	vbox.add_child(title)

	if success:
		var dtype: String = str(results.get("dungeon_type", "story"))
		var detail: Label = Label.new()
		if dtype == "story":
			var stage: int = int(results.get("stage_num", 1))
			detail.text = "Stage " + str(stage) + " Clear!\nRewards applied."
		else:
			detail.text = "Awakening Dungeon Clear!\nStones obtained."
		detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		detail.add_theme_font_size_override("font_size", 24)
		vbox.add_child(detail)

	var ok_btn: Button = Button.new()
	ok_btn.text = "OK"
	ok_btn.custom_minimum_size = Vector2(200, 60)
	ok_btn.add_theme_font_size_override("font_size", 28)
	ok_btn.pressed.connect(_on_dungeon_result_ok.bind(panel))
	var center: CenterContainer = CenterContainer.new()
	center.add_child(ok_btn)
	vbox.add_child(center)

	popup_layer.add_child(panel)
	GameManager.open_popup()


func _on_dungeon_result_ok(panel: PanelContainer) -> void:
	panel.queue_free()
	GameManager.close_popup()
	player_party.revive_all()
	stage_system.exit_dungeon_mode()
	_update_ui()


func _on_level_up(_char_id: String, new_level: int) -> void:
	var banner: Label = Label.new()
	banner.text = "LEVEL UP! Lv." + str(new_level)
	banner.position = Vector2(140.0, 700.0)
	banner.size = Vector2(800.0, 100.0)
	banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	banner.add_theme_font_size_override("font_size", 40)
	banner.add_theme_color_override("font_color", Color.YELLOW)
	add_child(banner)
	var tw: Tween = create_tween()
	tw.tween_property(banner, "position:y", 650.0, 0.5)
	tw.tween_interval(0.8)
	tw.tween_property(banner, "modulate:a", 0.0, 0.3)
	tw.tween_callback(banner.queue_free)
