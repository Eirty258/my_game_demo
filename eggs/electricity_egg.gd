extends Egg


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super._ready()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _init() -> void:
	type="electricity"

func shoot(chain_count:int):
	var electricity_ball_scene:PackedScene=load("res://projectiles/electricity_ball.tscn")
	var damage_multiply:float=1+(chain_count-max(GameState.min_chain-1,1))/5#TODO 硬编码要修改
	for i in directions:
		var electricity_ball=electricity_ball_scene.instantiate()
		electricity_ball.direction=i
		electricity_ball.type=type
		electricity_ball.knocked_back=i*100
		electricity_ball.global_position=global_position
		electricity_ball.damage_mul*=damage_multiply
		SignalBus.egg_shot.emit(electricity_ball)
		get_tree().root.add_child(electricity_ball)
