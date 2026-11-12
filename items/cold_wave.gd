extends Item

#寒流（原名降雪）：冰蛋出现概率提高

func _ready() -> void:
	item_name="cold_wave"
	WeightTable.random_eggs["ice"]+=1
