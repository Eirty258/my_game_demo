extends CanvasLayer

@export var egg_shards=0
@export var energy=0
var board:Board
var _energy_tween: Tween = null
var energy_bar_mode:String="energy":
	set(value):
		energy_bar_mode=value
		if energy_bar_mode=="boss":
			$HUD/BossIcon.visible=true
			$HUD/BossIcon2.visible=false
		elif energy_bar_mode=="energy":
			$HUD/BossIcon.visible=false
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	board=get_tree().get_first_node_in_group("board")
	update_all()
	SignalBus.egg_shards_updated.connect(update_egg_shards_label)
	SignalBus.energy_updated.connect(update_energy)
	SignalBus.energy_full.connect(_on_energy_full)
	SignalBus.boss_cleared.connect(_on_boss_cleared)
	SignalBus.edge_destroyed.connect(gameover)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func update_all():
	update_egg_shards_label(GameState.egg_shards)
	update_energy(GameState.energy)

func update_egg_shards_label(value):
	
	var difference=value-egg_shards
	egg_shards=value
	$HUD/TopLeft/PanelContainer/EggShardsUI/Count.text=str(egg_shards)


#func update_energy(value):
	#var difference=value-energy
	#energy=value
	#$HUD/EnergyBar.value=energy
func update_energy(value: float) -> void:
	if _energy_tween and _energy_tween.is_valid():
		_energy_tween.kill()
	energy = value
	_energy_tween = create_tween()
	_energy_tween.set_trans(Tween.TRANS_QUAD)
	_energy_tween.set_ease(Tween.EASE_OUT)
	_energy_tween.tween_property($HUD/EnergyBar, "value", energy, 0.5)


func setup_top_center(order:Node):#好像没用
	add_child(order)


func _on_energy_full():
	energy_bar_mode="boss"

func _on_boss_cleared():
	energy_bar_mode="energy"


func show_game_over() -> void:
	var canvas_layer = CanvasLayer.new()
	canvas_layer.layer = 1
	add_child(canvas_layer)

	# Game Over 文字
	var label = Label.new()
	label.text = "Game Over"
	label.add_theme_font_size_override("font_size", 72)
	label.add_theme_color_override("font_color", Color(1.0, 0.2, 0.2))
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 6)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.set_anchors_preset(Control.PRESET_FULL_RECT)

	var screen_size = get_viewport().get_visible_rect().size
	label.pivot_offset = screen_size / 2.0
	label.modulate.a = 0.0
	label.scale = Vector2(2.0, 2.0)

	canvas_layer.add_child(label)

	# 重启按钮
	var restart = preload("res://ui/restart_button.tscn").instantiate()
	#restart.set_anchors_preset(Control.PRESET_CENTER)
	restart.position = Vector2(screen_size.x / 2.0, screen_size.y / 2.0+128)
	#restart.pivot_offset = screen_size / 2.0
	restart.modulate.a = 0.0
	canvas_layer.add_child(restart)

	# 入场动画
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "modulate:a", 1.0, 0.5)
	tween.tween_property(label, "scale", Vector2.ONE, 0.5)\
		.set_trans(Tween.TRANS_BACK)\
		.set_ease(Tween.EASE_OUT)
	tween.tween_property(restart, "modulate:a", 1.0, 0.5)\
		.set_delay(0.3)
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
func coord_to_pos(coord:Vector2i)->Vector2:
	var pos=512*Vector2(coord)+Vector2(256,256)+board.offset
	return pos
func gameover(cell:Cell):
	SignalBus.paused.emit()
	show_game_over()
	focus_camera(coord_to_pos(cell.coord))
	$HUD.visible=false
	


func _on_texture_button_pressed() -> void:
	SignalBus.orders_button_clicked.emit()


func _on_pause_button_pressed() -> void:
	$HUD/PausePage.show_page()

func init():
	energy=0
	energy_bar_mode="energy"
	#--------------------
	board=get_tree().get_first_node_in_group("board")
	update_all()
