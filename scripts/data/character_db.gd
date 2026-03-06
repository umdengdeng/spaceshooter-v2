extends Node

var _data: Dictionary = {}
var _loaded: bool = false


func _ready() -> void:
	_ensure_loaded()


func _ensure_loaded() -> void:
	if _loaded:
		return
	var file: FileAccess = FileAccess.open("res://data/characters.json", FileAccess.READ)
	if file:
		var json: JSON = JSON.new()
		var err: Error = json.parse(file.get_as_text())
		file.close()
		if err == OK:
			var arr: Array = json.data as Array
			for entry: Variant in arr:
				var d: Dictionary = entry as Dictionary
				_data[str(d["id"])] = d
	_loaded = true


func get_character(id: String) -> Dictionary:
	_ensure_loaded()
	return _data.get(id, {}) as Dictionary


func get_all() -> Array:
	_ensure_loaded()
	return _data.values()


func get_all_ids() -> Array:
	_ensure_loaded()
	return _data.keys()
