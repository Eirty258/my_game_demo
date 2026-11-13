extends Buff

#镀金：没有任何数值加成，只是给怪物镀一圈金边
#死亡时额外掉一个"金色道具池"（WeightTable.gold_item_pool）里的道具——
#掉落判断写在 Enemy.spawn_drops()，因为那里才是统一的死亡掉落出口

const GOLD_GLOW=preload("res://visual_effects/gold_glow_edge.gd")
const GLOW_LIFETIME:=999999.0#常驻，靠 remove() 销毁
const GLOW_PULSE_HZ:=1.5

var _glow:Node2D=null

func _init() -> void:
	type="gilded"

func _ready() -> void:
	super._ready()
	_apply_glow()

func _apply_glow() -> void:
	if carrier==null:
		return
	#用受击盒半径换算金边大小（本地坐标，父节点的缩放会自动带上）
	var size:=512.0
	var shape_node=carrier.get_node_or_null("Hurtbox/CollisionShape2D")
	if shape_node!=null and shape_node.shape is CircleShape2D:
		size=(shape_node.shape as CircleShape2D).radius*2.4
	_glow=GOLD_GLOW.new()
	_glow.setup(GLOW_LIFETIME,size)
	_glow.pulse_hz=GLOW_PULSE_HZ
	carrier.add_child(_glow)

func remove() -> void:
	if _glow!=null and is_instance_valid(_glow):
		_glow.queue_free()
	_glow=null
	super.remove()
