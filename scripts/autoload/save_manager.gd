extends Node

const SAVE_PATH: String = "user://save_data.json"

var data: Dictionary = {}


func _ready() -> void:
	load_game()


func get_default_data() -> Dictionary:
	var default_data: Dictionary = {
		"gold": 1000,
		"diamond": 300,
		"stage": 1,
		"current_exp": 0,
		"tutorial_completed": false,
		"owned_characters": {
			"fire_n_01": {"level": 1, "current_exp": 0, "stars": 1, "awakening": 0, "dupes": 0},
		},
		"party_presets": [
			["fire_n_01", "", ""],
			["", "", ""],
			["", "", ""],
		],
		"active_preset": 0,
		"gacha_pity_ssr": 0,
		"gacha_pity_ur": 0,
		"awakening_stones": {"fire": 0, "water": 0, "wind": 0, "light": 0, "dark": 0},
		"shop_awakening_purchases": {"fire": 0, "water": 0, "wind": 0, "light": 0, "dark": 0},
		"dungeon_story_progress": 1,
		"dungeon_story_stars": {},
		"dungeon_story_entries": 0,
		"dungeon_awakening_entries": 0,
		"last_reset_date": "",
	}
	return default_data


func save_game() -> void:
	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		var json_string: String = JSON.stringify(data)
		file.store_string(json_string)
		file.close()


func load_game() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.READ)
		if file:
			var json_string: String = file.get_as_text()
			file.close()
			var json: JSON = JSON.new()
			var parse_result: Error = json.parse(json_string)
			if parse_result == OK:
				data = json.data as Dictionary
			else:
				data = get_default_data()
		else:
			data = get_default_data()
	else:
		data = get_default_data()
		save_game()
	_ensure_fields()
	_check_daily_reset()


func _check_daily_reset() -> void:
	var today: String = Time.get_date_string_from_system()
	var last_reset: String = str(data.get("last_reset_date", ""))
	if last_reset != today:
		data["last_reset_date"] = today
		data["shop_awakening_purchases"] = {"fire": 0, "water": 0, "wind": 0, "light": 0, "dark": 0}
		data["dungeon_story_entries"] = 0
		data["dungeon_awakening_entries"] = 0
		save_game()


func _ensure_fields() -> void:
	var defaults: Dictionary = get_default_data()
	for key: String in defaults:
		if not data.has(key):
			data[key] = defaults[key]
