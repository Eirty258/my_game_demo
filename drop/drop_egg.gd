extends Drop
class_name DropEgg

var type:String="fire"
var egg_sprite_dictionary:Dictionary={
	"fire":"res://drop/egg_texture/fire_egg.tres",
	"ice":"res://drop/egg_texture/ice_egg.tres",
	"electricity":"res://drop/egg_texture/electricity_egg.tres",
	#棋子的蛋（红车/红炮/红帅）用的是棋盘上那张整图，不需要再从元素蛋序列图里切
	"red_ju":"res://arts/texture/chesses/red_ju.png",
	"red_pao":"res://arts/texture/chesses/red_pao.png",
	"red_shuai":"res://arts/texture/chesses/red_shuai.png",
}
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if type=="null":
		type=WeightTable.pick_egg_type()
	scale=Vector2.ONE*0.5
	$Sprite2D.texture=get_egg_texture(type)

#取掉落时显示的贴图：查表，查不到再找棋子蛋的整图，都没有就别崩
func get_egg_texture(egg_type:String) -> Texture2D:
	if egg_sprite_dictionary.has(egg_type):
		return load(egg_sprite_dictionary[egg_type]) as Texture2D
	var path="res://arts/texture/chesses/%s.png"%egg_type
	if ResourceLoader.exists(path):
		return load(path)
	push_warning("drop_egg：没有蛋 %s 的掉落贴图" % egg_type)
	return null


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func handle_click():
	SignalBus.drop_egg_picked.emit(type)#红方“兵”也在调用这个信号
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
