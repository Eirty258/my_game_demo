extends Node

#每一层的背景贴图（下标 = GameState.floor）
#第一层草地、第二层换成教学关那张雪地
const FLOOR_BACKGROUNDS:Array[String]=[
	"res://arts/texture/background_1.png",
	"res://arts/texture/background_2.png",
]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	SignalBus.void_clicked.connect(goto_next_floor)
	update_background()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

#按当前层换背景（背景挂在 Camera2D 下，会跟着画面一起缩放）
func update_background() -> void:
	var bg:Node=get_node_or_null("Camera2D/Background")
	if bg==null:
		return
	var index:=clampi(GameState.floor,0,FLOOR_BACKGROUNDS.size()-1)
	bg.call("set_texture_path",FLOOR_BACKGROUNDS[index])

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
	Weather.start_floor(GameState.floor)#第一层无天气，之后每层随机
	update_background()#换层背景（此刻画面是黑的，换完不会被看到）
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
