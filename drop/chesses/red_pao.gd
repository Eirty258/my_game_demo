extends Chess

#红方的“炮”：左键点击掉落物后，在棋盘内随机空格生成一颗红炮
func _ready() -> void:
	pass

func _process(delta: float) -> void:
	pass

func handle_click():
	SignalBus.drop_egg_picked.emit("pao")#与掉蛋共用入口：棋盘随机位置生成一颗红炮
	VisualEffect.show_text_hint("炮：'隔子打子，隔山打牛'-给予一颗红炮")
	queue_free()
