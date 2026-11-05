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

var _current_hint_layer: CanvasLayer = null
var _current_hint_tween: Tween = null

func show_text_hint(text: String, duration: float = 5.0) -> void:
	# 先清除上一个提示
	if _current_hint_tween and _current_hint_tween.is_valid():
		_current_hint_tween.kill()
	if is_instance_valid(_current_hint_layer):
		_current_hint_layer.queue_free()

	var label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 48)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 4)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	var screen_size = get_viewport().get_visible_rect().size
	label.size = Vector2(screen_size.x, 100)
	label.position = Vector2(0, screen_size.y * 0.05)
	label.pivot_offset = label.size / 2.0

	label.modulate.a = 0.0
	label.scale = Vector2(0.8, 0.8)

	var canvas_layer = CanvasLayer.new()
	canvas_layer.layer = 100
	canvas_layer.add_child(label)
	add_child(canvas_layer)

	_current_hint_layer = canvas_layer

	_current_hint_tween = create_tween()
	_current_hint_tween.set_parallel(true)
	_current_hint_tween.tween_property(label, "modulate:a", 1.0, 0.2)
	_current_hint_tween.tween_property(label, "scale", Vector2.ONE, 0.2)\
		.set_trans(Tween.TRANS_BACK)\
		.set_ease(Tween.EASE_OUT)
	_current_hint_tween.chain().tween_interval(duration)
	_current_hint_tween.chain().tween_property(label, "modulate:a", 0.0, 0.3)
	_current_hint_tween.chain().tween_callback(func():
		if is_instance_valid(canvas_layer):
			canvas_layer.queue_free()
		if _current_hint_layer == canvas_layer:
			_current_hint_layer = null
	)

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
