extends Chess

#红方“相”：左键拾取后，在棋盘内随机空格生成一颗红相（万用蛋）
#相不能单独发射，只能跟同组里的其他蛋一起发，并让这一组所有弹体伤害 +1；
#同一颗相可以同时连在两个组里。具体规则在 eggs/red_xiang_egg.gd

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	pass

func handle_click():
	SignalBus.drop_egg_picked.emit("red_xiang")#与掉蛋共用入口：棋盘随机位置生成一颗相
	VisualEffect.show_text_hint("相：'神本无相'-给予一颗相")
	queue_free()
