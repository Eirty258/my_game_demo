extends Node2D

const CARDINALS = [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]
var flamaleon_scene=preload("res://enemys/flamaleon.tscn")
var green_snake_scene=preload("res://enemys/green_snake.tscn")
var black_mole_scene=preload("res://enemys/bosses/black_mole.tscn")
var origami_dove_scene=preload("res://enemys/origami_dove.tscn")
var tutorial_enemy_scene=preload("res://enemys/tutorial_enemy.tscn")
var enemy_dic:Dictionary={
	"flamaleon":flamaleon_scene,
	"green_snake":green_snake_scene,
	"origami_dove":origami_dove_scene,
	"tutorial_enemy":tutorial_enemy_scene,
}
var boss_dic:Dictionary={
	"black_mole":black_mole_scene
}
var enemy_cost:Dictionary={
	"flamaleon":3,
	"green_snake":1
}
var enemy_weights:Dictionary={}
var boss_weights:Dictionary={}
var wave:int=0
var budget:int=0
var base_budget:int=10
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
		return 0
	#随机挑选敌人;判断并减少预算；在坐标生成对应朝向的敌人;小组敌人数量+1
	var cost=0
	var enemy_name=pick_by_weight(enemy_weights)
	while budget<enemy_cost[enemy_name]:
		enemy_name=pick_by_weight(enemy_weights)
	budget-=enemy_cost[enemy_name]
	cost+=enemy_cost[enemy_name]
	var pos=coord_to_pos(coord)
	spawn_enemy(enemy_name,pos,dir)
	enemy_number+=1
	return cost

func coord_to_pos(coord:Vector2i)->Vector2:
	var pos=512*Vector2(coord)+Vector2(256,256)+offset
	return pos


func _on_enemy_spawn_cooldown_timeout() -> void:
	can_spawn=true
	enemy_number=0

func get_next_wave_budget():
	await get_tree().create_timer(8).timeout
	print("新波次")
	budget=base_budget*randf_range(0.7,1.3)
	print("budget:",budget)

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
		var cooldown=spawn_a_group_of_enemy(random_cardinal())
		group_cooldown(cooldown)

func spawn_a_group_of_enemy(dir:Vector2)->float:
	if GameState.is_floor_cleared:
		return 0
	var x=0
	var y=0
	var limit=0
	enemy_spawn_point_left.shuffle()
	enemy_spawn_point_right.shuffle()
	enemy_spawn_point_up.shuffle()
	enemy_spawn_point_down.shuffle()
	if dir==Vector2.DOWN:
		y=-6
		limit=min(enemy_limit,enemy_spawn_point_down.size())
	elif dir==Vector2.LEFT:
		x=17
		limit=min(enemy_limit,enemy_spawn_point_left.size())
	elif dir==Vector2.UP:
		y=11
		limit=min(enemy_limit,enemy_spawn_point_up.size())
	elif dir==Vector2.RIGHT:
		x=-10
		limit=min(enemy_limit,enemy_spawn_point_right.size())
	var count=0
	var cost=0
	while enemy_number<limit&&budget>0:
		if GameState.is_floor_cleared:
			return 0
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
		var coord=Vector2(x,y)
		cost+=spawn_random_enemy(dir,coord)
		count+=1
	var cooldown=3.0 + count * 1.2 * (1.0 + cost * 0.05)
	print("数量:",count,"花费:",cost,"冷却:",cooldown)
	return cooldown

func group_cooldown(budget:int):
	#生成一组敌人后的冷却
	can_spawn=false
	var cooldown:float=4+budget
	$EnemySpawnCooldown.start(randf_range(4,8))
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
	var dir=CARDINALS.pick_random()
	var x=0
	var y=0
	enemy_spawn_point_left.shuffle()
	enemy_spawn_point_right.shuffle()
	enemy_spawn_point_up.shuffle()
	enemy_spawn_point_down.shuffle()
	if dir==Vector2.DOWN:
		y=-4
	elif dir==Vector2.LEFT:
		x=17
	elif dir==Vector2.UP:
		y=11
	elif dir==Vector2.RIGHT:
		x=-10
	if dir==Vector2.DOWN:
		x=enemy_spawn_point_down.pick_random()
	elif dir==Vector2.UP:
		x=enemy_spawn_point_up.pick_random()
	elif dir==Vector2.RIGHT:
		y=enemy_spawn_point_right.pick_random()
	elif dir==Vector2.LEFT:
		y=enemy_spawn_point_left.pick_random()
	else:
		print("enemy_manager.gd:spawn_a_group_of_enemy():方向有误")
	var coord=Vector2(x,y)
	var boss_name=pick_by_weight(boss_weights)
	var pos=coord_to_pos(coord)
	spawn_boss(boss_name,pos,dir)
func update_energy_by_hp():
	if total_boss_hp==0:
		GameState.energy=0
	else:
		GameState.energy=100*current_boss_hp/total_boss_hp
func _on_boss_cleared():
	GameState.is_boss_cleared=true
	if total_enemy_number==0:
		GameState.is_floor_cleared=true
	total_boss_hp=0
	GameState.energy_mode="energy"
	var item_name=WeightTable.pick_by_weight(WeightTable.boss_item_pool)
	SignalBus.item_droped.emit(boss_pos,item_name)
	WeightTable.boss_item_pool[item_name]=0
	SignalBus.void_egg_droped.emit(boss_pos)

func spawn_dove():
	spawn_enemy("origami_dove",Vector2(-4096*1.8,-2048-1024),Vector2.RIGHT)

func init():
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
	budget=base_budget
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
