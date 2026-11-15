extends Egg

#红仕：不参与发射，只在被击碎（双击打碎 / 献祭）时给所有边界套护盾

const SHIELD_DURATION:=10.0

func _init() -> void:
	type="shi"

func _ready() -> void:
	super._ready()

func _process(delta: float) -> void:
	pass

#仕不发射：board.rescan_groups 里已保证它不会成组
func shoot(chain_count:int):
	pass

#破碎时给所有边界套盾（由 board.remove_egg_broken 在节点销毁前调用）
func on_broken() -> void:
	var board=get_parent()
	if board!=null&&board.has_method("shield_all_edges"):
		board.shield_all_edges(SHIELD_DURATION)
	#VisualEffect.show_text_hint("仕：'护驾十秒'-所有边界获得护盾")
