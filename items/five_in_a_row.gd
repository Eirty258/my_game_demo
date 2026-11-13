extends Item

#五子棋必胜阵法：
#· 一次发射连锁数正好 = 5 → 这一批子弹伤害 ×1.5（原效果）
#· 场上存在"正好 5 颗同种蛋"的连通组 → 这 5 颗蛋贴图外轮廓镀金边；
#  蛋被发射 / 打碎 / 被拆成不是 5 个时自动消失

const REQUIRED_CHAIN:=5
const DAMAGE_MULTIPLY:=1.5

#蛋 instance_id -> Egg（金边由 Egg 自己维护，和"可发射金边"共用材质）
var _outlined:Dictionary={}

func _ready() -> void:
	item_name="five_in_a_row"
	SignalBus.projectile_spawned.connect(on_projectile_spawned)
	SignalBus.eggs_regrouped.connect(_refresh_outlines)
	SignalBus.eggs_fired.connect(_on_eggs_fired)
	SignalBus.egg_broken.connect(_refresh_outlines)
	_refresh_outlines()

func on_projectile_spawned(projectile:Projectile) -> void:
	if projectile.chain_count!=REQUIRED_CHAIN:
		return
	projectile.damage_mul*=DAMAGE_MULTIPLY

#——镀金提示：只给"正好 5 颗同种蛋连通"的组上金边 ——
func _refresh_outlines() -> void:
	var board=get_tree().get_first_node_in_group("board")
	if board==null:
		return
	var wanted:Dictionary={}
	for egg in _collect_five_groups(board):
		wanted[egg.get_instance_id()]=egg

	#摘掉不再满足的（拆开、数量变了、蛋已经没了）
	var stale=[]
	for id in _outlined:
		var egg:Egg=_outlined[id]
		if not wanted.has(id) or not is_instance_valid(egg):
			stale.append(id)
	for id in stale:
		_clear_outline(id)

	#给新凑齐的蛋套上
	for id in wanted:
		if _outlined.has(id):
			continue
		_apply_outline(wanted[id])

#把场上所有蛋按"同种 + 四连通"分块，返回大小正好 REQUIRED_CHAIN 的组的全部蛋
func _collect_five_groups(board:Board) -> Array:
	var result:=[]
	var visited:Dictionary={}
	for coord in board.egg_nodes.keys():
		if visited.has(coord):
			continue
		var first:Egg=board.egg_nodes.get(coord)
		if first==null or first.disabled:
			continue
		var stack:=[coord]
		visited[coord]=true
		var members:=[]
		while not stack.is_empty():
			var current:Vector2i=stack.pop_back()
			var current_egg:Egg=board.egg_nodes.get(current)
			if current_egg==null or current_egg.disabled:
				continue
			members.append(current_egg)
			for offset in [Vector2i.RIGHT,Vector2i.UP,Vector2i.LEFT,Vector2i.DOWN]:
				var next:Vector2i=current+offset
				if visited.has(next):
					continue
				var next_egg:Egg=board.egg_nodes.get(next)
				if next_egg==null or next_egg.disabled:
					continue
				if next_egg.type!=first.type:
					continue
				visited[next]=true
				stack.append(next)
		if members.size()==REQUIRED_CHAIN:
			result.append_array(members)
	return result

func _apply_outline(egg:Egg) -> void:
	egg.set_five_outline(true)
	_outlined[egg.get_instance_id()]=egg

func _clear_outline(id:int) -> void:
	var egg:Egg=_outlined.get(id)
	_outlined.erase(id)
	if is_instance_valid(egg):
		egg.set_five_outline(false)

#发射：金边立刻消失（蛋也要飞走了）
func _on_eggs_fired(eggs:Array,_chain_count:int) -> void:
	for egg in eggs:
		if is_instance_valid(egg):
			_clear_outline(egg.get_instance_id())
