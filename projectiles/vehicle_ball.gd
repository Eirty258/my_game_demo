extends Projectile

#“车”发射出来的载具弹。行为全部由导出参数决定，六种载具共用这一个脚本：
# - forced_pierce：自带穿透，不管有没有拿穿透道具
# - ignore_pierce_bonus：不参与穿透，拿“尖尖蛋头”也穿不了
# - explode_on_hit：命中即触发炮式爆炸，不再造成直击伤害
# - drop_egg_on_hit：命中时掉一颗随机蛋

const BLAST=preload("res://projectiles/blast.gd")
const EXPLOSION_RADIUS:=512.0
const EXPLOSION_DAMAGE_SCALE:=3.0

@export var forced_pierce:bool=false
@export var ignore_pierce_bonus:bool=false
@export var explode_on_hit:bool=false
@export var drop_egg_on_hit:bool=false

func _ready() -> void:
	super._ready()
	#载具不跟着方向旋转：大货车是非等比缩放的，转了会变形
	$AnimatedSprite2D.rotation=0.0

func _process(delta: float) -> void:
	super._process(delta)

#父类的伤害缩放会把碰撞体一起放大，载具尺寸必须是固定的
func update_scale() -> void:
	pass

func is_piercing() -> bool:
	if forced_pierce:
		return true
	if ignore_pierce_bonus:
		return false
	return pierce_flag

func _on_area_entered(area: Area2D) -> void:
	var body=area.get_parent()
	if not (body is Enemy):
		return
	if hit_targets.has(body):
		return
	hit_targets[body]=true
	has_hit=true
	if explode_on_hit:
		_explode()
		return
	body.take_hit(final_damage,knocked_back,type)
	if drop_egg_on_hit:
		SignalBus.something_droped.emit(global_position,"egg")
	if not is_piercing():
		queue_free()

func _explode() -> void:
	BLAST.explode(get_tree(),global_position,final_damage*EXPLOSION_DAMAGE_SCALE,EXPLOSION_RADIUS,200.0,type)
	queue_free()
