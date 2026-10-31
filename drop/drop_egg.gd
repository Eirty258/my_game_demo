extends Drop
class_name DropEgg

var type:String="fire"
var egg_sprite_dictionary:Dictionary={
	"fire":"res://drop/egg_texture/fire_egg.tres",
	"ice":"res://drop/egg_texture/ice_egg.tres",
	"electricity":"res://drop/egg_texture/electricity_egg.tres"
}
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if type=="null":
		type=pick_by_weight(WeightTable.random_eggs)
	scale=Vector2.ONE*0.5
	$Sprite2D.texture=load(egg_sprite_dictionary[type]) as Texture


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func handle_click():
	SignalBus.drop_egg_picked.emit(type)
	queue_free()

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
