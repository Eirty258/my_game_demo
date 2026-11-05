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
