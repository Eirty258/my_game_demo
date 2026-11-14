extends Egg

const EGG_SHOT=preload("res://eggs/egg_shot_factory.gd")

#红相：万用蛋（棋盘上那颗相，不是掉落物）
#· 不能单独发射，只能跟同组里其他蛋一起发射；即使它属于某个已达标的组，点它本身也不发
#· 发射时装成这一组的蛋种：组里有火蛋就发 fire_ball，有车就发载具，有炮就发炮弹……
#· 同一颗相可以同时连在两个组里（比如左边火组、右边冰组），点哪个组它就跟着哪边发
#· 它所在的这一组，所有弹体伤害额外 +1（在伤害公式的根号里放大）
#分组由 board.rescan_groups() 负责：相可以同时被写进多个组

func _init() -> void:
	type="xiang"

func _ready() -> void:
	super._ready()

func _process(delta: float) -> void:
	pass

func shoot(chain_count:int):
	#shot_type 由棋盘在发射前按所在组写入；为空说明没分到组（或整组都是相）
	if shot_type=="":
		return
	EGG_SHOT.shoot(shot_type,directions,chain_count,global_position,shot_damage_mul,shot_damage_add,get_tree())
