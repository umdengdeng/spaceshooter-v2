extends Node

signal stage_changed(stage_num: int)
signal boss_spawned(boss_ref: Area2D)
signal boss_defeated

const ELEMENTS: Array[String] = ["fire", "water", "wind", "light", "dark"]

var current_stage: int = 1
var enemies_remaining: int = 0
var enemies_to_spawn: int = 0
var enemies_spawned: int = 0
var is_spawning: bool = false
var spawn_elapsed: float = 0.0
var spawn_interval: float = 1.5
var is_boss_stage: bool = false
var is_transitioning: bool = false
var in_dungeon: bool = false

var enemy_scene: PackedScene = preload("res://scenes/battle/enemy.tscn")
var boss_scene: PackedScene = preload("res://scenes/battle/boss.tscn")
var stage_banner_scene: PackedScene = preload("res://scenes/effects/stage_banner.tscn")


func _ready() -> void:
	current_stage = int(SaveManager.data.get("stage", 1))
	_start_stage.call_deferred()


func _process(delta: float) -> void:
	if in_dungeon:
		return
	if not is_spawning or is_transitioning:
		return
	if enemies_spawned >= enemies_to_spawn:
		is_spawning = false
		return
	spawn_elapsed += delta
	var interval: float = maxf(0.5, spawn_interval - current_stage * 0.02)
	if spawn_elapsed >= interval:
		spawn_elapsed = 0.0
		_spawn_one_enemy()


func _start_stage() -> void:
	is_transitioning = false
	is_boss_stage = current_stage % 10 == 0
	stage_changed.emit(current_stage)
	_show_stage_banner()

	if is_boss_stage:
		enemies_to_spawn = 0
		enemies_remaining = 1
		enemies_spawned = 0
		is_spawning = false
		_show_warning_then_boss()
	else:
		enemies_to_spawn = _calc_enemy_count()
		enemies_spawned = 0
		enemies_remaining = enemies_to_spawn
		is_spawning = true
		spawn_elapsed = 0.0
		spawn_interval = randf_range(1.0, 2.0)


func _calc_enemy_count() -> int:
	var count: int = 5 + (current_stage - 1) * 2
	return mini(count, 30)


func _get_hp_multiplier() -> float:
	return 1.0 + current_stage * 0.1


func _get_speed_multiplier() -> float:
	return 1.0 + current_stage * 0.02


func _get_type_roll() -> int:
	var fast_chance: float = minf(0.2 + current_stage * 0.01, 0.4)
	var tank_chance: float = minf(0.1 + current_stage * 0.005, 0.25)
	var roll: float = randf()
	if roll > 1.0 - tank_chance:
		return 2
	elif roll > 1.0 - tank_chance - fast_chance:
		return 1
	return 0


func _spawn_one_enemy() -> void:
	var enemy: Area2D = enemy_scene.instantiate()
	var rand_x: float = randf_range(60.0, 1020.0)
	enemy.position = Vector2(rand_x, -50.0)

	var enemy_type: int = _get_type_roll()
	var rand_element: String = ELEMENTS[randi() % ELEMENTS.size()]
	enemy.setup(enemy_type, rand_element)
	enemy.hp_multiplier = _get_hp_multiplier()
	enemy.speed_multiplier = _get_speed_multiplier()
	enemy.died.connect(_on_enemy_died)
	get_parent().add_child(enemy)
	enemies_spawned += 1


func _on_enemy_died() -> void:
	enemies_remaining -= 1
	if enemies_remaining <= 0:
		_stage_cleared()


func _stage_cleared() -> void:
	is_transitioning = true
	is_spawning = false
	current_stage += 1
	SaveManager.data["stage"] = current_stage
	SaveManager.save_game()

	var delay_tween: Tween = create_tween()
	delay_tween.tween_interval(1.5)
	delay_tween.tween_callback(_start_stage)


func _show_stage_banner() -> void:
	var banner: Label = stage_banner_scene.instantiate()
	get_parent().add_child(banner)
	banner.setup(current_stage, is_boss_stage)


func _show_warning_then_boss() -> void:
	var warning: Label = Label.new()
	warning.text = "⚠ WARNING ⚠"
	warning.position = Vector2(140.0, 860.0)
	warning.size = Vector2(800.0, 200.0)
	warning.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	warning.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	warning.add_theme_font_size_override("font_size", 52)
	warning.add_theme_color_override("font_color", Color.RED)
	get_parent().add_child(warning)

	var tween: Tween = create_tween()
	for i: int in range(3):
		tween.tween_property(warning, "modulate:a", 0.0, 0.15)
		tween.tween_property(warning, "modulate:a", 1.0, 0.18)
	tween.tween_callback(warning.queue_free)
	tween.tween_interval(0.5)
	tween.tween_callback(_spawn_boss)


func _spawn_boss() -> void:
	var boss: Area2D = boss_scene.instantiate()
	boss.position = Vector2(540.0, -100.0)
	var rand_element: String = ELEMENTS[randi() % ELEMENTS.size()]
	boss.element = rand_element
	boss.hp_multiplier = _get_hp_multiplier()
	boss.died.connect(_on_boss_died)
	get_parent().add_child(boss)
	boss_spawned.emit(boss)


func _on_boss_died() -> void:
	boss_defeated.emit()
	enemies_remaining = 0
	_stage_cleared()


func restart_stage() -> void:
	is_spawning = false
	is_transitioning = true
	enemies_spawned = 0
	enemies_remaining = 0
	_clear_enemies()


func resume_stage() -> void:
	_start_stage()


func _clear_enemies() -> void:
	for node: Node in get_tree().get_nodes_in_group("enemy"):
		node.queue_free()


func enter_dungeon_mode() -> void:
	in_dungeon = true
	is_spawning = false
	is_transitioning = true
	_clear_enemies()


func exit_dungeon_mode() -> void:
	in_dungeon = false
	_start_stage()
