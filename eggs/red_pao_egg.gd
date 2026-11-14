extends Egg

const EGG_SHOT=preload("res://eggs/egg_shot_factory.gd")

#红炮：棋子类蛋，与普通蛋同构（可拖动、可成组、可被双击打碎）
#唯一区别：只需要 1 颗就能成组发射，且发射物在第二个敌人处爆炸

func _init() -> void:
	type="pao"

func _ready() -> void:
	super._ready()


func _process(delta: float) -> void:
	pass

func shoot(chain_count:int):
	EGG_SHOT.shoot(type,directions,chain_count,global_position,shot_damage_mul,shot_damage_add,get_tree())
