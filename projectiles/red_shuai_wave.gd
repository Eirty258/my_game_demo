extends Area2D

#红帅破碎时的环形冲击波：半径从破碎处迅速扩大，碰到的敌人各吃一次固定伤害
#默认扩到“盖住整个屏幕”，也就是全屏伤害
#（判定用不断变大的实心圆，视觉用 Line2D 画一个粗圆环）

@export var expand_to_screen:bool=true    #自动按“覆盖整个屏幕”算最大半径
@export var max_radius:float=1536.0       #expand_to_screen 关闭时才用这个值
@export var expand_time:float=1.0        #扩到最大用时
@export var damage:float=30.0             #固定伤害，不吃道具加成
@export var knock_back_force:float=200.0
@export var ring_color:Color=Color(1.0,0.15,0.15,0.9)
@export var ring_width:float=160.0        #世界单位

var current_radius:float=0.0
var elapsed:float=0.0
var hit_targets:Dictionary={}
var _finished:bool=false

var _ring:Line2D=null
var _shape:CircleShape2D=null

func _ready() -> void:
	if expand_to_screen:
		max_radius=get_full_screen_radius()+64.0#多给一点余量，保证边缘也吃到
	_shape=CircleShape2D.new()
	_shape.radius=1.0
	$CollisionShape2D.shape=_shape
	_ring=Line2D.new()
	_ring.width=ring_width
	_ring.default_color=ring_color
	_ring.antialiased=true
	add_child(_ring)
	_update_ring(0.0)
	area_entered.connect(_on_area_entered)

func _process(delta: float) -> void:
	#多留一帧再销毁，让最后一圈的重叠判定有机会触发
	if _finished:
		queue_free()
		return
	elapsed+=delta
	var t:float=clampf(elapsed/expand_time,0.0,1.0)
	var eased:float=1.0-pow(1.0-t,3.0)#先快后慢
	current_radius=max_radius*eased
	_shape.radius=maxf(current_radius,1.0)
	_update_ring(current_radius)
	#最后 30% 淡出
	if t>0.7:
		_ring.modulate.a=1.0-(t-0.7)/0.3
	if t>=1.0:
		_finished=true

func _on_area_entered(area: Area2D) -> void:
	var body=area.get_parent()
	if not (body is Enemy):
		return
	if hit_targets.has(body):
		return
	hit_targets[body]=true
	var push:Vector2=body.global_position-global_position
	if push==Vector2.ZERO:
		push=Vector2.DOWN
	body.take_hit(damage,push.normalized()*knock_back_force,"shuai")

func _update_ring(radius:float) -> void:
	if _ring==null:
		return
	var points:=PackedVector2Array()
	var count:=96
	for i in range(count+1):
		var angle:=TAU*float(i)/float(count)
		points.append(Vector2(cos(angle),sin(angle))*radius)
	_ring.points=points

#从冲击波中心到屏幕最远角的距离（世界单位），保证波能盖住整个画面
func get_full_screen_radius() -> float:
	var viewport_size:Vector2=get_viewport().get_visible_rect().size
	var camera:=get_viewport().get_camera_2d()
	var zoom:Vector2=Vector2.ONE
	var center:Vector2=viewport_size*0.5
	if camera!=null:
		zoom=camera.zoom
		center=camera.global_position
	var half:Vector2=viewport_size*0.5/zoom
	var corners:Array=[
		center+Vector2(-half.x,-half.y),
		center+Vector2(half.x,-half.y),
		center+Vector2(-half.x,half.y),
		center+Vector2(half.x,half.y),
	]
	var max_distance:float=0.0
	for corner in corners:
		max_distance=maxf(max_distance,global_position.distance_to(corner))
	return max_distance
