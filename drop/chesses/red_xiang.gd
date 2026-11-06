extends "res://drop/targeted_drop.gd"

#红相：临时拿起后点边界格，把那面墙的耐久回满
#点非边界格或右键则原地放下（不消耗）

func is_valid_target(cell:Cell) -> bool:
	return cell!=null&&cell.is_edge

func apply_target(cell:Cell) -> void:
	cell.durability=cell.max_durability
	VisualEffect.show_text_hint("相：'固若金汤'-边界耐久回满")
	queue_free()
