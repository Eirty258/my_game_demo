extends Egg

const EGG_SHOT=preload("res://eggs/egg_shot_factory.gd")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super._ready()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _init() -> void:
	type="fire"

func shoot(chain_count:int):
	#发射逻辑统一在 egg_shot_factory.gd（相也要走同一个入口，弹体和伤害才会完全一样）
	EGG_SHOT.shoot(type,directions,chain_count,global_position,shot_damage_mul,shot_damage_add,get_tree())
