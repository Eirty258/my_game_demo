extends Egg


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super._ready()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _init() -> void:
	type="fire"

func shoot(chain_count:int):
	var fire_ball_scene:PackedScene=load("res://projectiles/fire_ball.tscn")
	var damage_multiply:float=1+(chain_count-max(GameState.min_chain,1))/5#TODO 硬编码要修改
	for i in directions:
		var fire_ball=fire_ball_scene.instantiate()
		fire_ball.direction=i
		fire_ball.type=type
		fire_ball.knocked_back=i*100
		fire_ball.global_position=global_position
		fire_ball.damage_mul*=damage_multiply
		SignalBus.egg_shot.emit(fire_ball)
		get_tree().root.add_child(fire_ball)
