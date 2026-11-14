extends Item

#反步兵地雷：拾取后立刻在随机一条车道上放一颗地雷跟班
#之后每次"新一波敌人刷出"（enemy_manager 里 budget 重置那一刻）都再放一颗：
#不看上一颗有没有被踩掉，所以攒着不打会越来越多（每颗各自等敌人来踩）
#换层时棋盘重建：还活着的地雷自己挪到新棋盘上（监听 floor_ready），道具再补一颗

const MINE_SCENE:PackedScene=preload("res://familiar/anti_personnel_mine.tscn")

func _ready() -> void:
	item_name="anti_personnel_mine"
	SignalBus.wave_started.connect(spawn_mine)
	SignalBus.floor_ready.connect(spawn_mine)
	spawn_mine()

#放一颗新地雷（不设上限）
func spawn_mine() -> void:
	var board:=get_tree().get_first_node_in_group("board") as Board
	if board==null:
		return
	var parent:Node=board.get_parent()
	if parent==null:
		parent=board
	var mine:=MINE_SCENE.instantiate()
	parent.add_child(mine)
