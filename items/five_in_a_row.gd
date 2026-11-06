extends Item

#五子棋必胜阵法：一次正好 5 颗蛋一起发射时，这一次发射的伤害 ×1.5
#接 projectile_spawned（每颗子弹真正进树时触发），所以高铁这种一次发一串的也能整串吃到

const REQUIRED_CHAIN:=5
const DAMAGE_MULTIPLY:=1.5

func _ready() -> void:
	item_name="five_in_a_row"
	SignalBus.projectile_spawned.connect(on_projectile_spawned)

func on_projectile_spawned(projectile:Projectile) -> void:
	if projectile.chain_count!=REQUIRED_CHAIN:
		return
	projectile.damage_mul*=DAMAGE_MULTIPLY
