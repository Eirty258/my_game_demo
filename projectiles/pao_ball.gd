extends Projectile

#红炮的炮弹：穿过第一个敌人，碰到第二个敌人时爆炸
#基础伤害与火球一致（Projectile 默认 3.5），并继承火属性加成（木炭等）
#但不附加灼烧 —— 命中只结算伤害
#爆炸对半径内的所有敌人造成 N 倍面板伤害（默认 3 倍）
#（特效暂时统一使用 red_pao 贴图）

@export var explosion_radius:float=512.0*1.5
@export var explosion_damage_multiplier:float=3.0
@export var knock_back_force:float=100.0
@export var projectile_speed_scale:float=0.8

const RED_PAO_TEXTURE_PATH:String="res://arts/texture/chesses/red_pao.png"

var enemy_hit_count:int=0
var is_exploded:bool=false

func _ready() -> void:
	speed=4096*projectile_speed_scale
	super._ready()
	#棋子保持正立，不做方向旋转
	$AnimatedSprite2D.rotation=0.0
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
	if hit_targets.has(body):
		return
	hit_targets[body]=true
	enemy_hit_count+=1
	#第一个敌人照常吃伤害，炮弹继续飞行（没有灼烧等附加状态）
	if enemy_hit_count>=2:
		explode()
		return
	has_hit=true
	body.take_hit(final_damage,knocked_back,type)

func explode() -> void:
	if is_exploded:
		return
	is_exploded=true
	var center:Vector2=global_position
	var explosion_damage:float=final_damage*explosion_damage_multiplier
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if not is_instance_valid(enemy) or enemy.is_dying:
			continue
		if center.distance_to(enemy.global_position)<=explosion_radius:
			var push:Vector2=enemy.global_position-center
			if push==Vector2.ZERO:
				push=Vector2.DOWN
			enemy.take_hit(explosion_damage,push.normalized()*knock_back_force,type)
	spawn_explosion_visual(center)
	queue_free()

#爆炸范围表现：用红炮贴图铺满直径并淡出
func spawn_explosion_visual(center:Vector2) -> void:
	var texture:Texture2D=load(RED_PAO_TEXTURE_PATH)
	if texture==null:
		return
	var texture_width:float=float(texture.get_width())
	if texture_width<=0:
		return
	var sprite:=Sprite2D.new()
	sprite.texture=texture
	var visual_scale:=explosion_radius*2.0/texture_width
	sprite.scale=Vector2(visual_scale,visual_scale)
	sprite.modulate=Color(1,1,1,0.8)
	get_tree().root.add_child(sprite)
	sprite.global_position=center
	var tween:=sprite.create_tween()
	tween.set_parallel(true)
	tween.tween_property(sprite,"scale",Vector2.ZERO,0.35)
	tween.tween_property(sprite,"modulate:a",0.0,0.35)
	tween.chain().tween_callback(sprite.queue_free)
