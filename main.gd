extends Node

var game_session_scene:PackedScene=preload("res://game_session.tscn")
var tutorial_scene:PackedScene=preload("res://tutorial.tscn")
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	SignalBus.paused.connect(pause_game)
	SignalBus.resumed.connect(resume_game)
	SignalBus.restart_button_pressed.connect(restart)
	SignalBus.tutorial_finished.connect(tutorial_finish)
	tutorial()
	#GameState.tutorial_step=-1
	#restart()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func pause_game():
	get_tree().paused=true
func resume_game():
	get_tree().paused=false

func restart():
	VisualEffect.cutscene_out()
	await get_tree().create_timer(2).timeout
	#先重置局内状态，再建新的 GameSession：
	#否则 Board._ready() 抽棋盘时会读到上一局残留的 floor（比如死在第 2 层就会抽到第 2 层的棋盘）
	GameState.restart()
	WeightTable.reset()#新一局：所有概率表回到初始状态
	Weather.reset()#新一局：天气回到无天气
	if get_node("GameSession") !=null:
		get_node("GameSession").queue_free()
		await get_tree().process_frame
	var game_session=game_session_scene.instantiate()
	add_child(game_session)
	resume_game()
	VisualEffect.cutscene_in()

func tutorial():
	VisualEffect.cutscene_out()
	await get_tree().create_timer(2).timeout
	add_child(tutorial_scene.instantiate())
	resume_game()
	VisualEffect.cutscene_in()
func tutorial_finish():
	VisualEffect.cutscene_out()
	await get_tree().create_timer(2).timeout
	#同样要先重置状态再建新场景，避免抽到教程/上一局残留的楼层棋盘
	GameState.restart()
	WeightTable.reset()#从教程进正式局，也当成新一局
	Weather.reset()#从教程进正式局：天气也清回无天气
	if get_node("Tutorial") !=null:
		get_node("Tutorial").queue_free()
		await get_tree().process_frame
	var game_session=game_session_scene.instantiate()
	add_child(game_session)
	resume_game()
	VisualEffect.cutscene_in()
