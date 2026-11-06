extends Node2D

#边缘护盾的视觉：蓝色圆形，四个象限各一种颜色，整体缓慢自转
#由 board.shield_all_edges() 动态创建，到期自己消失

@export var radius:float=236.0
@export var lifetime:float=10.0
@export var spin_speed:float=0.55
@export var rim_width:float=7.0

var elapsed:float=0.0
var _colors:Array[Color]=[
	Color(0.22,0.5,1.0,0.30),
	Color(0.45,0.82,1.0,0.40),
	Color(0.16,0.34,0.92,0.30),
	Color(0.60,0.88,1.0,0.40),
]

func _ready() -> void:
	z_index=50
	queue_redraw()

func _process(delta: float) -> void:
	rotation+=delta*spin_speed#缓慢自转，扇形颜色随之扫过
	elapsed+=delta
	#最后 1 秒淡出
	if lifetime-elapsed<1.0:
		modulate.a=clampf(lifetime-elapsed,0.0,1.0)
	if elapsed>=lifetime:
		queue_free()

func _draw() -> void:
	var segments:=24
	for quarter in range(_colors.size()):
		var points:=PackedVector2Array()
		points.append(Vector2.ZERO)
		var start:=TAU*0.25*float(quarter)
		for i in range(segments+1):
			var angle:=start+TAU*0.25*float(i)/float(segments)
			points.append(Vector2(cos(angle),sin(angle))*radius)
		draw_colored_polygon(points,_colors[quarter])
	#外圈描边
	draw_arc(Vector2.ZERO,radius,0.0,TAU,64,Color(0.65,0.9,1.0,0.75),rim_width,true)
