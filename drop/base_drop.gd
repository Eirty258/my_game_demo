extends Node2D
class_name Drop

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if is_click_blocked():#别的掉落物正在“临时拿起”瞄准时，所有掉落物都不响应点击
				return
			handle_click()
			get_viewport().set_input_as_handled()

#当前是否应该屏蔽掉落物点击（由 board 维护：瞄准中，或刚结束瞄准）
func is_click_blocked() -> bool:
	var board=get_tree().get_first_node_in_group("board")
	if board==null:
		return false
	return board.blocks_drop_clicks()

func handle_click():
	pass
