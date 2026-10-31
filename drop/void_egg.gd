extends Drop

var click_count=0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$AnimatedSprite2D.play("complete")
	$Void.visible=false
	float_up_down($AnimatedSprite2D)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func handle_click():
	click_count+=1
	if click_count==1:
		break_()
	elif click_count>=2:
		disappear()

func float_up_down(sprite: Node, amplitude: float = 30.0, duration: float = 1.5) -> void:
	if sprite == null or not is_instance_valid(sprite):
		return

	var start_pos = sprite.position
	var tween = create_tween()
	tween.set_loops()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(sprite, "position:y", start_pos.y - amplitude, duration)
	tween.tween_property(sprite, "position:y", start_pos.y, duration)

func break_():
	$AnimatedSprite2D.play("break")
	$CollisionShape2D.disabled=true
	await get_tree().create_timer(0.5).timeout
	$Void.visible=true
	$Void.play("spin")
	await $AnimatedSprite2D.animation_finished
	$AnimatedSprite2D.play("broken")
	$CollisionShape2D.disabled=false
func disappear():
	#focus_camera(global_position,0.3,5)
	$AnimatedSprite2D.play("disappear")
	$CollisionShape2D.disabled=true
	SignalBus.void_clicked.emit()
	GameState.is_floor_cleared=true
	var tween=create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property($Void,"speed_scale",10.0,2.83)
	await $AnimatedSprite2D.animation_finished

func focus_camera(world_pos: Vector2, zoom_multiplier: float = 0.30, duration: float = 0.5) -> void:
	var camera = get_viewport().get_camera_2d()
	if camera == null:
		push_error("没有 Camera2D")
		return

	var tween = create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)

	tween.tween_property(camera, "global_position", world_pos, duration)
	tween.tween_property(camera, "zoom", Vector2(zoom_multiplier, zoom_multiplier), duration)
