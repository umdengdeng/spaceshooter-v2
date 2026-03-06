extends Node

signal dungeon_completed(results: Dictionary)

var enemy_scene: PackedScene = preload("res://scenes/battle/enemy.tscn")
var stage_banner_scene: PackedScene = preload("res://scenes/effects/stage_banner.tscn")

var waves: Array = []
var current_wave: int = 0
var enemies_alive: int = 0
var total_enemies_killed: int = 0
var dungeon_type: String = "story"
var dungeon_element: String = "fire"
var difficulty: int = 0
var stage_num: int = 1
var is_active: bool = false


func setup_story(p_stage: int) -> void:
	stage_num = p_stage
	dungeon_type = "story"
	var hp_mult: float = 1.0 + p_stage * 0.2
	var spd_mult: float = 1.0 + p_stage * 0.03
	waves = []
	for w: int in range(3):
		var count: int = 5 + p_stage + w * 2
		waves.append({"count": mini(count, 15), "hp_mult": hp_mult, "spd_mult": spd_mult})


func setup_awakening(p_element: String, p_difficulty: int) -> void:
	dungeon_type = "awakening"
	dungeon_element = p_element
	difficulty = p_difficulty
	var hp_mult: float = 1.0 + p_difficulty * 0.5
	var spd_mult: float = 1.0 + p_difficulty * 0.1
	waves = []
	for w: int in range(2):
		var count: int = 5 + p_difficulty * 3 + w * 2
		waves.append({"count": mini(count, 12), "hp_mult": hp_mult, "spd_mult": spd_mult})


func start() -> void:
	is_active = true
	current_wave = 0
	total_enemies_killed = 0
	_start_wave()


func _start_wave() -> void:
	if current_wave >= waves.size():
		_on_dungeon_clear()
		return
	var wave_config: Dictionary = waves[current_wave] as Dictionary
	var count: int = int(wave_config.get("count", 5))
	enemies_alive = count
	for i: int in range(count):
		_spawn_enemy_delayed(i, wave_config)


func _spawn_enemy_delayed(index: int, wave_config: Dictionary) -> void:
	var tw: Tween = create_tween()
	tw.tween_interval(float(index) * 0.8)
	tw.tween_callback(_spawn_one.bind(wave_config))


func _spawn_one(wave_config: Dictionary) -> void:
	if not is_active:
		return
	var enemy: Area2D = enemy_scene.instantiate()
	var rand_x: float = randf_range(60.0, 1020.0)
	enemy.position = Vector2(rand_x, -50.0)
	var elements: Array[String] = ["fire", "water", "wind", "light", "dark"]
	var elem: String = ""
	if dungeon_type == "awakening":
		elem = dungeon_element
	else:
		elem = elements[randi() % elements.size()]
	var type_roll: int = randi() % 3
	if type_roll > 1:
		type_roll = 0
	enemy.setup(type_roll, elem)
	enemy.hp_multiplier = float(wave_config.get("hp_mult", 1.0))
	enemy.speed_multiplier = float(wave_config.get("spd_mult", 1.0))
	enemy.died.connect(_on_enemy_died)
	get_parent().add_child(enemy)


func _on_enemy_died() -> void:
	if not is_active:
		return
	enemies_alive -= 1
	total_enemies_killed += 1
	if enemies_alive <= 0:
		current_wave += 1
		var tw: Tween = create_tween()
		tw.tween_interval(1.0)
		tw.tween_callback(_start_wave)


func _on_dungeon_clear() -> void:
	is_active = false
	var results: Dictionary = {
		"success": true,
		"dungeon_type": dungeon_type,
		"element": dungeon_element,
		"difficulty": difficulty,
		"stage_num": stage_num,
		"enemies_killed": total_enemies_killed,
	}
	dungeon_completed.emit(results)


func fail() -> void:
	is_active = false
	for node: Node in get_tree().get_nodes_in_group("enemy"):
		node.queue_free()
	var results: Dictionary = {
		"success": false,
		"dungeon_type": dungeon_type,
		"element": dungeon_element,
		"difficulty": difficulty,
		"stage_num": stage_num,
		"enemies_killed": total_enemies_killed,
	}
	dungeon_completed.emit(results)
