extends Node2D

#可复用的"镀发光金边"效果：给一个 512 的格子套一圈会呼吸的金色描边 + 外发光
#到时间自己淡出销毁，不会留在场景里
#
#用法（位置按父节点的局部坐标，和 edge_shield 一样）：
#   const GOLD_GLOW=preload("res://visual_effects/gold_glow_edge.gd")
#   var fx=GOLD_GLOW.new()
#   fx.position=Vector2(coord)*512.0+Vector2(256,256)
#   fx.setup(5.0,512.0)
#   board.add_child(fx)

const GLOW_LAYERS:=5#外发光的层数
const GLOW_STEP:=9.0#每往外一层多宽

@export var cell_size:float=512.0#格子边长
@export var lifetime:float=5.0#总时长（含最后淡出）
@export var edge_color:Color=Color(1.0,0.84,0.30)#主金边
@export var glow_color:Color=Color(1.0,0.62,0.10)#外发光
@export var rim_width:float=7.0#主边线宽
@export var pulse_hz:float=1.2#呼吸频率
@export var fade_time:float=0.55#最后多久淡出

var elapsed:float=0.0

func setup(p_lifetime:float=5.0,p_cell_size:float=512.0) -> Node2D:
	lifetime=maxf(p_lifetime,0.05)
	cell_size=p_cell_size
	return self

func _ready() -> void:
	z_index=50#和边缘护盾同层：压在格子和蛋上面
	#加色混合：金色叠在石板上会真的"发光"，而不是糊一层黄
	var mat:=CanvasItemMaterial.new()
	mat.blend_mode=CanvasItemMaterial.BLEND_MODE_ADD
	material=mat
	queue_redraw()

func _process(delta:float) -> void:
	elapsed+=delta
	if elapsed>=lifetime:
		queue_free()
		return
	queue_redraw()

func _draw() -> void:
	var half:=cell_size*0.5
	var rect:=Rect2(Vector2(-half,-half),Vector2(cell_size,cell_size))
	#呼吸 + 最后淡出
	var pulse:=0.5+0.5*sin(elapsed*TAU*pulse_hz)
	var alpha:=1.0
	if lifetime-elapsed<fade_time:
		alpha=clampf((lifetime-elapsed)/fade_time,0.0,1.0)
	#外发光：由外往内叠几层，越外面越淡
	for i in range(GLOW_LAYERS,0,-1):
		var grow:=GLOW_STEP*float(i)
		var glow_alpha:=(0.26-0.035*float(i))*(0.6+0.4*pulse)*alpha
		if glow_alpha<=0.0:
			continue
		draw_rect(rect.grow(grow),Color(glow_color.r,glow_color.g,glow_color.b,glow_alpha),false,GLOW_STEP*1.8)
	#主金边
	draw_rect(rect,Color(edge_color.r,edge_color.g,edge_color.b,(0.80+0.20*pulse)*alpha),false,rim_width)
	#内侧细亮线，让边缘更"镀"一点
	draw_rect(rect.grow(-rim_width),Color(1.0,0.96,0.72,(0.35+0.35*pulse)*alpha),false,2.0)
