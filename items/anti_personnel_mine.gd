extends Item

#反步兵地雷：拾取后立刻在随机一条车道上放一颗地雷跟班
#地雷被踩掉之后，在下一波敌人刷出时（budget 重置那一刻）再随机放一颗
#同一时间只维持一颗地雷

const MINE_SCENE:PackedScene=preload("res://familiar/anti_personnel_mine.tscn")

var _mine:Node=null

func _ready() -> void:
	item_name="anti_personnel_mine"
	SignalBus.wave_started.connect(_on_wave_started)
	#换层时棋盘重建：地雷还在就跟着挪（它自己监听 floor_ready），
	#已经被踩掉了就补一颗，新一层的第一个波次也有雷可用
	SignalBus.floor_ready.connect(_on_wave_started)
	spawn_mine()

func _on_wave_started() -> void:
	spawn_mine()

#放一颗新地雷；已经有一颗活着就什么也不做（返回 false）
func spawn_mine() -> bool:
	if is_instance_valid(_mine):
		return false
	var board:=get_tree().get_first_node_in_group("board") as Board
	if board==null:
		return false
	var parent:Node=board.get_parent()
	if parent==null:
		parent=board
	_mine=MINE_SCENE.instantiate()
	parent.add_child(_mine)
	_mine.consumed.connect(_on_mine_consumed)
	return true

func _on_mine_consumed() -> void:
	_mine=null
