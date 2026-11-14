extends Control

#棋盘可视化编辑器：新建/涂格子/编辑刷怪点/保存 tres/读取 tres
#用法：在 Godot 里打开 tools/board_editor/board_editor.tscn，按 F6 单独运行这个场景

const BOARD_DIR:="res://board"
const DEFAULT_NAME:="board_new"
#用 preload 而不是 class_name，避免还没打开过编辑器时全局类缓存没注册
const BoardCanvasScript=preload("res://tools/board_editor/board_canvas.gd")

#画笔（顺序就是面板上的按钮顺序）
const PALETTE:Array=[
	{"id":"inner","name":"普通格"},
	{"id":"edge","name":"边界(墙)"},
	{"id":"empty","name":"虚空"},
	{"id":"left","name":"方向 ←"},
	{"id":"right","name":"方向 →"},
	{"id":"up","name":"方向 ↑"},
	{"id":"down","name":"方向 ↓"},
]
const BRUSH_COLORS:Dictionary={
	"inner":Color(0.74,0.74,0.78),
	"edge":Color(0.32,0.32,0.36),
	"empty":Color(0.14,0.14,0.16),
	"left":Color(0.28,0.55,0.85),
	"right":Color(0.28,0.55,0.85),
	"up":Color(0.28,0.55,0.85),
	"down":Color(0.28,0.55,0.85),
}
const SIDES:Array=[
	{"id":"left","label":"左(行号)"},
	{"id":"right","label":"右(行号)"},
	{"id":"up","label":"上(列号)"},
	{"id":"down","label":"下(列号)"},
]

var board_data:BoardData=null
var canvas

var _brush:String="inner"
var _palette_buttons:Dictionary={}
var _w_spin:SpinBox
var _h_spin:SpinBox
var _border_check:CheckBox
var _spawn_edits:Dictionary={}
var _name_edit:LineEdit
var _board_list:ItemList
var _status_label:Label
var _info_label:Label
var _hover_label:Label

func _ready() -> void:
	_build_ui()
	new_board(8,8)
	_refresh_board_list()

#———————————————————————— 界面 ————————————————————————

func _build_ui() -> void:
	var bg:=ColorRect.new()
	bg.color=Color(0.10,0.10,0.12)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter=Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var margin:=MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["left","top","right","bottom"]:
		margin.add_theme_constant_override("margin_"+side,12)
	add_child(margin)

	var hbox:=HBoxContainer.new()
	hbox.add_theme_constant_override("separation",12)
	margin.add_child(hbox)

	var left_panel:=PanelContainer.new()
	left_panel.custom_minimum_size=Vector2(340,0)
	hbox.add_child(left_panel)
	var left_margin:=MarginContainer.new()
	for side in ["left","top","right","bottom"]:
		left_margin.add_theme_constant_override("margin_"+side,10)
	left_panel.add_child(left_margin)
	var panel_box:=VBoxContainer.new()
	panel_box.add_theme_constant_override("separation",6)
	left_margin.add_child(panel_box)
	var scroll:=ScrollContainer.new()
	scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	panel_box.add_child(scroll)
	var vbox:=VBoxContainer.new()
	vbox.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation",8)
	scroll.add_child(vbox)

	var title:=Label.new()
	title.text="棋盘编辑器"
	title.add_theme_font_size_override("font_size",22)
	vbox.add_child(title)

	var hint:=Label.new()
	hint.text="左键绘制 / 右键擦成虚空 / 按住拖拽连续画\n（浅色 = 可放蛋，深色 = 墙/虚空）"
	hint.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	hint.add_theme_color_override("font_color",Color(0.7,0.72,0.8))
	vbox.add_child(hint)
	vbox.add_child(HSeparator.new())

	#——尺寸——
	vbox.add_child(_section_label("尺寸"))
	var size_row:=HBoxContainer.new()
	size_row.add_theme_constant_override("separation",6)
	vbox.add_child(size_row)
	size_row.add_child(_small_label("宽"))
	_w_spin=SpinBox.new()
	_w_spin.min_value=3
	_w_spin.max_value=30
	_w_spin.step=1
	_w_spin.value=8
	_w_spin.custom_minimum_size=Vector2(70,0)
	size_row.add_child(_w_spin)
	size_row.add_child(_small_label("高"))
	_h_spin=SpinBox.new()
	_h_spin.min_value=3
	_h_spin.max_value=30
	_h_spin.step=1
	_h_spin.value=8
	_h_spin.custom_minimum_size=Vector2(70,0)
	size_row.add_child(_h_spin)
	var new_button:=Button.new()
	new_button.text="新建"
	new_button.pressed.connect(_on_new_pressed)
	size_row.add_child(new_button)

	_border_check=CheckBox.new()
	_border_check.text="新建时自动围一圈边界"
	_border_check.button_pressed=true
	vbox.add_child(_border_check)
	vbox.add_child(HSeparator.new())

	#——画笔——
	vbox.add_child(_section_label("画笔"))
	var palette_grid:=GridContainer.new()
	palette_grid.columns=2
	palette_grid.add_theme_constant_override("h_separation",6)
	palette_grid.add_theme_constant_override("v_separation",6)
	vbox.add_child(palette_grid)
	var group:=ButtonGroup.new()
	for entry in PALETTE:
		var btn:=Button.new()
		btn.text=String(entry["name"])
		btn.toggle_mode=true
		btn.button_group=group
		btn.custom_minimum_size=Vector2(140,32)
		btn.icon=_color_icon(BRUSH_COLORS[entry["id"]])
		btn.expand_icon=false
		btn.toggled.connect(_on_palette_toggled.bind(String(entry["id"])))
		palette_grid.add_child(btn)
		_palette_buttons[entry["id"]]=btn
	vbox.add_child(HSeparator.new())

	#——刷怪点——
	vbox.add_child(_section_label("刷怪点"))
	var spawn_hint:=Label.new()
	spawn_hint.text="逗号分隔，空白=不刷；左/右填行号，上/下填列号"
	spawn_hint.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	spawn_hint.add_theme_font_size_override("font_size",11)
	spawn_hint.add_theme_color_override("font_color",Color(0.7,0.72,0.8))
	vbox.add_child(spawn_hint)
	for side in SIDES:
		var row:=HBoxContainer.new()
		row.add_theme_constant_override("separation",6)
		vbox.add_child(row)
		var label:=_small_label(String(side["label"]))
		label.custom_minimum_size=Vector2(80,0)
		row.add_child(label)
		var edit:=LineEdit.new()
		edit.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		edit.placeholder_text="1,2,3"
		edit.text_changed.connect(_on_spawn_edited)
		row.add_child(edit)
		_spawn_edits[side["id"]]=edit
	var fill_button:=Button.new()
	fill_button.text="按尺寸填满四边"
	fill_button.pressed.connect(_on_fill_spawn_pressed)
	vbox.add_child(fill_button)
	vbox.add_child(HSeparator.new())

	#——文件——
	vbox.add_child(_section_label("文件"))
	var save_row:=HBoxContainer.new()
	save_row.add_theme_constant_override("separation",6)
	vbox.add_child(save_row)
	_name_edit=LineEdit.new()
	_name_edit.text=DEFAULT_NAME
	_name_edit.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	_name_edit.placeholder_text="文件名（不含 .tres）"
	save_row.add_child(_name_edit)
	var save_button:=Button.new()
	save_button.text="保存"
	save_button.pressed.connect(_on_save_pressed)
	save_row.add_child(save_button)

	var list_row:=HBoxContainer.new()
	list_row.add_theme_constant_override("separation",6)
	vbox.add_child(list_row)
	var list_label:=_small_label("res://board/*.tres")
	list_label.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	list_row.add_child(list_label)
	var refresh_button:=Button.new()
	refresh_button.text="刷新列表"
	refresh_button.pressed.connect(_refresh_board_list)
	list_row.add_child(refresh_button)

	_board_list=ItemList.new()
	_board_list.custom_minimum_size=Vector2(0,160)
	_board_list.item_selected.connect(_on_board_selected)
	vbox.add_child(_board_list)

	#——底部固定状态栏（不跟着左边滚动）——
	panel_box.add_child(HSeparator.new())

	_status_label=Label.new()
	_status_label.text="就绪"
	_status_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	panel_box.add_child(_status_label)

	_info_label=Label.new()
	_info_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	_info_label.add_theme_color_override("font_color",Color(0.7,0.72,0.8))
	panel_box.add_child(_info_label)

	_hover_label=Label.new()
	_hover_label.add_theme_font_size_override("font_size",11)
	_hover_label.add_theme_color_override("font_color",Color(0.7,0.72,0.8))
	panel_box.add_child(_hover_label)

	#——右侧画布——
	var canvas_panel:=PanelContainer.new()
	canvas_panel.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	canvas_panel.size_flags_vertical=Control.SIZE_EXPAND_FILL
	hbox.add_child(canvas_panel)
	canvas=BoardCanvasScript.new()
	canvas.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	canvas.size_flags_vertical=Control.SIZE_EXPAND_FILL
	canvas_panel.add_child(canvas)
	canvas.painted.connect(_on_painted)
	canvas.hovered.connect(_on_hovered)
	canvas.mouse_exited.connect(_on_canvas_mouse_exited)
	_set_brush("inner")
	_palette_buttons["inner"].button_pressed=true

func _section_label(text:String) -> Label:
	var label:=Label.new()
	label.text=text
	label.add_theme_font_size_override("font_size",15)
	return label

func _small_label(text:String) -> Label:
	var label:=Label.new()
	label.text=text
	label.add_theme_color_override("font_color",Color(0.8,0.82,0.88))
	return label

func _color_icon(color:Color) -> ImageTexture:
	var img:=Image.create(16,16,false,Image.FORMAT_RGBA8)
	img.fill(color)
	return ImageTexture.create_from_image(img)

#———————————————————————— 数据 ————————————————————————

#w×h 新板：默认铺普通格，可选自动围边界
func new_board(w:int,h:int) -> void:
	w=clampi(w,3,30)
	h=clampi(h,3,30)
	var data:=BoardData.new()
	data.size=Vector2i(w,h)
	var grid:Array[CellData]=[]
	grid.resize(w*h)
	var use_border:=_border_check==null or _border_check.button_pressed
	for j in range(h):
		for i in range(w):
			var type:="inner"
			if use_border and (i==0 or j==0 or i==w-1 or j==h-1):
				type="edge"
			grid[i+w*j]=BoardCanvasScript.PRESETS[type]
	data.grid=grid
	board_data=data
	if _w_spin!=null:
		_w_spin.value=w
		_h_spin.value=h
	if _name_edit!=null:
		_name_edit.text=DEFAULT_NAME
	_fill_spawn_for_size(w,h)
	canvas.set_board(board_data)
	_update_info()
	_set_status("新板 %d×%d" % [w,h])

#把四边刷怪点按尺寸填满（1 .. n-2）
func _fill_spawn_for_size(w:int,h:int) -> void:
	var cols:Array[int]=[]
	for i in range(1,w-1):
		cols.append(i)
	var rows:Array[int]=[]
	for j in range(1,h-1):
		rows.append(j)
	_spawn_edits["left"].text=_ints_to_text(rows)
	_spawn_edits["right"].text=_ints_to_text(rows)
	_spawn_edits["up"].text=_ints_to_text(cols)
	_spawn_edits["down"].text=_ints_to_text(cols)
	_on_spawn_edited("")

func _ints_to_text(values:Array) -> String:
	var parts:Array[String]=[]
	for v in values:
		parts.append(str(v))
	return ",".join(parts)

func _parse_ints(text:String) -> Array[int]:
	var result:Array[int]=[]
	var cleaned:=text.replace("，",",").replace(" ","").replace("、",",")
	for token in cleaned.split(",",false):
		if token.is_valid_int():
			var value:=token.to_int()
			if not result.has(value):
				result.append(value)
	return result

#把界面上的刷怪点写进 board_data，并刷新画布上的标记
func _sync_spawn_from_ui() -> void:
	if board_data==null:
		return
	var left:=_parse_ints(_spawn_edits["left"].text)
	var right:=_parse_ints(_spawn_edits["right"].text)
	var up:=_parse_ints(_spawn_edits["up"].text)
	var down:=_parse_ints(_spawn_edits["down"].text)
	board_data.enemy_spawn_point_left=left
	board_data.enemy_spawn_point_right=right
	board_data.enemy_spawn_point_up=up
	board_data.enemy_spawn_point_down=down
	canvas.set_spawn_markers(left,right,up,down)

#保存到 path（res://board/xxx.tres），返回 Error
func save_board(path:String) -> int:
	if board_data==null:
		return ERR_UNCONFIGURED
	_sync_spawn_from_ui()
	if board_data.grid.size()!=board_data.size.x*board_data.size.y:
		return ERR_INVALID_DATA
	var err:=ResourceSaver.save(board_data,path)
	return err

#读取 path，返回 Error
func load_board(path:String) -> int:
	var res=load(path)
	if res==null:
		return ERR_FILE_CANT_READ
	if not (res is BoardData):
		return ERR_FILE_UNRECOGNIZED
	var data:=res as BoardData
	var expected:=data.size.x*data.size.y
	if data.grid.size()!=expected:
		return ERR_INVALID_DATA
	#补齐空项，避免游戏里 loadboard 拿到 null
	var grids:Array[CellData]=data.grid
	for i in range(grids.size()):
		if grids[i]==null:
			grids[i]=BoardCanvasScript.PRESETS["empty"]
	data.grid=grids
	board_data=data
	_w_spin.value=data.size.x
	_h_spin.value=data.size.y
	_name_edit.text=path.get_file().get_basename()
	_spawn_edits["left"].text=_ints_to_text(data.enemy_spawn_point_left)
	_spawn_edits["right"].text=_ints_to_text(data.enemy_spawn_point_right)
	_spawn_edits["up"].text=_ints_to_text(data.enemy_spawn_point_up)
	_spawn_edits["down"].text=_ints_to_text(data.enemy_spawn_point_down)
	canvas.set_board(board_data)
	_on_spawn_edited("")
	_update_info()
	return OK

#———————————————————————— 交互 ————————————————————————

func _on_new_pressed() -> void:
	new_board(int(_w_spin.value),int(_h_spin.value))

func _on_palette_toggled(pressed:bool,brush_id:String) -> void:
	if pressed:
		_set_brush(brush_id)

func _set_brush(brush_id:String) -> void:
	_brush=brush_id
	if canvas!=null:
		canvas.set_brush(brush_id)
	for id in _palette_buttons:
		var btn:Button=_palette_buttons[id]
		if id==brush_id and not btn.button_pressed:
			btn.button_pressed=true

func _on_painted(coord:Vector2i) -> void:
	_update_info()
	_show_hover(coord)

func _on_hovered(coord:Vector2i) -> void:
	_show_hover(coord)

func _show_hover(coord:Vector2i) -> void:
	if board_data==null or coord.x<0 or coord.y<0 or coord.x>=board_data.size.x or coord.y>=board_data.size.y:
		_hover_label.text=""
		return
	var cell:CellData=canvas.get_cell(coord)
	if cell!=null:
		_hover_label.text="(%d, %d)  %s" % [coord.x,coord.y,_describe_cell(cell)]

func _on_canvas_mouse_exited() -> void:
	_hover_label.text=""

func _describe_cell(cell:CellData) -> String:
	if cell.direction!=Vector2.ZERO:
		if cell.direction==Vector2.LEFT:
			return "方向格 左"
		elif cell.direction==Vector2.RIGHT:
			return "方向格 右"
		elif cell.direction==Vector2.UP:
			return "方向格 上"
		elif cell.direction==Vector2.DOWN:
			return "方向格 下"
	if cell.is_edge:
		return "边界"
	if not cell.is_available:
		return "虚空"
	return "普通格"

func _on_spawn_edited(_text:String) -> void:
	_sync_spawn_from_ui()

func _on_fill_spawn_pressed() -> void:
	_fill_spawn_for_size(board_data.size.x,board_data.size.y)
	_set_status("已按 %d×%d 填满刷怪点" % [board_data.size.x,board_data.size.y])

func _on_save_pressed() -> void:
	var file_name:=_name_edit.text.strip_edges()
	if file_name=="" or file_name.contains("/") or file_name.contains("\\"):
		_set_status("文件名不能为空，也不能带路径")
		return
	if file_name.ends_with(".tres"):
		file_name=file_name.substr(0,file_name.length()-5)
	var path:=BOARD_DIR+"/"+file_name+".tres"
	var err:=save_board(path)
	if err==OK:
		_set_status("已保存 %s" % path)
		_refresh_board_list()
	else:
		_set_status("保存失败：%s（%s）" % [_error_text(err),path])

func _error_text(err:int) -> String:
	match err:
		ERR_CANT_OPEN:
			return "目标文件打不开，检查目录/权限"
		ERR_FILE_CANT_WRITE:
			return "无法写入文件"
		ERR_INVALID_DATA:
			return "格子数量和尺寸对不上"
		ERR_UNCONFIGURED:
			return "还没有棋盘数据"
		_:
			return "错误码 %d" % err

func _refresh_board_list() -> void:
	if _board_list==null:
		return
	_board_list.clear()
	var files:=DirAccess.get_files_at(BOARD_DIR)
	var names:Array[String]=[]
	for file_name in files:
		if file_name.ends_with(".tres"):
			names.append(file_name)
	names.sort()
	for file_name in names:
		_board_list.add_item(file_name)

func _on_board_selected(index:int) -> void:
	var file_name:=_board_list.get_item_text(index)
	var path:=BOARD_DIR+"/"+file_name
	var err:=load_board(path)
	if err==OK:
		_set_status("已载入 %s（%d×%d）" % [path,board_data.size.x,board_data.size.y])
	else:
		_set_status("载入失败：%s（%s）" % [_error_text(err),path])

#———————————————————————— 状态 ————————————————————————

func _update_info() -> void:
	if _info_label==null or board_data==null:
		return
	var playable:=0
	var edge:=0
	var empty:=0
	var direction:=0
	for cell in board_data.grid:
		if cell==null:
			empty+=1
			continue
		if cell.direction!=Vector2.ZERO:
			direction+=1
		elif cell.is_edge:
			edge+=1
		elif not cell.is_available:
			empty+=1
		else:
			playable+=1
	_info_label.text="%d×%d　可放蛋 %d 格 / 边界 %d / 虚空 %d / 方向 %d" % [board_data.size.x,board_data.size.y,playable,edge,empty,direction]

func _set_status(text:String) -> void:
	if _status_label!=null:
		_status_label.text=text
