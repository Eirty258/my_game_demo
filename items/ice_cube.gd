extends Item


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	item_name="ice_cube"
	SignalBus.ice_ball_spawned.connect(ice_ball_damage_add)
	WeightTable.random_eggs["ice"]+=1


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func ice_ball_damage_add(ice_ball:Projectile):
	ice_ball.damage_add+=1
