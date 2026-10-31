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
	if get_node("GameSession") !=null:
		get_node("GameSession").queue_free()
		await get_tree().process_frame
	var game_session=game_session_scene.instantiate()
	add_child(game_session)
	GameState.restart()
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
	if get_node("Tutorial") !=null:
		get_node("Tutorial").queue_free()
		await get_tree().process_frame
	var game_session=game_session_scene.instantiate()
	add_child(game_session)
	GameState.restart()
	resume_game()
	VisualEffect.cutscene_in()
