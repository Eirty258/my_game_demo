extends Item

#五子棋必胜阵法：一次正好 5 颗蛋一起发射时，这一次发射的伤害 ×1.5
#接 projectile_spawned（每颗子弹真正进树时触发），所以高铁这种一次发一串的也能整串吃到
#另外接 eggs_fired：真的凑够 5 颗一起发射时，给这 5 个蛋所在的格子镀一圈金边（纯表现）

const REQUIRED_CHAIN:=5
const DAMAGE_MULTIPLY:=1.5
const GOLD_GLOW=preload("res://visual_effects/gold_glow_edge.gd")
const GOLD_GLOW_DURATION:=2.0#五连发射时金边亮多久

func _ready() -> void:
	item_name="five_in_a_row"
	SignalBus.projectile_spawned.connect(on_projectile_spawned)
	SignalBus.eggs_fired.connect(_on_eggs_fired)

func on_projectile_spawned(projectile:Projectile) -> void:
	if projectile.chain_count!=REQUIRED_CHAIN:
		return
	projectile.damage_mul*=DAMAGE_MULTIPLY

#五连达成：五个蛋都镀上金边（蛋马上就要飞走，所以金边落在它们原来的格子上）
func _on_eggs_fired(eggs:Array,chain_count:int) -> void:
	if chain_count!=REQUIRED_CHAIN:
		return
	var board=get_tree().get_first_node_in_group("board")
	if board==null:
		return
	for egg in eggs:
		if not is_instance_valid(egg):
			continue
		var fx=GOLD_GLOW.new()
		fx.position=Vector2(egg.coordinate)*512.0+Vector2(256,256)
		fx.setup(GOLD_GLOW_DURATION,512.0)
		board.add_child(fx)
