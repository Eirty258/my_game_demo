extends Projectile

#红炮的炮弹：穿过第一个敌人，碰到第二个敌人时爆炸
#基础伤害与火球一致（Projectile 默认 3.5），并继承火属性加成（木炭等）
#但不附加灼烧 —— 命中只结算伤害
#爆炸交给通用组件 explosion.gd（受击盒判定 + 原地炸开）

const EXPLOSION=preload("res://projectiles/explosion.gd")

@export var explosion_radius:float=512.0*1.5
@export var explosion_damage_multiplier:float=5.0
@export var knock_back_force:float=100.0
@export var projectile_speed_scale:float=0.8

var enemy_hit_count:int=0
var is_exploded:bool=false

func _ready() -> void:
	speed=4096*projectile_speed_scale
	super._ready()
	#贴图默认朝右，按发射方向转
	$AnimatedSprite2D.rotation=direction.angle()
	$CollisionShape2D.rotation=direction.angle()
	#继承火属性加成：木炭等监听 fire_ball_spawned 的道具会加到本炮弹上
	SignalBus.fire_ball_spawned.emit(self)

func _process(delta: float) -> void:
	super._process(delta)

func _on_area_entered(area: Area2D) -> void:
	if is_exploded:
		return
	var body=area.get_parent()
	if not (body is Enemy):
		return
	if body.has_method("accepts_hit") and not body.accepts_hit(type):
		return
	if hit_targets.has(body):
		return
	hit_targets[body]=true
	enemy_hit_count+=1
	#第一个敌人照常吃伤害，炮弹继续飞行（没有灼烧等附加状态）
	if enemy_hit_count>=2:
		explode(area)
		return
	has_hit=true
	body.take_hit(final_damage,knocked_back,type)

func explode(area:Area2D=null) -> void:
	if is_exploded:
		return
	is_exploded=true
	#炸在碰撞点上（敌人受击盒朝向弹体的那一侧），而不是弹体自己的中心
	var center:=impact_point(area) if area!=null else global_position
	var blast=EXPLOSION.new()
	blast.setup(center,final_damage*explosion_damage_multiplier,explosion_radius,knock_back_force,type)
	get_tree().root.add_child(blast)
	queue_free()
