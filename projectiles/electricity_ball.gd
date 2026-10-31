extends Projectile


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	speed=4096*1.5
	super._ready()
	SignalBus.electricity_ball_spawned.emit(self)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	super._process(delta)
