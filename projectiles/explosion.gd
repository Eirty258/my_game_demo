extends Node2D

#通用爆炸（可复用组件）
#- 判定：延迟一帧后对受击盒做一次圆形范围查询，命中范围内所有敌人
#        （用受击盒而不是“到中心的距离”，所以被变大 buff 撑大的敌人也能炸到）
#- 视觉：把传入的贴图放大到爆炸直径，在原地缩没，节点本身不位移
#
#用法：
#	const EXPLOSION=preload("res://projectiles/explosion.gd")
#	var blast=EXPLOSION.new()
#	blast.setup(中心点, 总伤害, 半径, 击退力度, "ju", 贴图, 颜色)
#	get_tree().root.add_child(blast)
#
#为什么延迟一帧：爆炸基本都在 area_entered 回调里触发，那一刻物理空间是锁着的，
#不能做 intersect_shape 查询；等过一帧才安全。

const ENEMY_AREA_MASK:=2#敌人受击盒/攻击盒所在的物理层

@export var radius:float=512.0
@export var damage:float=10.5
@export var knock_force:float=200.0
@export var attack_type:String="ju"
@export var burst_texture:Texture2D=null
@export var burst_tint:Color=Color.WHITE
@export var burst_duration:float=0.35
@export var max_targets:int=256

var center:Vector2=Vector2.ZERO

func setup(p_center:Vector2,p_damage:float,p_radius:float=512.0,p_knock:float=200.0,p_type:String="ju",texture:Texture2D=null,tint:Color=Color.WHITE) -> Node2D:
	center=p_center
	damage=p_damage
	radius=p_radius
	knock_force=p_knock
	attack_type=p_type
	burst_texture=texture
	burst_tint=tint
	return self

func _ready() -> void:
	global_position=center
	_spawn_burst()
	_run()

func _run() -> void:
	await get_tree().physics_frame
	if not is_inside_tree():
		return
	_apply_damage()
	#等特效播完再销毁：贴图是这个节点的子节点，提前 free 会把特效一起掐掉
	if burst_duration>0.0:
		await get_tree().create_timer(burst_duration).timeout
	if is_inside_tree():
		queue_free()

func _apply_damage() -> void:
	var space:=get_world_2d().direct_space_state
	if space==null:
		return
	var shape:=CircleShape2D.new()
	shape.radius=radius
	var query:=PhysicsShapeQueryParameters2D.new()
	query.shape=shape
	query.transform=Transform2D(0.0,center)
	query.collision_mask=ENEMY_AREA_MASK
	query.collide_with_areas=true
	query.collide_with_bodies=false
	var hits:=space.intersect_shape(query,max_targets)
	var hit_enemies:=[]
	for hit in hits:
		var collider=hit.get("collider")
		if collider==null or not is_instance_valid(collider):
			continue
		var enemy=collider.get_parent()
		if enemy==null or not (enemy is Enemy):
			continue
		if enemy.is_dying or hit_enemies.has(enemy):
			continue
		hit_enemies.append(enemy)
		var push:Vector2=enemy.global_position-center
		if push==Vector2.ZERO:
			push=Vector2.DOWN
		enemy.take_hit(damage,push.normalized()*knock_force,attack_type)

func _spawn_burst() -> void:
	if burst_texture==null:
		return
	var texture_width:=float(burst_texture.get_width())
	if texture_width<=0.0:
		return
	var sprite:=Sprite2D.new()
	sprite.texture=burst_texture
	var burst_scale:=radius*2.0/texture_width
	sprite.scale=Vector2(burst_scale,burst_scale)
	sprite.modulate=Color(burst_tint.r,burst_tint.g,burst_tint.b,0.8)
	#挂在爆炸节点自己身上：节点就在爆炸中心，这里不能往 root 上加兄弟节点
	add_child(sprite)
	var tween:=sprite.create_tween()
	tween.set_parallel(true)
	tween.tween_property(sprite,"scale",Vector2.ZERO,burst_duration)
	tween.tween_property(sprite,"modulate:a",0.0,burst_duration)
