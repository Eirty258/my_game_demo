extends Egg

const SHUAI_WAVE_SCENE=preload("res://projectiles/shuai_wave.tscn")

#红帅：不参与发射，只作防线保险
#1. 破碎（双击打碎，或被献祭）时，在破碎处释放红色环形冲击波
#2. 边界被击破时，如果场上还有帅，由帅顶替这次失败

func _init() -> void:
	type="shuai"

func _ready() -> void:
	super._ready()

func _process(delta: float) -> void:
	pass

#帅不发射：board.rescan_groups 里已保证它不会成组
func shoot(chain_count:int):
	pass

#破碎时释放环形冲击波（由 board.remove_egg_broken 在节点销毁前调用）
func on_broken() -> void:
	var wave=SHUAI_WAVE_SCENE.instantiate()
	wave.global_position=global_position
	get_tree().root.add_child(wave)
