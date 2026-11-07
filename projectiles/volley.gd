extends Node

#编队发射器：从一个固定起点按间隔依次生成弹射物
#第一节用 first_scene，之后都用 repeat_scene（为空就继续用 first_scene）
#和任何弹射物的存活状态无关，自己发完就销毁
#
#用法：
#	const VOLLEY=preload("res://projectiles/volley.gd")
#	var volley=VOLLEY.new()
#	volley.setup(车头场景, 车厢场景, 起点, 方向, 16, 0.04, 伤害倍率, "ju", 击退)
#	get_tree().root.add_child(volley)

var first_scene:PackedScene=null
var repeat_scene:PackedScene=null
var origin:Vector2=Vector2.ZERO
var direction:Vector2=Vector2.RIGHT
var count:int=1
var interval:float=0.08
var first_interval:float=-1.0#第一节和第二节之间的间隔（负数=和 interval 一样）
var damage_mul:float=1.0
var attack_type:String="ju"
var knockback:Vector2=Vector2.ZERO
var chain_count:int=1#这次发射一共几颗蛋（五连之类的道具要判定它）

func setup(p_first:PackedScene,p_repeat:PackedScene,p_origin:Vector2,p_direction:Vector2,p_count:int,p_interval:float,p_damage_mul:float,p_type:String,p_knockback:Vector2,p_chain_count:int=1,p_first_interval:float=-1.0) -> Node:
	first_scene=p_first
	repeat_scene=p_repeat
	origin=p_origin
	direction=p_direction
	count=p_count
	interval=p_interval
	first_interval=p_first_interval
	damage_mul=p_damage_mul
	attack_type=p_type
	knockback=p_knockback
	chain_count=p_chain_count
	return self

func _ready() -> void:
	_run()

func _run() -> void:
	for i in range(count):
		if i>0:
			var wait:float=interval
			if i==1&&first_interval>=0.0:
				wait=first_interval
			await get_tree().create_timer(wait).timeout
		if not is_inside_tree():
			return
		_fire_one(i)
	queue_free()

func _fire_one(index:int) -> void:
	var scene:PackedScene=first_scene
	if index>0&&repeat_scene!=null:
		scene=repeat_scene
	if scene==null:
		return
	var projectile=scene.instantiate()
	projectile.direction=direction
	projectile.type=attack_type
	projectile.chain_count=chain_count
	projectile.knocked_back=knockback
	projectile.global_position=origin
	projectile.damage_mul*=damage_mul
	#只有第一节参与“双黄蛋/锋利蛋片”这类发射时道具，避免一次刷出十几份
	if index==0:
		SignalBus.egg_shot.emit(projectile)
	get_tree().root.add_child(projectile)
