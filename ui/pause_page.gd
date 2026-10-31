extends Control

var item_bar_scene:PackedScene=preload("res://ui/item_bar.tscn")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	hide_page()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func update_items():
	for i in $ItemBar/ScrollContainer/GridContainer.get_children():
		i.queue_free()
	var items=get_tree().get_first_node_in_group("item_manager").get_children()
	for i in items:
		var item=item_bar_scene.instantiate()
		item.item_name=i.item_name
		$ItemBar/ScrollContainer/GridContainer.add_child(item)

#func show_page():
	#visible=true
	#update_items()
	#SignalBus.paused.emit()
#func hide_page():
	#visible=false
	#SignalBus.resumed.emit()
var _fade_tween: Tween = null
func hide_page_instant() -> void:
	visible = false
	modulate.a = 0.0
func show_page() -> void:
	if _fade_tween and _fade_tween.is_valid():
		_fade_tween.kill()
	visible = true
	modulate.a = 0.0
	update_items()
	_fade_tween = create_tween()
	_fade_tween.set_trans(Tween.TRANS_QUAD)
	_fade_tween.set_ease(Tween.EASE_OUT)
	_fade_tween.tween_property(self, "modulate:a", 1.0, 0.25)
	SignalBus.paused.emit()
func hide_page() -> void:
	if _fade_tween and _fade_tween.is_valid():
		_fade_tween.kill()
	SignalBus.resumed.emit()
	_fade_tween = create_tween()
	_fade_tween.set_trans(Tween.TRANS_QUAD)
	_fade_tween.set_ease(Tween.EASE_IN)
	_fade_tween.tween_property(self, "modulate:a", 0.0, 0.2)
	_fade_tween.tween_callback(func():
		if is_instance_valid(self):
			visible = false
	)
func _on_continue_button_pressed() -> void:
	hide_page()
