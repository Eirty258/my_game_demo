extends Enemy

#旋转龟：两种状态
#· 滚动(rolling)：入场先缩进壳里、然后一路滚，速度很快、不会被击退；
#   被攻击 或者 撞到边界格 → 从壳里钻出来，退出滚动状态
#· 常规(normal)：速度很慢，不会自己再进入滚动状态；
#   但保留 enter_rolling() 接口，以后别的 Boss 可以让它重新滚起来
#
#贴图只有 right / down 两套（arts/texture/enemies/spin_turtle_*.png）：
#   右 = right   左 = right 水平翻转
#   下 = down    上 = down  竖直翻转
#以后补了 up 贴图，只要改 _direction_sheet() 一处

@export var rolling_speed:float=800.0#滚动状态速度
@export var normal_speed:float=120.0#常规状态速度
@export var edge_damage_multiplier:float=3.0#滚动撞边时的伤害倍率（乘面板伤害）
@export var edge_attack_interval:float=2#常规状态贴着边界时的攻击间隔

var is_rolling:bool=false
var _attack_timer:float=0.0

func _ready() -> void:
	super._ready()
	weekness="fire"
	health=10
	close_attack_damage=4
	energy=10
	#攻击/进出壳这些单次动作播完后，回到当前状态该循环的动作
	$AnimatedSprite2D.animation_finished.connect(_on_animation_finished)
	#入场即滚动
	enter_rolling()

func _init() -> void:
	pass

func _physics_process(delta: float) -> void:
	super._physics_process(delta)

func handle_ai():
	if is_rolling:
		ai_velocity=speed*direction
		#滚着撞到边界：造成 3 倍面板伤害，然后退出滚动
		if touch_cell!=null:
			touch_cell.take_hit(close_attack_damage*edge_damage_multiplier)
			exit_rolling()
			ai_velocity=Vector2.ZERO
		return
	#常规状态：慢慢蹭，贴住边界就停下来，隔一会儿啃一口
	if touch_cell!=null:
		ai_velocity=Vector2.ZERO
		_attack_timer-=get_physics_process_delta_time()
		if _attack_timer<=0.0 and _can_attack():
			_attack_timer=edge_attack_interval
			_start_attack()
	else:
		_attack_timer=0.0
		ai_velocity=speed*direction

#能不能开始下一口：受击、进出壳、上一口还没咬完都不行
func _can_attack() -> bool:
	if is_stunned or is_rolling:
		return false
	var sprite:AnimatedSprite2D=$AnimatedSprite2D
	if sprite.is_playing():
		var current:String=sprite.animation
		if current.begins_with("attack") or current.begins_with("inshell") or current.begins_with("outshell"):
			return false
	var player:AnimationPlayer=get_node_or_null("AnimationPlayer")
	if player!=null and player.is_playing():
		return false
	return true

#咬：动画和判定计时器同时起，真正掉血由 AnimationPlayer 在"头伸出去"那一帧调用 close_attack()
func _start_attack() -> void:
	play_animation("attack")
	var player:AnimationPlayer=get_node_or_null("AnimationPlayer")
	if player==null:
		#没有 AnimationPlayer 就退回旧行为，至少别丢伤害
		if touch_cell!=null:
			touch_cell.take_hit(close_attack_damage)
		return
	player.play("attack_%s"%_direction_sheet()[0])

#进入滚动状态（以后别的 Boss 也可以调这个让它重新滚起来）
func enter_rolling() -> void:
	is_rolling=true
	speed=rolling_speed
	_attack_timer=0.0
	touch_cell=null#忘掉之前贴墙的判定，免得刚开滚就判定成"撞墙"
	ai_velocity=speed*direction
	play_animation("inshell")#缩壳，播完自动切到 spin

#退出滚动，回到慢速常规状态
func exit_rolling() -> void:
	if not is_rolling:
		return
	is_rolling=false
	speed=normal_speed
	ai_velocity=Vector2.ZERO
	#给"出壳"动画留出时间，不然贴墙时第一帧就会切进攻击动作
	_attack_timer=edge_attack_interval
	play_animation("outshell")#出壳，播完自动切到 walk

func take_hit(damage:float,knocked_back:Vector2,type:String):
	if is_rolling:
		#滚动中被打：先退出滚动，而且这一次不吃击退
		exit_rolling()
		super.take_hit(damage,Vector2.ZERO,type)
	else:
		super.take_hit(damage,knocked_back,type)

#单次动作播完：回到当前状态该循环的动作
#（AnimatedSprite2D.animation_finished 不带参数，当前动作名直接从 sprite 读）
func _on_animation_finished() -> void:
	var anim_name:String=$AnimatedSprite2D.animation
	if anim_name.begins_with("attack"):
		_play_state_animation()
	elif anim_name.begins_with("inshell"):
		if is_rolling:
			play_animation("spin")
	elif anim_name.begins_with("outshell"):
		_play_state_animation()

func _play_state_animation() -> void:
	if is_stunned:
		return
	play_animation("spin" if is_rolling else "walk")

func _direction_sheet() -> Array:
	#返回 [贴图朝向后缀, 是否水平翻转, 是否竖直翻转]
	if direction==Vector2.LEFT:
		return ["right",true,false]
	if direction==Vector2.UP:
		return ["down",false,true]
	if direction==Vector2.DOWN:
		return ["down",false,false]
	return ["right",false,false]

func play_animation(motion_name:String) -> void:
	motion=motion_name
	var sprite:AnimatedSprite2D=$AnimatedSprite2D
	if sprite==null or sprite.sprite_frames==null:
		return
	var sheet:=_direction_sheet()
	var animation:String="%s_%s"%[motion_name,sheet[0]]
	if not sprite.sprite_frames.has_animation(animation):
		return
	sprite.flip_h=sheet[1]
	sprite.flip_v=sheet[2]
	#切到别的动作 = 这一口被打断：判定计时器也要停，否则动画断了伤害还会迟到
	if motion_name!="attack":
		var player:AnimationPlayer=get_node_or_null("AnimationPlayer")
		if player!=null:
			player.stop()
	#同一个动作已经在播就别从头播，否则每帧调用会把攻击/受击动画一直重置
	if sprite.animation==animation and sprite.is_playing():
		return
	sprite.play(animation)
