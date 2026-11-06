extends Item

#降雪：冰蛋出现概率提高

func _ready() -> void:
	item_name="snowfall"
	WeightTable.random_eggs["ice"]+=1
