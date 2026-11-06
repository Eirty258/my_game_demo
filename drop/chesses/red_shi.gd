extends Chess

#红方“仕”：拾取后给所有边界格套上 10 秒护盾
#护盾期间敌人照常索敌攻击，但边界不掉耐久

const SHIELD_DURATION:float=10.0

func handle_click():
	var board=get_tree().get_first_node_in_group("board")
	if board==null:
		push_error("red_shi: 找不到 board")
		return
	board.shield_all_edges(SHIELD_DURATION)
	VisualEffect.show_text_hint("仕：'护驾十秒'-所有边界获得护盾")
	queue_free()
