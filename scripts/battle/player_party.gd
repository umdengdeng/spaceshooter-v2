extends Node2D

signal auto_changed(is_on: bool)
signal party_wiped

const FORMATION_LEFT: Vector2 = Vector2(-120.0, 80.0)
const FORMATION_RIGHT: Vector2 = Vector2(120.0, 80.0)
const LERP_WEIGHT: float = 0.12
const AUTO_SPEED: float = 300.0
const SCREEN_WIDTH: float = 1080.0
const SCREEN_HEIGHT: float = 1920.0
const MARGIN: float = 40.0

@onready var leader_unit: Area2D = %LeaderUnit
@onready var left_unit: Area2D = %LeftUnit
@onready var right_unit: Area2D = %RightUnit

var is_dragging: bool = false
var is_auto: bool = false
var auto_direction: float = 1.0
var leader_target: Vector2 = Vector2(540.0, 1600.0)


func _ready() -> void:
	_load_party_from_save()
	leader_target = leader_unit.position
	leader_unit.unit_died.connect(_on_unit_died)
	left_unit.unit_died.connect(_on_unit_died)
	right_unit.unit_died.connect(_on_unit_died)


func _load_party_from_save() -> void:
	var preset_idx: int = int(SaveManager.data.get("active_preset", 0))
	var presets: Array = SaveManager.data.get("party_presets", []) as Array
	if presets.is_empty() or presets.size() <= preset_idx:
		leader_unit.setup("fire")
		left_unit.setup("water")
		right_unit.setup("wind")
		return
	var party: Array = presets[preset_idx] as Array
	if party.size() < 3:
		leader_unit.setup("fire")
		left_unit.setup("water")
		right_unit.setup("wind")
		return
	var units: Array[Area2D] = [leader_unit, left_unit, right_unit]
	var fallback_elements: Array[String] = ["fire", "water", "wind"]
	for i: int in range(3):
		var char_id: String = str(party[i])
		if char_id.is_empty():
			units[i].setup(fallback_elements[i])
			continue
		var char_data: Dictionary = CharacterDB.get_character(char_id)
		if char_data.is_empty():
			units[i].setup(fallback_elements[i])
			continue
		var owned: Dictionary = SaveManager.data.get("owned_characters", {}) as Dictionary
		var inst: Dictionary = owned.get(char_id, {}) as Dictionary
		units[i].setup_from_data(char_data, inst)


func reload_party() -> void:
	_load_party_from_save()


func _process(delta: float) -> void:
	if is_auto and not is_dragging:
		leader_target.x += AUTO_SPEED * auto_direction * delta
		if leader_target.x > SCREEN_WIDTH - MARGIN:
			leader_target.x = SCREEN_WIDTH - MARGIN
			auto_direction = -1.0
		elif leader_target.x < MARGIN:
			leader_target.x = MARGIN
			auto_direction = 1.0

	leader_unit.position = leader_target
	_clamp_unit(leader_unit)

	var target_left: Vector2 = leader_unit.position + FORMATION_LEFT
	var target_right: Vector2 = leader_unit.position + FORMATION_RIGHT

	left_unit.position = left_unit.position.lerp(target_left, LERP_WEIGHT)
	right_unit.position = right_unit.position.lerp(target_right, LERP_WEIGHT)
	_clamp_unit(left_unit)
	_clamp_unit(right_unit)


func _clamp_unit(unit: Area2D) -> void:
	unit.position.x = clampf(unit.position.x, MARGIN, SCREEN_WIDTH - MARGIN)
	unit.position.y = clampf(unit.position.y, MARGIN, SCREEN_HEIGHT - MARGIN)


func _unhandled_input(event: InputEvent) -> void:
	if GameManager.is_popup_open:
		return

	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				is_dragging = true
				if is_auto:
					is_auto = false
					auto_changed.emit(false)
				leader_target = mb.position
			else:
				is_dragging = false
	elif event is InputEventMouseMotion and is_dragging:
		var mm: InputEventMouseMotion = event as InputEventMouseMotion
		leader_target = mm.position


func toggle_auto() -> void:
	is_auto = !is_auto
	auto_changed.emit(is_auto)


func _on_unit_died() -> void:
	if leader_unit.is_dead and left_unit.is_dead and right_unit.is_dead:
		party_wiped.emit()


func revive_all() -> void:
	leader_unit.revive()
	left_unit.revive()
	right_unit.revive()
	leader_target = Vector2(540.0, 1600.0)
	leader_unit.position = leader_target
	left_unit.position = leader_target + FORMATION_LEFT
	right_unit.position = leader_target + FORMATION_RIGHT
