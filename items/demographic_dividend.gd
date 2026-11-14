extends Item

#人口红利：发射时按"发射前的蛋数 / 上限"给这一发伤害倍率
#蛋数 ≤ 上限的 30% 时 1 倍；满上限时 2 倍；中间线性过渡
#统计的是发射前的蛋数（eggs_firing 在 shoots 之前发出），所以一次把满上限的蛋全打出去能吃满

const LOW_RATIO:=0.3
const MAX_DAMAGE_MUL:=2.0

func _ready() -> void:
	item_name="demographic_dividend"
	SignalBus.eggs_firing.connect(_on_eggs_firing)

func _on_eggs_firing(eggs:Array,_chain_count:int) -> void:
	var board:=get_tree().get_first_node_in_group("board") as Board
	if board==null or board.max_egg_number<=0:
		return
	var ratio:=float(board.egg_number)/float(board.max_egg_number)
	var t:=clampf((ratio-LOW_RATIO)/(1.0-LOW_RATIO),0.0,1.0)
	var damage_mul:=1.0+t*(MAX_DAMAGE_MUL-1.0)
	for node in eggs:
		if is_instance_valid(node):
			var egg:=node as Egg
			if egg!=null:
				egg.shot_damage_mul=damage_mul
