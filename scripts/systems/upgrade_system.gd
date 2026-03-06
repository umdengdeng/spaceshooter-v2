extends Node

signal level_up_occurred(char_id: String, new_level: int)

const MAX_LEVEL_BY_GRADE: Dictionary = {
	"N": 30, "R": 50, "SR": 70, "SSR": 90, "UR": 100,
}


func get_exp_needed(level: int) -> int:
	return level * 100


func get_max_level(grade: String) -> int:
	return int(MAX_LEVEL_BY_GRADE.get(grade, 30))


func get_stat_multiplier(level: int, stars: int, awakening: int) -> float:
	var level_mult: float = 1.0 + level * 0.05
	var star_mult: float = 1.0 + stars * 0.1
	var awaken_mult: float = 1.0 + awakening * 0.15
	return level_mult * star_mult * awaken_mult


func grant_battle_exp(amount: int) -> void:
	var save: Dictionary = SaveManager.data
	var preset_idx: int = int(save.get("active_preset", 0))
	var presets: Array = save.get("party_presets", []) as Array
	if presets.is_empty() or presets.size() <= preset_idx:
		return
	var party: Array = presets[preset_idx] as Array
	var owned: Dictionary = save.get("owned_characters", {}) as Dictionary
	for i: int in range(party.size()):
		var char_id: String = str(party[i])
		if char_id.is_empty() or not owned.has(char_id):
			continue
		_add_exp_to_char(char_id)
		_add_exp_amount(char_id, amount)


func _add_exp_to_char(_char_id: String) -> void:
	pass


func _add_exp_amount(char_id: String, amount: int) -> void:
	var save: Dictionary = SaveManager.data
	var owned: Dictionary = save.get("owned_characters", {}) as Dictionary
	if not owned.has(char_id):
		return
	var inst: Dictionary = owned[char_id] as Dictionary
	var char_data: Dictionary = CharacterDB.get_character(char_id)
	var grade: String = str(char_data.get("grade", "N"))
	var max_level: int = get_max_level(grade)
	var level: int = int(inst.get("level", 1))
	var cur_exp: int = int(inst.get("current_exp", 0))
	cur_exp += amount
	var needed: int = get_exp_needed(level)
	while cur_exp >= needed and level < max_level:
		cur_exp -= needed
		level += 1
		needed = get_exp_needed(level)
		level_up_occurred.emit(char_id, level)
	if level >= max_level:
		cur_exp = 0
	inst["level"] = level
	inst["current_exp"] = cur_exp


func try_star_upgrade(char_id: String) -> bool:
	var save: Dictionary = SaveManager.data
	var owned: Dictionary = save.get("owned_characters", {}) as Dictionary
	if not owned.has(char_id):
		return false
	var inst: Dictionary = owned[char_id] as Dictionary
	var stars: int = int(inst.get("stars", 0))
	if stars >= 5:
		return false
	var dupes_needed: int = stars + 1
	var dupes: int = int(inst.get("dupes", 0))
	if dupes < dupes_needed:
		return false
	inst["dupes"] = dupes - dupes_needed
	inst["stars"] = stars + 1
	SaveManager.save_game()
	return true


func get_star_upgrade_cost(char_id: String) -> int:
	var save: Dictionary = SaveManager.data
	var owned: Dictionary = save.get("owned_characters", {}) as Dictionary
	if not owned.has(char_id):
		return -1
	var inst: Dictionary = owned[char_id] as Dictionary
	var stars: int = int(inst.get("stars", 0))
	if stars >= 5:
		return -1
	return stars + 1


func try_awaken(char_id: String) -> bool:
	var save: Dictionary = SaveManager.data
	var owned: Dictionary = save.get("owned_characters", {}) as Dictionary
	if not owned.has(char_id):
		return false
	var inst: Dictionary = owned[char_id] as Dictionary
	var awakening: int = int(inst.get("awakening", 0))
	if awakening >= 5:
		return false
	var cost: int = (awakening + 1) * 50
	var char_data: Dictionary = CharacterDB.get_character(char_id)
	var elem: String = str(char_data.get("element", "fire"))
	var stones_dict: Dictionary = save.get("awakening_stones", {}) as Dictionary
	var current_stones: int = int(stones_dict.get(elem, 0))
	if current_stones < cost:
		return false
	stones_dict[elem] = current_stones - cost
	save["awakening_stones"] = stones_dict
	inst["awakening"] = awakening + 1
	SaveManager.save_game()
	return true


func get_awaken_cost(char_id: String) -> int:
	var save: Dictionary = SaveManager.data
	var owned: Dictionary = save.get("owned_characters", {}) as Dictionary
	if not owned.has(char_id):
		return -1
	var inst: Dictionary = owned[char_id] as Dictionary
	var awakening: int = int(inst.get("awakening", 0))
	if awakening >= 5:
		return -1
	return (awakening + 1) * 50
