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
@export var flip_h_by_direction:bool=false#贴图默认朝右：向左飞时水平翻转
@export var vertical_texture:Texture2D=null#朝下的贴图：竖直飞时换这张，向上再竖直翻转

func _ready() -> void:
	super._ready()
	#贴图不单独转，方向由节点整体决定，避免非等比缩放被拧变形
	$AnimatedSprite2D.rotation=0.0
	_apply_direction_sprite()
	if align_to_direction:
		#载具的长边要始终垂直于前进方向：纵向飞时形态天然是横的，
		#横向飞时转 90° 让“三格宽”落在竖直方向上
		if absf(direction.x)>absf(direction.y):
			rotation=PI*0.5
		else:
			rotation=0.0

#按方向挑贴图并翻转；有竖直贴图的（高铁/货车/摩托等）同时换掉碰撞体
func _apply_direction_sprite() -> void:
	var sprite:AnimatedSprite2D=$AnimatedSprite2D
	sprite.flip_h=false
	sprite.flip_v=false
	var vertical:bool=absf(direction.y)>absf(direction.x)
	if vertical:
		if vertical_texture!=null:
			#竖直方向单独一张朝下的图：上下都换它，向上再竖直翻转
			var frames:=SpriteFrames.new()
			frames.set_animation_loop("default",true)
			frames.add_frame("default",vertical_texture)
			sprite.sprite_frames=frames
			#碰撞体按竖直贴图的尺寸来（俯视图的长宽和侧视图完全不是一回事）
			var shape_node:CollisionShape2D=$CollisionShape2D
			if shape_node!=null and shape_node.shape is RectangleShape2D:
				var rect:RectangleShape2D=shape_node.shape.duplicate()
				rect.size=Vector2(float(vertical_texture.get_width()),float(vertical_texture.get_height()))
				shape_node.shape=rect
		sprite.flip_v=direction.y<0.0#贴图是朝下的，向上飞就竖直翻转
		return
	if flip_h_by_direction:
		sprite.flip_h=direction.x<0.0

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
		_explode(area)
		return
	body.take_hit(final_damage,knocked_back,type)
	if drop_egg_on_hit:
		SignalBus.something_droped.emit(global_position,"egg")
	if not is_piercing():
		queue_free()

func _explode(area:Area2D=null) -> void:
	#爆炸共用同一套 spritesheet（和红炮的爆炸是同一个组件），尺寸由 EXPLOSION_RADIUS 决定
	#炸在碰撞点上（敌人受击盒朝向弹体的那一侧），而不是弹体自己的中心
	var center:=impact_point(area) if area!=null else global_position
	var blast=EXPLOSION.new()
	blast.setup(center,final_damage*EXPLOSION_DAMAGE_SCALE,EXPLOSION_RADIUS,200.0,type)
	get_tree().root.add_child(blast)
	queue_free()
