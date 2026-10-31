extends Enemy




func _ready() -> void:
	super._ready()
	weekness="null"
	speed=200
	health=3
	close_attack_damage=3
	energy=5
	ai_velocity=speed*direction

func _physics_process(delta: float) -> void:
	super._physics_process(delta)

func _init() -> void:
	pass

func handle_ai():
	close_attacking()
