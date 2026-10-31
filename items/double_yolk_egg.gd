extends Item


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	item_name="double_yolk_egg"
	SignalBus.egg_shot.connect(double_yolk)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func double_yolk(projectile: Projectile, spacing: float = 100.0) -> void:
	var copy = projectile.duplicate()
	var dir = projectile.direction
	var origin = projectile.global_position
	var perp = Vector2(-dir.y, dir.x).normalized()
	projectile.global_position = origin + perp * (spacing * 0.5)
	copy.global_position = origin - perp * (spacing * 0.5)
	copy.damage_mul*=0.8
	projectile.damage_mul*=0.8
	get_tree().root.add_child(copy)
