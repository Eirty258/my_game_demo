extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	add_to_group("item_manager")
	SignalBus.to_get_item_by_name.connect(get_item_by_name)
	SignalBus.item_clicked.connect(get_item_by_name)
	#get_item_by_name("charge_bread")
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func get_item_by_id(item_id:int):
	print("通过id得到了道具:",item_id)

func get_item_by_name(item_name:String):
	var path="res://items/%s.tscn"%item_name
	if not ResourceLoader.exists(path):
		print("item_manager.get_item_by_name:道具名不存在")
		return
	var item_scene:PackedScene=load(path)
	var item=item_scene.instantiate()
	add_child(item)
	print("通过道具名得到了道具:",item_name)
