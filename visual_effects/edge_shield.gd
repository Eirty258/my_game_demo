extends Node2D

#边缘护盾的视觉：盾形轮廓 + 半透明填充，没有内部纹理
#下半弧是一条二次贝塞尔曲线（就是抛物线），从上角一路接到下尖，中间没有拼接
#由 board.shield_all_edges() 动态创建，到期自己消失

@export var radius:float=236.0
@export var lifetime:float=10.0
@export var rim_width:float=7.0

var elapsed:float=0.0
var _shield_polygon:=PackedVector2Array()

func _ready() -> void:
	z_index=50
	_shield_polygon=_build_shield_polygon()
	queue_redraw()

func _process(delta: float) -> void:
	elapsed+=delta
	#最后 1 秒淡出
	if lifetime-elapsed<1.0:
		modulate.a=clampf(lifetime-elapsed,0.0,1.0)
	if elapsed>=lifetime:
		queue_free()

func _draw() -> void:
	if _shield_polygon.size()<3:
		return
	draw_colored_polygon(_shield_polygon,Color(0.18,0.42,1.0,0.26))
	var outline:=_shield_polygon.duplicate()
	outline.append(_shield_polygon[0])
	draw_polyline(outline,Color(0.65,0.9,1.0,0.9),rim_width,true)

#盾形轮廓：上边平直，左右各一条二次曲线从顶角收到下尖
#控制点放在顶角正下方，所以顶角切线竖直、下尖切线水平，两条曲线在下尖平滑相接
func _build_shield_polygon() -> PackedVector2Array:
	var half_w:float=radius*0.86
	var top:float=-radius
	var bottom:float=radius*1.02
	var steps:=24
	var points:=PackedVector2Array()
	#顶边
	points.append(Vector2(-half_w,top))
	points.append(Vector2(half_w,top))
	#右侧：二次贝塞尔
	for i in range(1,steps+1):
		points.append(_quad_bezier(Vector2(half_w,top),Vector2(half_w,bottom),Vector2(0.0,bottom),float(i)/float(steps)))
	#左侧：镜像，从下尖回到左上角
	for i in range(steps,0,-1):
		points.append(_quad_bezier(Vector2(-half_w,top),Vector2(-half_w,bottom),Vector2(0.0,bottom),float(i)/float(steps)))
	return points

func _quad_bezier(p0:Vector2,p1:Vector2,p2:Vector2,t:float) -> Vector2:
	var mt:float=1.0-t
	return mt*mt*p0+2.0*mt*t*p1+t*t*p2
