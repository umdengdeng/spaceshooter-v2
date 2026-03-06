extends Area2D

signal unit_died

var element: String = "fire"
var max_hp: float = 100.0
var current_hp: float = 100.0
var element_color: Color = Color.RED
var shoot_cooldown: float = 0.3
var shoot_elapsed: float = 0.0
var atk: float = 50.0
var crit_rate: float = 0.1
var is_invincible: bool = false
var is_dead: bool = false
var weapon_type: String = "straight"

const ELEMENT_COLORS: Dictionary = {
	"fire": Color(1, 0.2, 0.1),
	"water": Color(0.1, 0.4, 1),
	"wind": Color(0.1, 0.9, 0.3),
	"light": Color(1, 0.9, 0.2),
	"dark": Color(0.6, 0.1, 0.9),
}

var bullet_scene: PackedScene = preload("res://scenes/battle/bullet.tscn")

@onready var ship_shape: Polygon2D = $ShipShape
@onready var hp_bar: ProgressBar = $HPBar


func _ready() -> void:
	_apply_element()


func setup(p_element: String) -> void:
	element = p_element
	if ship_shape:
		_apply_element()


func setup_from_data(char_data: Dictionary, inst_data: Dictionary) -> void:
	element = str(char_data.get("element", "fire"))
	weapon_type = str(char_data.get("weapon_type", "straight"))
	var base: Dictionary = char_data.get("base_stats", {}) as Dictionary
	var level: int = int(inst_data.get("level", 1))
	var stars: int = int(inst_data.get("stars", 0))
	var awakening: int = int(inst_data.get("awakening", 0))
	var stat_mult: float = UpgradeSystem.get_stat_multiplier(level, stars, awakening)
	atk = float(base.get("atk", 50)) * stat_mult
	max_hp = float(base.get("hp", 100)) * stat_mult
	current_hp = max_hp
	crit_rate = float(base.get("crit_rate", 0.05))
	match weapon_type:
		"straight":
			shoot_cooldown = 0.3
		"double":
			shoot_cooldown = 0.35
		"spread":
			shoot_cooldown = 0.4
		"homing":
			shoot_cooldown = 0.5
		"laser":
			shoot_cooldown = 0.08
	if ship_shape:
		_apply_element()
	if hp_bar:
		hp_bar.value = 100.0


func _apply_element() -> void:
	element_color = ELEMENT_COLORS.get(element, Color.RED)
	ship_shape.color = element_color
	queue_redraw()


func _draw() -> void:
	if is_dead:
		return
	draw_circle(Vector2(0.0, 25.0), 14.0, Color(element_color.r, element_color.g, element_color.b, 0.25))
	draw_circle(Vector2(0.0, 30.0), 7.0, Color(element_color.r, element_color.g, element_color.b, 0.45))
	draw_circle(Vector2.ZERO, 38.0, Color(element_color.r, element_color.g, element_color.b, 0.1))
	draw_circle(Vector2.ZERO, 24.0, Color(element_color.r, element_color.g, element_color.b, 0.18))


func _process(delta: float) -> void:
	if is_dead:
		return
	shoot_elapsed += delta
	if shoot_elapsed >= shoot_cooldown:
		shoot_elapsed = 0.0
		_shoot()


func _shoot() -> void:
	match weapon_type:
		"straight":
			_fire_bullet(Vector2.UP, 800.0, false, false)
		"double":
			_fire_bullet(Vector2(-0.12, -1.0).normalized(), 800.0, false, false)
			_fire_bullet(Vector2(0.12, -1.0).normalized(), 800.0, false, false)
		"spread":
			_fire_bullet(Vector2.UP, 800.0, false, false)
			_fire_bullet(Vector2(-0.35, -1.0).normalized(), 750.0, false, false)
			_fire_bullet(Vector2(0.35, -1.0).normalized(), 750.0, false, false)
		"homing":
			_fire_bullet(Vector2.UP, 400.0, true, false)
		"laser":
			_fire_bullet(Vector2.UP, 1200.0, false, true)


func _fire_bullet(dir: Vector2, spd: float, homing: bool, piercing: bool) -> void:
	var bullet: Area2D = bullet_scene.instantiate()
	bullet.position = position + Vector2(0, -35)
	bullet.bullet_color = element_color
	bullet.atk = atk
	bullet.element = element
	bullet.crit_rate = crit_rate
	bullet.direction = dir
	bullet.speed = spd
	bullet.is_homing = homing
	bullet.is_piercing = piercing
	get_parent().add_child(bullet)
	bullet.add_to_group("battle")


func take_character_damage(amount: float) -> void:
	if is_invincible or is_dead:
		return
	current_hp = maxf(current_hp - amount, 0.0)
	hp_bar.value = (current_hp / max_hp) * 100.0
	if current_hp <= 0.0:
		_on_death()
	else:
		_start_invincibility()


func _on_death() -> void:
	is_dead = true
	visible = false
	collision_layer = 0
	unit_died.emit()


func revive() -> void:
	is_dead = false
	current_hp = max_hp
	hp_bar.value = 100.0
	visible = true
	collision_layer = 8
	modulate.a = 1.0
	is_invincible = false
	shoot_elapsed = 0.0


func _start_invincibility() -> void:
	is_invincible = true
	var tween: Tween = create_tween()
	tween.set_loops(5)
	tween.tween_property(self, "modulate:a", 0.3, 0.05)
	tween.tween_property(self, "modulate:a", 1.0, 0.05)
	tween.tween_callback(_end_invincibility)


func _end_invincibility() -> void:
	is_invincible = false
	modulate.a = 1.0
