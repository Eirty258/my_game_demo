extends Enemy









func _ready() -> void:
	super._ready()
	weekness="ice"
	scale=Vector2(2.0,2.0)
	close_attack_damage=8
	ai_velocity=speed*direction
	energy=15

func _physics_process(delta: float) -> void:
	super._physics_process(delta)

func _init() -> void:
	pass

func handle_ai():
	close_attacking()
