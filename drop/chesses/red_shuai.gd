extends Chess

#红方的“帅”：左键拾取后，在棋盘内随机空格生成一颗帅
func _ready() -> void:
	pass

func _process(delta: float) -> void:
	pass

func handle_click():
	SignalBus.drop_egg_picked.emit("shuai")#与掉蛋共用入口：棋盘随机位置生成一颗帅
	VisualEffect.show_text_hint("帅：最后手段")
	queue_free()
