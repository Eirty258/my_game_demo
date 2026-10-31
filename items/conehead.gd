extends Item


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	item_name="conehead"
	SignalBus.projectile_spawned.connect(set_pierce_flag)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func set_pierce_flag(projectile:Projectile):
	projectile.pierce_flag=true
