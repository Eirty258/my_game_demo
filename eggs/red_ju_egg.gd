extends Egg

const EGG_SHOT=preload("res://eggs/egg_shot_factory.gd")

#红车：和炮一样单颗可发射，但打出来的是随机载具
#载具表、高铁发车间隔这些都在 egg_shot_factory.gd 里（相也要发同样的东西）

func _init() -> void:
	type="ju"

func _ready() -> void:
	super._ready()

func _process(delta: float) -> void:
	pass

func shoot(chain_count:int):
	EGG_SHOT.shoot(type,directions,chain_count,global_position,shot_damage_mul,shot_damage_add,get_tree())
