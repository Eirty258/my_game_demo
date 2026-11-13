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

#鼠标悬停时微微放大 + 提亮
const HOVER_SCALE:=1.12
const HOVER_GLOW:=Color(1.35,1.35,1.35,1.0)
const HOVER_TIME:=0.12
var _hover_tween:Tween=null
var _playing_death:bool=false

#可发射的金边：棋类（车/炮）没有真正的"active"动画，靠金边提示可发射
const GOLD_OUTLINE=preload("res://visual_effects/gold_outline.gd")
const OUTLINE_PX:=10.0
const GLOW_PX:=22.0
var _plain_material:Material=null#原本的材质，摘掉金边时还回去
var _outline_material:ShaderMaterial=null
var _five_outline:bool=false#五子棋道具专用的金边开关

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_plain_material=$AnimatedSprite2D.material
	spawn_animation()
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	#inactivate()
	#await  get_tree().create_timer(3).timeout
	#activate()
	pass # Replace with function body.

func _on_mouse_entered() -> void:
	_hover_to(HOVER_SCALE,HOVER_GLOW)

func _on_mouse_exited() -> void:
	_hover_to(1.0,Color.WHITE)

func _hover_to(target_scale:float,target_glow:Color) -> void:
	if _playing_death:
		return
	if _hover_tween and _hover_tween.is_valid():
		_hover_tween.kill()
	_hover_tween=create_tween()
	_hover_tween.set_parallel(true)
	_hover_tween.set_trans(Tween.TRANS_QUAD)
	_hover_tween.set_ease(Tween.EASE_OUT)
	_hover_tween.tween_property(self,"scale",Vector2.ONE*target_scale,HOVER_TIME)
	#用 self_modulate 提亮，避免和失活变暗用的 modulate 打架
	_hover_tween.tween_property(self,"self_modulate",target_glow,HOVER_TIME)


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
		#有真正的 active 动画就播放；没有（棋类）就保持 idle，用金边提示
		if has_active_animation():
			$AnimatedSprite2D.play("active")
		else:
			$AnimatedSprite2D.play("idle")
	_refresh_outline()

#这个蛋的贴图资源里，active 是否是"不一样的动画"（不是和 idle 同一张图）
func has_active_animation() -> bool:
	var frames:SpriteFrames=$AnimatedSprite2D.sprite_frames
	if frames==null or not frames.has_animation("active"):
		return false
	var active_count:=frames.get_frame_count("active")
	if not frames.has_animation("idle"):
		return active_count>1
	if active_count!=frames.get_frame_count("idle"):
		return true
	for i in range(active_count):
		if frames.get_frame_texture("active",i)!=frames.get_frame_texture("idle",i):
			return true
	return false

#五子棋道具：外部开关，和"可发射金边"共用同一块材质
func set_five_outline(enabled:bool) -> void:
	_five_outline=enabled
	_refresh_outline()

func _refresh_outline() -> void:
	var sprite:AnimatedSprite2D=$AnimatedSprite2D
	if sprite==null:
		return
	var want_gold:bool=_five_outline or (group_id!=-1 and not has_active_animation())
	if want_gold:
		if _outline_material==null:
			_outline_material=GOLD_OUTLINE.make_material(OUTLINE_PX,GLOW_PX)
		sprite.material=_outline_material
	else:
		sprite.material=_plain_material

func shoot(chain_count:int):
	pass

#破碎（双击打碎 / 被献祭）时的钩子，子类可覆盖
func on_broken() -> void:
	pass

func die():
	_playing_death=true#死亡动画期间不要被悬停效果拉回来
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
