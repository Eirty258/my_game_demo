extends Drop

@export var contents:Dictionary={
	"requirements":[{"type":"egg_shard","amount":3}],
	"rewards":[{"type":"item","amount":1,"item_name":"conehead"}]
}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func handle_click():
	var screen_pos = get_viewport().get_canvas_transform() * global_position
	SignalBus.drop_order_picked.emit(screen_pos)
	queue_free()
