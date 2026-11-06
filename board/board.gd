extends Node2D
class_name Board

const DRAG_THRESHOLD:=8.0
const DRAG_ARROW_TEXTURE=preload("res://arts/texture/arrow.png")
const DRAG_ARROW_DISTANCE:=320.0#箭头离蛋中心的距离（蛋半径约 256，所以刚好在蛋外侧）
const DRAG_ARROW_SIZE:=220.0#箭头的目标宽度
const DRAG_ARROW_ROTATION_OFFSET:=0.0#贴图朝上就填 -PI/2
const fire_egg=preload("res://eggs/fire_egg.tscn")
const ice_egg=preload("res://eggs/ice_egg.tscn")
const electricity_egg=preload("res://eggs/electricity_egg.tscn")
const red_pao_egg=preload("res://eggs/red_pao_egg.tscn")
const red_shuai_egg=preload("res://eggs/red_shuai_egg.tscn")
const red_ju_egg=preload("res://eggs/red_ju_egg.tscn")
const EDGE_SHIELD_SCRIPT=preload("res://visual_effects/edge_shield.gd")



var size:Vector2i=Vector2i(8,8)
var grid=[]
var offset:Vector2=Vector2.ZERO
var egg_nodes:Dictionary={}#Vector2i:Egg
var egg_number:int=0:
	set(value):
		egg_number=value
		egg_spawn_chance=get_spawn_chance()
		if egg_number==0:
			SignalBus.egg_number_zero.emit()
var max_egg_number:int=0


#鼠标交互相关
var drag_start_pos:Vector2
var is_dragging:bool=false
var dragging_egg:Egg=null
var _drag_arrow:Sprite2D=null#拖动时提示方向的箭头

#分配堆id相关
var visited:Dictionary={}#Vector2i:bool
var next_group_id:int=0
var free_group_ids:Array[int]=[]
var group=[]#临时组
var current_type:String="null"#临时蛋种
var directions=[]#临时方向组

#刷怪相关
var enemy_spawn_point_left=[]#用inner_cell计算所有可刷怪范围
var enemy_spawn_point_right=[]
var enemy_spawn_point_up=[]
var enemy_spawn_point_down=[]
var enemy_spawn_point_x=[]
var enemy_spawn_point_y=[]

#刷蛋相关
var egg_spawn_chance:float=0.002
var base_spawn_chance:float=0.002


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	SignalBus.drop_egg_picked.connect(spawn_egg_at_random_position)
	SignalBus.egg_double_clicked.connect(remove_egg_broken)
	if GameState.tutorial_step!=-1:
		load_tutorial()
		return
	init()
	#await get_tree().create_timer(3).timeout
	#VisualEffect.cast_lightning(Vector2(0,0),Vector2(3000,3000))


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if is_targeting:
		_update_target_highlight()
	if !GameState.is_floor_cleared&&GameState.tutorial_step==-1:
		try_to_spawn_egg()
	#print("平均生成一颗蛋耗时:",1/(egg_spawn_chance * 60))
	pass

func _init() -> void:
	pass

#鼠标交互
func _input(event: InputEvent) -> void:
	if _handle_targeting_input(event):#瞄准状态优先接管鼠标
		return
	if dragging_egg==null:
		return
	if event is InputEventMouseMotion:
		if not is_dragging:
			if event.position.distance_to(drag_start_pos) > DRAG_THRESHOLD:
				is_dragging=true
		if is_dragging:
			_update_drag_arrow(event.global_position)
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			if is_dragging:
				#_on_drag_end()
				#print("拖拽结束")
				var vector=snap_to_cardinal(event.global_position-drag_start_pos)
				#print(vector)
				move_egg(dragging_egg,vector)
				
				
			else:
				print("普通点击")
				_on_click_only(dragging_egg)
			dragging_egg = null
			is_dragging = false
			_hide_drag_arrow()

#在指定坐标生成指定类型的蛋
func spawn_egg(coord:Vector2i,type:String):
	#权重表里的键带阵营（red_ju），蛋内部只用属性名（ju），这里统一转换
	#以后有黑棋，在这个分支里按阵营分发到不同的蛋场景
	if type.begins_with("red_"):
		type=type.substr(4)
	var egg
	if type=="fire":
		egg=fire_egg.instantiate()
	elif type=="ice":
		egg=ice_egg.instantiate()
	elif type=="electricity":
		egg=electricity_egg.instantiate()
	elif type=="pao":
		egg=red_pao_egg.instantiate()
	elif type=="shuai":
		egg=red_shuai_egg.instantiate()
	elif type=="ju":
		egg=red_ju_egg.instantiate()
	else:
		print("蛋种类名错误")
		return
	egg.egg_clicked.connect(_on_egg_clicked)
	egg.coordinate=coord
	#测试
	egg.position=Vector2(coord)*512+Vector2(256,256)
	egg_nodes[coord]=egg
	add_child(egg)
	egg_number+=1
	update_cell(coord)
	rescan_groups()

func egg_number_reduce():
	egg_number-=1

#鼠标交互信号
func _on_egg_clicked(egg:Egg,mouse_pos:Vector2):
	drag_start_pos=mouse_pos
	is_dragging=false
	dragging_egg=egg

#向量单位化并吸附
func snap_to_cardinal(delta: Vector2) -> Vector2:
	if delta == Vector2.ZERO:
		return Vector2.ZERO
	if absf(delta.x) > absf(delta.y):
		return Vector2(signf(delta.x), 0)
	else:
		return Vector2(0, signf(delta.y))

#拖动预览：在蛋要移动的那一侧显示一个小箭头
func _update_drag_arrow(mouse_pos:Vector2) -> void:
	if dragging_egg==null or not is_instance_valid(dragging_egg):
		_hide_drag_arrow()
		return
	var vector=snap_to_cardinal(mouse_pos-drag_start_pos)
	if vector==Vector2.ZERO:
		_hide_drag_arrow()
		return
	var arrow=_ensure_drag_arrow()
	arrow.visible=true
	arrow.rotation=vector.angle()+DRAG_ARROW_ROTATION_OFFSET
	arrow.position=dragging_egg.position+vector*DRAG_ARROW_DISTANCE

func _hide_drag_arrow() -> void:
	if is_instance_valid(_drag_arrow):
		_drag_arrow.visible=false

func _ensure_drag_arrow() -> Sprite2D:
	if not is_instance_valid(_drag_arrow):
		_drag_arrow=Sprite2D.new()
		_drag_arrow.texture=DRAG_ARROW_TEXTURE
		_drag_arrow.visible=false
		_drag_arrow.z_index=80
		var texture_width:=float(DRAG_ARROW_TEXTURE.get_width())
		if texture_width>0.0:
			_drag_arrow.scale=Vector2.ONE*(DRAG_ARROW_SIZE/texture_width)
		add_child(_drag_arrow)
	return _drag_arrow

#根据坐标返回蛋
#func find_egg(coord: Vector2i) -> Egg:
	#return egg_nodes.get(coord, null)
func find_egg(coord: Vector2i) -> Egg:
	var egg = egg_nodes.get(coord, null)
	if egg and is_instance_valid(egg):
		return egg
	return null

#根据坐标返回单元格
func find_cell(coord:Vector2i)->Cell:
	if coord.x>=size.x||coord.x<0||coord.y>=size.y||coord.y<0:
		return null
	return grid[coord.x][coord.y]

#更新单元格的状态
func update_cell(coord:Vector2i):
	if find_egg(coord):
		find_cell(coord).is_exist_egg=true
		find_cell(coord).is_collidable=true
	else:
		find_cell(coord).is_exist_egg=false
		find_cell(coord).is_collidable=false

#蛋的移动
func move_egg(egg:Egg,direction:Vector2):
	var current_cell=egg.coordinate
	var adjacent_cell=current_cell+Vector2i(direction)
	if find_egg(adjacent_cell):
		if !find_egg(adjacent_cell).disabled:
			move_egg(find_egg(adjacent_cell),direction)
	var end_cell=find_endpoint(current_cell,direction)
	var endpoint=Vector2(end_cell)*512+Vector2(256,256)+offset
	egg.move_to(endpoint,0.15)
	egg.coordinate=end_cell
	egg_nodes.erase(current_cell)
	egg_nodes[end_cell]=egg
	update_cell(current_cell)
	update_cell(end_cell)
	rescan_groups()
	#TODO 移动动画要加锁

#蛋的移动：找终点
func find_endpoint(current_cell:Vector2i,direction:Vector2)->Vector2i:
	var adjacent_cell=current_cell+Vector2i(direction)
	var endpoint=current_cell
	while find_cell(adjacent_cell).is_collidable==false:
		endpoint=adjacent_cell
		adjacent_cell+=Vector2i(direction)
	return endpoint
	
#根据grid填充tile
func spawn_tile():
	var gridtile=$grid
	gridtile.clear()
	var tile2=$grid/tile2
	tile2.clear()
	for i in range(size.x):
		for j in range(size.y):
			var cell=find_cell(Vector2i(i,j))
			if cell.is_available:
				if cell.is_edge:#标记
					gridtile.set_cell(Vector2i(i,j),2,Vector2i(0,0))
				else:
					gridtile.set_cell(Vector2i(i,j),1,Vector2i(1,1))
				if cell.direction!=Vector2.ZERO:
					var rotation=0
					if cell.direction==Vector2.UP:
						rotation=TileSetAtlasSource.TRANSFORM_FLIP_V | TileSetAtlasSource.TRANSFORM_TRANSPOSE
					elif cell.direction==Vector2.LEFT:
						rotation=TileSetAtlasSource.TRANSFORM_FLIP_H | TileSetAtlasSource.TRANSFORM_FLIP_V
					elif cell.direction==Vector2.DOWN:
						rotation=TileSetAtlasSource.TRANSFORM_FLIP_H | TileSetAtlasSource.TRANSFORM_TRANSPOSE
					tile2.set_cell(Vector2i(i,j),0,Vector2i(0,0),rotation)

#堆id分配
func alloc_group_id()->int:#
	if free_group_ids.size()>0:
		return free_group_ids.pop_back()
	else:
		var id=next_group_id
		next_group_id+=1
		return id

#连通块算法
func rescan_groups():
	visited.clear()
	group.clear()
	directions.clear()
	current_type="null"
	for i in range(size.x):
		for j in range(size.y):
			scan(Vector2i(i,j))
			#成组门槛：电力蛋少一颗，红炮一颗即可；帅不成组（不参与发射）
			var min_group_size:int=max(GameState.min_chain,1)
			var can_group:bool=true
			if current_type=="electricity":
				min_group_size=max(GameState.min_chain-1,1)
			elif current_type=="pao"||current_type=="ju":
				min_group_size=1
			elif current_type=="shuai":
				can_group=false
			if can_group&&group.size()>=min_group_size:#达到门槛则分配新id
				var group_id=alloc_group_id()
				for e in group:
					e.group_id=group_id
					e.directions=directions.duplicate()
					#print(e.directions)
			else:#否则不成组，id重置为-1
				for e in group:
					e.group_id=-1
					e.directions.clear()
					#print(e.coordinate,":","clear")
			#重置临时变量
			group.clear()
			directions.clear()
			current_type="null"
func scan(current_cell_coord:Vector2i):
	var current_cell=find_cell(current_cell_coord)
	var current_egg=find_egg(current_cell_coord)
	if current_egg:#如果当前单元格有蛋，且是新元素或与前一个元素相同，且没有被访问过
		if (current_type=="null"||current_type==current_egg.type)&&!current_egg.disabled:
			if !visited.has(current_cell_coord):
				#访问并添加访问标记,加入临时组
				visited[current_cell_coord]=true
				current_type=current_egg.type
				group.append(current_egg)
				if current_cell.direction!=Vector2.ZERO:
					if !directions.has(current_cell.direction):
						directions.append(current_cell.direction)
						#print(directions)
				#向四个联通方向继续寻找
				var next_cell_coord=current_cell_coord+Vector2i.RIGHT
				scan(next_cell_coord)
				next_cell_coord=current_cell_coord+Vector2i.UP
				scan(next_cell_coord)
				next_cell_coord=current_cell_coord+Vector2i.LEFT
				scan(next_cell_coord)
				next_cell_coord=current_cell_coord+Vector2i.DOWN
				scan(next_cell_coord)
		else:#有蛋但元素不同,结束
			return

#测试
func output():
	for i in egg_nodes.values():
		print(i.coordinate,":",i.directions)
		
#单击发射
func _on_click_only(egg:Egg):
	var group_id=egg.group_id
	var to_remove=[]
	var egg_count=0
	for i in egg_nodes.values():
		if i.group_id==group_id:
			egg_count+=1
	if group_id!=-1&&egg.directions.size()>0:
		for e in egg_nodes.values():
			if e.group_id==group_id:
				e.shoot(egg_count)
				to_remove.append(e)
	for e in to_remove:
		remove_egg(e)
	#print(egg_nodes)

#删除蛋时维护数据；蛋在三方面存在：具体节点 字典 cell的属性
func remove_egg(egg:Egg):
	egg_nodes.erase(egg.coordinate)#字典
	var cell=find_cell(egg.coordinate)#cell
	cell.is_collidable=false
	cell.is_exist_egg=false
	egg.die()#节点本身
func remove_egg_broken(egg:Egg):
	egg_nodes.erase(egg.coordinate)#字典
	var cell=find_cell(egg.coordinate)#cell
	cell.is_collidable=false
	cell.is_exist_egg=false
	egg.on_broken()#破碎效果（帅的冲击波在这里）
	egg.die()#节点本身
	SignalBus.egg_broken.emit()

#边界被击破时的“帅”的护驾：场上有帅就献祭一枚、把这面墙修回 1 点耐久
#返回 true 表示这次破坏被顶替，不触发游戏失败
func absorb_edge_destruction(cell:Cell) -> bool:
	var shuai_list:=get_all_shuai()
	if shuai_list.is_empty():
		return false
	var shuai:Egg=shuai_list.pick_random()
	cell.durability=1
	remove_egg_broken(shuai)
	return true

#棋盘上所有还活着的帅
func get_all_shuai() -> Array:
	var result:=[]
	for egg in egg_nodes.values():
		if is_instance_valid(egg) and egg.type=="shuai":
			result.append(egg)
	return result

#替换受伤红色tile
func turn_red_tile(coord:Vector2i):
	var tilemaplayer=$grid
	coord=coord
	var source_id = tilemaplayer.get_cell_source_id(coord)
	var atlas_coords = tilemaplayer.get_cell_atlas_coords(coord)
	tilemaplayer.set_cell(coord, source_id, atlas_coords, 1)
	await get_tree().create_timer(0.3).timeout
	tilemaplayer.set_cell(coord, source_id, atlas_coords, 0)
func turn_tile(coord:Vector2i,level:int):
	var tilemaplayer=$grid
	var source_id = tilemaplayer.get_cell_source_id(coord)
	tilemaplayer.set_cell(coord, source_id,Vector2(level,0),0)

#给所有边界格套护盾：敌人照常索敌攻击，但边界不掉耐久
#duration 秒后自动失效；重复套用会重置时长并重做视觉
var _shield_nodes:Dictionary={}#coord -> 护盾视觉节点

func shield_all_edges(duration:float=10.0) -> void:
	for column in grid:
		for cell in column:
			if cell!=null&&cell.is_edge:
				shield_edge(cell,duration)

#给单个边界格套护盾（以后别的道具可以只护其中一面）
func shield_edge(cell:Cell,duration:float) -> void:
	if cell==null||not cell.is_edge:
		return
	cell.apply_shield(duration)
	_spawn_shield_visual(cell.coord,duration)

func _spawn_shield_visual(coord:Vector2i,duration:float) -> void:
	if _shield_nodes.has(coord) and is_instance_valid(_shield_nodes[coord]):
		_shield_nodes[coord].queue_free()
	var shield=EDGE_SHIELD_SCRIPT.new()
	shield.lifetime=duration
	shield.position=Vector2(coord)*512.0+Vector2(256,256)
	add_child(shield)
	_shield_nodes[coord]=shield
func loadboard(board_tres:BoardData):
	size=board_tres.size
	offset=-256*Vector2(size)
	enemy_spawn_point_left=board_tres.enemy_spawn_point_left
	enemy_spawn_point_right=board_tres.enemy_spawn_point_right
	enemy_spawn_point_up=board_tres.enemy_spawn_point_up
	enemy_spawn_point_down=board_tres.enemy_spawn_point_down
	for i in range(size.x):
		var array=[]
		for j in range(size.y):
			var cell=Cell.new()
			cell.is_edge=board_tres.grid[i+size.x*j].is_edge
			#if board_tres.grid[i+size.x*j].direction==Vector2.LEFT:
				#if !enemy_spawn_point_left.has(j):
					#enemy_spawn_point_left.append(j)
			#elif board_tres.grid[i+size.x*j].direction==Vector2.RIGHT:
				#if !enemy_spawn_point_right.has(j):
					#enemy_spawn_point_right.append(j)
			#elif board_tres.grid[i+size.x*j].direction==Vector2.UP:
				#if !enemy_spawn_point_up.has(i):
					#enemy_spawn_point_up.append(i)
			#elif board_tres.grid[i+size.x*j].direction==Vector2.DOWN:
				#if !enemy_spawn_point_down.has(i):
					#enemy_spawn_point_down.append(i)
			if board_tres.grid[i+size.x*j].is_edge==false:
				if !enemy_spawn_point_x.has(i):
					enemy_spawn_point_x.append(i)
				if !enemy_spawn_point_y.has(j):
					enemy_spawn_point_y.append(j)
			cell.board=self
			cell.is_collidable=board_tres.grid[i+size.x*j].is_collidable
			cell.is_available=board_tres.grid[i+size.x*j].is_available
			cell.direction=board_tres.grid[i+size.x*j].direction
			cell.max_durability=board_tres.grid[i+size.x*j].durability
			cell.durability=board_tres.grid[i+size.x*j].durability
			cell.coord=Vector2i(i,j)
			array.append(cell)
			if cell.is_available&&!cell.is_edge:
				max_egg_number+=1
		grid.append(array)

func pick_by_weight(weights: Dictionary) -> String:
	var total = 0.0
	for key in weights:
		total += weights[key]
	var roll = randf() * total
	var acc = 0.0
	for key in weights:
		acc += weights[key]
		if roll < acc:
			return key
	return weights.keys()[0]   # 兜底

#================ 指向/瞄准状态（供“临时拿起”的掉落物复用） ================
#调用方：board.begin_targeting(可用判定, 使用回调, 取消回调, 准星贴图)
#  - 可用判定(cell) -> bool：鼠标指到这一格时是否高亮、可点
#  - 使用回调(cell)：左键点在可用格上时触发
#  - 取消回调()：左键点无效处 / 右键时触发
#board 负责接管鼠标、画高亮、最后把系统指针还原
var is_targeting:bool=false
var _target_is_valid:Callable
var _target_on_used:Callable
var _target_on_cancelled:Callable
var _target_highlight:ColorRect=null
var _target_cursor:ImageTexture=null
var _block_drop_clicks_until:int=0

#瞄准中，或刚刚结束瞄准的头几帧：掉落物不要再响应点击
#（拣起/放下的那一次点击会通过物理拾取再送到掉落物一次，这里挡掉）
func blocks_drop_clicks() -> bool:
	return is_targeting||Time.get_ticks_msec()<_block_drop_clicks_until

func begin_targeting(is_valid:Callable,on_used:Callable,on_cancelled:Callable,cursor_texture:Texture2D=null) -> void:
	is_targeting=true
	_target_is_valid=is_valid
	_target_on_used=on_used
	_target_on_cancelled=on_cancelled
	_set_target_cursor(cursor_texture)
	#高亮交给 _process 更新：拿起动作发生在物理拾取回调里，这里不宜新建节点

func end_targeting() -> void:
	if not is_targeting:
		return
	is_targeting=false
	_target_is_valid=Callable()
	_target_on_used=Callable()
	_target_on_cancelled=Callable()
	_block_drop_clicks_until=Time.get_ticks_msec()+120
	_clear_target_cursor()
	_hide_target_highlight()

#主动取消（等价于玩家点了无效处）
func cancel_targeting() -> void:
	if not is_targeting:
		return
	var callback:=_target_on_cancelled
	end_targeting()
	if callback.is_valid():
		callback.call()

#鼠标当前指向的格子，棋盘外返回 null
func get_cell_at_mouse() -> Cell:
	var local:=get_global_mouse_position()-offset
	var coord:=Vector2i(floori(local.x/512.0),floori(local.y/512.0))
	return find_cell(coord)

func _handle_targeting_input(event:InputEvent) -> bool:
	if not is_targeting:
		return false
	if not (event is InputEventMouseButton):
		return false
	if not event.pressed:
		return false
	if event.button_index==MOUSE_BUTTON_RIGHT:
		cancel_targeting()
		get_viewport().set_input_as_handled()
		return true
	if event.button_index!=MOUSE_BUTTON_LEFT:
		return false
	var cell:=get_cell_at_mouse()
	if cell!=null&&_target_is_valid.is_valid()&&bool(_target_is_valid.call(cell)):
		var callback:=_target_on_used
		end_targeting()
		if callback.is_valid():
			callback.call(cell)
	else:
		cancel_targeting()
	get_viewport().set_input_as_handled()
	return true

func _update_target_highlight() -> void:
	if not is_targeting:
		return
	var cell:=get_cell_at_mouse()
	var valid:=cell!=null&&_target_is_valid.is_valid()&&bool(_target_is_valid.call(cell))
	var rect:=_ensure_target_highlight()
	rect.visible=valid
	if valid:
		rect.position=Vector2(cell.coord)*512.0

func _ensure_target_highlight() -> ColorRect:
	if not is_instance_valid(_target_highlight):
		_target_highlight=ColorRect.new()
		_target_highlight.size=Vector2(512.0,512.0)
		_target_highlight.color=Color(1.0,0.85,0.2,0.32)
		_target_highlight.mouse_filter=Control.MOUSE_FILTER_IGNORE
		_target_highlight.z_index=100
		_target_highlight.visible=false
		add_child(_target_highlight)
	return _target_highlight

func _hide_target_highlight() -> void:
	if is_instance_valid(_target_highlight):
		_target_highlight.visible=false

func _set_target_cursor(texture:Texture2D) -> void:
	if texture==null:
		return
	var image:Image=texture.get_image()
	if image==null:
		return
	var cursor_size:=96
	image.resize(cursor_size,cursor_size,Image.INTERPOLATE_BILINEAR)
	_target_cursor=ImageTexture.create_from_image(image)
	Input.set_custom_mouse_cursor(_target_cursor,Input.CURSOR_ARROW,Vector2(cursor_size*0.5,cursor_size*0.5))

func _clear_target_cursor() -> void:
	Input.set_custom_mouse_cursor(null)
	_target_cursor=null

#场景切换/重开时别把准星指针留在屏幕上
func _exit_tree() -> void:
	if is_targeting:
		_clear_target_cursor()

func spawn_egg_at_random_position(type:String):
	if egg_number>=max_egg_number:
		return
	var x=randi_range(0,size.x-1)
	var y=randi_range(0,size.y-1)
	var coord=Vector2(x,y)
	var cell=find_cell(coord)
	while cell.is_exist_egg||cell.is_edge||!cell.is_available:
		x=randi_range(0,size.x-1)
		y=randi_range(0,size.y-1)
		coord=Vector2(x,y)
		cell=find_cell(coord)
	spawn_egg(coord,type)

func spawn_random_egg():
	var egg_type=pick_by_weight(WeightTable.random_eggs)
	spawn_egg_at_random_position(egg_type)

func spawn_initial_eggs():
	var num=max_egg_number/3
	for i in range(num):
		spawn_random_egg()

func try_to_spawn_egg():
	if randf()<egg_spawn_chance:
		spawn_random_egg()

#func get_spawn_chance() -> float:#线性版本
	#if max_egg_number <= 0:
		#return 0.0
	#var ratio = 1.0 - float(egg_number) / float(max_egg_number)
	#ratio = clampf(ratio, 0.0, 1.0)
	#return base_spawn_chance * ratio * 3.0
func get_spawn_chance() -> float:#指数版本
	if max_egg_number <= 0:
		return 0.0
	var ratio = 1.0 - float(egg_number) / float(max_egg_number)
	ratio = clampf(ratio, 0.0, 1.0)
	ratio = pow(ratio, 2)
	return base_spawn_chance * ratio * 8.0

func clear_eggs():
	for i in egg_nodes.values():
		if is_instance_valid(i):
			i. disable_collisionshape()
	for i in egg_nodes.values():
		if is_instance_valid(i):
			remove_egg(i)
			await get_tree().create_timer(0.1).timeout
	await get_tree().create_timer(0.5).timeout

func init():
	grid.clear()
	egg_nodes.clear()
	#offset=Vector2.ZERO
	global_position=Vector2(0,0)
	egg_number=0
	max_egg_number=0
	enemy_spawn_point_left=[]
	enemy_spawn_point_right=[]
	enemy_spawn_point_up=[]
	enemy_spawn_point_down=[]
	var board_address=pick_by_weight(FloorData.board_weights_tables[GameState.floor].pick_random())
	var board_data=load("res://board/%s.tres"%board_address) as BoardData
	loadboard(board_data)
	global_position=offset
	add_to_group("board")
	spawn_initial_eggs()
	spawn_tile()

func load_tutorial():
	grid.clear()
	egg_nodes.clear()
	global_position=Vector2(0,0)
	egg_number=0
	max_egg_number=0
	enemy_spawn_point_left=[]
	enemy_spawn_point_right=[]
	enemy_spawn_point_up=[]
	enemy_spawn_point_down=[]
	var board_address=pick_by_weight(FloorData.board_weights_tables[GameState.floor].pick_random())
	var board_data=load("res://board/board_tutorial.tres") as BoardData
	loadboard(board_data)
	global_position=offset
	add_to_group("board")
	#spawn_initial_eggs()
	spawn_tile()

func spawn_tutorial_eggs():
	if GameState.tutorial_step==0:
		await clear_eggs()
		spawn_egg(Vector2i(1,2),"fire")
		spawn_egg(Vector2i(2,1),"fire")
		spawn_egg(Vector2i(3,1),"fire")
	elif GameState.tutorial_step==1:
		await clear_eggs()
		spawn_egg(Vector2i(1,2),"fire")
		spawn_egg(Vector2i(2,1),"fire")
		spawn_egg(Vector2i(3,1),"fire")
	elif GameState.tutorial_step==2:
		spawn_egg(Vector2i(1,1),"fire")
		spawn_egg(Vector2i(2,1),"ice")
		spawn_egg(Vector2i(3,1),"electricity")
		spawn_egg(Vector2i(1,2),"ice")
		spawn_egg(Vector2i(2,2),"electricity")
		spawn_egg(Vector2i(3,2),"fire")
		spawn_egg(Vector2i(1,3),"electricity")
		spawn_egg(Vector2i(2,3),"fire")
		spawn_egg(Vector2i(3,3),"ice")
