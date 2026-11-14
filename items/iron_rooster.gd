extends Item

#铁公鸡：加入一只跟班（每拾取一次多一只）

const FAMILIAR_SCENE:PackedScene=preload("res://familiar/iron_rooster.tscn")

func _ready() -> void:
	item_name="iron_rooster"
	var board:=get_tree().get_first_node_in_group("board") as Board
	if board==null:
		return
	var parent:Node=board.get_parent()
	if parent==null:
		parent=board
	var familiar=FAMILIAR_SCENE.instantiate()
	parent.add_child(familiar)
