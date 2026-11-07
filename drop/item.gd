extends Drop

const TOAST_HOLD:=5.0#提示停留时长
const TOAST_FADE:=1.0#正常淡出时长
const TOAST_DISMISS_FADE:=1.0#被新道具顶掉时的淡出时长

#当前正在显示提示的道具（所有道具共享一个"当前"）
static var _active_toast:Node=null

var id:int=-1
var item_name:String="charcoal"
var speed:float=1
var _toast_tween:Tween=null
var _fading:bool=false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	setup()
	float_up_down($Icon)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	$Background1.rotation+=delta*0.25*speed
	$Background2.rotation-=delta*0.5*speed

func handle_click():
	#新道具一被拾取，就让上一个道具和它的说明文字立刻淡出
	dismiss_active_toast()
	_active_toast=self
	$CollisionShape2D.disabled=true
	SignalBus.item_clicked.emit(item_name)
	#漂浮到画面中间并显示内容
	process_mode=Node.PROCESS_MODE_ALWAYS
	speed=5
	await move_up()
	if not is_inside_tree():
		return
	var slow_tween=create_tween()
	slow_tween.set_ease(Tween.EASE_IN)
	slow_tween.tween_property(self,"speed",0,TOAST_HOLD)
	show_item_toast()
	#到点后自己淡出
	if _toast_tween!=null and _toast_tween.is_valid():
		_toast_tween.kill()
	_toast_tween=create_tween()
	_toast_tween.tween_interval(TOAST_HOLD)
	_toast_tween.tween_callback(func():
		_start_fade_out(TOAST_FADE)
	)

#让当前正在显示的道具提示立刻淡出（由新道具拾取时调用）
static func dismiss_active_toast() -> void:
	var old=_active_toast
	_active_toast=null
	if old==null or not is_instance_valid(old):
		return
	old.dismiss_now()

#被顶掉：停掉自己的计时，直接快速淡出并销毁
func dismiss_now() -> void:
	if _toast_tween!=null and _toast_tween.is_valid():
		_toast_tween.kill()
	_start_fade_out(TOAST_DISMISS_FADE)

func _start_fade_out(duration:float=TOAST_FADE) -> void:
	if _fading:
		return
	_fading=true
	var label=$Control/Label
	var tween=create_tween()
	tween.set_parallel(true)
	tween.tween_property(self,"modulate:a",0.0,duration)
	if label!=null:
		tween.tween_property(label,"modulate:a",0.0,duration)
	tween.set_parallel(false)
	tween.tween_callback(_free_self)

func _free_self() -> void:
	if _active_toast==self:
		_active_toast=null
	queue_free()

func setup():
	#贴图还没做的道具 Icon 就空着，不报错
	$Icon.texture=ItemData.get_icon_texture(item_name)

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
