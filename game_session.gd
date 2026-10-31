extends Node


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	SignalBus.void_clicked.connect(goto_next_floor)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func goto_next_floor():
	#await get_tree().create_timer(3).timeout
	$UI.visible=false
	focus_camera(Vector2(0,0),0.3,2)
	await get_tree().create_timer(1)
	await $Board.clear_eggs()
	VisualEffect.cutscene_out()
	await get_tree().create_timer(2).timeout
	GameState.init()
	GameState.floor+=1
	#Background
	await $Board.init()
	$Camera2D.zoom=Vector2(0.15,0.15)
	$EnemyManager.init()
	$DropManager.init()
	$UI.init()
	VisualEffect.cutscene_in()
	$UI.visible=true

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
