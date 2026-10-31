extends Area2D
class_name Egg

signal egg_clicked(egg:Egg,mouse_pos: Vector2)

var coordinate:Vector2i=Vector2i.ZERO
var type:String="null"
var group_id: int = -1:
	set(value):
		if group_id == value:
			return   # 值没变，不触发
		group_id = value
		_on_group_id_changed(value)
var directions=[]#待发射的有方向
var shards_number:int=1
var disabled:bool=false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	spawn_animation()
	#inactivate()
	#await  get_tree().create_timer(3).timeout
	#activate()
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _input_event(viewport: Viewport, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.double_click:
			#print("双击")
			SignalBus.egg_double_clicked.emit(self)
			get_viewport().set_input_as_handled()
			return
		if event.button_index==MOUSE_BUTTON_LEFT&&event.pressed:
			egg_clicked.emit(self,event.global_position)
			#print("已按下")
			get_viewport().set_input_as_handled()

func move_to(target: Vector2, duration: float = 0.15) -> void:
	var tween := create_tween()
	tween.tween_property(self, "global_position", target, duration)

func _on_group_id_changed(value):
	if value==-1:
		$AnimatedSprite2D.play("idle")
	else:
		$AnimatedSprite2D.frame=0
		$AnimatedSprite2D.play("active")

func shoot(chain_count:int):
	pass

func die():
	$CollisionShape2D.disabled=true
	GameState.modify_egg_shards(shards_number)
	get_parent().egg_number_reduce()
	die_animation()

func spawn_animation():
	scale = Vector2.ZERO
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2.ONE, 0.3)
	
func die_animation():
	var tween = create_tween()
	#tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_IN)
	tween.tween_property(self, "scale", Vector2.ZERO, 0.3)
	await tween.finished
	queue_free()


#变暗
func dim_self_smooth(amount: float = 0.5, duration: float = 0.3) -> void:
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(amount, amount, amount, modulate.a), duration)
#恢复
func restore_self_smooth(duration: float = 0.3) -> void:
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color.WHITE, duration)

#失活
func inactivate():
	disabled=true
	$CollisionShape2D.disabled=true
	dim_self_smooth()
	get_parent().rescan_groups()
#激活
func activate():
	disabled=false
	$CollisionShape2D.disabled=false
	restore_self_smooth()
	get_parent().rescan_groups()
#失活若干秒
func inactivate_temporarily(duration:float=10):
	inactivate()
	await get_tree().create_timer(duration).timeout
	activate()

func disable_collisionshape():
	$CollisionShape2D.disabled=true
