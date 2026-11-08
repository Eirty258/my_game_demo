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
var tilemap_body:Node2D=null#当前贴着的那层瓦片（索敌用）
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
#掉落物表：留空就用 WeightTable.enemy_drops（想单独定制的敌人再在这里覆盖）
@export var drop_table:Dictionary={}
@export var drop_count:int=3

@export var _original_speed:float=0

@export var energy:float=0

func _ready() -> void:
	add_to_group("enemy")#放在 _ready：子类都会 super._ready()，_init 里的会被子类覆盖掉
	play_animation("walk")
	$AnimatedSprite2D.frame=randi_range(0,8)#动画起码9帧
	pass

func _physics_process(delta: float) -> void:
	#击退每帧都要走：被一击打死、正在播死亡动画的敌人也要被推一下
	_apply_knockback(delta)
	if is_dying:
		_keep_outside_board()
		return
	#贴着墙的每一帧都重新算一次索敌，避免只在进入时算一次算错就再也不更新
	if is_instance_valid(tilemap_body):
		touch_cell=_cell_ahead(tilemap_body)
	#受击硬直期间不往前走（击退本身照常生效）
	if is_stunned:
		ai_velocity=Vector2.ZERO
	else:
		handle_ai()
	_apply_separation(delta)
	velocity = ai_velocity + separation_velocity
	move_and_slide()
	_keep_outside_board()#兜底：不允许任何推动把它挤进棋盘

#击退用"速度冲量 + 指数衰减"，不再用 tween：
#tween 每次都会从当前位置重设目标点，多段击退互相抢位置，所以叠不满。
#改成速度之后，同时受到的几段击退直接向量相加，位移能全额叠加，衰减也自然。
func _apply_knockback(delta:float) -> void:
	if knock_velocity==Vector2.ZERO:
		return
	position+=knock_velocity*delta
	knock_velocity*=exp(-KNOCK_DECAY*delta)
	if knock_velocity.length_squared()<64.0:
		knock_velocity=Vector2.ZERO

func take_hit(damage:float,knocked_back:Vector2,type:String):
	is_stunned=true
	var is_weakness:=type==weekness
	if is_weakness:
		damage*=2
	health=health-damage
	#属性克制翻倍时用另一种颜色，一眼能看出来
	show_damage(damage,WEAKNESS_DAMAGE_COLOR if is_weakness else NORMAL_DAMAGE_COLOR)
	#播放受击动画
	play_animation("takehit")
	#击退：冲量 = 位移 × 衰减率，单次总位移正好等于 knocked_back
	knock_velocity+=knocked_back*KNOCK_DECAY
	await get_tree().create_timer(1.0).timeout
	is_stunned=false
	if !is_dying:#TODO 临时用，最好加变量锁
		play_animation("walk")

const DAMAGE_NUMBER_OFFSET:=Vector2(0,-160)#数字出现在敌人头顶
const NORMAL_DAMAGE_COLOR:=Color(1.0,0.86,0.32)#普通伤害数字颜色
const WEAKNESS_DAMAGE_COLOR:=Color(0.45,0.95,1.0)#属性克制（翻倍）时的伤害数字颜色
const KNOCK_DECAY:=3.7#击退速度衰减率：越大停得越快

var knock_velocity:Vector2=Vector2.ZERO#当前击退速度（多段击退会累加）

#受击盒中心（世界坐标）：爆炸/命中特效定位"碰撞点"时用
func get_hurt_center() -> Vector2:
	var node:CollisionShape2D=get_node_or_null("Hurtbox/CollisionShape2D")
	if node==null:
		return global_position
	return node.global_position

#受击盒半径（考虑缩放）：爆炸/命中特效定位"碰撞点"时用
func get_hurt_radius() -> float:
	var node:CollisionShape2D=get_node_or_null("Hurtbox/CollisionShape2D")
	var radius:=200.0
	if node!=null:
		var shape:=node.shape
		if shape is CircleShape2D:
			radius=(shape as CircleShape2D).radius
		elif shape is CapsuleShape2D:
			radius=(shape as CapsuleShape2D).radius+(shape as CapsuleShape2D).height*0.5
		elif shape is RectangleShape2D:
			radius=(shape as RectangleShape2D).size.length()*0.5
	return radius*maxf(absf(global_scale.x),absf(global_scale.y))

#显示这次受到的伤害数值（弱点翻倍后也是显示实际数值）
func show_damage(damage:float,color:Color=Color(1.0,0.86,0.32)) -> void:
	VisualEffect.show_damage_number(global_position+DAMAGE_NUMBER_OFFSET,damage,color)

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
	if body is TileMapLayer:
		tilemap_body=body
		touch_cell=_cell_ahead(body)

#正前方那一格；空洞（棋盘挖掉的格子）不算，返回 null
func _cell_ahead(body:Node2D) -> Cell:
	var board=get_tree().get_first_node_in_group("board")
	if board==null:
		return null
	var coord:=_front_cell_coord(body,board.size)
	if coord.x<0:
		return null
	var cell=board.find_cell(coord)
	#正前方是空洞（棋盘挖掉的格子）就不能算“打到了墙”，否则敌人会停下来对着空气攻击
	if cell==null||!cell.is_available:
		return null
	return cell

#朝面朝方向、用“缩放后”的 hitbox 半径往前探一格，返回那一格的坐标。
#原来的写法只用了未缩放的 shape 半径：敌人被变大后 hitbox 实际半径远大于它，
#投影点会落在棋盘外（find_cell 返回 null），于是不攻击、直接穿墙走过去。
func _front_cell_coord(tilemap:Node2D,board_size:Vector2i) -> Vector2i:
	var shape_node:CollisionShape2D=$Hitbox/CollisionShape2D
	var circle:=shape_node.shape as CircleShape2D
	var base_radius:=0.0
	if circle!=null:
		base_radius=circle.radius
	var scaled_radius:=base_radius*maxf(absf(global_scale.x),absf(global_scale.y))
	var center:Vector2=shape_node.global_position
	var front_point:Vector2=center+direction.normalized()*(scaled_radius+256.0)
	var coord:Vector2i=tilemap.local_to_map(tilemap.to_local(front_point))
	#夹回棋盘内：大体积敌人的投影点可能还在棋盘外，取最近的边界格
	coord.x=clampi(coord.x,0,board_size.x-1)
	coord.y=clampi(coord.y,0,board_size.y-1)
	return coord


func find_cell(coord:Vector2i)->Cell:
	var board=get_tree().get_first_node_in_group("board")
	return board.find_cell(coord)

#不允许敌人进入棋盘内部：只沿它接近的那条轴夹住，别的方向（比如纸鹤横穿屏幕）不受影响
func _keep_outside_board() -> void:
	global_position=_clamp_outside_board(global_position)

#这一格是不是棋盘“挖掉”的格子（坐标在盘内但没有格子）
func _is_hole_cell(board:Node,coord:Vector2i) -> bool:
	if coord.x<0:
		return false
	var cell=board.find_cell(coord)
	return cell!=null&&!cell.is_available

#自己脚下这一格（可能已经走进缺口里了）
func _cell_at_point(board:Node,point:Vector2) -> Vector2i:
	var tilemap:Node2D=board.get_node_or_null("grid")
	if tilemap==null:
		return Vector2i(-1,-1)
	return tilemap.local_to_map(tilemap.to_local(point))

func _clamp_outside_board(point:Vector2) -> Vector2:
	var board=get_tree().get_first_node_in_group("board")
	if board==null:
		return point
	#自己脚下或正前方是空洞（棋盘挖掉的格子）：这里没有墙，不夹，
	#让它继续往前走，穿过缺口去攻击缺口后面那一格真正的 edge
	var tilemap:Node2D=board.get_node_or_null("grid")
	if tilemap!=null:
		if _is_hole_cell(board,_cell_at_point(board,point))||_is_hole_cell(board,_front_cell_coord(tilemap,board.size)):
			return point
	var left:float=board.offset.x
	var top:float=board.offset.y
	var right:float=left+board.size.x*512.0
	var bottom:float=top+board.size.y*512.0
	var margin:=_body_radius()
	if direction.x>0.0:
		if point.y>=top&&point.y<=bottom:
			point.x=minf(point.x,left-margin)
	elif direction.x<0.0:
		if point.y>=top&&point.y<=bottom:
			point.x=maxf(point.x,right+margin)
	elif direction.y>0.0:
		if point.x>=left&&point.x<=right:
			point.y=minf(point.y,top-margin)
	elif direction.y<0.0:
		if point.x>=left&&point.x<=right:
			point.y=maxf(point.y,bottom+margin)
	return point

#身体碰撞半径（考虑缩放），用来决定敌人能贴到离棋盘多近
func _body_radius() -> float:
	var shape_node:CollisionShape2D=$CollisionShape2D
	var circle:=shape_node.shape as CircleShape2D
	var base_radius:=20.0
	if circle!=null:
		base_radius=circle.radius
	return base_radius*maxf(absf(global_scale.x),absf(global_scale.y))


func _on_area_2d_body_exited(body: Node2D) -> void:#临时修复反复body_exit：延迟两帧再判断
	if body is TileMapLayer:
		await get_tree().physics_frame
		await get_tree().physics_frame
		if not $Hitbox.has_overlapping_bodies():
			tilemap_body=null
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
	#贴图还没有这个动作的动画时，退回同名动画 / idle，别刷一堆报错
	var frames=$AnimatedSprite2D.sprite_frames
	if frames!=null and not frames.has_animation(animation):
		if frames.has_animation(motion_name):
			animation=motion_name
		elif frames.has_animation("idle"):
			animation="idle"
		else:
			return
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
	var table:Dictionary=drop_table
	if table.is_empty():
		table=WeightTable.enemy_drops
	for i in range(drop_count):
		var drop=pick_by_weight(table)
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
