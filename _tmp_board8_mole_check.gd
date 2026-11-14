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
	rooster.set_physics_process(false)

	var rect:=Rect2(board.offset,Vector2(board.size)*512.0)
	print("board_8 size=",board.size," rect=",rect)
	print("车道 left=",board.enemy_spawn_point_left," right=",board.enemy_spawn_point_right,
		" up=",board.enemy_spawn_point_up," down=",board.enemy_spawn_point_down)

	#每条车道的落点，往里扫第一个有格子的位置，看是不是可攻击的普通边界
	for side in range(4):
		for lane in rooster._lanes_for_side(side):
			var p:Vector2=rooster._lane_point(side,int(lane))
			var wall:=_first_cell_inward(p,rect)
			print("  side=",side," lane=",lane," 落点=",p," 撞到格=",wall)

	#旧算法的四个边中点（会落在空槽里的那些）
	var c:=rect.get_center()
	var old_mid=[[rect.position.x-rooster.lane_outset,c.y],[rect.end.x+rooster.lane_outset,c.y],[c.x,rect.position.y-rooster.lane_outset],[c.x,rect.end.y+rooster.lane_outset]]
	print("旧边中点=",old_mid)

	#从几个位置看新寻路目标
	for pos in [c,Vector2(c.x,c.y-900),Vector2(rect.position.x-700,c.y),Vector2(rect.end.x+700,c.y)]:
		rooster.global_position=pos
		var t:Vector2=rooster._nearest_lane_point()
		print("  从 ",pos," 最近车道点=",t," 在旧中点里=",old_mid.has(t)," 在棋盘外=",not rect.has_point(t))

	await get_tree().create_timer(0.2).timeout
	get_tree().quit()

#从车道外侧落点沿"垂直进入棋盘"的方向扫，返回第一个可用格的坐标
func _first_cell_inward(point:Vector2,rect:Rect2) -> Vector2i:
	var dir:=Vector2.ZERO
	if point.x<rect.position.x:
		dir=Vector2.RIGHT
	elif point.x>rect.end.x:
		dir=Vector2.LEFT
	elif point.y<rect.position.y:
		dir=Vector2.DOWN
	else:
		dir=Vector2.UP
	var p:=point
	for i in range(400):
		p+=dir*64.0
		if rect.has_point(p):
			var coord:=Vector2i(floori((p.x-rect.position.x)/512.0),floori((p.y-rect.position.y)/512.0))
			var cell:Cell=board.find_cell(coord)
			if cell!=null and cell.is_available:
				return coord
	return Vector2i(-1,-1)
