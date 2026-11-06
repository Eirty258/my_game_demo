extends Egg

#红炮：棋子类蛋，与普通蛋同构（可拖动、可成组、可被双击打碎）
#唯一区别：只需要 1 颗就能成组发射，且发射物在第二个敌人处爆炸

func _init() -> void:
	type="pao"

func _ready() -> void:
	super._ready()


func _process(delta: float) -> void:
	pass

func shoot(chain_count:int):
	var pao_ball_scene:PackedScene=load("res://projectiles/red_pao_ball.tscn")
	var damage_multiply:float=1+(chain_count-1)/5
	for i in directions:
		var pao_ball=pao_ball_scene.instantiate()
		pao_ball.direction=i
		pao_ball.type="fire"#火属性炮弹：吃火属性加成与火弱点，但不附加灼烧
		pao_ball.chain_count=chain_count
		pao_ball.knocked_back=i*100
		pao_ball.global_position=global_position
		pao_ball.damage_mul*=damage_multiply
		SignalBus.egg_shot.emit(pao_ball)
		get_tree().root.add_child(pao_ball)
