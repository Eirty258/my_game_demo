extends Node2D

const CARDINALS = [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]
var flamaleon_scene=preload("res://enemys/flamaleon.tscn")
var green_snake_scene=preload("res://enemys/green_snake.tscn")
var black_mole_scene=preload("res://enemys/bosses/black_mole.tscn")
var boss_2_scene=preload("res://enemys/bosses/boss_2.tscn")
var origami_dove_scene=preload("res://enemys/origami_dove.tscn")
var tutorial_enemy_scene=preload("res://enemys/tutorial_enemy.tscn")
var spin_turtle_scene=preload("res://enemys/spin_turtle.tscn")
var enemy_dic:Dictionary={
	"flamaleon":flamaleon_scene,
	"green_snake":green_snake_scene,
	"origami_dove":origami_dove_scene,
	"tutorial_enemy":tutorial_enemy_scene,
	"spin_turtle":spin_turtle_scene,
}
var boss_dic:Dictionary={
	"black_mole":black_mole_scene,
	"boss_2":boss_2_scene,
}
var enemy_cost:Dictionary={
	"flamaleon":3,
	"green_snake":1,
	"spin_turtle":4,
}
var enemy_weights:Dictionary={}
var boss_weights:Dictionary={}
var wave:int=0
var budget:int=0
var base_budget:int=10
#难度随层数（GameState.floor，从 0 开始）增长
const BUDGET_PER_FLOOR:=5.0#每层每波预算 +5
const COOLDOWN_PER_FLOOR:=0.8#每层组间冷却 -0.8 秒
const COOLDOWN_MIN:=1.5#冷却下限
const WAVE_GAP:=8.0#两波之间的间隔
var budget_limit:int=20
var enemy_spawn_point_left=[]
var enemy_spawn_point_right=[]
var enemy_spawn_point_up=[]
var enemy_spawn_point_down=[]
var enemy_limit=1
var enemy_number=0#当前波的敌人数量，用于控制敌人一次刷新的敌人数量;
var enemy_nodes=[]
var boss_nodes=[]
var boss_pos:Vector2=Vector2.ZERO
var total_enemy_number:int=0:
	set(value):
		total_enemy_number=value
		#print("total_enemy_number:",total_enemy_number)
		_on_total_enemy_number_changed()
		if value==0&&GameState.is_boss_cleared:
			GameState.is_floor_cleared=true
var can_spawn:bool=true
var offset:Vector2=Vector2.ZERO
var total_boss_hp:float=0
#能量≥30时只镀金一只怪：用过就置 true，换层/重开时在 init() 里重置
var _gilded_spawn_used:bool=false
#这些怪不参与"能量镀金"，也不会消耗镀金名额（鸽子是能量奖励、教学怪是教程专用）
const GILDED_EXCLUDED:=["origami_dove","tutorial_enemy"]
var current_boss_hp:float:
	get():
		var sum=0
		for i in boss_nodes:
			sum+=i.health
		return sum
# Called when the node enters the scene tree for the first time.
func _ready() -> void:#要比board晚加入节点树
	SignalBus.energy_full.connect(spawn_random_boss)
	SignalBus.boss_cleared.connect(_on_boss_cleared)
	SignalBus.dove_spawned.connect(spawn_dove)
	SignalBus.void_clicked.connect(clear_enemies)
	if GameState.tutorial_step!=-1:
		load_tutorial()
		return
	init()
	#budget=base_budget
	#var board=get_tree().get_first_node_in_group("board")
	#enemy_spawn_point_left=board.enemy_spawn_point_left.duplicate()
	#enemy_spawn_point_right=board.enemy_spawn_point_right.duplicate()
	#enemy_spawn_point_up=board.enemy_spawn_point_up.duplicate()
	#enemy_spawn_point_down=board.enemy_spawn_point_down.duplicate()
	#offset=board.offset
	##spawn_boss("black_mole",coord_to_pos(Vector2i(-3,3)),Vector2.UP)
	#await get_tree().create_timer(5).timeout
	##spawn_enemy("green_snake",Vector2(256,4096),Vector2.UP)
	##spawn_enemy("flamaleon",Vector2(256,-4096),Vector2.DOWN)
	##spawn_enemy("green_snake",Vector2(-256,-4076),Vector2.DOWN)
	##spawn_enemy("green_snake",Vector2(-256,-4096),Vector2.DOWN)
	#spawn_a_wave_of_enemy()
	##spawn_random_boss()
	#spawn_test_scarecrows()
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	#print(total_enemy_number)
	#get_next_wave_budget()
	#if budget>0&&can_spawn:
		#spawn_random_enemy()
	pass
func spawn_boss(bossname:String,pos:Vector2,dir:Vector2):
	var boss_scene=boss_dic[bossname]
	var boss=boss_scene.instantiate()
	boss.global_position=pos
	boss.direction=dir
	add_child(boss)
	#total_enemy_number+=1
	boss_nodes.append(boss)
	total_boss_hp+=boss.health
	update_energy_by_hp()

func spawn_enemy(enemyname:String,pos:Vector2,dir:Vector2):
	var enemy_scene=enemy_dic[enemyname]
	var enemy=enemy_scene.instantiate()
	enemy.global_position=pos
	enemy.direction=dir
	add_child(enemy)
	#能量≥30：下一只生成的怪物镀金，每层只给一只（鸽子/教学怪不占名额）
	if not _gilded_spawn_used and not GILDED_EXCLUDED.has(enemyname) and GameState.energy>=30.0:
		enemy.add_buff("gilded",{})
		_gilded_spawn_used=true
	total_enemy_number+=1
	enemy_nodes.append(enemy)

func remove_enemy(enemy:Enemy):
	enemy_nodes.erase(enemy)
	enemy.queue_free()
func remove_boss(boss:Enemy):
	boss_nodes.erase(boss)
	boss_pos=boss.global_position
	boss.queue_free()
	if boss_nodes.is_empty():
		SignalBus.boss_cleared.emit()
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

func spawn_random_enemy(dir:Vector2,coord:Vector2)->float:
	if GameState.is_floor_cleared:
		return 0.0
	#先把“当前预算买得起的敌人”筛出来再按权重抽。
	#原来的写法是抽到买不起的就重新抽，预算不够时可能永远抽不到（死循环）。
	var affordable:Dictionary={}
	for enemy_name in enemy_weights:
		var weight:float=enemy_weights[enemy_name]
		if weight<=0.0:
			continue
		if float(enemy_cost.get(enemy_name,0))<=budget:
			affordable[enemy_name]=weight
	if affordable.is_empty():
		return 0.0
	var picked:String=pick_by_weight(affordable)
	var cost:float=float(enemy_cost.get(picked,0))
	budget-=cost
	var pos=coord_to_pos(coord)
	spawn_enemy(picked,pos,dir)
	enemy_number+=1
	return cost

func coord_to_pos(coord:Vector2i)->Vector2:
	var pos=512*Vector2(coord)+Vector2(256,256)+offset
	return pos


func _on_enemy_spawn_cooldown_timeout() -> void:
	can_spawn=true
	enemy_number=0

const TEST_CELL_SIZE:=512.0

#测试用：相机可见范围内、棋盘以外的每一格都刷一个教学稻草人
#（不动、1 血、不掉落，专门用来打靶；数量可能有几百个，只在测试时用）
func spawn_test_scarecrows(every:int=1) -> int:
	var board_node=get_tree().get_first_node_in_group("board")
	if board_node==null:
		push_error("spawn_test_scarecrows: 找不到 board")
		return 0
	var board_size:Vector2i=board_node.size
	var offset:Vector2=board_node.offset

	#相机可见的世界矩形；拿不到相机时退回“棋盘外扩 4 格”
	var camera:=get_viewport().get_camera_2d()
	var view_rect:Rect2
	if camera!=null:
		var viewport_size:Vector2=get_viewport().get_visible_rect().size
		var half:Vector2=viewport_size*0.5/camera.zoom
		view_rect=Rect2(camera.global_position-half,half*2.0)
	else:
		var expand:=Vector2(TEST_CELL_SIZE,TEST_CELL_SIZE)*4.0
		view_rect=Rect2(offset-expand,Vector2(board_size)*TEST_CELL_SIZE+expand*2.0)

	var min_x:int=floori((view_rect.position.x-offset.x)/TEST_CELL_SIZE)
	var min_y:int=floori((view_rect.position.y-offset.y)/TEST_CELL_SIZE)
	var max_x:int=floori((view_rect.end.x-offset.x)/TEST_CELL_SIZE)
	var max_y:int=floori((view_rect.end.y-offset.y)/TEST_CELL_SIZE)

	var spawned:=0
	for x in range(min_x,max_x+1,every):
		for y in range(min_y,max_y+1,every):
			if x>=0&&x<board_size.x&&y>=0&&y<board_size.y:
				continue#棋盘内的格子跳过
			var cell:=Vector2i(x,y)
			spawn_enemy("tutorial_enemy",coord_to_pos(cell),direction_to_board(cell,board_size))
			spawned+=1
	print("测试稻草人：共 %d 个（相机范围 x:%d~%d y:%d~%d）"%[spawned,min_x,max_x,min_y,max_y])
	return spawned

#从某一格指向棋盘中心的方向，只取上下左右（敌人只有这四个朝向的动画）
func direction_to_board(cell:Vector2i,board_size:Vector2i) -> Vector2:
	var target:=Vector2(board_size)*0.5
	var delta:=target-Vector2(cell)
	if absf(delta.x)>absf(delta.y):
		return Vector2.RIGHT if delta.x>0.0 else Vector2.LEFT
	return Vector2.DOWN if delta.y>0.0 else Vector2.UP

func get_next_wave_budget():
	await get_tree().create_timer(WAVE_GAP).timeout
	budget=get_wave_budget()
	print("新波次 budget:",budget)

#每波预算：基础预算 + 每层递增，再乘一个随机浮动
#兜底保证至少买得起一个敌人，否则会刷出一波空波
func get_wave_budget() -> float:
	var value:float=(base_budget+BUDGET_PER_FLOOR*GameState.floor)*randf_range(0.7,1.3)
	var cheapest:=INF
	for enemy_name in enemy_weights:
		if enemy_weights[enemy_name]>0.0:
			cheapest=minf(cheapest,float(enemy_cost.get(enemy_name,1)))
	if cheapest==INF:
		cheapest=1.0
	return maxf(value,cheapest)

func random_cardinal() -> Vector2:
	return CARDINALS.pick_random()

func spawn_a_wave_of_enemy():
	if GameState.is_boss_cleared:
		return
	if GameState.is_floor_cleared:
		return
	if GameState.tutorial_step!=-1:
		return
	#生成若干组敌人直到预算用尽
	while budget>0:
		if GameState.is_floor_cleared:
			return
		if not can_spawn:
			await $EnemySpawnCooldown.timeout
			continue
		var spawned:=spawn_a_group_of_enemy(random_cardinal())
		if spawned<=0:
			budget=0.0#预算已经买不起任何一个敌人了，收掉这波，等下一波
			break
		group_cooldown()

#出生线在棋盘外几格：棋盘越大、镜头越远，这条线就跟着往外推，保证敌人在画面外出现
func get_spawn_offset() -> Vector2i:
	var cam_half:=Vector2(6400.0,3600.0)
	var camera:=get_viewport().get_camera_2d()
	if camera!=null&&camera.zoom.x>0.001&&camera.zoom.y>0.001:
		cam_half=get_viewport().get_visible_rect().size*0.5/camera.zoom
	var board_node=get_tree().get_first_node_in_group("board")
	var board_size:=Vector2i(8,8)
	if board_node!=null:
		board_size=board_node.size
	var board_half:=Vector2(board_size)*256.0
	#比画面边缘再多留 1 格
	var out_x:int=int(ceil((cam_half.x-board_half.x)/512.0))+1
	var out_y:int=int(ceil((cam_half.y-board_half.y)/512.0))+1
	return Vector2i(maxi(1,out_x),maxi(1,out_y))

func spawn_a_group_of_enemy(dir:Vector2)->int:
	if GameState.is_floor_cleared:
		return 0
	var board_node=get_tree().get_first_node_in_group("board")
	if board_node==null:
		return 0
	var board_size:Vector2i=board_node.size
	var spawn_offset:=get_spawn_offset()
	var x=0
	var y=0
	var limit=0
	enemy_spawn_point_left.shuffle()
	enemy_spawn_point_right.shuffle()
	enemy_spawn_point_up.shuffle()
	enemy_spawn_point_down.shuffle()
	if dir==Vector2.DOWN:
		y=-spawn_offset.y
		limit=min(enemy_limit,enemy_spawn_point_down.size())
	elif dir==Vector2.LEFT:
		x=board_size.x-1+spawn_offset.x
		limit=min(enemy_limit,enemy_spawn_point_left.size())
	elif dir==Vector2.UP:
		y=board_size.y-1+spawn_offset.y
		limit=min(enemy_limit,enemy_spawn_point_up.size())
	elif dir==Vector2.RIGHT:
		x=-spawn_offset.x
		limit=min(enemy_limit,enemy_spawn_point_right.size())
	var count=0
	var cost:=0.0
	while enemy_number<limit&&budget>0:
		if GameState.is_floor_cleared:
			break
		if dir==Vector2.DOWN:
			x=enemy_spawn_point_down[enemy_number]
		elif dir==Vector2.UP:
			x=enemy_spawn_point_up[enemy_number]
		elif dir==Vector2.RIGHT:
			y=enemy_spawn_point_right[enemy_number]
		elif dir==Vector2.LEFT:
			y=enemy_spawn_point_left[enemy_number]
		else:
			print("enemy_manager.gd:spawn_a_group_of_enemy():方向有误")
		var spent:=spawn_random_enemy(dir,Vector2(x,y))
		if spent<=0.0:
			break#预算买不起任何一个敌人了
		cost+=spent
		count+=1
	print("数量:",count,"花费:",cost)
	return count

func group_cooldown():
	#生成一组敌人后的冷却：随层数缩短
	can_spawn=false
	var shrink:=COOLDOWN_PER_FLOOR*GameState.floor
	var low:float=maxf(COOLDOWN_MIN,4.0-shrink)
	var high:float=maxf(low+0.8,8.0-shrink*1.5)
	$EnemySpawnCooldown.start(randf_range(low,high))
	var next_enemy_limit=enemy_limit+randi_range(-1,1)
	if next_enemy_limit<=0:
		next_enemy_limit=1
	enemy_limit=min(next_enemy_limit,max(enemy_spawn_point_left.size(),enemy_spawn_point_right.size(),enemy_spawn_point_up.size(),enemy_spawn_point_down.size()))

func total_enemy_number_reduce():
	total_enemy_number-=1

func _on_total_enemy_number_changed():
	if GameState.is_floor_cleared:
		return
	if total_enemy_number<=0&&budget<=0:
		await get_next_wave_budget()
		spawn_a_wave_of_enemy()

func spawn_random_boss():
	#一层的 Boss 只出一次：打完（is_boss_cleared）之后能量再满也不再刷
	if GameState.is_boss_cleared:
		return
	if GameState.is_floor_cleared:
		return
	var board_node=get_tree().get_first_node_in_group("board")
	if board_node==null:
		return
	var board_size:Vector2i=board_node.size
	var spawn_offset:=get_spawn_offset()
	var dir=CARDINALS.pick_random()
	var x=0
	var y=0
	if dir==Vector2.DOWN:
		y=-spawn_offset.y
		x=enemy_spawn_point_down.pick_random()
	elif dir==Vector2.UP:
		y=board_size.y-1+spawn_offset.y
		x=enemy_spawn_point_up.pick_random()
	elif dir==Vector2.RIGHT:
		x=-spawn_offset.x
		y=enemy_spawn_point_right.pick_random()
	elif dir==Vector2.LEFT:
		x=board_size.x-1+spawn_offset.x
		y=enemy_spawn_point_left.pick_random()
	var coord=Vector2(x,y)
	var boss_name=pick_by_weight(boss_weights)
	var pos=coord_to_pos(coord)
	spawn_boss(boss_name,pos,dir)
func update_energy_by_hp():
	#Boss 已经被打掉了：能量条就停在满格，别再被血量计算拉回 0
	if GameState.is_boss_cleared:
		GameState.energy=100
		return
	if total_boss_hp==0:
		GameState.energy=0
	else:
		GameState.energy=100*current_boss_hp/total_boss_hp
func _on_boss_cleared():
	GameState.is_boss_cleared=true
	if total_enemy_number==0:
		GameState.is_floor_cleared=true
	total_boss_hp=0
	#Boss 打完后能量条保持满格；能量模式继续留在 "boss"，
	#这样之后再涨能量也不会再触发“能量满”事件（Boss 一局只出一个）
	GameState.energy=100
	var item_name=WeightTable.pick_by_weight(WeightTable.boss_item_pool)
	SignalBus.item_droped.emit(boss_pos,item_name)
	WeightTable.boss_item_pool[item_name]=0
	SignalBus.void_egg_droped.emit(boss_pos)

func spawn_dove():
	spawn_enemy("origami_dove",Vector2(-4096*1.8,-2048-1024),Vector2.RIGHT)

func init():
	_gilded_spawn_used=false#新一层：能量到 30 后可以再镀金一只
	wave=0
	budget=0
	base_budget=10#
	budget_limit=20#
	enemy_spawn_point_left=[]
	enemy_spawn_point_right=[]
	enemy_spawn_point_up=[]
	enemy_spawn_point_down=[]
	enemy_limit=1#
	enemy_number=0
	enemy_nodes=[]
	boss_nodes=[]
	boss_pos=Vector2.ZERO
	total_enemy_number=0
	can_spawn=true
	offset=Vector2.ZERO
	total_boss_hp=0
	#-------------------
	enemy_weights=FloorData.enemy_weights_tables[GameState.floor].pick_random()
	boss_weights=FloorData.boss_weights_tables[GameState.floor]
	budget=get_wave_budget()
	var board=get_tree().get_first_node_in_group("board")
	enemy_spawn_point_left=board.enemy_spawn_point_left.duplicate()
	enemy_spawn_point_right=board.enemy_spawn_point_right.duplicate()
	enemy_spawn_point_up=board.enemy_spawn_point_up.duplicate()
	enemy_spawn_point_down=board.enemy_spawn_point_down.duplicate()
	offset=board.offset
	await get_tree().create_timer(5).timeout
	spawn_a_wave_of_enemy()
func clear_enemies():
	for i in enemy_nodes:
		if is_instance_valid(i):
			i.die()
			await get_tree().create_timer(0.1).timeout
	await get_tree().create_timer(1).timeout

func spawn_tutorial_enemys():
	if GameState.tutorial_step==-1:
		return
	for i in enemy_nodes.duplicate():
		if is_instance_valid(i):
			i.remove()
	if GameState.tutorial_step==0:
		spawn_enemy("tutorial_enemy",coord_to_pos(Vector2(1,-2)),Vector2.DOWN)
	if GameState.tutorial_step==1:
		spawn_enemy("tutorial_enemy",coord_to_pos(Vector2(2,-2)),Vector2.DOWN)
		spawn_enemy("tutorial_enemy",coord_to_pos(Vector2(6,2)),Vector2.DOWN)
	if GameState.tutorial_step==2:
		spawn_enemy("tutorial_enemy",coord_to_pos(Vector2(1,-2)),Vector2.DOWN)
func load_tutorial():
	wave=0
	budget=0
	base_budget=10#
	budget_limit=20#
	enemy_spawn_point_left=[]
	enemy_spawn_point_right=[]
	enemy_spawn_point_up=[]
	enemy_spawn_point_down=[]
	enemy_limit=1#
	enemy_number=0
	enemy_nodes=[]
	boss_nodes=[]
	boss_pos=Vector2.ZERO
	total_enemy_number=0
	can_spawn=true
	offset=Vector2.ZERO
	total_boss_hp=0
	var board=get_tree().get_first_node_in_group("board")
	enemy_spawn_point_left=board.enemy_spawn_point_left.duplicate()
	enemy_spawn_point_right=board.enemy_spawn_point_right.duplicate()
	enemy_spawn_point_up=board.enemy_spawn_point_up.duplicate()
	enemy_spawn_point_down=board.enemy_spawn_point_down.duplicate()
	offset=board.offset
