extends Chess

#红方“车”：左键拾取后在棋盘随机空格生成一颗车，车可以向炮一样单颗发射

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	pass

func handle_click():
	SignalBus.drop_egg_picked.emit("ju")
	VisualEffect.show_text_hint("车：横冲直撞")
	queue_free()
