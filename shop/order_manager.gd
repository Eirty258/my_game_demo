extends Control



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	SignalBus.drop_order_picked.connect(spawn_order)
	SignalBus.orders_button_clicked.connect(open_orders_page)
	$OrdersPage.visible=false


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func pick_by_weight(weights: Dictionary) -> String:
	var total = 0.0
	for key in weights:
		total += weights[key]
	var roll = randf() * total
	var acc = 0.0
	for key in weights:
		acc += weights[key]
		if roll < acc:
			return key
	print("道具池过空，保底")
	return weights.keys()[0]   # 兜底

func setup_random()->Dictionary:
	var dic={}
	#需求：
	var requirement=[{"type":"egg_shard","amount":50}]
	dic["requirements"]=requirement
	#TODO 抽道具可以独立出去
	var item=pick_by_weight(WeightTable.order_item_pool)
	WeightTable.order_item_pool[item]=0
	
	var reward=[{"type":"item","amount":1,"item_name":item}]
	dic["rewards"]=reward
	return dic

func spawn_order(pos:Vector2):
	var order_scene:PackedScene=load("res://shop/order.tscn")
	var order=order_scene.instantiate()
	order.setup(setup_random())
	order.global_position=pos
	add_child(order)
	float_up_and_fade(order)

func float_up_and_fade(ui_node: Control, distance: float = 50.0, duration: float = 2.0) -> void:
	var start_pos = ui_node.position
	var tween = create_tween()
	tween.set_parallel(true)

	tween.tween_property(ui_node, "position", start_pos + Vector2(0, -distance), duration)\
		.set_trans(Tween.TRANS_QUAD)\
		.set_ease(Tween.EASE_OUT)

	tween.tween_property(ui_node, "modulate:a", 0.0, duration)\
		.set_trans(Tween.TRANS_QUAD)\
		.set_ease(Tween.EASE_IN)

	tween.chain().tween_callback(func():
		if is_instance_valid(ui_node):
			#ui_node.visible=false
			ui_node.reparent($OrdersPage/PanelContainer/ScrollContainer/VBoxContainer)
			ui_node.modulate.a=100
			ui_node.set_deal_button()
	)

func open_orders_page():
	popup_page($OrdersPage)
	SignalBus.paused.emit()

func close_orders_page():
	close_page($OrdersPage)
	SignalBus.resumed.emit()


func _on_close_button_button_down() -> void:
	close_orders_page()

func popup_page(page: Control, duration: float = 0.3) -> void:
	page.visible = true
	page.modulate.a = 0.0
	page.scale = Vector2(0.8, 0.8)
	page.pivot_offset = page.size / 2.0

	var tween = create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)

	tween.tween_property(page, "scale", Vector2.ONE, duration)
	tween.tween_property(page, "modulate:a", 1.0, duration)

func close_page(page: Control, duration: float = 0.3) -> void:
	if not is_instance_valid(page):
		return

	page.pivot_offset = page.size / 2.0

	var tween = create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_IN)

	tween.tween_property(page, "scale", Vector2(0.8, 0.8), duration)
	tween.tween_property(page, "modulate:a", 0.0, duration)

	await tween.finished

	if is_instance_valid(page):
		page.visible = false
