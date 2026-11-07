extends Enemy

#旋转龟：两种状态
#· 滚动(rolling)：入场就是滚动状态，速度很快、不会被击退；
#   被攻击 或者 撞到边界格 → 退出滚动状态
#· 常规(normal)：速度很慢，不会自己再进入滚动状态；
#   但保留 enter_rolling() 接口，以后别的 Boss 可以让它重新滚起来
#
#下面几个 @export 都是可调数值，直接改检查器或者这里的默认值

@export var rolling_speed:float=800.0#滚动状态速度
@export var normal_speed:float=120.0#常规状态速度
@export var edge_damage_multiplier:float=3.0#滚动撞边时的伤害倍率（乘面板伤害）
@export var edge_attack_interval:float=1.0#常规状态贴着边界时的攻击间隔
@export var rolling_spin_speed:float=10.0#滚动时贴图自转速度（只是状态提示，正式贴图来了可以删）

var is_rolling:bool=false
var _attack_timer:float=0.0

func _ready() -> void:
	super._ready()
	weekness="null"
	health=10
	close_attack_damage=5
	energy=10
	#入场即滚动
	enter_rolling()

func _init() -> void:
	pass

func _process(delta: float) -> void:
	#滚动时贴图自转，方便一眼看出当前状态
	var sprite:AnimatedSprite2D=$AnimatedSprite2D
	if sprite==null:
		return
	if is_rolling:
		sprite.rotation+=delta*rolling_spin_speed
	elif sprite.rotation!=0.0:
		sprite.rotation=0.0

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
		if _attack_timer<=0.0:
			_attack_timer=edge_attack_interval
			touch_cell.take_hit(close_attack_damage)
	else:
		_attack_timer=0.0
		ai_velocity=speed*direction

#进入滚动状态（以后别的 Boss 也可以调这个让它重新滚起来）
func enter_rolling() -> void:
	is_rolling=true
	speed=rolling_speed
	_attack_timer=0.0
	touch_cell=null#忘掉之前贴墙的判定，免得刚开滚就判定成"撞墙"
	ai_velocity=speed*direction
	play_animation("walk")

#退出滚动，回到慢速常规状态
func exit_rolling() -> void:
	if not is_rolling:
		return
	is_rolling=false
	speed=normal_speed
	ai_velocity=Vector2.ZERO
	var sprite:AnimatedSprite2D=$AnimatedSprite2D
	if sprite!=null:
		sprite.rotation=0.0
	play_animation("walk")

func take_hit(damage:float,knocked_back:Vector2,type:String):
	if is_rolling:
		#滚动中被打：先退出滚动，而且这一次不吃击退
		exit_rolling()
		super.take_hit(damage,Vector2.ZERO,type)
	else:
		super.take_hit(damage,knocked_back,type)

#贴图暂时用教学怪的（只有 idle 动画）：找不到对应动作就退回 idle
func play_animation(motion_name:String) -> void:
	motion=motion_name
	var sprite:AnimatedSprite2D=$AnimatedSprite2D
	if sprite==null or sprite.sprite_frames==null:
		return
	var dirstr:="right"
	if direction==Vector2.DOWN:
		dirstr="down"
	elif direction==Vector2.UP:
		dirstr="up"
	var anim:=motion_name+"_"+dirstr
	if not sprite.sprite_frames.has_animation(anim):
		if sprite.sprite_frames.has_animation(motion_name):
			anim=motion_name
		elif sprite.sprite_frames.has_animation("idle"):
			anim="idle"
		else:
			return
	sprite.play(anim)
