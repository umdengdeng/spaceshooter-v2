extends Panel

signal closed

const GRADE_COLORS: Dictionary = {
	"N": Color(0.5, 0.5, 0.5),
	"R": Color(0.2, 0.8, 0.2),
	"SR": Color(0.2, 0.4, 1.0),
	"SSR": Color(0.7, 0.2, 1.0),
	"UR": Color(1.0, 0.85, 0.0),
}
const ELEMENT_COLORS: Dictionary = {
	"fire": Color(1, 0.2, 0.1),
	"water": Color(0.1, 0.4, 1),
	"wind": Color(0.1, 0.9, 0.3),
	"light": Color(1, 0.9, 0.2),
	"dark": Color(0.6, 0.1, 0.9),
}
const ELEMENT_NAMES: Dictionary = {
	"fire": "불", "water": "물", "wind": "풍", "light": "빛", "dark": "암흑",
}

var active_preset: int = 0
var party_slots: Array = ["", "", ""]

var list_tab: Control = null
var detail_view: Control = null
var party_tab: Control = null
var list_grid: GridContainer = null
var party_grid: GridContainer = null
var detail_info: VBoxContainer = null
var slot_buttons: Array[Button] = []
var synergy_label: Label = null
var leader_skill_label: Label = null
var preset_buttons: Array[Button] = []
var list_tab_btn: Button = null
var party_tab_btn: Button = null
var _current_detail_id: String = ""


func _ready() -> void:
	_build_ui()
	_show_list()


func _build_ui() -> void:
	var margin: MarginContainer = MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 15)
	margin.add_theme_constant_override("margin_right", 15)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	add_child(margin)

	var root_vbox: VBoxContainer = VBoxContainer.new()
	root_vbox.add_theme_constant_override("separation", 8)
	margin.add_child(root_vbox)

	_build_top_bar(root_vbox)
	_build_tab_bar(root_vbox)
	_build_content(root_vbox)


func _build_top_bar(parent: VBoxContainer) -> void:
	var bar: HBoxContainer = HBoxContainer.new()
	bar.custom_minimum_size = Vector2(0, 40)
	parent.add_child(bar)

	var title: Label = Label.new()
	title.text = "캐릭터"
	title.add_theme_font_size_override("font_size", 28)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.add_child(title)

	var close_btn: Button = Button.new()
	close_btn.text = "X"
	close_btn.custom_minimum_size = Vector2(50, 40)
	close_btn.pressed.connect(_on_close_pressed)
	bar.add_child(close_btn)


func _build_tab_bar(parent: VBoxContainer) -> void:
	var bar: HBoxContainer = HBoxContainer.new()
	bar.custom_minimum_size = Vector2(0, 36)
	parent.add_child(bar)

	list_tab_btn = Button.new()
	list_tab_btn.text = "목록"
	list_tab_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list_tab_btn.pressed.connect(_show_list)
	bar.add_child(list_tab_btn)

	party_tab_btn = Button.new()
	party_tab_btn.text = "파티편성"
	party_tab_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	party_tab_btn.pressed.connect(_show_party)
	bar.add_child(party_tab_btn)


func _build_content(parent: VBoxContainer) -> void:
	var content: Control = Control.new()
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	parent.add_child(content)

	_build_list_tab(content)
	_build_detail_view(content)
	_build_party_tab(content)


func _build_list_tab(parent: Control) -> void:
	list_tab = Control.new()
	list_tab.set_anchors_preset(Control.PRESET_FULL_RECT)
	parent.add_child(list_tab)

	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	list_tab.add_child(scroll)

	list_grid = GridContainer.new()
	list_grid.columns = 4
	list_grid.add_theme_constant_override("h_separation", 8)
	list_grid.add_theme_constant_override("v_separation", 8)
	scroll.add_child(list_grid)


func _build_detail_view(parent: Control) -> void:
	detail_view = Control.new()
	detail_view.set_anchors_preset(Control.PRESET_FULL_RECT)
	detail_view.visible = false
	parent.add_child(detail_view)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	detail_view.add_child(vbox)

	var back_btn: Button = Button.new()
	back_btn.text = "<< 뒤로"
	back_btn.custom_minimum_size = Vector2(120, 36)
	back_btn.pressed.connect(_show_list)
	vbox.add_child(back_btn)

	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)

	detail_info = VBoxContainer.new()
	detail_info.add_theme_constant_override("separation", 6)
	scroll.add_child(detail_info)


func _build_party_tab(parent: Control) -> void:
	party_tab = Control.new()
	party_tab.set_anchors_preset(Control.PRESET_FULL_RECT)
	party_tab.visible = false
	parent.add_child(party_tab)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 6)
	party_tab.add_child(vbox)

	var slot_label: Label = Label.new()
	slot_label.text = "파티 슬롯"
	slot_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	slot_label.add_theme_font_size_override("font_size", 18)
	vbox.add_child(slot_label)

	var slot_bar: HBoxContainer = HBoxContainer.new()
	slot_bar.custom_minimum_size = Vector2(0, 70)
	slot_bar.alignment = BoxContainer.ALIGNMENT_CENTER
	slot_bar.add_theme_constant_override("separation", 20)
	vbox.add_child(slot_bar)

	var slot_names: Array[String] = ["후위 좌", "♛ 리더", "후위 우"]
	for i: int in range(3):
		var btn: Button = Button.new()
		btn.text = slot_names[i] + "\n(비어있음)"
		btn.custom_minimum_size = Vector2(200, 70)
		btn.pressed.connect(_on_slot_pressed.bind(i))
		slot_bar.add_child(btn)
		slot_buttons.append(btn)

	synergy_label = Label.new()
	synergy_label.text = ""
	synergy_label.add_theme_font_size_override("font_size", 14)
	synergy_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.3))
	synergy_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(synergy_label)

	leader_skill_label = Label.new()
	leader_skill_label.text = ""
	leader_skill_label.add_theme_font_size_override("font_size", 14)
	leader_skill_label.add_theme_color_override("font_color", Color.YELLOW)
	vbox.add_child(leader_skill_label)

	var preset_bar: HBoxContainer = HBoxContainer.new()
	preset_bar.custom_minimum_size = Vector2(0, 36)
	vbox.add_child(preset_bar)
	for i: int in range(3):
		var pbtn: Button = Button.new()
		pbtn.text = "프리셋 " + str(i + 1)
		pbtn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		pbtn.pressed.connect(_on_preset_pressed.bind(i))
		preset_bar.add_child(pbtn)
		preset_buttons.append(pbtn)
	var save_btn: Button = Button.new()
	save_btn.text = "저장"
	save_btn.custom_minimum_size = Vector2(80, 36)
	save_btn.pressed.connect(_on_save_pressed)
	preset_bar.add_child(save_btn)

	var party_scroll: ScrollContainer = ScrollContainer.new()
	party_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(party_scroll)

	party_grid = GridContainer.new()
	party_grid.columns = 4
	party_grid.add_theme_constant_override("h_separation", 8)
	party_grid.add_theme_constant_override("v_separation", 8)
	party_scroll.add_child(party_grid)


func _show_list() -> void:
	list_tab.visible = true
	detail_view.visible = false
	party_tab.visible = false
	_populate_list_grid()


func _show_detail(char_id: String) -> void:
	list_tab.visible = false
	detail_view.visible = true
	party_tab.visible = false
	_populate_detail(char_id)


func _show_party() -> void:
	list_tab.visible = false
	detail_view.visible = false
	party_tab.visible = true
	_load_party_preset()
	_update_party_slots_display()
	_populate_party_grid()


func _populate_list_grid() -> void:
	for child: Node in list_grid.get_children():
		child.queue_free()
	var owned: Dictionary = SaveManager.data.get("owned_characters", {}) as Dictionary
	for char_id: String in owned:
		var char_data: Dictionary = CharacterDB.get_character(char_id)
		if char_data.is_empty():
			continue
		var inst: Dictionary = owned[char_id] as Dictionary
		var card: PanelContainer = _create_card(char_id, char_data, inst, false)
		list_grid.add_child(card)


func _create_card(char_id: String, char_data: Dictionary, inst: Dictionary, for_party: bool) -> PanelContainer:
	var card: PanelContainer = PanelContainer.new()
	card.custom_minimum_size = Vector2(170, 130)

	var grade: String = str(char_data.get("grade", "N"))
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.12, 0.18, 0.95)
	style.border_color = GRADE_COLORS.get(grade, Color.GRAY)
	style.set_border_width_all(3)
	style.set_corner_radius_all(4)
	card.add_theme_stylebox_override("panel", style)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)
	card.add_child(vbox)

	var top_row: HBoxContainer = HBoxContainer.new()
	vbox.add_child(top_row)
	var elem: String = str(char_data.get("element", "fire"))
	var dot: ColorRect = ColorRect.new()
	dot.custom_minimum_size = Vector2(14, 14)
	dot.color = ELEMENT_COLORS.get(elem, Color.WHITE)
	top_row.add_child(dot)
	var spacer: Control = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_row.add_child(spacer)
	var grade_lbl: Label = Label.new()
	grade_lbl.text = grade
	grade_lbl.add_theme_font_size_override("font_size", 13)
	grade_lbl.add_theme_color_override("font_color", GRADE_COLORS.get(grade, Color.GRAY))
	top_row.add_child(grade_lbl)

	var weapon_lbl: Label = Label.new()
	weapon_lbl.text = str(char_data.get("weapon_type", ""))
	weapon_lbl.add_theme_font_size_override("font_size", 11)
	weapon_lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	weapon_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(weapon_lbl)

	var name_lbl: Label = Label.new()
	name_lbl.text = str(char_data.get("name", "???"))
	name_lbl.add_theme_font_size_override("font_size", 14)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	vbox.add_child(name_lbl)

	var level_lbl: Label = Label.new()
	level_lbl.text = "Lv." + str(inst.get("level", 1))
	level_lbl.add_theme_font_size_override("font_size", 12)
	level_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(level_lbl)

	var btn_overlay: Button = Button.new()
	btn_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	btn_overlay.flat = true
	btn_overlay.mouse_filter = Control.MOUSE_FILTER_PASS
	if for_party:
		btn_overlay.pressed.connect(_on_party_card_pressed.bind(char_id))
	else:
		btn_overlay.pressed.connect(_on_card_pressed.bind(char_id))
	card.add_child(btn_overlay)

	return card


func _on_card_pressed(char_id: String) -> void:
	_show_detail(char_id)


func _populate_detail(char_id: String) -> void:
	_current_detail_id = char_id
	for child: Node in detail_info.get_children():
		child.queue_free()

	var char_data: Dictionary = CharacterDB.get_character(char_id)
	var owned: Dictionary = SaveManager.data.get("owned_characters", {}) as Dictionary
	var inst: Dictionary = owned.get(char_id, {}) as Dictionary
	var grade: String = str(char_data.get("grade", "N"))
	var elem: String = str(char_data.get("element", "fire"))
	var level: int = int(inst.get("level", 1))
	var stars: int = int(inst.get("stars", 0))
	var awakening: int = int(inst.get("awakening", 0))
	var stat_mult: float = UpgradeSystem.get_stat_multiplier(level, stars, awakening)

	var header: Label = Label.new()
	header.text = "[" + grade + "] " + str(char_data.get("name", ""))
	header.add_theme_font_size_override("font_size", 24)
	header.add_theme_color_override("font_color", GRADE_COLORS.get(grade, Color.WHITE))
	detail_info.add_child(header)

	var info_lbl: Label = Label.new()
	info_lbl.text = "속성: " + ELEMENT_NAMES.get(elem, elem) + " | 무기: " + str(char_data.get("weapon_type", ""))
	info_lbl.add_theme_color_override("font_color", ELEMENT_COLORS.get(elem, Color.WHITE))
	detail_info.add_child(info_lbl)

	var status_lbl: Label = Label.new()
	var star_text: String = ""
	for i: int in range(stars):
		star_text += "★"
	for i: int in range(5 - stars):
		star_text += "☆"
	status_lbl.text = "Lv." + str(level) + "  " + star_text + "  각성 " + str(awakening) + "/5"
	detail_info.add_child(status_lbl)

	var exp_lbl: Label = Label.new()
	var cur_exp: int = int(inst.get("current_exp", 0))
	var max_lvl: int = UpgradeSystem.get_max_level(grade)
	if level >= max_lvl:
		exp_lbl.text = "EXP: MAX"
	else:
		var needed: int = UpgradeSystem.get_exp_needed(level)
		exp_lbl.text = "EXP: " + str(cur_exp) + "/" + str(needed)
	exp_lbl.add_theme_font_size_override("font_size", 14)
	detail_info.add_child(exp_lbl)

	var dupes_lbl: Label = Label.new()
	dupes_lbl.text = "Duplicates: " + str(int(inst.get("dupes", 0)))
	dupes_lbl.add_theme_font_size_override("font_size", 14)
	detail_info.add_child(dupes_lbl)

	detail_info.add_child(HSeparator.new())

	var base: Dictionary = char_data.get("base_stats", {}) as Dictionary
	var stat_keys: Array[String] = ["atk", "hp", "def", "spd", "crit_rate", "crit_dmg", "acc"]
	var stat_names: Array[String] = ["ATK", "HP", "DEF", "SPD", "CRIT RATE", "CRIT DMG", "ACC"]
	for i: int in range(stat_keys.size()):
		var val: float = float(base.get(stat_keys[i], 0))
		var display: String = ""
		if stat_keys[i] in ["crit_rate", "acc"]:
			display = str(snapped(val * 100.0, 0.1)) + "%"
		elif stat_keys[i] == "crit_dmg":
			display = "x" + str(snapped(val, 0.01))
		else:
			display = str(int(val * stat_mult))
		var s: Label = Label.new()
		s.text = stat_names[i] + ": " + display
		s.add_theme_font_size_override("font_size", 16)
		detail_info.add_child(s)

	detail_info.add_child(HSeparator.new())

	var passive: Variant = char_data.get("passive_skill")
	if passive != null and passive is Dictionary:
		var pd: Dictionary = passive as Dictionary
		var pl: Label = Label.new()
		var passive_text: String = "패시브: " + str(pd.get("name", "")) + "\n  " + str(pd.get("description", ""))
		if awakening >= 5:
			passive_text += " (x2)"
		pl.text = passive_text
		pl.autowrap_mode = TextServer.AUTOWRAP_WORD
		detail_info.add_child(pl)

	var leader: Variant = char_data.get("leader_skill")
	if leader != null and leader is Dictionary:
		var ld: Dictionary = leader as Dictionary
		var ll: Label = Label.new()
		ll.text = "리더스킬: " + str(ld.get("description", ""))
		ll.add_theme_color_override("font_color", Color.YELLOW)
		detail_info.add_child(ll)

	detail_info.add_child(HSeparator.new())

	var btn_bar: HBoxContainer = HBoxContainer.new()
	btn_bar.add_theme_constant_override("separation", 12)
	detail_info.add_child(btn_bar)

	var star_cost: int = UpgradeSystem.get_star_upgrade_cost(char_id)
	var enhance_btn: Button = Button.new()
	if star_cost < 0:
		enhance_btn.text = "성급 MAX"
		enhance_btn.disabled = true
	else:
		var dupes: int = int(inst.get("dupes", 0))
		enhance_btn.text = "성급 강화 (" + str(dupes) + "/" + str(star_cost) + ")"
		if dupes < star_cost:
			enhance_btn.disabled = true
	enhance_btn.custom_minimum_size = Vector2(200, 45)
	enhance_btn.pressed.connect(_on_enhance_pressed)
	btn_bar.add_child(enhance_btn)

	var awaken_cost: int = UpgradeSystem.get_awaken_cost(char_id)
	var stones_dict: Dictionary = SaveManager.data.get("awakening_stones", {}) as Dictionary
	var current_stones: int = int(stones_dict.get(elem, 0))
	var awaken_btn: Button = Button.new()
	if awaken_cost < 0:
		awaken_btn.text = "각성 MAX"
		awaken_btn.disabled = true
	else:
		awaken_btn.text = "각성 (" + str(current_stones) + "/" + str(awaken_cost) + ")"
		if current_stones < awaken_cost:
			awaken_btn.disabled = true
	awaken_btn.custom_minimum_size = Vector2(200, 45)
	awaken_btn.pressed.connect(_on_awaken_pressed)
	btn_bar.add_child(awaken_btn)


func _load_party_preset() -> void:
	active_preset = int(SaveManager.data.get("active_preset", 0))
	var presets: Array = SaveManager.data.get("party_presets", []) as Array
	if presets.size() > active_preset:
		var p: Array = presets[active_preset] as Array
		party_slots = [
			str(p[0]) if p.size() > 0 else "",
			str(p[1]) if p.size() > 1 else "",
			str(p[2]) if p.size() > 2 else "",
		]
	else:
		party_slots = ["", "", ""]


func _update_party_slots_display() -> void:
	var labels: Array[String] = ["후위 좌", "♛ 리더", "후위 우"]
	for i: int in range(3):
		var char_id: String = str(party_slots[i])
		if char_id.is_empty():
			slot_buttons[i].text = labels[i] + "\n(비어있음)"
		else:
			var cd: Dictionary = CharacterDB.get_character(char_id)
			var grade: String = str(cd.get("grade", ""))
			slot_buttons[i].text = labels[i] + "\n[" + grade + "] " + str(cd.get("name", char_id))
	_update_synergy()


func _update_synergy() -> void:
	var elements: Array[String] = []
	for slot_id: String in party_slots:
		if str(slot_id).is_empty():
			continue
		var cd: Dictionary = CharacterDB.get_character(str(slot_id))
		if not cd.is_empty():
			elements.append(str(cd.get("element", "")))

	var synergy_texts: Array[String] = []
	var element_count: Dictionary = {}
	for e: String in elements:
		element_count[e] = int(element_count.get(e, 0)) + 1

	for e: String in element_count:
		if int(element_count[e]) >= 2:
			synergy_texts.append("같은 속성(" + ELEMENT_NAMES.get(e, e) + ") 2명: ATK +10%")

	var has_light: bool = "light" in elements
	var has_dark: bool = "dark" in elements
	if has_light and has_dark:
		synergy_texts.append("빛+암흑: CRIT +5%")

	synergy_label.text = "\n".join(synergy_texts) if synergy_texts.size() > 0 else "시너지 없음"

	var leader_id: String = str(party_slots[1])
	if not leader_id.is_empty():
		var cd: Dictionary = CharacterDB.get_character(leader_id)
		var ls: Variant = cd.get("leader_skill")
		if ls != null and ls is Dictionary:
			var lsd: Dictionary = ls as Dictionary
			leader_skill_label.text = "리더스킬: " + str(lsd.get("description", ""))
		else:
			leader_skill_label.text = "리더스킬: 없음"
	else:
		leader_skill_label.text = "리더스킬: -"


func _populate_party_grid() -> void:
	for child: Node in party_grid.get_children():
		child.queue_free()
	var owned: Dictionary = SaveManager.data.get("owned_characters", {}) as Dictionary
	for char_id: String in owned:
		if char_id in party_slots:
			continue
		var char_data: Dictionary = CharacterDB.get_character(char_id)
		if char_data.is_empty():
			continue
		var inst: Dictionary = owned[char_id] as Dictionary
		var card: PanelContainer = _create_card(char_id, char_data, inst, true)
		party_grid.add_child(card)


func _on_party_card_pressed(char_id: String) -> void:
	for i: int in range(3):
		if str(party_slots[i]).is_empty():
			party_slots[i] = char_id
			_update_party_slots_display()
			_populate_party_grid()
			return


func _on_slot_pressed(index: int) -> void:
	party_slots[index] = ""
	_update_party_slots_display()
	_populate_party_grid()


func _on_preset_pressed(index: int) -> void:
	active_preset = index
	SaveManager.data["active_preset"] = active_preset
	_load_party_preset()
	_update_party_slots_display()
	_populate_party_grid()


func _on_save_pressed() -> void:
	var presets: Array = SaveManager.data.get("party_presets", []) as Array
	while presets.size() <= active_preset:
		presets.append(["", "", ""])
	presets[active_preset] = [party_slots[0], party_slots[1], party_slots[2]]
	SaveManager.data["party_presets"] = presets
	SaveManager.data["active_preset"] = active_preset
	SaveManager.save_game()


func _on_enhance_pressed() -> void:
	if _current_detail_id.is_empty():
		return
	var success: bool = UpgradeSystem.try_star_upgrade(_current_detail_id)
	if success:
		_populate_detail(_current_detail_id)


func _on_awaken_pressed() -> void:
	if _current_detail_id.is_empty():
		return
	var success: bool = UpgradeSystem.try_awaken(_current_detail_id)
	if success:
		_populate_detail(_current_detail_id)


func _on_close_pressed() -> void:
	closed.emit()
	queue_free()
