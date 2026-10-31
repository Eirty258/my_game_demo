extends Projectile


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	speed=4096*randf_range(0.6,0.8)
	super._ready()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	super._process(delta)
	rotation += delta * 10.0

func update_scale():
	pass
