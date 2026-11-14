extends Enemy
class_name Familiar

#跟班基类（第一个：铁公鸡）
#继承 Enemy 只是为了复用子弹命中判定（Projectile 里只看 body is Enemy），
#但不加入 "enemy" 组，也不走 Enemy 的 AI / 分离 / 死亡逻辑。
#
#状态机：
#  有电(POWERED)：棋盘外随意游荡；偶尔播 idle，idle 播完下一颗蛋（掉落物）；
#                 60 秒后进入寻路
#  寻路(SEEKING)：走向最近的一侧车道中点；到达后播 discharge
#  没电(DISCHARGED)：原地不动，hurtbox 开启；被电属性打中后播 charge
#  充电(CHARGING)：播完 charge 回到有电
#
#贴图只有朝右一套：左右/斜向移动按 x 位移翻转，竖直移动保持当前朝向。

enum State {POWERED, RESTING, SEEKING, DISCHARGING, DISCHARGED, CHARGING}

const CELL_SIZE:=512.0
const FRAME_SIZE:=512.0

@export_group("贴图")
@export var walk_texture:Texture2D
@export var idle_texture:Texture2D
@export var discharge_texture:Texture2D
@export var charge_texture:Texture2D

@export_group("行为")
@export var move_speed:float=260.0
@export var power_duration:float=60.0#有电持续多少秒
@export var lane_outset:float=512.0#在车道外侧多远的位置出生/停靠
@export var roam_limit:float=768.0#游荡时离棋盘最远多少
@export var egg_drop_name:String="egg"#idle 后掉什么（只掉蛋）
@export var idle_interval_min:float=6.0
@export var idle_interval_max:float=12.0

var state:=State.POWERED
var power_left:float=0.0
var idle_timer:float=0.0
var _board:Board=null
var _wander_dir:=Vector2.ZERO
var _wander_left:float=0.0
var _seeking_target:=Vector2.ZERO

func _ready() -> void:
	add_to_group("familiar")
	_board=get_tree().get_first_node_in_group("board") as Board
	_build_frames()
	$AnimatedSprite2D.animation_finished.connect(_on_animation_finished)
	SignalBus.floor_ready.connect(_on_floor_ready)
	if _board!=null:
		global_position=_random_lane_position()
		_enter_powered()

func _physics_process(delta:float) -> void:
	if _board==null:
		return
	if state==State.POWERED or state==State.RESTING or state==State.SEEKING:
		power_left-=delta
		if power_left<=0.0 and state!=State.SEEKING:
			_start_seeking()
			return
	match state:
		State.POWERED:
			_wander(delta)
			idle_timer-=delta
			if idle_timer<=0.0:
				_start_resting()
		State.SEEKING:
			_seek(delta)

#子弹先问一句：这一发打不打得到我（没电时只吃电属性，别的直接穿过）
func accepts_hit(type:String) -> bool:
	return state==State.DISCHARGED and type=="electricity"

#被电属性打中：没电状态才会被充能（有电时 hurtbox 是关的，正常打不到）
func take_hit(_damage:float,_knocked_back:Vector2,type:String) -> void:
	if type!="electricity":
		return
	if state!=State.DISCHARGED:
		return
	$Hurtbox/CollisionShape2D.set_deferred("disabled",true)
	state=State.CHARGING
	$AnimatedSprite2D.play("charge")

#跟班不会死
func die() -> void:
	pass

func _enter_powered() -> void:
	state=State.POWERED
	power_left=power_duration
	idle_timer=randf_range(idle_interval_min,idle_interval_max)
	_wander_left=0.0
	$Hurtbox/CollisionShape2D.set_deferred("disabled",true)
	$AnimatedSprite2D.play("walk")

func _start_resting() -> void:
	if state!=State.POWERED:
		return
	state=State.RESTING
	$AnimatedSprite2D.play("idle")

func _start_seeking() -> void:
	_enter_seeking()

func _enter_seeking() -> void:
	_seeking_target=_nearest_lane_midpoint()
	state=State.SEEKING
	$AnimatedSprite2D.play("walk")

func _start_discharging() -> void:
	state=State.DISCHARGING
	$AnimatedSprite2D.play("discharge")

func _on_animation_finished() -> void:
	var anim:String=$AnimatedSprite2D.animation
	if state==State.RESTING and anim=="idle":
		_lay_egg()
		state=State.POWERED
		idle_timer=randf_range(idle_interval_min,idle_interval_max)
		$AnimatedSprite2D.play("walk")
	elif state==State.DISCHARGING and anim=="discharge":
		state=State.DISCHARGED
		$Hurtbox/CollisionShape2D.set_deferred("disabled",false)
	elif state==State.CHARGING and anim=="charge":
		_enter_powered()

func _lay_egg() -> void:
	SignalBus.something_droped.emit(global_position,egg_drop_name)

func _on_floor_ready() -> void:
	_board=get_tree().get_first_node_in_group("board") as Board
	if _board==null:
		return
	global_position=_random_lane_position()
	_enter_powered()

#——游荡——
func _wander(delta:float) -> void:
	_wander_left-=delta
	if _wander_left<=0.0:
		_wander_dir=_random_direction()
		_wander_left=randf_range(0.6,1.8)
	var next:=global_position+_wander_dir*move_speed*delta
	var clamped:=_clamp_outside_board(next)
	if clamped.distance_to(next)>0.5:
		_wander_left=0.0
	global_position=clamped
	_update_flip(_wander_dir.x)

func _random_direction() -> Vector2:
	var angle:=randf()*TAU
	return Vector2(cos(angle),sin(angle))

func _seek(delta:float) -> void:
	var to:=_seeking_target-global_position
	if to.length()<=24.0:
		global_position=_seeking_target
		_start_discharging()
		return
	global_position+=to.normalized()*move_speed*delta
	_update_flip(to.x)

#左右/斜向按 x 位移翻转；竖直移动（x≈0）保持原朝向
func _update_flip(dx:float) -> void:
	if dx<-0.5:
		$AnimatedSprite2D.flip_h=true
	elif dx>0.5:
		$AnimatedSprite2D.flip_h=false

#——棋盘/车道位置——
func _board_rect() -> Rect2:
	return Rect2(_board.offset,Vector2(_board.size)*CELL_SIZE)

#随机在某一侧的某条车道上、棋盘外 lane_outset 处出生
func _random_lane_position() -> Vector2:
	var rect:=_board_rect()
	var side:=randi()%4
	var lanes:Array=_lanes_for_side(side)
	var center:=rect.get_center()
	if lanes.is_empty():
		if side==0:
			return Vector2(rect.position.x-lane_outset,center.y)
		elif side==1:
			return Vector2(rect.end.x+lane_outset,center.y)
		elif side==2:
			return Vector2(center.x,rect.position.y-lane_outset)
		return Vector2(center.x,rect.end.y+lane_outset)
	var lane:=int(lanes.pick_random())
	if side==0:#左侧：lane 是行号
		return Vector2(rect.position.x-lane_outset,rect.position.y+(lane+0.5)*CELL_SIZE)
	elif side==1:#右侧
		return Vector2(rect.end.x+lane_outset,rect.position.y+(lane+0.5)*CELL_SIZE)
	elif side==2:#上侧：lane 是列号
		return Vector2(rect.position.x+(lane+0.5)*CELL_SIZE,rect.position.y-lane_outset)
	#下侧
	return Vector2(rect.position.x+(lane+0.5)*CELL_SIZE,rect.end.y+lane_outset)

func _lanes_for_side(side:int) -> Array:
	match side:
		0:
			return _board.enemy_spawn_point_left
		1:
			return _board.enemy_spawn_point_right
		2:
			return _board.enemy_spawn_point_up
		3:
			return _board.enemy_spawn_point_down
	return []

#最近的一侧车道中点（寻路目标）
func _nearest_lane_midpoint() -> Vector2:
	var rect:=_board_rect()
	var center:=rect.get_center()
	var dl:=absf(global_position.x-rect.position.x)
	var dr:=absf(global_position.x-rect.end.x)
	var dt:=absf(global_position.y-rect.position.y)
	var db:=absf(global_position.y-rect.end.y)
	var m:=minf(dl,minf(dr,minf(dt,db)))
	if m==dl:
		return Vector2(rect.position.x-lane_outset,center.y)
	elif m==dr:
		return Vector2(rect.end.x+lane_outset,center.y)
	elif m==dt:
		return Vector2(center.x,rect.position.y-lane_outset)
	return Vector2(center.x,rect.end.y+lane_outset)

#不允许进入棋盘内部：把落点推到棋盘外（按最小穿透方向），并限制最大游荡范围
func _clamp_outside_board(point:Vector2) -> Vector2:
	var rect:=_board_rect()
	var margin:=280.0#贴图半宽 256 + 一点余量，保证身体不压到棋盘
	var left:=rect.position.x-margin
	var right:=rect.end.x+margin
	var top:=rect.position.y-margin
	var bottom:=rect.end.y+margin
	if point.x>left and point.x<right and point.y>top and point.y<bottom:
		var dl:=point.x-left
		var dr:=right-point.x
		var dt:=point.y-top
		var db:=bottom-point.y
		var m:=minf(dl,minf(dr,minf(dt,db)))
		if m==dl:
			point.x=left
		elif m==dr:
			point.x=right
		elif m==dt:
			point.y=top
		else:
			point.y=bottom
	point.x=clampf(point.x,rect.position.x-roam_limit,rect.end.x+roam_limit)
	point.y=clampf(point.y,rect.position.y-roam_limit,rect.end.y+roam_limit)
	return point

#——动画：贴图是横向排的 512 帧表，运行时切成 SpriteFrames——
func _build_frames() -> void:
	var sf:=SpriteFrames.new()
	_add_animation(sf,"walk",walk_texture,5,24,10.0,true)
	_add_animation(sf,"idle",idle_texture,4,13,8.0,false)
	_add_animation(sf,"discharge",discharge_texture,5,24,12.0,false)
	_add_animation(sf,"charge",charge_texture,5,24,12.0,false)
	#SpriteFrames 默认自带一个空的 default 动画，用不到
	if sf.has_animation("default"):
		sf.remove_animation("default")
	$AnimatedSprite2D.sprite_frames=sf

func _add_animation(sf:SpriteFrames,anim_name:String,tex:Texture2D,columns:int,count:int,fps:float,loop:bool) -> void:
	if tex==null:
		return
	sf.add_animation(anim_name)
	sf.set_animation_speed(anim_name,fps)
	sf.set_animation_loop(anim_name,loop)
	for i in range(count):
		var atlas:=AtlasTexture.new()
		atlas.atlas=tex
		var col:=i%columns
		var row:=int(i/columns)
		atlas.region=Rect2(col*FRAME_SIZE,row*FRAME_SIZE,FRAME_SIZE,FRAME_SIZE)
		sf.add_frame(anim_name,atlas)
