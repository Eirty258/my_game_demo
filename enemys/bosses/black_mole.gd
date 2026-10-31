extends Enemy

const CARDINALS = [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]

var board
var offset
var enemy_nodes:Array=[]
var parent
var to_apply_enemies:Array=[]
var move_list:Array=["move_1","move_2","move_3","move_random"]
func _ready() -> void:
	super._ready()
	add_to_group("boss")
	board=get_tree().get_first_node_in_group("board")
	offset=board.offset
	weekness="null"
	speed=0
	health=100
	energy=0
	ai_velocity=speed*direction
	parent=get_parent()
	global_position=coord_to_pos(Vector2i(-4,4))
	#------------------------------------------------
	$Hurtbox/CollisionShape2D.disabled=true
	entrance_animation()
	#var params={
		#"duration":1000,
		#"time_scale":0.7
	#}
	#add_buff("chill",params)
	#await get_tree().create_timer(15).timeout
	#move_2()
	#move_1()

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	handle_ai()

func _init() -> void:
	pass

func handle_ai():
	if is_dying:
		return
	pick_move()

func pick_move():
	if $AnimatedSprite2D.is_playing():
		return
	var num=randi_range(1,3)
	for i in range(num):
		$AnimatedSprite2D.play("idle")
		await $AnimatedSprite2D.animation_finished
	var move=move_list.pick_random()
	if move=="move_1":
		move_1()
	elif move=="move_2":
		move_2()
	elif move=="move_3":
		move_3()
	elif move=="move_random":
		move_random()

const CELL_SIZE := 512


func is_cell_in_board(cell: Vector2i, size: Vector2i) -> bool:
	return cell.x >= 0 and cell.x < size.x and cell.y >= 0 and cell.y < size.y
func is_world_in_board(world_pos: Vector2, size: Vector2i) -> bool:
	var cell = Vector2i(
		floori(world_pos.x / CELL_SIZE),
		floori(world_pos.y / CELL_SIZE)
	)
	return is_cell_in_board(cell, size)


func disappear():
	$AnimatedSprite2D.play("disappear")
	$AnimationPlayer.play("disappear")
func appear():
	$AnimatedSprite2D.play("appear")
	$AnimationPlayer.play("appear")
func hide_hurtbox():
	$Hurtbox/CollisionShape2D.disabled=true
func show_hurtbox():
	$Hurtbox/CollisionShape2D.disabled=false


func coord_to_pos(coord:Vector2i)->Vector2:
	var pos=512*Vector2(coord)+Vector2(256,256)+offset
	return pos


func move_random():
	var dir=CARDINALS.pick_random()
	var x=0
	var y=0
	if dir==Vector2.LEFT:
		y=board.enemy_spawn_point_left.pick_random()
		x=board.enemy_spawn_point_x[0]-5
	elif dir==Vector2.DOWN:
		x=board.enemy_spawn_point_down.pick_random()
		y=board.enemy_spawn_point_y[-1]+4
	elif dir==Vector2.RIGHT:
		y=board.enemy_spawn_point_right.pick_random()
		x=board.enemy_spawn_point_x[-1]+5
	elif dir==Vector2.UP:
		x=board.enemy_spawn_point_up.pick_random()
		y=board.enemy_spawn_point_y[0]-3
	var pos=coord_to_pos(Vector2i(x,y))
	disappear()
	await get_tree().create_timer(2).timeout
	global_position=pos
	appear()

func giant_effect():
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(self,"scale",Vector2(2.5,2.5),2)

func move_3():
	$AnimatedSprite2D.play("mud_sport")
	await get_tree().create_timer(0.5).timeout
	var count=randi_range(2,4)
	var arr=[]
	for i in range(count):
		if not board.egg_nodes.is_empty():
			var egg:Egg=board.egg_nodes.values().pick_random()
			var try_count=1
			while arr.has(egg)||egg.disabled:
				egg=null
				if try_count>=5:
					break
				egg=board.egg_nodes.values().pick_random()
				try_count+=1
			if is_instance_valid(egg):
				var red_cross_scene:PackedScene=load("res://visual_effects/red_cross.tscn")
				var red_cross=red_cross_scene.instantiate()
				egg.add_child(red_cross)
				egg.inactivate_temporarily(randf_range(5,7))

func entrance_animation():
	appear()
	await $AnimatedSprite2D.animation_finished
	$AnimatedSprite2D.play("entrance")
	$AnimationPlayer.play("giant")

func giant_enemies(e:Array):
	$AnimatedSprite2D.play("hat_snake")
	var arr=e.duplicate()
	to_apply_enemies.clear()
	for i in arr:
		await get_tree().create_timer(1).timeout
		if is_instance_valid(i):
			VisualEffect.sustained_lightning($Snake,i,2.0,Color(0.659, 0.401, 1.0, 1.0))
		await get_tree().create_timer(1).timeout
		var params={
			"size":2
		}
		if is_instance_valid(i):
			i.add_buff("giant",params)
func tiny_enemies(e:Array):
	$AnimatedSprite2D.play("hat_crane")
	var arr=e.duplicate()
	to_apply_enemies.clear()
	for i in arr:
		await get_tree().create_timer(1).timeout
		if is_instance_valid(i):
			VisualEffect.sustained_lightning($Crane,i,2.0,Color(1.0, 0.725, 0.275, 1.0))
		await get_tree().create_timer(1).timeout
		var params={
			"size":0.7
		}
		if is_instance_valid(i):
			i.add_buff("tiny",params)
#技能1，随机选中2~3个敌人给予变大buff
func move_1():
	var enemies:Array=parent.enemy_nodes.duplicate()
	if enemies.is_empty():
			return
	var num=randi_range(2,3)
	for i in range(num):
		var enemy=enemies.pick_random()#抽一个敌人
		while enemy_nodes.has(enemy)||"boss" in enemy.get_groups():#如果敌人之前抽到过,或者抽到boss，把这个选项去掉再重新抽
			enemies.erase(enemy)
			enemy=null
			#重新抽之前判断，如果池子空了就不抽了直接结束
			if enemies.is_empty():
				return
			enemy=enemies.pick_random()
		#抽中了，加入抽过的行列，加入待变大行列
		enemy_nodes.append(enemy)
		to_apply_enemies.append(enemy)
	#for i in to_giant_enemies:
		#var params={
			#"duration":100,
			#"time_scale":0.5
		#}
		#i.add_buff("chill",params)
	#对选好的敌人进行变大
	giant_enemies(to_apply_enemies)
#技能2，随机选中2~3个敌人赋予变小buff
func move_2():
	var enemies:Array=parent.enemy_nodes.duplicate()
	if enemies.is_empty():
			return
	var num=randi_range(2,3)
	for i in range(num):
		var enemy=enemies.pick_random()#抽一个敌人
		while enemy_nodes.has(enemy)||"boss" in enemy.get_groups():#如果敌人之前抽到过,或者抽到boss，把这个选项去掉再重新抽
			enemies.erase(enemy)
			enemy=null
			#重新抽之前判断，如果池子空了就不抽了直接结束
			if enemies.is_empty():
				return
			enemy=enemies.pick_random()
		#抽中了，加入抽过的行列，加入待变大行列
		enemy_nodes.append(enemy)
		to_apply_enemies.append(enemy)
	#for i in to_giant_enemies:
		#var params={
			#"duration":100,
			#"time_scale":0.5
		#}
		#i.add_buff("chill",params)
	#对选好的敌人进行变小
	tiny_enemies(to_apply_enemies)

func take_hit(damage:float,knocked_back:Vector2,type:String):
	is_stunned=true
	if type==weekness:
		damage*=2
	health=health-damage
	#播放受击动画
	if $AnimatedSprite2D.animation=="idle":
		$AnimatedSprite2D.play("takehit")
	#position改变用tween做，时长刚好和受击动画一致
	flash_red()
	var target_pos := position + Vector2(0,0)
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "position", target_pos, 0.8)
	tween.tween_property(self, "position", target_pos, 0.2)
	await get_tree().create_timer(1.0).timeout
	is_stunned=false
	if !is_dying:#TODO 临时用，最好加变量锁
		play_animation("walk")

var _flash_tween: Tween = null
var _original_modulate: Color = Color.WHITE
var _has_original: bool = false
func flash_red(duration: float = 0.12) -> void:
	var sprite = get_node_or_null("AnimatedSprite2D")
	if sprite == null or not is_instance_valid(sprite):
		return
	if not _has_original:
		_original_modulate = sprite.modulate
		_has_original = true
	if _flash_tween and _flash_tween.is_valid():
		_flash_tween.kill()
	_flash_tween = create_tween()
	_flash_tween.tween_property(sprite, "modulate", Color(0.945, 0.0, 0.149, 1.0), duration * 0.5)
	_flash_tween.tween_property(sprite, "modulate", _original_modulate, duration * 0.5)
func die():
	#碰撞箱消失+播放死亡动画+清理
	if is_dying:
		return
	is_dying=true
	$CollisionShape2D.set_deferred("disabled", true)
	$Hitbox/CollisionShape2D.set_deferred("disabled", true)
	$Hurtbox/CollisionShape2D.set_deferred("disabled", true)
	$AnimatedSprite2D.play("takehit")
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
	get_parent().remove_boss(self)
