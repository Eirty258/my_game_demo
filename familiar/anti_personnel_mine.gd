extends Area2D

#反步兵地雷（跟班）
#· 放在棋盘外的车道上（敌人必经的那条线上），随机一种乐高颜色
#· 地面敌人踩中即触发：非 boss 即死，boss 吃 30 点无属性伤害（不吃天气/弱点加成）
#· 空中单位（纸鸽子 is_airborne）踩不到；触发后自己踩扁消失
#· 道具 items/anti_personnel_mine.gd 每波敌人刷出时都再放一颗，所以场上可能同时有好几颗，
#  摆位时会尽量避开已有的地雷（别叠在一起）
#· 换层时棋盘重建，地雷跟着挪到新棋盘的车道上

signal consumed#被踩掉了（留给以后的道具/统计用，目前道具不靠它决定补雷）

const CELL_SIZE:=512.0
#四种乐高颜色，出生时随机一张
const MINE_TEXTURES:Array[Texture2D]=[
	preload("res://arts/texture/familiar/anti_personnel_mine_red.png"),
	preload("res://arts/texture/familiar/anti_personnel_mine_yellow.png"),
	preload("res://arts/texture/familiar/anti_personnel_mine_blue.png"),
	preload("res://arts/texture/familiar/anti_personnel_mine_green.png"),
]
#离墙第几格到第几格之间随机（都在敌人走进来的路线上，最近贴着墙 1 格）
const MIN_OUTSET_CELLS:=1
const MAX_OUTSET_CELLS:=3
#摆位时可以试几次来躲开已有的地雷（试完还撞上就照样放下）
const PLACE_ATTEMPTS:=8
const MINE_AVOID_DISTANCE:=600.0
const HIT_TYPE:="mine"#无属性：不吃天气倍率、也不触发任何弱点翻倍

@export var boss_damage:float=30.0
@export var trigger_radius:float=120.0

var _board:Board=null
var _used:bool=false
var _pulse:Tween=null

func _ready() -> void:
	add_to_group("familiar")
	add_to_group("mine")
	$Sprite2D.texture=MINE_TEXTURES.pick_random()
	body_entered.connect(_on_body_entered)
	SignalBus.floor_ready.connect(_on_floor_ready)
	_place_on_random_lane()
	_start_pulse()

func _start_pulse() -> void:
	#一点点呼吸感：地上有块东西在闪，玩家才注意得到
	_pulse=create_tween()
	_pulse.set_loops()
	_pulse.tween_property(self,"modulate",Color(1.2,1.2,1.2,1.0),0.55)
	_pulse.tween_property(self,"modulate",Color(0.8,0.8,0.8,1.0),0.55)

#——位置：随机侧、随机车道、离墙 1~3 格——
func _on_floor_ready() -> void:
	_board=get_tree().get_first_node_in_group("board") as Board
	_place_on_random_lane()

func _place_on_random_lane() -> void:
	if _board==null:
		_board=get_tree().get_first_node_in_group("board") as Board
	if _board==null:
		return
	#场上可能已经有好几颗雷：多试几次，挑一个不跟别人叠在一起的位置
	var best:=Vector2.ZERO
	for attempt in range(PLACE_ATTEMPTS):
		var point:=_random_lane_point()
		if point==Vector2.INF:
			return
		best=point
		if not _mine_too_close(point):
			break
	global_position=best

#随机一条可刷怪车道、离墙 1~3 格的一个点；没有配置车道时返回 Vector2.INF
func _random_lane_point() -> Vector2:
	var sides:Array[int]=[]
	for side in range(4):
		if not _lanes_for_side(side).is_empty():
			sides.append(side)
	if sides.is_empty():
		return Vector2.INF
	var side:int=sides.pick_random()
	var lanes:Array=_lanes_for_side(side)
	var lane:int=int(lanes.pick_random())
	var outset:=float(randi_range(MIN_OUTSET_CELLS,MAX_OUTSET_CELLS))*CELL_SIZE
	return _lane_point(side,lane,outset)

#这个点附近是不是已经有一颗地雷了（不含自己）
func _mine_too_close(point:Vector2) -> bool:
	for node in get_tree().get_nodes_in_group("mine"):
		if node==self or not is_instance_valid(node):
			continue
		var other:=node as Node2D
		if other!=null and other.global_position.distance_to(point)<MINE_AVOID_DISTANCE:
			return true
	return false

func _board_rect() -> Rect2:
	return Rect2(_board.offset,Vector2(_board.size)*CELL_SIZE)

#某条车道在棋盘外 outset 像素处的落点（left/right 的 lane 是行号，up/down 是列号）
func _lane_point(side:int,lane:int,outset:float) -> Vector2:
	var rect:=_board_rect()
	if side==0:
		return Vector2(rect.position.x-outset,rect.position.y+(lane+0.5)*CELL_SIZE)
	elif side==1:
		return Vector2(rect.end.x+outset,rect.position.y+(lane+0.5)*CELL_SIZE)
	elif side==2:
		return Vector2(rect.position.x+(lane+0.5)*CELL_SIZE,rect.position.y-outset)
	return Vector2(rect.position.x+(lane+0.5)*CELL_SIZE,rect.end.y+outset)

func _lanes_for_side(side:int) -> Array:
	match side:
		0:
			return _board.enemy_spawn_point_left
		1:
			return _board.enemy_spawn_point_right
		2:
			return _board.enemy_spawn_point_up
		3:
			return _board.enemy_spawn_point_down
	return []

#——踩中触发——
func _on_body_entered(body:Node2D) -> void:
	if _used:
		return
	var enemy:=body as Enemy
	if enemy==null:
		return
	if enemy.is_airborne:#天上飞的踩不到
		return
	if enemy.is_dying:
		return
	_trigger(enemy)

func _trigger(enemy:Enemy) -> void:
	_used=true
	if _pulse!=null and _pulse.is_valid():
		_pulse.kill()
	$CollisionShape2D.set_deferred("disabled",true)
	set_deferred("monitoring",false)
	if "boss" in enemy.get_groups():
		enemy.take_hit(boss_damage,Vector2.ZERO,HIT_TYPE)
	else:
		#即死：直接把它的血量当伤害打进去（无属性，不会翻倍也不会被天气削）
		enemy.take_hit(enemy.health,Vector2.ZERO,HIT_TYPE)
	consumed.emit()
	#被踩扁：压扁 + 淡出
	var tween:=create_tween()
	tween.set_parallel(true)
	tween.tween_property(self,"scale",Vector2(1.4,0.12),0.12)
	tween.tween_property(self,"modulate",Color(1,1,1,0),0.24)
	await tween.finished
	queue_free()
