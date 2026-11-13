extends Item

#紧急出口：随机把一个普通格变成"额外出口"（有方向的格子）
#有方向的格子会进入所在蛋组的发射方向（Board.scan() 收集的 directions），
#所以蛋停在这一格上时，这一组会多一个可发射方向。
#每 30 秒换一格；切换楼层时棋盘会重建，也会重新选。

const REROLL_INTERVAL:=30.0#多久换一格
const GLOW_DURATION:=5.0#重新选好之后，金边高亮持续多久
const GOLD_GLOW=preload("res://visual_effects/gold_glow_edge.gd")
const TILE2_SOURCE:=0#箭头层（grid/tile2）的 TileSet source
const TILE2_ATLAS:=Vector2i(0,0)
const GREEN_ALTERNATIVE:=1#tile2 的备选1：绿色箭头（0 是原来的黄色）
const DIRECTIONS:=[Vector2.UP,Vector2.DOWN,Vector2.LEFT,Vector2.RIGHT]

var _timer:Timer=null
var _board:Board=null
var _cell:Cell=null
var _glow:Node2D=null
var _last_floor:int=-1

func _ready() -> void:
	item_name="emergency_exit"
	_timer=Timer.new()
	_timer.wait_time=REROLL_INTERVAL
	_timer.autostart=true
	_timer.timeout.connect(reroll)
	add_child(_timer)
	_last_floor=GameState.floor
	reroll()

func _process(_delta:float) -> void:
	#换楼层时棋盘会重建（Board.init() 里 spawn_tile() 会把箭头层清空）：
	#旧格子作废，等一帧确认新棋盘铺好，再在新棋盘上重新选
	if GameState.floor!=_last_floor:
		_last_floor=GameState.floor
		_kill_glow()
		_board=null
		_cell=null
		await get_tree().process_frame
		if not is_inside_tree():
			return
		reroll()

#重新选一格：先清掉上一格的出口，再从普通格里随机挑一个
func reroll() -> void:
	var board:Board=get_tree().get_first_node_in_group("board")
	if board==null:
		return
	if board!=_board:
		_board=board
		_cell=null
	_kill_glow()
	_clear_current()
	var cell:Cell=_pick_cell(board)
	if cell!=null:
		var direction:Vector2=DIRECTIONS.pick_random()
		cell.direction=direction
		_cell=cell
		_paint(cell.coord,direction)
		_spawn_glow(cell)
	#方向变了，蛋组的发射方向要立刻刷新（不然要等蛋动一下才生效）
	board.rescan_groups()

#候选：非edge、无方向、available 的普通格；尽量不选上一格
func _pick_cell(board:Board) -> Cell:
	var candidates:Array[Cell]=[]
	for x in range(board.size.x):
		for y in range(board.size.y):
			var cell:Cell=board.find_cell(Vector2i(x,y))
			if cell==null:
				continue
			if not cell.is_available or cell.is_edge:
				continue
			if cell.direction!=Vector2.ZERO:
				continue
			if _cell!=null and cell.coord==_cell.coord:
				continue
			candidates.append(cell)
	if candidates.is_empty():
		return null
	return candidates.pick_random()

func _clear_current() -> void:
	if _cell==null:
		return
	if is_instance_valid(_cell):
		_cell.direction=Vector2.ZERO
		_erase(_cell.coord)
	_cell=null

#——选中格的金边高亮：复用 visual_effects/gold_glow_edge.gd ——
func _spawn_glow(cell:Cell) -> void:
	if _board==null or not is_instance_valid(_board):
		return
	var fx=GOLD_GLOW.new()
	fx.position=Vector2(cell.coord)*512.0+Vector2(256,256)
	fx.setup(GLOW_DURATION,512.0)
	_board.add_child(fx)
	_glow=fx

func _kill_glow() -> void:
	if _glow!=null and is_instance_valid(_glow):
		_glow.queue_free()
	_glow=null

#——棋盘贴图：绿色箭头 = 备选1 + 方向对应的翻转 ——
func _paint(coord:Vector2i,direction:Vector2) -> void:
	var tile2:TileMapLayer=_get_tile2()
	if tile2==null:
		return
	tile2.set_cell(coord,TILE2_SOURCE,TILE2_ATLAS,GREEN_ALTERNATIVE|_transform_of(direction))

func _erase(coord:Vector2i) -> void:
	var tile2:TileMapLayer=_get_tile2()
	if tile2!=null:
		tile2.erase_cell(coord)

func _get_tile2() -> TileMapLayer:
	if _board==null or not is_instance_valid(_board):
		return null
	return _board.get_node_or_null("grid/tile2") as TileMapLayer

#和 Board.spawn_tile() 里的方向->翻转映射保持一致
func _transform_of(direction:Vector2) -> int:
	if direction==Vector2.UP:
		return TileSetAtlasSource.TRANSFORM_FLIP_V|TileSetAtlasSource.TRANSFORM_TRANSPOSE
	if direction==Vector2.LEFT:
		return TileSetAtlasSource.TRANSFORM_FLIP_H|TileSetAtlasSource.TRANSFORM_FLIP_V
	if direction==Vector2.DOWN:
		return TileSetAtlasSource.TRANSFORM_FLIP_H|TileSetAtlasSource.TRANSFORM_TRANSPOSE
	return 0
