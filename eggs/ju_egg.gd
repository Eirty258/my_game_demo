extends Egg

#红车：和炮一样单颗可发射，但打出来的是随机载具

const VEHICLE_SCENES=[
	#preload("res://projectiles/vehicles/ju_stroller.tscn"),#婴儿车
	#preload("res://projectiles/vehicles/ju_bicycle.tscn"),#自行车
	#preload("res://projectiles/vehicles/ju_motorcycle.tscn"),#摩托车
	#preload("res://projectiles/vehicles/ju_minibus.tscn"),#小客车
	#preload("res://projectiles/vehicles/ju_truck.tscn"),#大货车
	preload("res://projectiles/vehicles/ju_train_head.tscn"),#高铁
]

const VOLLEY=preload("res://projectiles/volley.gd")
const TRAIN_HEAD=preload("res://projectiles/vehicles/ju_train_head.tscn")
const TRAIN_CARRIAGE=preload("res://projectiles/vehicles/ju_train_carriage.tscn")
const TRAIN_COUNT:=16#1 车头 + 15 车厢
const TRAIN_INTERVAL:=0.04#8192 速度下约 328 像素一节

func _init() -> void:
	type="ju"

func _ready() -> void:
	super._ready()

func _process(delta: float) -> void:
	pass

func shoot(chain_count:int):
	var vehicle_scene:PackedScene=VEHICLE_SCENES.pick_random()
	var damage_multiply:float=1+(chain_count-1)/5
	for i in directions:
		if vehicle_scene==TRAIN_HEAD:
			#高铁：从棋子位置一节节发出去，跟车头的位置、存活都无关
			var volley=VOLLEY.new()
			volley.setup(TRAIN_HEAD,TRAIN_CARRIAGE,global_position,i,TRAIN_COUNT,TRAIN_INTERVAL,damage_multiply,type,i*100)
			get_tree().root.add_child(volley)
			continue
		var ball=vehicle_scene.instantiate()
		ball.direction=i
		ball.type=type
		ball.knocked_back=i*100
		ball.global_position=global_position
		ball.damage_mul*=damage_multiply
		SignalBus.egg_shot.emit(ball)
		get_tree().root.add_child(ball)
