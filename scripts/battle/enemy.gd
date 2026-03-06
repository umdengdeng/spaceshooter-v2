extends Area2D

signal died

const TYPE_NORMAL: int = 0
const TYPE_FAST: int = 1
const TYPE_TANK: int = 2

const ELEMENT_COLORS: Dictionary = {
	"fire": Color(1, 0.2, 0.1),
	"water": Color(0.1, 0.4, 1),
	"wind": Color(0.1, 0.9, 0.3),
	"light": Color(1, 0.9, 0.2),
	"dark": Color(0.6, 0.1, 0.9),
}

var enemy_type: int = TYPE_NORMAL
var element: String = "fire"
var max_hp: float = 100.0
var current_hp: float = 100.0
var speed: float = 150.0
var element_color: Color = Color.RED
var start_x: float = 0.0
var time_alive: float = 0.0
var enemy_atk: float = 15.0
var hp_multiplier: float = 1.0
var speed_multiplier: float = 1.0

var damage_number_scene: PackedScene = preload("res://scenes/effects/damage_number.tscn")
var explosion_scene: PackedScene = preload("res://scenes/effects/explosion.tscn")

@onready var enemy_shape: Polygon2D = $EnemyShape
@onready var hp_bar: ProgressBar = $HPBar


func setup(p_type: int, p_element: String) -> void:
	enemy_type = p_type
	element = p_element


func _ready() -> void:
	add_to_group("enemy")
	_apply_settings()


func _apply_settings() -> void:
	match enemy_type:
		TYPE_NORMAL:
			max_hp = 100.0 * hp_multiplier
			speed = 150.0 * speed_multiplier
			enemy_atk = 15.0
		TYPE_FAST:
			max_hp = 60.0 * hp_multiplier
			speed = 300.0 * speed_multiplier
			enemy_atk = 10.0
		TYPE_TANK:
			max_hp = 300.0 * hp_multiplier
			speed = 80.0 * speed_multiplier
			enemy_atk = 25.0
			scale = Vector2(1.5, 1.5)
	current_hp = max_hp
	element_color = ELEMENT_COLORS.get(element, Color.RED)
	enemy_shape.color = element_color
	start_x = position.x
	hp_bar.value = 100.0


func _process(delta: float) -> void:
	time_alive += delta
	position.y += speed * delta

	if enemy_type == TYPE_FAST:
		position.x = start_x + sin(time_alive * 4.0) * 100.0

	if position.y > 2000.0:
		died.emit()
		queue_free()


func take_damage(amount: int, is_crit: bool) -> void:
	if current_hp <= 0.0:
		return
	current_hp -= float(amount)
	hp_bar.value = (current_hp / max_hp) * 100.0
	_spawn_damage_number(amount, is_crit)
	if current_hp <= 0.0:
		_die()


func _spawn_damage_number(amount: int, is_crit: bool) -> void:
	var dmg_num: Label = damage_number_scene.instantiate()
	get_parent().add_child(dmg_num)
	dmg_num.setup(amount, is_crit, position + Vector2(0, -30))


func _die() -> void:
	var gold_reward: int = randi_range(10, 30)
	var current_gold: int = int(SaveManager.data.get("gold", 0))
	SaveManager.data["gold"] = current_gold + gold_reward
	GameManager.gold_changed.emit(SaveManager.data["gold"])
	var exp_reward: int = 15 + int(max_hp / 10.0)
	UpgradeSystem.grant_battle_exp(exp_reward)

	var boom: Node2D = explosion_scene.instantiate()
	boom.position = position
	get_parent().add_child(boom)
	boom.setup(element_color)

	GameManager.enemy_killed.emit()
	died.emit()
	queue_free()


func _draw() -> void:
	draw_circle(Vector2.ZERO, 32.0, Color(element_color.r, element_color.g, element_color.b, 0.12))
	draw_circle(Vector2.ZERO, 20.0, Color(element_color.r, element_color.g, element_color.b, 0.22))


func _on_area_entered(area: Area2D) -> void:
	if area.has_method("take_character_damage"):
		area.take_character_damage(enemy_atk)
