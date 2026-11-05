extends Area2D

#红帅破碎时的环形冲击波：半径从破碎处迅速扩大，碰到的敌人各吃一次固定伤害
#（用不断变大的圆形判定区，敌人被波前扫过时触发；纯视觉用的是 Line2D 圆环）

@export var max_radius:float=1536.0        #最大半径（3 格）
@export var expand_time:float=0.35         #扩到最大用时
@export var damage:float=30.0              #固定伤害，不吃道具加成
@export var knock_back_force:float=200.0
@export var ring_color:Color=Color(1.0,0.15,0.15,0.9)
@export var ring_width:float=24.0

var current_radius:float=0.0
var elapsed:float=0.0
var hit_targets:Dictionary={}

var _ring:Line2D=null
var _shape:CircleShape2D=null

func _ready() -> void:
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
		queue_free()

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
	var count:=64
	for i in range(count+1):
		var angle:=TAU*float(i)/float(count)
		points.append(Vector2(cos(angle),sin(angle))*radius)
	_ring.points=points
