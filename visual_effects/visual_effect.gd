extends Node

var cutscene=preload("res://visual_effects/cutscene.tscn").instantiate()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	add_child(cutscene)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


#闪电链效果,用法cast_lightning(起点,终点)
func cast_lightning(from: Vector2, to: Vector2,color:Color=Color(0.8,0.9,1.0)) -> void:
	var line = draw_lightning(from, to,10,200.0,color)
	flicker_lightning(line)
func draw_lightning(from: Vector2, to: Vector2, segments: int = 10, jitter: float = 200.0,color:Color=Color(0.8,0.9,1.0)) -> Line2D:
	var line = Line2D.new()
	line.width = 500.0
	line.default_color = color
	line.texture = load("res://arts/texture/lightning.png")       # ← 贴图
	line.texture_mode = Line2D.LINE_TEXTURE_TILE            # ← 平铺
	line.points = _make_lightning_points(from, to, segments, jitter)
	get_tree().current_scene.add_child(line)
	return line
func _make_lightning_points(from: Vector2, to: Vector2, segments: int, jitter: float) -> PackedVector2Array:
	var points = PackedVector2Array()
	points.append(from)
	var dir = (to - from).normalized()
	var perp = Vector2(-dir.y, dir.x)
	for i in range(1, segments):
		var t = float(i) / segments
		var base = from.lerp(to, t)
		var offset = perp * randf_range(-jitter, jitter)
		points.append(base + offset)
	points.append(to)
	return points
func flicker_lightning(line: Line2D) -> void:
	var tween = create_tween()
	tween.set_loops(3)
	tween.tween_property(line, "modulate:a", 0.0, 0.03)
	tween.tween_property(line, "modulate:a", 1.0, 0.03)
	tween.tween_property(line, "modulate:a", 0.0, 0.2)
	tween.chain().tween_callback(line.queue_free)
#分支闪电链,暂时不会用
func draw_lightning_with_branches(from: Vector2, to: Vector2) -> Node2D:
	var root = Node2D.new()
	var main_line = draw_lightning(from, to)
	main_line.reparent(root)

	for i in randf_range(2, 3):
		var t = randf_range(0.2, 0.8)
		var branch_start = from.lerp(to, t)
		var branch_end = branch_start + Vector2(randf_range(-100, 100), randf_range(-100, 100))
		var branch = draw_lightning(branch_start, branch_end)
		branch.reparent(root)

	get_tree().current_scene.add_child(root)
	return root
#在节点之间持续产生闪电链
func sustained_lightning(from_node: Node2D, to_node: Node2D, duration: float = 3.0,color:Color=Color(0.8,0.9,1.0), interval: float = 0.05) -> void:
	var elapsed: float = 0.0
	while elapsed < duration:
		if not is_instance_valid(from_node) or not is_instance_valid(to_node):
			break
		cast_lightning(from_node.global_position, to_node.global_position,color)
		await get_tree().create_timer(interval).timeout
		elapsed += interval

func cutscene_in():
	cutscene.iris_in()
func cutscene_out():
	cutscene.iris_out()

const HINT_MAX_VISIBLE:=2#屏幕上最多同时显示几条
const HINT_BASE_DURATION:=5.0#单条基础显示时长
const HINT_MIN_DURATION:=1.5#排队太长时的最短显示时长
const HINT_QUEUE_SPEEDUP:=0.12#队列每多一条，显示时长缩短的比例
const HINT_SLOT_Y:=0.05#第一条离屏幕顶部的位置（屏幕高度比例）
const HINT_SLOT_GAP:=110.0#第二条往下偏多少像素
const HINT_FONT_MAIN:=48
const HINT_FONT_SUB:=36
const HINT_ALPHA_MAIN:=1.0
const HINT_ALPHA_SUB:=0.65#第二条更淡
const HINT_SCALE_SUB:=0.92#第二条略小
const HINT_MOVE_TIME:=0.2
const HINT_FADE_TIME:=0.3

var _hint_layer:CanvasLayer=null
var _hint_queue:Array=[]#排队等着显示的 {text,duration}
var _hint_slots:Array=[]#正在显示的 {label,duration,layout_tween}

#屏幕上方的说明文字：最多同时显示两条，多的排队，前一条消失后依次往上补
func show_text_hint(text: String, duration: float = HINT_BASE_DURATION) -> void:
	_hint_queue.append({"text":text,"duration":duration})
	_pump_hints()

func _get_hint_layer() -> CanvasLayer:
	if not is_instance_valid(_hint_layer):
		_hint_layer=CanvasLayer.new()
		_hint_layer.layer=100
		add_child(_hint_layer)
	return _hint_layer

#补位 + 重新排版
func _pump_hints() -> void:
	while _hint_slots.size()<HINT_MAX_VISIBLE&&not _hint_queue.is_empty():
		var item:Dictionary=_hint_queue.pop_front()
		#后面排队越多，这条显示得越短，免得越堆越多
		var wait_count:=_hint_queue.size()
		var show_time:float=maxf(HINT_MIN_DURATION,float(item["duration"])*(1.0-HINT_QUEUE_SPEEDUP*wait_count))
		_spawn_hint(str(item["text"]),show_time)
	for i in range(_hint_slots.size()):
		_apply_slot(_hint_slots[i],i,true)

func _spawn_hint(text:String,duration:float) -> void:
	var label:=Label.new()
	label.text=text
	label.add_theme_color_override("font_color",Color.WHITE)
	label.add_theme_color_override("font_outline_color",Color.BLACK)
	label.add_theme_constant_override("outline_size",4)
	label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
	var screen_size:=get_viewport().get_visible_rect().size
	label.size=Vector2(screen_size.x,100)
	label.pivot_offset=label.size/2.0
	#先按自己那一档摆好，再淡入
	var slot:=_hint_slots.size()
	var layout:=_slot_layout(slot)
	label.position=Vector2(0,float(layout["y"]))
	label.add_theme_font_size_override("font_size",int(layout["font"]))
	label.modulate.a=0.0
	label.scale=Vector2(0.85,0.85)
	_get_hint_layer().add_child(label)
	var entry:Dictionary={"label":label,"duration":duration,"layout_tween":null}
	_hint_slots.append(entry)
	_expire_hint(entry)

#每一条的样式：0 = 主位（大、亮、靠上），1 = 次位（小一点、淡一点、更靠下）
func _slot_layout(slot:int) -> Dictionary:
	var screen_h:=get_viewport().get_visible_rect().size.y
	if slot<=0:
		return {"y":screen_h*HINT_SLOT_Y,"font":HINT_FONT_MAIN,"alpha":HINT_ALPHA_MAIN,"scale":1.0}
	return {
		"y":screen_h*HINT_SLOT_Y+HINT_SLOT_GAP,
		"font":HINT_FONT_SUB,
		"alpha":HINT_ALPHA_SUB,
		"scale":HINT_SCALE_SUB,
	}

func _apply_slot(entry:Dictionary,slot:int,animate:bool) -> void:
	var label:Label=entry["label"]
	if not is_instance_valid(label):
		return
	var layout:=_slot_layout(slot)
	label.add_theme_font_size_override("font_size",int(layout["font"]))
	var old_tween=entry.get("layout_tween")
	if old_tween!=null and old_tween.is_valid():
		old_tween.kill()
	var target_pos:=Vector2(0,float(layout["y"]))
	var target_scale:=Vector2.ONE*float(layout["scale"])
	var target_alpha:=float(layout["alpha"])
	if not animate:
		label.position=target_pos
		label.scale=target_scale
		label.modulate.a=target_alpha
		return
	var tween:=label.create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(label,"position",target_pos,HINT_MOVE_TIME)
	tween.tween_property(label,"scale",target_scale,HINT_MOVE_TIME)
	tween.tween_property(label,"modulate:a",target_alpha,HINT_MOVE_TIME)
	entry["layout_tween"]=tween

func _expire_hint(entry:Dictionary) -> void:
	await get_tree().create_timer(entry["duration"]).timeout
	var label:Label=entry.get("label")
	if not is_instance_valid(label):
		return
	var old_tween=entry.get("layout_tween")
	if old_tween!=null and old_tween.is_valid():
		old_tween.kill()
	var fade:=label.create_tween()
	fade.tween_property(label,"modulate:a",0.0,HINT_FADE_TIME)
	await fade.finished
	if is_instance_valid(label):
		label.queue_free()
	_hint_slots.erase(entry)
	_pump_hints()

#------------------------------------------------------------------
#伤害数字
#用法：VisualEffect.show_damage_number(世界坐标, 伤害值)
#字号随伤害变大，有上下限；屏幕上飘起后淡出
const DAMAGE_FONT_MIN:int=26          #字号下限
const DAMAGE_FONT_MAX:int=110         #字号上限
const DAMAGE_FONT_BASE:int=26         #基础字号（伤害为 0 时的字号）
const DAMAGE_FONT_PER_DAMAGE:float=4.0#每 1 点伤害增加的字号
const DAMAGE_NUMBER_RISE:float=110.0  #向上飘的像素
const DAMAGE_NUMBER_LIFETIME:float=0.7
const DAMAGE_NUMBER_LAYER:int=90      #低于文字提示(100)，高于游戏画面
const DAMAGE_NUMBER_BOX:Vector2=Vector2(600.0,220.0)#固定大小的居中文本框

var _damage_layer:CanvasLayer=null

func show_damage_number(world_position:Vector2,damage:float,color:Color=Color(1.0,0.86,0.32)) -> void:
	if damage<=0.0:
		return
	#世界坐标 -> 屏幕坐标（自动带上当前相机的位置和缩放）
	var screen_pos:Vector2=get_viewport().get_canvas_transform()*world_position
	#随机偏移，避免连续命中时数字完全重叠
	screen_pos+=Vector2(randf_range(-24.0,24.0),randf_range(-16.0,16.0))
	var font_size:int=get_damage_font_size(damage)

	var label:=Label.new()
	label.text=format_damage(damage)
	label.add_theme_font_size_override("font_size",font_size)
	label.add_theme_color_override("font_color",color)
	label.add_theme_color_override("font_outline_color",Color.BLACK)
	label.add_theme_constant_override("outline_size",maxi(2,font_size/12))
	label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter=Control.MOUSE_FILTER_IGNORE

	_get_damage_layer().add_child(label)
	label.size=DAMAGE_NUMBER_BOX
	label.pivot_offset=DAMAGE_NUMBER_BOX*0.5
	label.position=screen_pos-DAMAGE_NUMBER_BOX*0.5
	label.scale=Vector2.ONE*0.6
	label.modulate.a=0.0

	var tween:=label.create_tween()
	tween.set_parallel(true)
	tween.tween_property(label,"modulate:a",1.0,0.08)
	tween.tween_property(label,"scale",Vector2.ONE,0.14)\
		.set_trans(Tween.TRANS_BACK)\
		.set_ease(Tween.EASE_OUT)
	tween.tween_property(label,"position:y",label.position.y-DAMAGE_NUMBER_RISE,DAMAGE_NUMBER_LIFETIME)\
		.set_trans(Tween.TRANS_QUAD)\
		.set_ease(Tween.EASE_OUT)
	tween.chain().tween_property(label,"modulate:a",0.0,0.2)
	tween.chain().tween_callback(label.queue_free)

#按伤害算字号，并夹在上下限之间
func get_damage_font_size(damage:float) -> int:
	var raw_size:float=DAMAGE_FONT_BASE+damage*DAMAGE_FONT_PER_DAMAGE
	return clampi(roundi(raw_size),DAMAGE_FONT_MIN,DAMAGE_FONT_MAX)

#整数伤害不带小数点，非整数保留一位
func format_damage(damage:float) -> String:
	if is_equal_approx(damage,roundf(damage)):
		return str(roundi(damage))
	return "%.1f"%damage

#伤害数字共用一个 CanvasLayer，避免每次都新建
func _get_damage_layer() -> CanvasLayer:
	if not is_instance_valid(_damage_layer):
		_damage_layer=CanvasLayer.new()
		_damage_layer.layer=DAMAGE_NUMBER_LAYER
		add_child(_damage_layer)
	return _damage_layer
