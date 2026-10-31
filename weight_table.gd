extends Node

var random_eggs:Dictionary={
	"fire":1,
	"ice":1,
	"electricity":1
}

var order_item_pool:Dictionary={#订单道具池
	"conehead":1,
	"double_yolk_egg":1,
	"sharp_shards":1,
}

var boss_item_pool:Dictionary={
	"charcoal":1,
	"ice_cube":1,
	"charge_bread":1,
}
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func pick_by_weight(weights: Dictionary) -> String:
	var total = 0.0
	for key in weights:
		total += weights[key]
	var roll = randf() * total
	var acc = 0.0
	for key in weights:
		acc += weights[key]
		if roll < acc:
			return key
	return weights.keys()[0]   # 兜底
