extends Drop
class_name TargetedDrop

#可“临时拿起”的掉落物基类：拿起后自己暂时消失、鼠标变成准星
#点击有效目标 -> 用掉（默认消耗自己）；点无效处或右键 -> 取消，原位显现
#子类只需要覆盖 is_valid_target() 与 apply_target()
#（以后别的掉落物要“拿起来指目标”，直接 extends TargetedDrop 即可）

@export var cursor_texture:Texture2D   #准星贴图，留空就用系统默认指针

var is_held:bool=false
var _home_position:Vector2
var _board:Board=null

func handle_click():
	if is_held:
		return
	_hold()

func _hold() -> void:
	_board=get_tree().get_first_node_in_group("board")
	if _board==null:
		push_error("TargetedDrop: 找不到 board，无法进入瞄准")
		return
	is_held=true
	_home_position=global_position
	hide()#暂时消失
	_board.begin_targeting(
		Callable(self,"is_valid_target"),
		Callable(self,"apply_target"),
		Callable(self,"cancel_hold"),
		cursor_texture
	)

#子类覆盖：这一格能否使用
func is_valid_target(cell:Cell) -> bool:
	return false

#子类覆盖：使用（默认直接把道具用掉）
func apply_target(cell:Cell) -> void:
	queue_free()

#取消：回到原位，重新变回可拾取的掉落物
func cancel_hold() -> void:
	is_held=false
	global_position=_home_position
	show()
