extends "res://drop/targeted_drop.gd"

#红马：临时拿起后点边界格，把那面墙的耐久回满
#（原来"相"的效果搬到这里，相改成了棋盘上的万用蛋）
#点非边界格或右键则原地放下（不消耗）

func is_valid_target(cell:Cell) -> bool:
	return cell!=null&&cell.is_edge

func apply_target(cell:Cell) -> void:
	cell.durability=cell.max_durability
	VisualEffect.show_text_hint("马：高贵的马儿能够驱除一切外力")
	queue_free()
