extends Node

signal gold_changed(total: int)
signal diamond_changed(total: int)
signal enemy_killed

var is_popup_open: bool = false


func open_popup() -> void:
	is_popup_open = true
	var battle_nodes: Array[Node] = get_tree().get_nodes_in_group("battle")
	for node: Node in battle_nodes:
		node.set_process(false)


func close_popup() -> void:
	is_popup_open = false
	var battle_nodes: Array[Node] = get_tree().get_nodes_in_group("battle")
	for node: Node in battle_nodes:
		node.set_process(true)
