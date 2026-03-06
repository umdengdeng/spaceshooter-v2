extends Panel

signal closed

const ELEMENT_NAMES: Dictionary = {
	"fire": "불", "water": "물", "wind": "풍", "light": "빛", "dark": "암흑",
}
const ELEMENTS: Array[String] = ["fire", "water", "wind", "light", "dark"]

var _diamond_tab: Control = null
var _material_tab: Control = null
var _material_content: VBoxContainer = null


func _ready() -> void:
	_build_ui()
	_show_diamond_tab()


func _build_ui() -> void:
	var margin: MarginContainer = MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 30)
	margin.add_theme_constant_override("margin_right", 30)
	margin.add_theme_constant_override("margin_top", 30)
	margin.add_theme_constant_override("margin_bottom", 30)
	add_child(margin)

	var root_vbox: VBoxContainer = VBoxContainer.new()
	root_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root_vbox.add_theme_constant_override("separation", 10)
	margin.add_child(root_vbox)

	var title_bar: HBoxContainer = HBoxContainer.new()
	root_vbox.add_child(title_bar)
	var title: Label = Label.new()
	title.text = "Shop"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 36)
	title_bar.add_child(title)
	var close_btn: Button = Button.new()
	close_btn.text = "X"
	close_btn.custom_minimum_size = Vector2(70, 50)
	close_btn.pressed.connect(_on_close)
	title_bar.add_child(close_btn)

	var tab_bar: HBoxContainer = HBoxContainer.new()
	tab_bar.add_theme_constant_override("separation", 10)
	root_vbox.add_child(tab_bar)
	var diamond_btn: Button = Button.new()
	diamond_btn.text = "Diamond Purchase"
	diamond_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	diamond_btn.custom_minimum_size = Vector2(0, 50)
	diamond_btn.pressed.connect(_show_diamond_tab)
	tab_bar.add_child(diamond_btn)
	var mat_btn: Button = Button.new()
	mat_btn.text = "Awakening Materials"
	mat_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mat_btn.custom_minimum_size = Vector2(0, 50)
	mat_btn.pressed.connect(_show_material_tab)
	tab_bar.add_child(mat_btn)

	_diamond_tab = Control.new()
	_diamond_tab.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root_vbox.add_child(_diamond_tab)
	_build_diamond_tab()

	_material_tab = Control.new()
	_material_tab.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_material_tab.visible = false
	root_vbox.add_child(_material_tab)
	_build_material_tab()


func _build_diamond_tab() -> void:
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 20)
	_diamond_tab.add_child(vbox)

	var packages: Array = [
		{"amount": 100, "price": "1,000"},
		{"amount": 500, "price": "4,500"},
		{"amount": 1000, "price": "8,000"},
		{"amount": 3000, "price": "20,000"},
	]
	for pkg: Variant in packages:
		var pd: Dictionary = pkg as Dictionary
		var btn: Button = Button.new()
		btn.text = "Diamond " + str(pd["amount"]) + " - W" + str(pd["price"])
		btn.custom_minimum_size = Vector2(0, 70)
		btn.add_theme_font_size_override("font_size", 24)
		btn.pressed.connect(_on_diamond_purchase)
		vbox.add_child(btn)


func _build_material_tab() -> void:
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	_material_tab.add_child(scroll)

	_material_content = VBoxContainer.new()
	_material_content.add_theme_constant_override("separation", 15)
	_material_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_material_content)


func _refresh_material_tab() -> void:
	for child: Node in _material_content.get_children():
		child.queue_free()

	var save: Dictionary = SaveManager.data
	var purchases: Dictionary = save.get("shop_awakening_purchases", {}) as Dictionary
	var stones: Dictionary = save.get("awakening_stones", {}) as Dictionary
	var gold: int = int(save.get("gold", 0))

	var gold_label: Label = Label.new()
	gold_label.text = "Gold: " + str(gold)
	gold_label.add_theme_font_size_override("font_size", 24)
	_material_content.add_child(gold_label)

	for elem: String in ELEMENTS:
		var bought: int = int(purchases.get(elem, 0))
		var current_stones: int = int(stones.get(elem, 0))
		var hbox: HBoxContainer = HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 10)
		_material_content.add_child(hbox)

		var info: Label = Label.new()
		info.text = ELEMENT_NAMES.get(elem, elem) + " Awakening Stone x5\nOwned: " + str(current_stones) + "  |  500 Gold"
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info.add_theme_font_size_override("font_size", 20)
		hbox.add_child(info)

		var count_label: Label = Label.new()
		count_label.text = str(bought) + "/3"
		count_label.add_theme_font_size_override("font_size", 22)
		hbox.add_child(count_label)

		var buy_btn: Button = Button.new()
		buy_btn.text = "Buy"
		buy_btn.custom_minimum_size = Vector2(100, 50)
		buy_btn.pressed.connect(_on_buy_stone.bind(elem))
		if bought >= 3 or gold < 500:
			buy_btn.disabled = true
		hbox.add_child(buy_btn)


func _show_diamond_tab() -> void:
	_diamond_tab.visible = true
	_material_tab.visible = false


func _show_material_tab() -> void:
	_diamond_tab.visible = false
	_material_tab.visible = true
	_refresh_material_tab()


func _on_diamond_purchase() -> void:
	var lbl: Label = Label.new()
	lbl.text = "Currently not supported"
	lbl.add_theme_font_size_override("font_size", 28)
	lbl.add_theme_color_override("font_color", Color.YELLOW)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.set_anchors_preset(Control.PRESET_CENTER)
	lbl.position.y += 200
	add_child(lbl)
	var tw: Tween = create_tween()
	tw.tween_interval(1.0)
	tw.tween_property(lbl, "modulate:a", 0.0, 0.5)
	tw.tween_callback(lbl.queue_free)


func _on_buy_stone(elem: String) -> void:
	var save: Dictionary = SaveManager.data
	var gold: int = int(save.get("gold", 0))
	if gold < 500:
		return
	var purchases: Dictionary = save.get("shop_awakening_purchases", {}) as Dictionary
	var bought: int = int(purchases.get(elem, 0))
	if bought >= 3:
		return
	save["gold"] = gold - 500
	GameManager.gold_changed.emit(int(save["gold"]))
	purchases[elem] = bought + 1
	save["shop_awakening_purchases"] = purchases
	var stones: Dictionary = save.get("awakening_stones", {}) as Dictionary
	var current_stones: int = int(stones.get(elem, 0))
	stones[elem] = current_stones + 5
	save["awakening_stones"] = stones
	SaveManager.save_game()
	_refresh_material_tab()


func _on_close() -> void:
	closed.emit()
	queue_free()
