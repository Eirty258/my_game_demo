extends Egg

#红车：和炮一样单颗可发射，但打出来的是随机载具

const VEHICLE_SCENES=[
	preload("res://projectiles/vehicles/ju_stroller.tscn"),#婴儿车
	preload("res://projectiles/vehicles/ju_bicycle.tscn"),#自行车
	preload("res://projectiles/vehicles/ju_motorcycle.tscn"),#摩托车
	preload("res://projectiles/vehicles/ju_minibus.tscn"),#小客车
	preload("res://projectiles/vehicles/ju_truck.tscn"),#大货车
	preload("res://projectiles/vehicles/ju_train_head.tscn"),#高铁
]

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
		var ball=vehicle_scene.instantiate()
		ball.direction=i
		ball.type=type
		ball.knocked_back=i*100
		ball.global_position=global_position
		ball.damage_mul*=damage_multiply
		SignalBus.egg_shot.emit(ball)
		get_tree().root.add_child(ball)
