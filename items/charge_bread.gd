extends Item


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	item_name="charge_bread"
	SignalBus.electricity_ball_spawned.connect(electricity_ball_damage_add)
	WeightTable.random_eggs["electricity"]+=1


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func electricity_ball_damage_add(electricity_ball:Projectile):
	electricity_ball.damage_add+=1
