extends Item


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	item_name="charcoal"
	SignalBus.fire_ball_spawned.connect(fire_ball_damage_add)
	WeightTable.random_eggs["fire"]+=1


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func fire_ball_damage_add(fire_ball:Projectile):
	fire_ball.damage_add+=1
