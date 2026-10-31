extends Egg


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super._ready()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _init() -> void:
	type="ice"

func shoot(chain_count:int):
	var ice_ball_scene:PackedScene=load("res://projectiles/ice_ball.tscn")
	var damage_multiply:float=1+(chain_count-max(GameState.min_chain,1))/5#TODO 硬编码要修改
	for i in directions:
		var ice_ball=ice_ball_scene.instantiate()
		ice_ball.direction=i
		ice_ball.type=type
		ice_ball.knocked_back=i*100
		ice_ball.global_position=global_position
		ice_ball.damage_mul*=damage_multiply
		SignalBus.egg_shot.emit(ice_ball)
		get_tree().root.add_child(ice_ball)
