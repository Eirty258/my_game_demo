extends Item

#神之右手：右键任意一颗蛋，在失活 / 激活之间切换
#失活的蛋碰撞体是关掉的，所以右键由棋盘按格子找蛋后再发信号过来（不依赖物理）

func _ready() -> void:
	item_name="god_right_hand"
	SignalBus.egg_right_clicked.connect(toggle_egg)

func toggle_egg(egg:Egg) -> void:
	if not is_instance_valid(egg):
		return
	if egg.disabled:
		egg.activate()
	else:
		egg.inactivate()
