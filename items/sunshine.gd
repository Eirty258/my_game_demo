extends Item

#怒火中烧（原名日照）：火蛋出现概率提高

func _ready() -> void:
	item_name="sunshine"
	WeightTable.random_eggs["fire"]+=1
