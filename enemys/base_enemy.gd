extends CharacterBody2D
class_name Enemy

@export var health:float=10:
	set(value):
		if health==value:
			return
		health=value
		_on_health_changed()
@export var speed:float=100
@export var weekness:String="null"
@export var direction:Vector2=Vector2.RIGHT:
	set(value):
		direction=value
		if value==Vector2.LEFT:
			$AnimatedSprite2D.flip_h=true
		else:
			$AnimatedSprite2D.flip_h=false
@export var close_attack_damage:float=5
@export var touch_cell:Cell=null
@export var is_stunned:bool=false
@export var is_dying:bool=false
@export var motion:String=""
@export var idle_count=0

##物理碰撞相关
@export var separation_radius: float = 50.0
@export var separation_force: float = 200.0
@export var separation_damping: float = 5.0

@export var ai_velocity: Vector2 = Vector2.ZERO
@export var separation_velocity: Vector2 = Vector2.ZERO
#掉落物表
@export var drop_table:Dictionary={#权重
	"null":2,
	"egg":1,
}
@export var drop_count:int=3

@export var _original_speed:float=0

@export var energy:float=0

func _ready() -> void:
	play_animation("walk")
	$AnimatedSprite2D.frame=randi_range(0,8)#动画起码9帧
	pass

func _physics_process(delta: float) -> void:
	if is_dying:
		return
	handle_ai()
	_apply_separation(delta)
	velocity = ai_velocity + separation_velocity
	move_and_slide()

func _init() -> void:
	add_to_group("enemy")
func take_hit(damage:float,knocked_back:Vector2,type:String):
	is_stunned=true
	if type==weekness:
		damage*=2
	health=health-damage
	#播放受击动画
	play_animation("takehit")
	#position改变用tween做，时长刚好和受击动画一致
	var target_pos := position + knocked_back
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "position", target_pos, 0.8)
	tween.tween_property(self, "position", target_pos, 0.2)
	await get_tree().create_timer(1.0).timeout
	is_stunned=false
	if !is_dying:#TODO 临时用，最好加变量锁
		play_animation("walk")

func _on_health_changed():
	if "boss" in get_groups():
		get_parent().update_energy_by_hp()
	if health<=0:
		die()

func die():
	#碰撞箱消失+播放死亡动画+清理
	if is_dying:
		return
	is_dying=true
	$CollisionShape2D.set_deferred("disabled", true)
	$Hitbox/CollisionShape2D.set_deferred("disabled", true)
	$Hurtbox/CollisionShape2D.set_deferred("disabled", true)
	play_animation("takehit")
	await get_tree().create_timer(0.5).timeout
	#死亡前闪红提示
	$AnimatedSprite2D.pause()   # 停在受击动作
	var flash_tween = create_tween()
	flash_tween.set_loops(5)    # 闪 5 次
	flash_tween.tween_property($AnimatedSprite2D, "modulate", Color.RED, 0.05)
	flash_tween.tween_property($AnimatedSprite2D, "modulate", Color.WHITE, 0.05)
	await flash_tween.finished
	if not is_instance_valid(self):
		return
	#TODO 消失烟雾
	var smokescene:PackedScene=load("res://visual_effects/smoke_death.tscn")
	var smoke=smokescene.instantiate()
	add_child(smoke)
	#慢慢消失
	var fade_tween = create_tween()
	fade_tween.tween_property(self, "modulate:a", 0.0, 0.34)
	await fade_tween.finished
	spawn_drops()
	get_parent().total_enemy_number_reduce()
	GameState.modify_energy(energy)
	get_parent().remove_enemy(self)

func handle_ai():
	pass

func close_attacking():
	if touch_cell!=null:
		ai_velocity=Vector2.ZERO
		#if direction==Vector2.UP:
			#print("velocity因攻击被设为0")
		#$CollisionShape2D.set_deferred("disabled", true)
		if $AnimatedSprite2D.is_playing()==false||motion!="close_attack"&&!is_stunned:
			play_animation("close_attack")
			$AnimationPlayer.play("close_attack_down")#TODO down可以去掉
	else:
		idle_count+=1
		if idle_count>=30:
			ai_velocity=speed*direction
			idle_count=0
		#if direction==Vector2.UP:
			#print("velocity因退出攻击而重置")
		#$CollisionShape2D.set_deferred("disabled", false)

func close_attack():
	if touch_cell!=null:
		touch_cell.take_hit(close_attack_damage)

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body  is TileMapLayer:
		var area = $Hitbox
		var shape_node = area.get_node("CollisionShape2D")
		var circle = shape_node.shape as CircleShape2D
		var radius = circle.radius
		var center = shape_node.global_position
		var front_point = center + direction.normalized() * (radius+256)
		var cell = body.local_to_map(body.to_local(front_point))
		touch_cell=find_cell(cell)


func find_cell(coord:Vector2i)->Cell:
	var board=get_tree().get_first_node_in_group("board")
	return board.find_cell(coord)


func _on_area_2d_body_exited(body: Node2D) -> void:#临时修复反复body_exit：延迟两帧再判断
	if body is TileMapLayer:
		await get_tree().physics_frame
		await get_tree().physics_frame
		if not $Hitbox.has_overlapping_bodies():
			touch_cell=null

func play_animation(motion_name:String):
	motion=motion_name
	var dirstr=""
	if direction==Vector2.RIGHT:
		dirstr="right"
	elif direction==Vector2.DOWN:
		dirstr="down"
	elif direction==Vector2.LEFT:
		dirstr="right"
	elif direction==Vector2.UP:
		dirstr="up"
	var animation=motion_name+"_"+dirstr
	$AnimatedSprite2D.play(animation)

func _apply_separation(delta):
	var separation = Vector2.ZERO
	for other in get_tree().get_nodes_in_group("enemy"):
		if other == self:
			continue
		var diff = global_position - other.global_position
		var dist = diff.length()
		if dist < separation_radius and dist > 0.1:
			var push = diff.normalized() * (1.0 - dist / separation_radius)
			separation += push
			if absf(diff.x) < 0.1:
				separation.x += randf_range(-1.0, 1.0) * (1.0 - dist / separation_radius)
			elif absf(diff.y) < 0.1:
				separation.y += randf_range(-1.0, 1.0) * (1.0 - dist / separation_radius)

	# 分离力累积
	separation_velocity += separation * separation_force * delta

	# 远离时衰减（没有分离力时，慢慢归零）
	if separation == Vector2.ZERO:
		separation_velocity = separation_velocity.lerp(Vector2.ZERO, separation_damping * delta)

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

func sample_drops()->Array:
	var to_spawn_drops=[]
	for i in range(drop_count):
		var drop=pick_by_weight(drop_table)
		if drop!="null":
			to_spawn_drops.append(drop)
	return to_spawn_drops

func spawn_drops():
	var to_spawn_drops=sample_drops()
	for drop in to_spawn_drops:
		SignalBus.something_droped.emit(global_position,drop)

func apply_chill(time_scale: float = 0.7):
	var sprite = get_node_or_null("AnimatedSprite2D")
	if sprite:
		sprite.speed_scale = time_scale
	var anim_player = get_node_or_null("AnimationPlayer")
	if anim_player:
		anim_player.speed_scale = time_scale
	if "speed" in self:
		_original_speed = speed
		speed *= time_scale

func remove_chill() -> void:
	var sprite = get_node_or_null("AnimatedSprite2D")
	if sprite:
		sprite.speed_scale = 1.0
	var anim_player = get_node_or_null("AnimationPlayer")
	if anim_player:
		anim_player.speed_scale = 1.0
	if "speed" in self:
		speed = _original_speed

func add_buff(buff_name:String,params:Dictionary):
	$BuffManager.add_buff(buff_name,params)
