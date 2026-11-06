extends Node2D

var void_egg_scene:PackedScene=preload("res://drop/void_egg.tscn")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#SignalBus.egg_droped.connect(spawn_drop_egg)
	add_to_group("drop_manager")
	SignalBus.something_droped.connect(spawn_drop)
	SignalBus.item_droped.connect(spawn_item)
	SignalBus.item_dealt.connect(spawn_and_get)
	SignalBus.void_egg_droped.connect(spawn_void_egg)
	#spawn_void_egg(Vector2(0,0))
	#spawn_item(Vector2(0,0),"double_yolk_egg")
	#for i in range(15):
		#spawn_item(Vector2(0,0),"double_yolk_egg")
	spawn_drop_specific_chess(Vector2(0,0),"red_pao")
	spawn_drop_specific_chess(Vector2(0,0),"red_shuai")
	spawn_drop_specific_chess(Vector2(0,0),"red_xiang")
	spawn_drop_specific_chess(Vector2(0,0),"red_shi")
	spawn_drop_specific_chess(Vector2(0,0),"red_ju")



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func spawn_drop(pos:Vector2,drop_name:String):
	if drop_name=="egg":
		spawn_drop_egg(pos)
	elif drop_name=="order":
		spawn_drop_order(pos)
	elif drop_name=="chess":
		spawn_drop_random_chess(pos)
	elif drop_name=="red_bing"||drop_name=="red_pao"||drop_name=="red_shuai"||drop_name=="red_xiang"||drop_name=="red_shi"||drop_name=="red_ju":
		spawn_drop_specific_chess(pos,drop_name)

#随机掉一颗棋子：种类从 WeightTable.chess_pieces 里按权重抽
func spawn_drop_random_chess(pos:Vector2):
	var chess_type:String=WeightTable.pick_by_weight(WeightTable.chess_pieces)
	spawn_drop_specific_chess(pos,chess_type)

func spawn_drop_egg(pos:Vector2,type:String="null"):
	var drop_egg_scene:PackedScene=load("res://drop/drop_egg.tscn")
	var drop_egg=drop_egg_scene.instantiate()
	drop_egg.type=type
	drop_egg.global_position=pos+Vector2(randf_range(-256,256),randf_range(-256,256))
	add_child(drop_egg)

func spawn_drop_order(pos:Vector2)->Drop:
	var drop_order_scene:PackedScene=load("res://drop/drop_order.tscn")
	var drop_order=drop_order_scene.instantiate()
	drop_order.global_position=pos+Vector2(randf_range(-256,256),randf_range(-256,256))
	add_child(drop_order)
	return drop_order

func spawn_drop_specific_chess(pos:Vector2,type:String="null"):
	var path="res://drop/chesses/%s.tscn"%type
	if not ResourceLoader.exists(path):
		push_warning("drop_manager：没有这颗棋子的掉落物 %s" % type)
		return
	var drop_chess=load(path).instantiate()
	drop_chess.global_position=pos+Vector2(randf_range(-256,256),randf_range(-256,256))
	add_child(drop_chess)

func spawn_item(pos:Vector2,item_name:String)->Drop:
	var item_scene:PackedScene=load("res://drop/item.tscn")
	var item=item_scene.instantiate()
	item.global_position=pos
	item.item_name=item_name
	add_child(item)
	return item
func spawn_and_get(item_name:String):
	var item=spawn_item(screen_to_world(Vector2(512,100)),item_name)
	item.handle_click()


func screen_to_world(screen_pos: Vector2) -> Vector2:
	var canvas_transform = get_viewport().get_canvas_transform()
	return canvas_transform.affine_inverse() * screen_pos

func spawn_void_egg(pos:Vector2):
	var void_egg=void_egg_scene.instantiate()
	void_egg.global_position=Vector2(0,0)
	add_child(void_egg)

func init():
	var drops=get_children()
	for drop in drops:
		drop.queue_free()
