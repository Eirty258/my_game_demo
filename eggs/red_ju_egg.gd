extends Egg

#红车：和炮一样单颗可发射，但打出来的是随机载具

#载具名 -> 场景；键名必须和 WeightTable.red_ju_vehicles 里的一致，权重统一在那张表里调
const VEHICLE_SCENES:Dictionary={
	"red_ju_stroller":preload("res://projectiles/vehicles/red_ju_stroller.tscn"),#婴儿车
	"red_ju_bicycle":preload("res://projectiles/vehicles/red_ju_bicycle.tscn"),#自行车
	"red_ju_motorcycle":preload("res://projectiles/vehicles/red_ju_motorcycle.tscn"),#摩托车
	"red_ju_minibus":preload("res://projectiles/vehicles/red_ju_minibus.tscn"),#小客车
	"red_ju_truck":preload("res://projectiles/vehicles/red_ju_truck.tscn"),#大货车
	"red_ju_train_head":preload("res://projectiles/vehicles/red_ju_train_head.tscn"),#高铁
}

const VOLLEY=preload("res://projectiles/volley.gd")
const TRAIN_HEAD=preload("res://projectiles/vehicles/red_ju_train_head.tscn")
const TRAIN_CARRIAGE=preload("res://projectiles/vehicles/red_ju_train_carriage.tscn")
const TRAIN_COUNT:=16#1 车头 + 15 车厢
#高铁各节贴图的长度（像素，高度都是512）：车头 1481、车厢 2273
#发车间隔按“长度 / 速度”算，车与车才会首尾相接（贴图都是中心对齐的）
const TRAIN_HEAD_LENGTH:=1481.0
const TRAIN_CARRIAGE_LENGTH:=2273.0

var _train_speed:float=0.0

func _init() -> void:
	type="ju"

func _ready() -> void:
	super._ready()

func _process(delta: float) -> void:
	pass

func shoot(chain_count:int):
	var vehicle_type:String=WeightTable.pick_by_weight(WeightTable.red_ju_vehicles)
	if not VEHICLE_SCENES.has(vehicle_type):
		push_warning("红车：权重表里的载具 %s 没有对应场景" % vehicle_type)
		return
	var vehicle_scene:PackedScene=VEHICLE_SCENES[vehicle_type]
	var damage_multiply:float=1+(chain_count-1)/5
	for i in directions:
		if vehicle_scene==TRAIN_HEAD:
			#高铁：从棋子位置一节节发出去，跟车头的位置、存活都无关
			var train_speed:=_get_train_speed()
			#车头中心到第一节车厢中心 = (车头长 + 车厢长) / 2
			var first_gap:float=(TRAIN_HEAD_LENGTH+TRAIN_CARRIAGE_LENGTH)*0.5/train_speed
			var body_gap:float=TRAIN_CARRIAGE_LENGTH/train_speed
			var volley=VOLLEY.new()
			volley.setup(TRAIN_HEAD,TRAIN_CARRIAGE,global_position,i,TRAIN_COUNT,body_gap,damage_multiply,type,i*100,chain_count,first_gap)
			get_tree().root.add_child(volley)
			continue
		var ball=vehicle_scene.instantiate()
		ball.direction=i
		ball.type=type
		ball.chain_count=chain_count
		ball.knocked_back=i*100
		ball.global_position=global_position
		ball.damage_mul*=damage_multiply
		SignalBus.egg_shot.emit(ball)
		get_tree().root.add_child(ball)

#高铁的速度写在场景里，这里读一次缓存下来，以后调速度不用回来改间隔
func _get_train_speed() -> float:
	if _train_speed<=0.0:
		var probe:Node=TRAIN_HEAD.instantiate()
		_train_speed=float(probe.get("speed"))
		probe.free()
	return maxf(_train_speed,1.0)
