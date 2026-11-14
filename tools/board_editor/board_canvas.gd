class_name BoardCanvas
extends Control

#棋盘编辑器里画格子的画布：只负责"显示 + 鼠标涂格子"，数据都在 board_data 里

signal painted(coord:Vector2i)
signal hovered(coord:Vector2i)

const PRESETS:Dictionary={
	"inner":preload("res://board/cells/inner_cell.tres"),
	"edge":preload("res://board/cells/edge_cell.tres"),
	"steel_edge":preload("res://board/cells/steel_edge.tres"),
	"empty":preload("res://board/cells/empty_cell.tres"),
	"left":preload("res://board/cells/left_cell.tres"),
	"right":preload("res://board/cells/right_cell.tres"),
	"up":preload("res://board/cells/up_cell.tres"),
	"down":preload("res://board/cells/down_cell.tres"),
}

const MARGIN:=48.0
const MIN_CELL:=12.0
const MAX_CELL:=80.0

const COLOR_INNER:=Color(0.74,0.74,0.78)
const COLOR_EDGE:=Color(0.32,0.32,0.36)
const COLOR_STEEL:=Color(0.55,0.60,0.68)
const COLOR_EMPTY:=Color(0.12,0.12,0.14)
const COLOR_DIRECTION:=Color(0.28,0.55,0.85)
const COLOR_MARKER:=Color(1.0,0.62,0.18)

var board_data:BoardData=null
var brush:String="inner"
var hover_coord:=Vector2i(-1,-1)
#四边的刷怪点（left/right 是行号，up/down 是列号）
var spawn_markers:Dictionary={"left":[],"right":[],"up":[],"down":[]}

var _cell_size:=48.0
var _origin:=Vector2.ZERO
var _painting:=false
var _erasing:=false

func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_STOP
	focus_mode=Control.FOCUS_NONE
	clip_contents=true
	resized.connect(queue_redraw)

func set_board(data:BoardData) -> void:
	board_data=data
	hover_coord=Vector2i(-1,-1)
	queue_redraw()

func set_brush(type:String) -> void:
	brush=type

func set_spawn_markers(left:Array,right:Array,up:Array,down:Array) -> void:
	spawn_markers={"left":left,"right":right,"up":up,"down":down}
	queue_redraw()

#给测试/外部用：直接改一格
func set_cell(coord:Vector2i,type:String) -> void:
	if board_data==null or not _in_bounds(coord) or not PRESETS.has(type):
		return
	board_data.grid[coord.x+board_data.size.x*coord.y]=PRESETS[type]
	queue_redraw()

func get_cell(coord:Vector2i) -> CellData:
	if board_data==null or not _in_bounds(coord):
		return null
	return board_data.grid[coord.x+board_data.size.x*coord.y]

func _in_bounds(coord:Vector2i) -> bool:
	return board_data!=null and coord.x>=0 and coord.y>=0 and coord.x<board_data.size.x and coord.y<board_data.size.y

func _update_layout() -> void:
	if board_data==null:
		return
	var available:=size-Vector2(MARGIN*2.0,MARGIN*2.0)
	if available.x<=0.0 or available.y<=0.0:
		return
	var cs:=minf(available.x/float(board_data.size.x),available.y/float(board_data.size.y))
	cs=clampf(cs,MIN_CELL,MAX_CELL)
	_cell_size=cs
	_origin=(size-Vector2(board_data.size)*cs)*0.5

func coord_at(pos:Vector2) -> Vector2i:
	if board_data==null:
		return Vector2i(-1,-1)
	_update_layout()
	var local:=(pos-_origin)/_cell_size
	return Vector2i(floori(local.x),floori(local.y))

func _draw() -> void:
	if board_data==null:
		return
	_update_layout()
	var cs:=_cell_size
	var w:=board_data.size.x
	var h:=board_data.size.y
	var grid_size:=Vector2(w,h)*cs

	#底板
	draw_rect(Rect2(_origin-Vector2(10,10),grid_size+Vector2(20,20)),Color(0.06,0.06,0.08),true)

	for j in range(h):
		for i in range(w):
			var cell:CellData=board_data.grid[i+w*j]
			var rect:=Rect2(_origin+Vector2(i,j)*cs,Vector2(cs,cs))
			draw_rect(rect,_cell_color(cell),true)
			draw_rect(rect,Color(0,0,0,0.45),false,1.0)
			if cell!=null and cell.is_steel_edge:
				#钢边界：里面再描一圈，和普通边界区分
				draw_rect(rect.grow(-4.0),Color(1,1,1,0.20),false,1.0)
			if cell!=null and cell.direction!=Vector2.ZERO:
				_draw_arrow(rect.get_center(),cell.direction,cs,Color(1,1,1,0.9))
			elif cell==null or (not cell.is_available and not cell.is_edge):
				#虚空：画个小叉
				var a:=rect.position+Vector2(cs*0.32,cs*0.32)
				var b:=rect.end-Vector2(cs*0.32,cs*0.32)
				draw_line(a,b,Color(1,1,1,0.10),1.0)
				draw_line(Vector2(b.x,a.y),Vector2(a.x,b.y),Color(1,1,1,0.10),1.0)

	#行列号
	if cs>=24.0:
		var font:=ThemeDB.fallback_font
		var top_y:=_origin.y-10.0
		var left_x:=_origin.x-10.0
		for i in range(w):
			var col_center:=_origin.x+(i+0.5)*cs
			draw_string(font,Vector2(col_center-5.0,top_y),str(i),HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color(0.85,0.85,0.9,0.9))
		for j in range(h):
			var row_center:=_origin.y+(j+0.5)*cs
			var text:=str(j)
			var tw:=font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,12).x
			draw_string(font,Vector2(left_x-tw,row_center+4.5),text,HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color(0.85,0.85,0.9,0.9))

	#刷怪点标记
	for j in spawn_markers["left"]:
		if j>=0 and j<h:
			_draw_marker(Vector2(_origin.x-10.0,_origin.y+(float(j)+0.5)*cs),Vector2.RIGHT)
	for j in spawn_markers["right"]:
		if j>=0 and j<h:
			_draw_marker(Vector2(_origin.x+grid_size.x+10.0,_origin.y+(float(j)+0.5)*cs),Vector2.LEFT)
	for i in spawn_markers["up"]:
		if i>=0 and i<w:
			_draw_marker(Vector2(_origin.x+(float(i)+0.5)*cs,_origin.y-10.0),Vector2.DOWN)
	for i in spawn_markers["down"]:
		if i>=0 and i<w:
			_draw_marker(Vector2(_origin.x+(float(i)+0.5)*cs,_origin.y+grid_size.y+10.0),Vector2.UP)

	#鼠标悬停格
	if _in_bounds(hover_coord):
		var hover_rect:=Rect2(_origin+Vector2(hover_coord)*cs,Vector2(cs,cs))
		draw_rect(hover_rect,Color(1,1,1,0.95),false,2.0)

func _cell_color(cell:CellData) -> Color:
	if cell==null:
		return COLOR_EMPTY
	if cell.direction!=Vector2.ZERO:
		return COLOR_DIRECTION
	if cell.is_steel_edge:
		return COLOR_STEEL
	if cell.is_edge:
		return COLOR_EDGE
	if not cell.is_available:
		return COLOR_EMPTY
	return COLOR_INNER

func _draw_arrow(center:Vector2,dirv:Vector2,cs:float,color:Color) -> void:
	var n:=dirv.normalized()
	var tip:=center+n*cs*0.32
	var tail:=center-n*cs*0.32
	draw_line(tail,tip,color,2.0)
	draw_line(tip,tip+n.rotated(2.5)*cs*0.16,color,2.0)
	draw_line(tip,tip+n.rotated(-2.5)*cs*0.16,color,2.0)

func _draw_marker(pos:Vector2,dirv:Vector2) -> void:
	var n:=dirv.normalized()
	var tip:=pos+n*7.0
	var base_a:=pos-n*3.0+n.orthogonal()*5.0
	var base_b:=pos-n*3.0-n.orthogonal()*5.0
	draw_colored_polygon(PackedVector2Array([tip,base_a,base_b]),COLOR_MARKER)

func _gui_input(event:InputEvent) -> void:
	if board_data==null:
		return
	if event is InputEventMouseButton:
		var mb:=event as InputEventMouseButton
		if mb.button_index==MOUSE_BUTTON_LEFT:
			_painting=mb.pressed
			if mb.pressed:
				hover_coord=coord_at(mb.position)
				_paint(hover_coord,brush)
			accept_event()
		elif mb.button_index==MOUSE_BUTTON_RIGHT:
			_erasing=mb.pressed
			if mb.pressed:
				hover_coord=coord_at(mb.position)
				_paint(hover_coord,"empty")
			accept_event()
	elif event is InputEventMouseMotion:
		var mm:=event as InputEventMouseMotion
		hover_coord=coord_at(mm.position)
		hovered.emit(hover_coord)
		if _painting:
			_paint(hover_coord,brush)
		elif _erasing:
			_paint(hover_coord,"empty")
		queue_redraw()

func _paint(coord:Vector2i,type:String) -> void:
	if not _in_bounds(coord):
		return
	board_data.grid[coord.x+board_data.size.x*coord.y]=PRESETS[type]
	queue_redraw()
	painted.emit(coord)

func _notification(what: int) -> void:
	if what==NOTIFICATION_MOUSE_EXIT:
		#鼠标拖出画布时松开按钮收不到，这里把笔状态清掉，避免出去再回来一直画
		_painting=false
		_erasing=false
		hover_coord=Vector2i(-1,-1)
		hovered.emit(hover_coord)
		queue_redraw()
