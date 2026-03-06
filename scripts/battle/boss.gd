extends Area2D

signal died

const ELEMENT_COLORS: Dictionary = {
	"fire": Color(1, 0.2, 0.1),
	"water": Color(0.1, 0.4, 1),
	"wind": Color(0.1, 0.9, 0.3),
	"light": Color(1, 0.9, 0.2),
	"dark": Color(0.6, 0.1, 0.9),
}

var element: String = "fire"
var max_hp: float = 2000.0
var current_hp: float = 2000.0
var speed: float = 80.0
var direction: float = 1.0
var element_color: Color = Color.RED
var boss_atk: float = 30.0
var target_y: float = 250.0
var hp_multiplier: float = 1.0
var has_arrived: bool = false

var damage_number_scene: PackedScene = preload("res://scenes/effects/damage_number.tscn")
var explosion_scene: PackedScene = preload("res://scenes/effects/explosion.tscn")

@onready var boss_shape: Polygon2D = $BossShape


func _ready() -> void:
	add_to_group("enemy")
	max_hp = 2000.0 * hp_multiplier
	current_hp = max_hp
	element_color = ELEMENT_COLORS.get(element, Color.RED)
	boss_shape.color = element_color


func _process(delta: float) -> void:
	if not has_arrived:
		position.y += 100.0 * delta
		if position.y >= target_y:
			position.y = target_y
			has_arrived = true
	else:
		position.x += speed * direction * delta
		if position.x > 880.0:
			direction = -1.0
		elif position.x < 200.0:
			direction = 1.0


func take_damage(amount: int, is_crit: bool) -> void:
	if current_hp <= 0.0:
		return
	current_hp -= float(amount)
	_spawn_damage_number(amount, is_crit)
	if current_hp <= 0.0:
		_die()


func _spawn_damage_number(amount: int, is_crit: bool) -> void:
	var dmg_num: Label = damage_number_scene.instantiate()
	get_parent().add_child(dmg_num)
	dmg_num.setup(amount, is_crit, position + Vector2(0, -80))


func _die() -> void:
	var current_gold: int = int(SaveManager.data.get("gold", 0))
	SaveManager.data["gold"] = current_gold + 100
	GameManager.gold_changed.emit(SaveManager.data["gold"])

	var current_diamond: int = int(SaveManager.data.get("diamond", 0))
	SaveManager.data["diamond"] = current_diamond + 50
	GameManager.diamond_changed.emit(SaveManager.data["diamond"])
	UpgradeSystem.grant_battle_exp(500)

	var boom: Node2D = explosion_scene.instantiate()
	boom.position = position
	get_parent().add_child(boom)
	boom.setup(element_color)

	GameManager.enemy_killed.emit()
	died.emit()
	queue_free()


func _draw() -> void:
	draw_circle(Vector2.ZERO, 35.0, Color(element_color.r, element_color.g, element_color.b, 0.12))
	draw_circle(Vector2.ZERO, 22.0, Color(element_color.r, element_color.g, element_color.b, 0.2))


func _on_area_entered(area: Area2D) -> void:
	if area.has_method("take_character_damage"):
		area.take_character_damage(boss_atk)
