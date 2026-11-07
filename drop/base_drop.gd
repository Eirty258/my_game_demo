extends Node2D
class_name Drop

#鼠标悬停：微微放大 + 提亮（和蛋的悬停效果同一套手感）
const HOVER_SCALE:=1.15
const HOVER_GLOW:=Color(1.3,1.3,1.3,1.0)
const HOVER_TIME:=0.12

var _hover_tween:Tween=null
var _hover_base_scale:Vector2=Vector2.ONE

#用字符串 connect：脚本基类是 Node2D，但实际节点是 Area2D（信号在实例上）
func _enter_tree() -> void:
	connect("mouse_entered",_on_mouse_entered)
	connect("mouse_exited",_on_mouse_exited)

func _on_mouse_entered() -> void:
	_hover_to(true)

func _on_mouse_exited() -> void:
	_hover_to(false)

func _hover_to(hovering:bool) -> void:
	if _hover_tween and _hover_tween.is_valid():
		_hover_tween.kill()
	#悬停开始时记下当前大小：不同掉落物基础缩放不一样（蛋0.5、道具2…）
	if hovering:
		_hover_base_scale=scale
	var target_scale:Vector2=_hover_base_scale*(HOVER_SCALE if hovering else 1.0)
	var target_glow:Color=HOVER_GLOW if hovering else Color.WHITE
	_hover_tween=create_tween()
	_hover_tween.set_parallel(true)
	_hover_tween.set_trans(Tween.TRANS_QUAD)
	_hover_tween.set_ease(Tween.EASE_OUT)
	_hover_tween.tween_property(self,"scale",target_scale,HOVER_TIME)
	#用 self_modulate 提亮：掉落物淡出用的是 modulate:a，互不干扰
	_hover_tween.tween_property(self,"self_modulate",target_glow,HOVER_TIME)

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
