extends Node

var is_clearing:bool=false
var projectile_count=0
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#SignalBus.egg_broken.connect(judge_egg_number)
	#SignalBus.projectile_disappeard.connect(judge_projectile_number)
	#SignalBus.tutorial_step_updated.connect(respawn)
	SignalBus.egg_number_zero.connect(judge)
	respawn()
	play_hand()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


#func judge_egg_number():
	#if GameState.tutorial_step==0:
		#if $Board.egg_number!=3&&$Board.egg_number!=0:
			#respawn()
	#elif GameState.tutorial_step==1:
		#if $Board.egg_number!=3&&$Board.egg_number!=0:
			#respawn()
	#elif GameState.tutorial_step==2:
		#if $Board.egg_number==0:
			#respawn()
#
#func judge_projectile_number():
	#projectile_count+=1
	#if GameState.tutorial_step==0:
		#if projectile_count==3:
			#respawn()
			#projectile_count=0

func judge():
	await get_tree().create_timer(2.5).timeout
	print($EnemyManager.enemy_nodes.is_empty())
	if !$EnemyManager.enemy_nodes.is_empty():
		respawn()
		print("失败了")
	else:
		if GameState.tutorial_step!=2:
			GameState.tutorial_step+=1
		else:
			GameState.tutorial_step=-1
		respawn()
		print("成功了")
func respawn():
	$Board.spawn_tutorial_eggs()
	$EnemyManager.spawn_tutorial_enemys()
	if GameState.tutorial_step==0:
		var text="拖动蛋，点击发射，击败敌人以进入下一步"
		show_text_hint(text)
	elif GameState.tutorial_step==1:
		var text="位于多个方向上的蛋组可以同时攻击多个方向，拖动蛋,同时击败两个敌人以进入下一步"
		show_text_hint(text)
	elif GameState.tutorial_step==2:
		var text="双击可以打碎多余的蛋。击败敌人并消除所有的蛋以完成教程"
		show_text_hint(text)


func animation_0():
	$Hand/AnimatedSprite2D.play("up")
	$Hand.global_position=$EnemyManager.coord_to_pos(Vector2(1,2))
	$Hand/AnimatedSprite2D.play("click")
	await $Hand/AnimatedSprite2D.animation_finished
	$Hand/AnimatedSprite2D.play("down")
	var tween_hand=create_tween()
	tween_hand.tween_property($Hand,"global_position",$EnemyManager.coord_to_pos(Vector2(1,1)),1)
	await tween_hand.finished
	$Hand/AnimatedSprite2D.play("up")
	await get_tree().create_timer(1).timeout
func animation_1():
	$Hand/AnimatedSprite2D.play("up")
	$Hand.global_position=$EnemyManager.coord_to_pos(Vector2(1,2))
	$Hand/AnimatedSprite2D.play("click")
	await $Hand/AnimatedSprite2D.animation_finished
	$Hand/AnimatedSprite2D.play("down")
	var tween_hand=create_tween()
	tween_hand.tween_property($Hand,"global_position",$EnemyManager.coord_to_pos(Vector2(2,2)),1)
	await tween_hand.finished
	$Hand/AnimatedSprite2D.play("up")
	await get_tree().create_timer(1).timeout
func animation_2():
	$Hand.global_position=$EnemyManager.coord_to_pos(Vector2(1,2))
	$Hand/AnimatedSprite2D.play("up")
	await get_tree().create_timer(0.2).timeout
	$Hand/AnimatedSprite2D.play("down")
	await get_tree().create_timer(0.2).timeout
	$Hand/AnimatedSprite2D.play("up")
	await get_tree().create_timer(0.2).timeout
	$Hand/AnimatedSprite2D.play("down")
	await get_tree().create_timer(1).timeout

func play_hand():
	while GameState.tutorial_step==0:
		await animation_0()
	while GameState.tutorial_step==1:
		await animation_1()
	while GameState.tutorial_step==2:
		await animation_2()
	$Hand.visible=false

var _current_hint_layer: CanvasLayer = null
var _current_hint_tween: Tween = null

func show_text_hint(text: String, duration: float = 60.0) -> void:
	# 先清除上一个提示
	if _current_hint_tween and _current_hint_tween.is_valid():
		_current_hint_tween.kill()
	if is_instance_valid(_current_hint_layer):
		_current_hint_layer.queue_free()

	var label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 48)
	label.add_theme_color_override("font_color", Color.BLACK)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 4)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	var screen_size = get_viewport().get_visible_rect().size
	label.size = Vector2(screen_size.x, 100)
	label.position = Vector2(0, screen_size.y * 0.05)
	label.pivot_offset = label.size / 2.0

	label.modulate.a = 0.0
	label.scale = Vector2(0.8, 0.8)

	var canvas_layer = CanvasLayer.new()
	canvas_layer.layer = 100
	canvas_layer.add_child(label)
	add_child(canvas_layer)

	_current_hint_layer = canvas_layer

	_current_hint_tween = create_tween()
	_current_hint_tween.set_parallel(true)
	_current_hint_tween.tween_property(label, "modulate:a", 1.0, 0.2)
	_current_hint_tween.tween_property(label, "scale", Vector2.ONE, 0.2)\
		.set_trans(Tween.TRANS_BACK)\
		.set_ease(Tween.EASE_OUT)
	_current_hint_tween.chain().tween_interval(duration)
	_current_hint_tween.chain().tween_property(label, "modulate:a", 0.0, 0.3)
	_current_hint_tween.chain().tween_callback(func():
		if is_instance_valid(canvas_layer):
			canvas_layer.queue_free()
		if _current_hint_layer == canvas_layer:
			_current_hint_layer = null
	)
