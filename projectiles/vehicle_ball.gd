extends Projectile

#“车”发射出来的载具弹。行为全部由导出参数决定，六种载具共用这一个脚本：
# - forced_pierce：自带穿透，不管有没有拿穿透道具
# - ignore_pierce_bonus：不参与穿透，拿“尖尖蛋头”也穿不了
# - explode_on_hit：命中即触发炮式爆炸，不再造成直击伤害
# - drop_egg_on_hit：命中时掉一颗随机蛋

const EXPLOSION=preload("res://projectiles/explosion.gd")
const EXPLOSION_RADIUS:=512.0
const EXPLOSION_DAMAGE_SCALE:=3.0

@export var forced_pierce:bool=false
@export var ignore_pierce_bonus:bool=false
@export var explode_on_hit:bool=false
@export var drop_egg_on_hit:bool=false
@export var align_to_direction:bool=false#整个节点跟着发射方向转（宽体载具用）

func _ready() -> void:
	super._ready()
	#贴图不单独转，方向由节点整体决定，避免非等比缩放被拧变形
	$AnimatedSprite2D.rotation=0.0
	if align_to_direction:
		#载具的长边要始终垂直于前进方向：纵向飞时形态天然是横的，
		#横向飞时转 90° 让“三格宽”落在竖直方向上
		if absf(direction.x)>absf(direction.y):
			rotation=PI*0.5
		else:
			rotation=0.0

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
	#爆炸特效就地用载具自己的贴图和颜色，判定留在原地，不跟随任何位移
	var texture:Texture2D=null
	var tint:=Color.WHITE
	var sprite:AnimatedSprite2D=$AnimatedSprite2D
	if sprite.sprite_frames!=null&&sprite.sprite_frames.has_animation("default")&&sprite.sprite_frames.get_frame_count("default")>0:
		texture=sprite.sprite_frames.get_frame_texture("default",0)
		tint=sprite.modulate
	var blast=EXPLOSION.new()
	blast.setup(global_position,final_damage*EXPLOSION_DAMAGE_SCALE,EXPLOSION_RADIUS,200.0,type,texture,tint)
	get_tree().root.add_child(blast)
	queue_free()
