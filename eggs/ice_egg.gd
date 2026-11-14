extends Egg

const EGG_SHOT=preload("res://eggs/egg_shot_factory.gd")


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super._ready()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _init() -> void:
	type="ice"

func shoot(chain_count:int):
	EGG_SHOT.shoot(type,directions,chain_count,global_position,shot_damage_mul,shot_damage_add,get_tree())
