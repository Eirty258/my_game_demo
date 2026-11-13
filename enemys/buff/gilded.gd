extends Buff

#镀金：没有任何数值加成，只是给怪物的贴图外轮廓镀一圈金边
#死亡时额外掉一个"金色道具池"（WeightTable.gold_item_pool）里的道具——
#掉落判断写在 Enemy.spawn_drops()，因为那里才是统一的死亡掉落出口

const GOLD_OUTLINE=preload("res://visual_effects/gold_outline.gd")
const OUTLINE_PX:=10.0
const GLOW_PX:=22.0

var _sprite:AnimatedSprite2D=null
var _original_material:Material=null

func _init() -> void:
	type="gilded"

func _ready() -> void:
	super._ready()
	_apply_outline()

func _apply_outline() -> void:
	if carrier==null:
		return
	_sprite=carrier.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if _sprite==null:
		return
	_original_material=_sprite.material
	_sprite.material=GOLD_OUTLINE.make_material(OUTLINE_PX,GLOW_PX)

func remove() -> void:
	if _sprite!=null and is_instance_valid(_sprite):
		_sprite.material=_original_material
	_sprite=null
	super.remove()
