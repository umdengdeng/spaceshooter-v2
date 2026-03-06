extends Node

const PULL_COST_1: int = 300
const PULL_COST_10: int = 2700

const RATE_N: float = 0.60
const RATE_R: float = 0.25
const RATE_SR: float = 0.10
const RATE_SSR: float = 0.04
const RATE_UR: float = 0.01

const PITY_SSR: int = 80
const PITY_UR: int = 200


func pull_single() -> Dictionary:
	var save: Dictionary = SaveManager.data
	var diamonds: int = int(save.get("diamond", 0))
	if diamonds < PULL_COST_1:
		return {}
	save["diamond"] = diamonds - PULL_COST_1
	GameManager.diamond_changed.emit(int(save["diamond"]))
	var result: Dictionary = _roll_one()
	_apply_result(result)
	SaveManager.save_game()
	return result


func pull_ten() -> Array:
	var save: Dictionary = SaveManager.data
	var diamonds: int = int(save.get("diamond", 0))
	if diamonds < PULL_COST_10:
		return []
	save["diamond"] = diamonds - PULL_COST_10
	GameManager.diamond_changed.emit(int(save["diamond"]))
	var results: Array = []
	var has_sr_plus: bool = false
	for i: int in range(10):
		var result: Dictionary = _roll_one()
		results.append(result)
		var grade: String = result.get("grade", "N") as String
		if grade == "SR" or grade == "SSR" or grade == "UR":
			has_sr_plus = true
	if not has_sr_plus:
		var guaranteed: Dictionary = _roll_guaranteed_sr_plus()
		results[9] = guaranteed
		_undo_pity_for(results[9])
	for r: Variant in results:
		var rd: Dictionary = r as Dictionary
		_apply_result(rd)
	SaveManager.save_game()
	return results


func _roll_one() -> Dictionary:
	var save: Dictionary = SaveManager.data
	var pity_ssr: int = int(save.get("gacha_pity_ssr", 0))
	var pity_ur: int = int(save.get("gacha_pity_ur", 0))
	pity_ssr += 1
	pity_ur += 1
	var grade: String = ""
	if pity_ur >= PITY_UR:
		grade = "UR"
		pity_ur = 0
		pity_ssr = 0
	elif pity_ssr >= PITY_SSR:
		grade = "SSR"
		pity_ssr = 0
	else:
		grade = _roll_grade()
		if grade == "SSR":
			pity_ssr = 0
		elif grade == "UR":
			pity_ssr = 0
			pity_ur = 0
	save["gacha_pity_ssr"] = pity_ssr
	save["gacha_pity_ur"] = pity_ur
	var char_data: Dictionary = _pick_character_of_grade(grade)
	return char_data


func _roll_grade() -> String:
	var roll: float = randf()
	if roll < RATE_UR:
		return "UR"
	elif roll < RATE_UR + RATE_SSR:
		return "SSR"
	elif roll < RATE_UR + RATE_SSR + RATE_SR:
		return "SR"
	elif roll < RATE_UR + RATE_SSR + RATE_SR + RATE_R:
		return "R"
	return "N"


func _roll_guaranteed_sr_plus() -> Dictionary:
	var roll: float = randf()
	var grade: String = ""
	if roll < 0.02:
		grade = "UR"
	elif roll < 0.10:
		grade = "SSR"
	else:
		grade = "SR"
	return _pick_character_of_grade(grade)


func _pick_character_of_grade(grade: String) -> Dictionary:
	var all_chars: Array = CharacterDB.get_all()
	var pool: Array = []
	for c: Variant in all_chars:
		var cd: Dictionary = c as Dictionary
		if cd.get("grade", "") == grade:
			pool.append(cd)
	if pool.is_empty():
		return {}
	var idx: int = randi() % pool.size()
	return pool[idx] as Dictionary


func _apply_result(char_data: Dictionary) -> void:
	if char_data.is_empty():
		return
	var char_id: String = str(char_data.get("id", ""))
	var save: Dictionary = SaveManager.data
	var owned: Dictionary = save.get("owned_characters", {}) as Dictionary
	if owned.has(char_id):
		var info: Dictionary = owned[char_id] as Dictionary
		var dupes: int = int(info.get("dupes", 0))
		info["dupes"] = dupes + 1
	else:
		owned[char_id] = {"level": 1, "current_exp": 0, "stars": 1, "awakening": 0, "dupes": 0}
	save["owned_characters"] = owned


func _undo_pity_for(char_data: Dictionary) -> void:
	var grade: String = char_data.get("grade", "") as String
	var save: Dictionary = SaveManager.data
	if grade == "SSR":
		save["gacha_pity_ssr"] = 0
	elif grade == "UR":
		save["gacha_pity_ssr"] = 0
		save["gacha_pity_ur"] = 0
