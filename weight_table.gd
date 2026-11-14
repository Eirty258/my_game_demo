extends Node

#所有概率表集中放这里，方便统一调权重
#约定：一张表 = 一个 Dictionary{名字:权重}，用 WeightTable.pick_by_weight(表名) 抽

var random_eggs:Dictionary={#自然生成蛋的权重
	"fire":1,
	"ice":1,
	"electricity":1,
	#下面几种目前权重为 0，不会自然生成；把位置留出来给道具/事件改写
	"red_pao":0,#红炮
	"red_ju":0,#红车
	"red_shuai":0,#红帅
}

#新一层随机天气的权重：第一层固定无天气，不走这张表，所以这里没有 "none"
var weathers:Dictionary={
	"sunny":1,#大晴天
	"snow":1,#雪天
	"storm":1,#雷暴天
}

#敌人死亡时的掉落表：每个掉落槽位抽一次，"null" 表示这次不掉
var enemy_drops:Dictionary={
	"null":2,
	"egg":1,
	"chess":0.2,#棋子：从 chess_pieces 表里随机抽一颗
}

#中国象棋棋子权重表：权重 = 一副棋里该棋子的数量
#红黑各7种共14种；红方：车2 马2 炮2 相2 仕2 帅1 兵5（共16个），黑方同数
#还没实装的先注释掉，做完把注释放开就行（键名要和 weight_table 之外的 spawn 逻辑对得上）
var chess_pieces:Dictionary={
	#——红方——
	"red_bing":5,#兵
	"red_pao":2,#炮
	"red_ju":2,#车
	"red_xiang":2,#相
	"red_shi":2,#仕
	"red_ma":2,#马
	"red_shuai":1,#帅
	#——黑方——
	#"black_bing":5,#卒
	#"black_pao":2,#炮
	#"black_ju":2,#车
	#"black_ma":2,#马
	#"black_xiang":2,#象
	#"black_shi":2,#士
	#"black_shuai":1,#将
}

#红车发射的载具权重表：先全为1，后面再调
var red_ju_vehicles:Dictionary={
	"red_ju_stroller":1,#婴儿车
	"red_ju_bicycle":1,#自行车
	"red_ju_motorcycle":1,#摩托车
	"red_ju_minibus":1,#小客车
	"red_ju_truck":1,#大货车
	"red_ju_train_head":1,#高铁
}

var order_item_pool:Dictionary={#订单道具池
	"conehead":1,
	"double_yolk_egg":1,
	"sharp_shards":1,
	"five_in_a_row":1,
	"driving_license":1,
	"god_right_hand":1,
	"red_chain":1,
	"emergency_exit":1,#紧急出口
	"baby_boom":1,#婴儿潮
	"demographic_dividend":1,#人口红利
	"iron_rooster":1,#铁公鸡
	"cold_wave":1,
	"fume":1,
	"magnetic_anomaly":1,
}

var boss_item_pool:Dictionary={
	"charcoal":1,
	"ice_cube":1,
	"charge_bread":1,
	"cold_wave":1,
	"fume":1,
	"magnetic_anomaly":1,
	"baby_boom":1,#婴儿潮
}

#金色道具池：镀金怪物死亡时从这里抽一个道具掉落
var gold_item_pool:Dictionary={
	"sharp_shards":1,
	"five_in_a_row":1,
	"driving_license":1,
	"god_right_hand":1,
	"red_chain":1,
	"emergency_exit":1,
	"baby_boom":1,#婴儿潮
	"demographic_dividend":1,#人口红利
	"iron_rooster":1,#铁公鸡
	"cold_wave":1,
	"fume":1,
	"magnetic_anomaly":1,
	"anti_personnel_mine":1,#反步兵地雷
}
#所有"自然刷道具"的池子；三个池共用一个已刷出记录，避免同一个道具从别的池再刷一次
const ITEM_POOL_NAMES:Array[String]=["order_item_pool","boss_item_pool","gold_item_pool"]
#已经自然刷出过的道具：抽中后从所有池里清零，本局不再出现（重开时 reset 清空）
var obtained_items:Dictionary={}
#开局时录下来的原始权重，reset() 照它还原
var _default_state:Dictionary={}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_default_state={
		"random_eggs":random_eggs.duplicate(),
		"weathers":weathers.duplicate(),
		"enemy_drops":enemy_drops.duplicate(),
		"chess_pieces":chess_pieces.duplicate(),
		"red_ju_vehicles":red_ju_vehicles.duplicate(),
		"order_item_pool":order_item_pool.duplicate(),
		"boss_item_pool":boss_item_pool.duplicate(),
		"gold_item_pool":gold_item_pool.duplicate(),
	}


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

#重开一局时调用：所有概率表回到初始值（道具加的权重要靠这里清掉）
#以后新增表，记得在上面 _ready 的 _default_state 里补一行
func reset() -> void:
	obtained_items.clear()
	for key in _default_state:
		set(key,_default_state[key].duplicate())

#从某个道具池抽一个"还没自然刷出过"的道具；抽中后标记，并从三个池里一起清零。
#池子被抽空时返回 ""，调用方跳过这次掉落即可
func pick_item(pool_name:String) -> String:
	if not ITEM_POOL_NAMES.has(pool_name):
		push_warning("道具池名不存在：%s" % pool_name)
		return ""
	var pool:Dictionary=get(pool_name)
	var available:Dictionary={}
	for item_name in pool:
		if float(pool[item_name])>0.0 and not obtained_items.has(item_name):
			available[item_name]=pool[item_name]
	if available.is_empty():
		return ""
	var picked:String=pick_by_weight(available)
	mark_item_obtained(picked)
	return picked

#标记某个道具已经自然刷出：之后任何池都不会再抽到它
func mark_item_obtained(item_name:String) -> void:
	if item_name=="":
		return
	obtained_items[item_name]=true
	for pool_name in ITEM_POOL_NAMES:
		var pool:Dictionary=get(pool_name)
		if pool.has(item_name):
			pool[item_name]=0.0

#抽一颗自然生成的蛋：基础权重 + 当前天气加成（天气的加成只在这里临时生效）
func pick_egg_type() -> String:
	return pick_by_weight(Weather.apply_egg_bonus(random_eggs))

func pick_by_weight(weights: Dictionary) -> String:
	var total = 0.0
	for key in weights:
		total += weights[key]
	var roll = randf() * total
	var acc = 0.0
	for key in weights:
		acc += weights[key]
		if roll < acc:
			return key
	return weights.keys()[0]   # 兜底
