extends "res://projectiles/vehicle_ball.gd"

#高铁车头：自带穿透，按节依次放出车厢，最后共 10 节

const CARRIAGE_SCENE=preload("res://projectiles/vehicles/ju_train_carriage.tscn")
const CARRIAGE_COUNT:=10
const CARRIAGE_INTERVAL:=0.08
const CARRIAGE_SPACING:=320.0

func _ready() -> void:
	super._ready()
	_spawn_carriages()

func _spawn_carriages() -> void:
	for i in range(CARRIAGE_COUNT-1):
		await get_tree().create_timer(CARRIAGE_INTERVAL).timeout
		if not is_instance_valid(self):
			return
		var carriage=CARRIAGE_SCENE.instantiate()
		carriage.direction=direction
		carriage.type=type
		carriage.damage_mul=damage_mul
		carriage.knocked_back=knocked_back
		carriage.global_position=global_position-direction.normalized()*CARRIAGE_SPACING
		get_tree().root.add_child(carriage)
