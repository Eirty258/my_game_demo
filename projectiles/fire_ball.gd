extends Projectile


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super._ready()
	SignalBus.fire_ball_spawned.emit(self)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	super._process(delta)

func _on_area_entered(area: Area2D) -> void:
	if has_hit&&!pierce_flag:#防止同一帧击中多个敌人
		return
	var body=area.get_parent()
	if body is Enemy:
		if hit_targets.has(body):
			return
		hit_targets[body]=true
		has_hit=true
		body.take_hit(final_damage,knocked_back,type)
		if pierce_flag:
			return
		var params={
			"burn_damage":final_damage/10,
			"duration":float(3.0)
		}
		body.add_buff("burn",params)
		#params={
			#"size":0.7
		#}
		#body.add_buff("tiny",params)
		queue_free()
