extends Node

#天气系统
#约定：同一时刻只有一种天气，新天气直接顶掉旧的（set_weather 覆盖）
#效果分两块：
#1.自然生成蛋的权重：抽蛋时临时 +egg_bonus，不改 WeightTable.random_eggs 本体，
#  所以天气消失后权重自动恢复，也不会和道具的永久加权重叠写坏
#2.属性伤害：对应属性 ×damage_mul，另外两种元素属性 ×WEAKEN_MUL（减弱），
#  在敌人 take_hit 里乘，所以伤害数字显示的就是加成后的值

const NONE:="none"
const SUNNY:="sunny"
const SNOW:="snow"
const STORM:="storm"

#三种元素属性；天气只影响这三种，帅/炮/车之类的伤害不变
const ELEMENTS:Array[String]=["fire","ice","electricity"]
#被天气压制的那两种属性：伤害 ×0.9
const WEAKEN_MUL:=0.9

#icon 留空表示图标还没做，HUD 只显示文字；做好之后把路径填进来就行
const WEATHERS:Dictionary={
	NONE:{"name":"无天气","icon":"","element":"","egg_bonus":0.0,"damage_mul":1.0,
		"description":"没有特殊效果"},
	SUNNY:{"name":"大晴天","icon":"res://arts/texture/sunshine.png","element":"fire",
		"egg_bonus":0.5,"damage_mul":1.2,
		"description":"火蛋权重+0.5，火伤害×1.2；冰/电伤害×0.9"},
	SNOW:{"name":"雪天","icon":"res://arts/texture/snowfall.png","element":"ice",
		"egg_bonus":0.5,"damage_mul":1.2,
		"description":"冰蛋权重+0.5，冰伤害×1.2；火/电伤害×0.9"},
	STORM:{"name":"雷暴天","icon":"res://arts/texture/storm.png","element":"electricity",
		"egg_bonus":0.5,"damage_mul":1.2,
		"description":"电蛋权重+0.5，电伤害×1.2；火/冰伤害×0.9"},
}

#当前天气（同时只有一种）
var current_id:String=NONE


#切换天气：后来的直接顶掉前面的
#道具/Boss 技能/事件以后都可以直接调这个接口
func set_weather(weather_id:String) -> void:
	if not WEATHERS.has(weather_id):
		push_warning("天气 id 不存在：%s" % weather_id)
		return
	if current_id==weather_id:
		return
	current_id=weather_id
	SignalBus.weather_changed.emit(current_id)


func clear_weather() -> void:
	set_weather(NONE)


#新一层开始时决定天气：第一层固定无天气，之后的层从 WeightTable.weathers 里抽
func start_floor(floor:int) -> void:
	if floor<=0:
		set_weather(NONE)
		return
	set_weather(WeightTable.pick_by_weight(WeightTable.weathers))


#重开一局：回到无天气
func reset() -> void:
	set_weather(NONE)


#——查询接口——
func is_clear() -> bool:
	return current_id==NONE

func get_weather_id() -> String:
	return current_id


func get_data(weather_id:String="") -> Dictionary:
	var id:=weather_id if weather_id!="" else current_id
	return WEATHERS.get(id,WEATHERS[NONE])


func get_weather_name() -> String:
	return get_data()["name"]


func get_description() -> String:
	return get_data()["description"]


func get_icon() -> Texture2D:
	var path:String=get_data()["icon"]
	if path=="" or not ResourceLoader.exists(path):
		return null
	return load(path) as Texture2D


#这一天气在给哪类蛋加权（空串表示不加权）
func get_egg_bonus_type() -> String:
	return get_data()["element"]


func get_egg_bonus() -> float:
	return get_data()["egg_bonus"]


#属性伤害倍率：
#- 当前天气对应的属性 ×damage_mul（1.2）
#- 另外两种元素属性 ×WEAKEN_MUL（0.9）
#- 无天气 / 非元素伤害（帅、车、炮等）不变
func get_damage_multiplier(type:String) -> float:
	var element:=get_egg_bonus_type()
	if element=="":
		return 1.0
	if type==element:
		return get_data()["damage_mul"]
	if ELEMENTS.has(type):
		return WEAKEN_MUL
	return 1.0


#给一份蛋权重表加上天气加成，返回新表（不改传入的原表）
func apply_egg_bonus(weights:Dictionary) -> Dictionary:
	var result:=weights.duplicate()
	var bonus_type:=get_egg_bonus_type()
	if bonus_type!="" and result.has(bonus_type):
		result[bonus_type]+=get_egg_bonus()
	return result
