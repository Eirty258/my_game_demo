extends Node

var item_chinese_name:Dictionary={
	"charcoal":"木炭",
	"charge_bread":"充能面包",
	"conehead":"尖尖蛋头",
	"double_yolk_egg":"双黄蛋",
	"ice_cube":"一块蓝冰",
	"sharp_shards":"锋利蛋片",
	"five_in_a_row":"五子棋必胜阵法",
	"driving_license":"机动车驾驶证",
	"cold_wave":"寒流",
	"fume":"怒火中烧",
	"magnetic_anomaly":"磁场异常",
	"god_right_hand":"神之右手",
	"red_chain":"红色锁链",
	"emergency_exit":"紧急出口",
}

var item_description:Dictionary={
	"charcoal":"火属性伤害上升",
	"charge_bread":"电属性伤害上升",
	"conehead":"子弹穿透",
	"double_yolk_egg":"双发",
	"ice_cube":"冰属性伤害上升",
	"sharp_shards":"附加锋利碎片",
	"five_in_a_row":"五子连珠",
	"driving_license":"引擎在轰鸣",
	"cold_wave":"冰蛋出现概率提高",
	"fume":"火蛋出现概率提高",
	"magnetic_anomaly":"电蛋出现概率提高",
	"god_right_hand":"幻想杀手，右键抑制蛋的力量",
	"red_chain":"知识！情感！意志！最少连锁数-1",
	"emergency_exit":"额外出口",
}

#图标：先找 arts/texture/items/ ，再退回 arts/texture/（老道具图标在根目录）
func get_icon_texture(icon_name:String) -> Texture2D:
	for dir in ["res://arts/texture/items/","res://arts/texture/"]:
		var path="%s%s.png"%[dir,icon_name]
		if ResourceLoader.exists(path):
			return load(path)
	return null

#悬浮提示的文案：不是道具（比如蛋片）就返回空串
func get_tooltip(item_name:String) -> String:
	if not item_chinese_name.has(item_name):
		return ""
	return "%s：%s" % [item_chinese_name[item_name],item_description.get(item_name,"")]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
