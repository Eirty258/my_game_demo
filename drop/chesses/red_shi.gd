extends Chess

#红方“仕”：左键拾取后，在棋盘内随机空格生成一颗红仕
#仕本身不发射，被击碎（双击打碎）时才给所有边界套 10 秒护盾

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	pass

func handle_click():
	SignalBus.drop_egg_picked.emit("red_shi")#与掉蛋共用入口：棋盘随机位置生成一颗仕
	VisualEffect.show_text_hint("仕：拱卫中军")
	queue_free()
