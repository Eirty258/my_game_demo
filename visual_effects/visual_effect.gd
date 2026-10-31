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
