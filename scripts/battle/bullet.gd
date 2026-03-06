extends Area2D

const ADVANTAGE: Dictionary = {
	"fire": "wind",
	"wind": "water",
	"water": "fire",
	"light": "dark",
	"dark": "light",
}

var speed: float = 800.0
var bullet_color: Color = Color.WHITE
var atk: float = 50.0
var element: String = "fire"
var crit_rate: float = 0.1
var has_hit: bool = false
var direction: Vector2 = Vector2.UP
var is_homing: bool = false
var is_piercing: bool = false

@onready var polygon: Polygon2D = $Polygon2D


func _ready() -> void:
	polygon.color = bullet_color
	if is_piercing:
		polygon.polygon = PackedVector2Array([-2, -15, 2, -15, 2, 15, -2, 15])
	queue_redraw()


func _draw() -> void:
	draw_circle(Vector2.ZERO, 10.0, Color(bullet_color.r, bullet_color.g, bullet_color.b, 0.15))
	draw_circle(Vector2.ZERO, 6.0, Color(bullet_color.r, bullet_color.g, bullet_color.b, 0.25))


func _process(delta: float) -> void:
	if is_homing:
		var nearest: Node2D = _find_nearest_enemy()
		if nearest and is_instance_valid(nearest):
			var target_dir: Vector2 = (nearest.position - position).normalized()
			direction = direction.lerp(target_dir, 0.08).normalized()
	position += direction * speed * delta
	if position.y < -50.0 or position.y > 2000.0 or position.x < -100.0 or position.x > 1180.0:
		queue_free()


func _find_nearest_enemy() -> Node2D:
	var nearest: Node2D = null
	var min_dist: float = 999999.0
	for node: Node in get_tree().get_nodes_in_group("enemy"):
		if node is Node2D:
			var dist: float = position.distance_squared_to((node as Node2D).position)
			if dist < min_dist:
				min_dist = dist
				nearest = node as Node2D
	return nearest


func _on_area_entered(area: Area2D) -> void:
	if has_hit and not is_piercing:
		return
	if not area.has_method("take_damage"):
		return
	if not is_piercing:
		has_hit = true

	var multiplier: float = _get_element_multiplier(element, area.element)
	var is_crit: bool = randf() < crit_rate
	var damage: float = atk * multiplier
	if is_crit:
		damage *= 1.5
	var final_damage: int = maxi(int(damage), 1)
	area.take_damage(final_damage, is_crit)
	if not is_piercing:
		queue_free()


func _get_element_multiplier(attacker_elem: String, defender_elem: String) -> float:
	if ADVANTAGE.get(attacker_elem) == defender_elem:
		return 1.3
	elif ADVANTAGE.get(defender_elem) == attacker_elem:
		return 0.7
	return 1.0
