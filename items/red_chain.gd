extends Item

#红色锁链：所有蛋的最少连锁数 -1
#冰/火 两颗即可发射，电 一颗，炮车帅本来就是一颗；最少不会低于 1

func _ready() -> void:
	item_name="red_chain"
	GameState.min_chain=max(GameState.min_chain-1,1)
