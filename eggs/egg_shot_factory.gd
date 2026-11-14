extends RefCounted

#蛋的发射统一入口：火/冰/电/炮/车各自发什么、伤害怎么算，全收在这里。
#普通蛋（fire_egg.gd 等）和"相"（万用蛋）都走这个入口：
#相只要把 shot_type 设成所在组的蛋种，发出来的弹就和那些蛋完全一样，
#不用再把车的发车逻辑抄一遍。
#
#damage_add：本组里有相时，棋盘在发射前给每颗蛋写入 +1（本组几颗相就 +几）。
#最终伤害 = damage_mul * (damage * sqrt(1 + 1.2 * damage_add) + damage_extra)，
#所以这个 +1 是在根号下的，和木炭/冰块/充电面包加伤害用的是同一个字段。

const VOLLEY=preload("res://projectiles/volley.gd")
const TRAIN_HEAD=preload("res://projectiles/vehicles/red_ju_train_head.tscn")
const TRAIN_CARRIAGE=preload("res://projectiles/vehicles/red_ju_train_carriage.tscn")

#载具名 -> 场景；键名必须和 WeightTable.red_ju_vehicles 里的一致，权重统一在那张表里调
const VEHICLE_SCENES:Dictionary={
	"red_ju_stroller":preload("res://projectiles/vehicles/red_ju_stroller.tscn"),#婴儿车
	"red_ju_bicycle":preload("res://projectiles/vehicles/red_ju_bicycle.tscn"),#自行车
	"red_ju_motorcycle":preload("res://projectiles/vehicles/red_ju_motorcycle.tscn"),#摩托车
	"red_ju_minibus":preload("res://projectiles/vehicles/red_ju_minibus.tscn"),#小客车
	"red_ju_truck":preload("res://projectiles/vehicles/red_ju_truck.tscn"),#大货车
	"red_ju_train_head":preload("res://projectiles/vehicles/red_ju_train_head.tscn"),#高铁
}

const TRAIN_COUNT:=16#1 车头 + 15 车厢
#高铁各节贴图的长度（像素）：横向是宽，竖直是朝下贴图的高
#发车间隔按“长度 / 速度”算，车与车才会首尾相接（贴图都是中心对齐的）
const TRAIN_HEAD_LENGTH:=1481.0
const TRAIN_CARRIAGE_LENGTH:=2273.0
const TRAIN_HEAD_LENGTH_V:=1134.0
const TRAIN_CARRIAGE_LENGTH_V:=1536.0

static var _train_speed:float=0.0

#按蛋种发射。egg_type 用蛋内部的名字（fire/ice/electricity/pao/ju），不带 red_ 前缀
static func shoot(egg_type:String,dirs:Array,chain_count:int,pos:Vector2,damage_mul:float,damage_add:float,tree:SceneTree) -> void:
	if tree==null:
		push_warning("蛋发射：拿不到 SceneTree")
		return
	match egg_type:
		"fire","ice","electricity":
			_shoot_elemental(egg_type,dirs,chain_count,pos,damage_mul,damage_add,tree)
		"pao":
			_shoot_pao(dirs,chain_count,pos,damage_mul,damage_add,tree)
		"ju":
			_shoot_ju(dirs,chain_count,pos,damage_mul,damage_add,tree)
		_:
			push_warning("蛋发射：不认识的蛋种 %s" % egg_type)

#——元素蛋（火/冰/电）——
static func _shoot_elemental(t:String,dirs:Array,chain_count:int,pos:Vector2,damage_mul:float,damage_add:float,tree:SceneTree) -> void:
	var ball_scene:PackedScene=load("res://projectiles/%s_ball.tscn"%t)
	if ball_scene==null:
		push_warning("蛋发射：没有 %s 的弹体场景" % t)
		return
	#成组门槛：电力蛋少一颗
	var threshold:int=maxi(GameState.min_chain,1)
	if t=="electricity":
		threshold=maxi(GameState.min_chain-1,1)
	var damage_multiply:float=(1+(chain_count-threshold)/5)*damage_mul#整数除法，和原来的连锁加成一致
	for dir:Vector2 in dirs:
		var ball:Projectile=ball_scene.instantiate()
		ball.direction=dir
		ball.type=t
		ball.chain_count=chain_count
		ball.knocked_back=dir*100
		ball.global_position=pos
		ball.damage_mul*=damage_multiply
		ball.damage_add+=damage_add
		SignalBus.egg_shot.emit(ball)
		tree.root.add_child(ball)

#——红炮：一发在第二个敌人处爆炸的炮弹——
static func _shoot_pao(dirs:Array,chain_count:int,pos:Vector2,damage_mul:float,damage_add:float,tree:SceneTree) -> void:
	var ball_scene:PackedScene=load("res://projectiles/red_pao_ball.tscn")
	var damage_multiply:float=(1+(chain_count-1)/5)*damage_mul
	for dir:Vector2 in dirs:
		var pao_ball:Projectile=ball_scene.instantiate()
		pao_ball.direction=dir
		pao_ball.type="fire"#火属性炮弹：吃火属性加成与火弱点，但不附加灼烧
		pao_ball.chain_count=chain_count
		pao_ball.knocked_back=dir*100
		pao_ball.global_position=pos
		pao_ball.damage_mul*=damage_multiply
		pao_ball.damage_add+=damage_add
		SignalBus.egg_shot.emit(pao_ball)
		tree.root.add_child(pao_ball)

#——红车：随机一种载具，高铁是一整列编队——
static func _shoot_ju(dirs:Array,chain_count:int,pos:Vector2,damage_mul:float,damage_add:float,tree:SceneTree) -> void:
	var vehicle_type:String=WeightTable.pick_by_weight(WeightTable.red_ju_vehicles)
	if not VEHICLE_SCENES.has(vehicle_type):
		push_warning("红车：权重表里的载具 %s 没有对应场景" % vehicle_type)
		return
	var vehicle_scene:PackedScene=VEHICLE_SCENES[vehicle_type]
	var damage_multiply:float=(1+(chain_count-1)/5)*damage_mul
	for dir:Vector2 in dirs:
		if vehicle_scene==TRAIN_HEAD:
			#高铁：从棋子位置一节节发出去，跟车头的位置、存活都无关
			var train_speed:=_get_train_speed()
			#纵向飞用的是朝下的贴图，长度和横向不一样
			var vertical:bool=absf(dir.y)>absf(dir.x)
			var head_length:float=TRAIN_HEAD_LENGTH_V if vertical else TRAIN_HEAD_LENGTH
			var carriage_length:float=TRAIN_CARRIAGE_LENGTH_V if vertical else TRAIN_CARRIAGE_LENGTH
			#车头中心到第一节车厢中心 = (车头长 + 车厢长) / 2
			var first_gap:float=(head_length+carriage_length)*0.5/train_speed
			var body_gap:float=carriage_length/train_speed
			var volley=VOLLEY.new()
			volley.setup(TRAIN_HEAD,TRAIN_CARRIAGE,pos,dir,TRAIN_COUNT,body_gap,damage_multiply,"ju",dir*100,chain_count,first_gap,damage_add)
			tree.root.add_child(volley)
			continue
		var ball:Projectile=vehicle_scene.instantiate()
		ball.direction=dir
		ball.type="ju"
		ball.chain_count=chain_count
		ball.knocked_back=dir*100
		ball.global_position=pos
		ball.damage_mul*=damage_multiply
		ball.damage_add+=damage_add
		SignalBus.egg_shot.emit(ball)
		tree.root.add_child(ball)

#高铁的速度写在场景里，这里读一次缓存下来，以后调速度不用回来改间隔
static func _get_train_speed() -> float:
	if _train_speed<=0.0:
		var probe:Node=TRAIN_HEAD.instantiate()
		_train_speed=float(probe.get("speed"))
		probe.free()
	return maxf(_train_speed,1.0)
