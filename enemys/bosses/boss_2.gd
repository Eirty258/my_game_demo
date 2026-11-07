extends Enemy

#Boss 2（临时代号）：受击队列 / 元素免疫
#· 被 火/冰/雷 打中时，往队列里压一个对应标记（最新在最左）
#· 队列满 且 全是同一种 → 免疫该属性：不掉血，但仍然吃击退，伤害数字显示"免疫"
#· 持续伤害（烧伤等）直接改 health、不走 take_hit，所以不会加标记
#· 队列长度跟血量挂钩：满血 queue_max 格，血量比例 ≤ low_hp_ratio 时 queue_min 格，中间线性过渡
#· 队列在头顶用一格一个小方块显示：从左到右是从新到旧，最新的那格边框更粗
#· 除此之外没有别的机制，行为和小怪一样：从屏幕外走过来贴墙攻击

const ELEMENT_TYPES:=["fire","ice","electricity"]
const TYPE_COLORS:={
	"fire":Color(1.0,0.36,0.12),
	"ice":Color(0.35,0.8,1.0),
	"electricity":Color(1.0,0.88,0.2),
}

@export var max_hp:float=50.0#血量上限
@export var queue_max:int=5#满血时的队列长度
@export var queue_min:int=1#低血量时的队列长度
@export var low_hp_ratio:float=0.1#血量比例低于它就用最短队列
@export var attack_interval:float=1.0#贴墙攻击间隔

#头顶队列 UI
const CELL_SIZE:=90.0
const CELL_GAP:=10.0
const UI_HEIGHT:=420.0#队列框在头顶多高（本地坐标，会被节点缩放放大）
const BORDER_NEWEST:=8
const BORDER_NORMAL:=3
const EMPTY_COLOR:=Color(0.15,0.15,0.18,0.85)

var markers:Array[String]=[]#从新到旧
var _attack_timer:float=0.0
var _ui_root:Control=null
var _cells:Array=[]
var _last_capacity:int=-1

func _ready() -> void:
	super._ready()
	add_to_group("boss")
	weekness="null"
	health=max_hp
	close_attack_damage=5
	speed=100#和火龙一样
	energy=0
	ai_velocity=speed*direction
	_build_queue_ui()
	_refresh_queue_ui()

func _init() -> void:
	pass

func _physics_process(delta: float) -> void:
	super._physics_process(delta)

func _process(delta: float) -> void:
	#血量变化会让队列长度变化，格子数跟着重铺
	var cap:=queue_capacity()
	if cap!=_last_capacity:
		_last_capacity=cap
		if markers.size()>cap:
			markers.resize(cap)
		_refresh_queue_ui()

func handle_ai():
	if touch_cell!=null:
		ai_velocity=Vector2.ZERO
		_attack_timer-=get_physics_process_delta_time()
		if _attack_timer<=0.0:
			_attack_timer=attack_interval
			touch_cell.take_hit(close_attack_damage)
	else:
		_attack_timer=0.0
		ai_velocity=speed*direction

#================ 受击 / 队列 ================

func take_hit(damage:float,knocked_back:Vector2,type:String):
	if is_immune_to(type):
		#免疫：不掉血，但照样被击退，数字显示"免疫"
		VisualEffect.show_float_text(global_position+DAMAGE_NUMBER_OFFSET,"免疫",Color(0.85,0.85,1.0),56)
		_knock_only(knocked_back)
		return
	super.take_hit(damage,knocked_back,type)
	if is_element(type):
		_push_marker(type)

func is_element(type:String) -> bool:
	return ELEMENT_TYPES.has(type)

#队列满、而且全是这一种属性 → 免疫
func is_immune_to(type:String) -> bool:
	if not is_element(type):
		return false
	var cap:=queue_capacity()
	if markers.size()<cap:
		return false
	for marker in markers:
		if marker!=type:
			return false
	return true

#队列长度随血量平滑变化
func queue_capacity() -> int:
	var ratio:=0.0
	if max_hp>0.0:
		ratio=clampf(health/max_hp,0.0,1.0)
	var t:=0.0
	if 1.0-low_hp_ratio>0.0:
		t=clampf((ratio-low_hp_ratio)/(1.0-low_hp_ratio),0.0,1.0)
	return clampi(roundi(lerpf(float(queue_min),float(queue_max),t)),1,maxi(queue_max,1))

func _push_marker(type:String) -> void:
	markers.push_front(type)
	var cap:=queue_capacity()
	if markers.size()>cap:
		markers.resize(cap)
	_last_capacity=cap
	_refresh_queue_ui()

#只被推开，不掉血（免疫时用）
func _knock_only(knocked_back:Vector2) -> void:
	#和普通受击一样走速度冲量，这样免疫期间的击退也能正常叠加
	knock_velocity+=knocked_back*KNOCK_DECAY

#================ 头顶队列 UI ================

func _build_queue_ui() -> void:
	if _ui_root!=null:
		return
	_ui_root=Control.new()
	_ui_root.mouse_filter=Control.MOUSE_FILTER_IGNORE
	add_child(_ui_root)

func _refresh_queue_ui() -> void:
	if _ui_root==null:
		return
	var cap:=queue_capacity()
	while _cells.size()<cap:
		var panel:=Panel.new()
		panel.mouse_filter=Control.MOUSE_FILTER_IGNORE
		panel.size=Vector2(CELL_SIZE,CELL_SIZE)
		_ui_root.add_child(panel)
		_cells.append(panel)
	while _cells.size()>cap:
		var extra=_cells.pop_back()
		if is_instance_valid(extra):
			extra.queue_free()
	var total_w:=cap*CELL_SIZE+(cap-1)*CELL_GAP
	_ui_root.position=Vector2(-total_w*0.5,-UI_HEIGHT)
	for i in range(cap):
		var panel:Panel=_cells[i]
		panel.position=Vector2(i*(CELL_SIZE+CELL_GAP),0)
		var marker:=""
		if i<markers.size():
			marker=markers[i]
		panel.add_theme_stylebox_override("panel",_cell_style(marker,i==0 and marker!=""))

func _cell_style(marker:String,is_newest:bool) -> StyleBoxFlat:
	var style:=StyleBoxFlat.new()
	style.bg_color=EMPTY_COLOR
	if TYPE_COLORS.has(marker):
		style.bg_color=TYPE_COLORS[marker]
	style.set_border_width_all(BORDER_NEWEST if is_newest else BORDER_NORMAL)
	style.border_color=Color(1,1,1,1) if is_newest else Color(0.75,0.75,0.8,0.6)
	style.corner_radius_top_left=6
	style.corner_radius_top_right=6
	style.corner_radius_bottom_left=6
	style.corner_radius_bottom_right=6
	return style

#================ 死亡 ================

func die():
	if is_dying:
		return
	is_dying=true
	$CollisionShape2D.set_deferred("disabled",true)
	$Hitbox/CollisionShape2D.set_deferred("disabled",true)
	$Hurtbox/CollisionShape2D.set_deferred("disabled",true)
	if _ui_root!=null:
		_ui_root.visible=false
	var tween:=create_tween()
	tween.tween_property(self,"modulate:a",0.0,0.5)
	await tween.finished
	get_parent().remove_boss(self)
