extends Chess


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func handle_click():
	var type=WeightTable.pick_by_weight(WeightTable.random_eggs)
	for i in range(3):
		SignalBus.drop_egg_picked.emit(type)
	VisualEffect.show_text_hint("兵：'夫尽小者大，积微者著'-给予三颗同种蛋")
	queue_free()
