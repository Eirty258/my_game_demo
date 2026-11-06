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
const TRAIN_INTERVAL:=0.04#8192 速度下约 328 像素一节

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
			var volley=VOLLEY.new()
			volley.setup(TRAIN_HEAD,TRAIN_CARRIAGE,global_position,i,TRAIN_COUNT,TRAIN_INTERVAL,damage_multiply,type,i*100,chain_count)
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
