extends Enemy

var is_threw_order:bool=false
var screen_exit_count=0:
	set(value):
		screen_exit_count=value
		if screen_exit_count>=2:
			leave()
func _ready() -> void:
	super._ready()
	weekness="electricity"
	speed=1024
	health=1
	energy=0
	ai_velocity=speed*direction
	drop_table={
		"null":1,
	}
	#------------------------------------------
	await get_tree().create_timer(randf_range(5,10)).timeout
	throw_order()

func _physics_process(delta: float) -> void:
	super._physics_process(delta)

func _init() -> void:
	pass

func handle_ai():
	pass

func leave():
	get_parent().total_enemy_number_reduce()
	GameState.modify_energy(energy)
	get_parent().remove_enemy(self)

func throw_order():
	is_threw_order=true
	var drop_manager=get_tree().get_first_node_in_group("drop_manager")
	var order=drop_manager.spawn_drop_order(global_position)
	drop_order_swaying(order,2048,6)

func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	screen_exit_count+=1
	direction=-direction
	ai_velocity=speed*direction

func drop_order_swaying(order: Node, distance: float = 200.0, duration: float = 2.5) -> void:
	var start_pos = order.position
	var tween = order.create_tween()
	tween.set_parallel(true)
	tween.tween_property(order, "position:y", start_pos.y + distance, duration)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN_OUT)
	# 左右摇摆
	tween.tween_property(order, "position:x", start_pos.x + 20, duration * 0.5)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(order, "position:x", start_pos.x, duration * 0.5)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN_OUT)

func die():
	#碰撞箱消失+播放死亡动画+清理
	if is_dying:
		return
	is_dying=true
	$CollisionShape2D.set_deferred("disabled", true)
	$Hitbox/CollisionShape2D.set_deferred("disabled", true)
	$Hurtbox/CollisionShape2D.set_deferred("disabled", true)
	$AnimatedSprite2D.play("die")
	await get_tree().create_timer(0.5).timeout
	#死亡前闪红提示
	$AnimatedSprite2D.pause()   # 停在受击动作
	#var flash_tween = create_tween()
	#flash_tween.set_loops(5)    # 闪 5 次
	#flash_tween.tween_property($AnimatedSprite2D, "modulate", Color.RED, 0.05)
	#flash_tween.tween_property($AnimatedSprite2D, "modulate", Color.WHITE, 0.05)
	#await flash_tween.finished
	if not is_instance_valid(self):
		return
	#TODO 消失烟雾
	#var smokescene:PackedScene=load("res://visual_effects/smoke_death.tscn")
	#var smoke=smokescene.instantiate()
	#add_child(smoke)
	#慢慢消失
	var fade_tween = create_tween()
	fade_tween.tween_property(self, "modulate:a", 0.0, 0.34)
	await fade_tween.finished
	spawn_drops()
	#----------------
	get_parent().total_enemy_number_reduce()
	GameState.modify_energy(energy)
	get_parent().remove_enemy(self)
	if !is_threw_order:
		throw_order()
	throw_order()
