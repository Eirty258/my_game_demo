extends Node

var board:Board
var rooster

func _ready() -> void:
	GameState.tutorial_step=0
	board=load("res://board/board.tscn").instantiate()
	add_child(board)
	await get_tree().process_frame
	var bd=load("res://board/board_8.tres") as BoardData
	board.grid.clear()
	board.max_egg_number=0
	board.loadboard(bd)
	board.global_position=board.offset
	board.spawn_tile()
	await get_tree().process_frame
	rooster=load("res://familiar/iron_rooster.tscn").instantiate()
	add_child(rooster)
	await get_tree().process_frame

	#从两块棋盘中间开始寻路
	rooster.global_position=Vector2(0,0)
	rooster.power_left=0.01
	await get_tree().physics_frame
	await get_tree().physics_frame
	print("状态=",rooster.state,"（期望 2=SEEKING） 目标=",rooster._seeking_target)
	var is_lane:=_is_lane_point(rooster._seeking_target)
	print("目标是实际车道点=",is_lane,"（期望 true） 在棋盘外=",not _rect().has_point(rooster._seeking_target))

	#直接到目标，走完放电
	rooster.global_position=rooster._seeking_target
	await get_tree().physics_frame
	await get_tree().physics_frame
	print("到达后状态=",rooster.state,"（期望 3=DISCHARGING）")
	await get_tree().create_timer(2.2).timeout
	print("放电后状态=",rooster.state,"（期望 4=DISCHARGED）")
	await get_tree().create_timer(0.2).timeout
	get_tree().quit()

func _is_lane_point(p:Vector2) -> bool:
	for side in range(4):
		for lane in rooster._lanes_for_side(side):
			if rooster._lane_point(side,int(lane)).distance_to(p)<0.5:
				return true
	return false

func _rect() -> Rect2:
	return Rect2(board.offset,Vector2(board.size)*512.0)
