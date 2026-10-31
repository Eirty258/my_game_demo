extends Item


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	item_name="sharp_shards"
	SignalBus.egg_shot.connect(spawn_sharp_shards)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func spawn_sharp_shards(projectile:Projectile):
	var ss1_scene:PackedScene=load("res://projectiles/sharp_shard_1.tscn")
	var ss2_scene:PackedScene=load("res://projectiles/sharp_shard_2.tscn")
	var ss3_scene:PackedScene=load("res://projectiles/sharp_shard_3.tscn")
	for i in randi_range(1,2):
		var r=randi_range(1,3)
		var ss
		if r==1:
			ss=ss1_scene.instantiate()
			ss.damage=2
		elif r==2:
			ss=ss2_scene.instantiate()
			ss.damage=1.5
		elif r==3:
			ss=ss3_scene.instantiate()
			ss.damage=1
		ss.global_position=projectile.global_position+Vector2(randf_range(-128,128),randf_range(-128,128))
		ss.direction=projectile.direction
		ss.knocked_back=ss.direction*30
		get_tree().root.add_child(ss)
