extends Node2D
class_name Board

const DRAG_THRESHOLD:=8.0
const fire_egg=preload("res://eggs/fire_egg.tscn")
const ice_egg=preload("res://eggs/ice_egg.tscn")
const electricity_egg=preload("res://eggs/electricity_egg.tscn")



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
	if !GameState.is_floor_cleared&&GameState.tutorial_step==-1:
		try_to_spawn_egg()
	#print("平均生成一颗蛋耗时:",1/(egg_spawn_chance * 60))
	pass

func _init() -> void:
	pass

#鼠标交互
func _input(event: InputEvent) -> void:
	if dragging_egg==null:
		return
	if event is InputEventMouseMotion:
		if not is_dragging:
			if event.position.distance_to(drag_start_pos) > DRAG_THRESHOLD:
				is_dragging=true
			#TODO 给egg写一个根据向量出现指示箭头的函数，在这里调用
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

#在指定坐标生成指定类型的蛋
func spawn_egg(coord:Vector2i,type:String):
	var egg
	if type=="fire":
		egg=fire_egg.instantiate()
	elif type=="ice":
		egg=ice_egg.instantiate()
	elif type=="electricity":
		egg=electricity_egg.instantiate()
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
			if current_type=="electricity":
				if group.size()>=max(GameState.min_chain-1,1):#临时组大于三个元素则分配新id
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
			else:
				if group.size()>=max(GameState.min_chain,1):#临时组大于三个元素则分配新id
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
	egg.die()#节点本身
	SignalBus.egg_broken.emit()

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
