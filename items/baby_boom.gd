extends Item

#婴儿潮：蛋的自然刷新率提高
#直接加 board.base_spawn_chance，多次拾取时每次只加固定值，相对提升会递减

const SPAWN_CHANCE_BONUS:=0.001

func _ready() -> void:
	item_name="baby_boom"
	var board:=get_tree().get_first_node_in_group("board") as Board
	if board==null:
		return
	board.base_spawn_chance+=SPAWN_CHANCE_BONUS
	board.egg_spawn_chance=board.get_spawn_chance()
