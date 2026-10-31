extends Drop

var id:int=-1
var item_name:String="charcoal"
var speed:float=1
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	setup()
	float_up_down($Icon)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	$Background1.rotation+=delta*0.25*speed
	$Background2.rotation-=delta*0.5*speed

func handle_click():
	$CollisionShape2D.disabled=true
	SignalBus.item_clicked.emit(item_name)
	#漂浮到画面中间并显示内容
	process_mode=Node.PROCESS_MODE_ALWAYS
	speed=5
	await move_up()
	
	var tween=create_tween()
	tween.set_ease(Tween.EASE_IN)
	tween.tween_property(self,"speed",0,5)
	
	show_item_toast()
	await get_tree().create_timer(5).timeout
	var tween1=create_tween()
	tween1.tween_property(self, "modulate:a", 0.0, 1)
	await tween1.finished
	queue_free()

func setup():
	$Icon.texture=load("res://arts/texture/%s.png"%item_name)

func float_up_down(sprite: Sprite2D, amplitude: float = 30.0, duration: float = 1.5) -> void:
	if sprite == null or not is_instance_valid(sprite):
		return

	var start_pos = sprite.position
	var tween = create_tween()
	tween.set_loops()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(sprite, "position:y", start_pos.y - amplitude, duration)
	tween.tween_property(sprite, "position:y", start_pos.y, duration)

func screen_to_world(screen_pos: Vector2) -> Vector2:
	var canvas_transform = get_viewport().get_canvas_transform()
	return canvas_transform.affine_inverse() * screen_pos

func move_up():
	var pos=screen_to_world(Vector2(512,100))
	var move_tween=create_tween()
	move_tween.tween_property(self,"global_position",pos,1)
	await move_tween.finished

func show_item_toast() -> void:
	var name=ItemData.item_chinese_name[item_name]
	var description=ItemData.item_description[item_name]
	var label = $Control/Label
	label.text = "%s：%s" % [name, description]
	label.visible = true
	label.modulate.a = 0.0
	label.scale = Vector2(1, 1)
	label.pivot_offset = label.size / 2.0
	
	var tween1 = create_tween()
	tween1.set_parallel(true)
	tween1.tween_property(label, "modulate:a", 1.0, 0.2)
	tween1.tween_property(label, "scale", Vector2.ONE, 0.2)
	tween1.set_parallel(false)
	tween1.tween_interval(5.0)
