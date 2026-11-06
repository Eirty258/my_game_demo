extends Item

#机动车驾驶证：红“车”蛋开始自然生成；同时淘汰掉两种最弱的载具

func _ready() -> void:
	item_name="driving_license"
	#红车蛋进入自然生成池
	WeightTable.random_eggs["red_ju"]+=0.1
	#载具池里婴儿车、自行车退役，不再出现
	WeightTable.red_ju_vehicles["red_ju_stroller"]=0
	WeightTable.red_ju_vehicles["red_ju_bicycle"]=0
