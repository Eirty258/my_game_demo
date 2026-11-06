extends Item

#磁场异常：电蛋出现概率提高

func _ready() -> void:
	item_name="magnetic_anomaly"
	WeightTable.random_eggs["electricity"]+=1
