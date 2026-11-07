extends Control
class_name Order
#订单数据格式
#{
	#"requirements":[{"type":"egg_shard","amount":3}],
#}
@export var contents:Dictionary={
	"requirements":[{"type":"egg_shard","amount":3}],
	"rewards":[{"type":"item","amount":1,"item_name":"conehead"}]
}

var dealbutton
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$PanelContainer.visible=false
	appear()
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func deal():
	var to_deliver=contents["requirements"]
	if !deliver(to_deliver):
		print("钱不够")
		return
	var to_recive=contents["rewards"]
	recive(to_recive)
	queue_free()

func deliver(to_deliver:Array)->bool:
	for i in to_deliver:
		if i["type"]=="egg_shard":
			return GameState.modify_egg_shards(-i["amount"])
	return true

func recive(to_recive:Array):
	for i in to_recive:
		if i["type"]=="item":
			for j in range(i["amount"]):
				SignalBus.item_dealt.emit(i["item_name"])

func appear():
	$PanelContainer.visible=true
	var hbox=$PanelContainer/HBoxContainer
	var requirements=contents["requirements"]
	var rewards=contents["rewards"]
	var icon_unit_scene:PackedScene=load("res://shop/icon_unit.tscn")
	#requirements
	for i in requirements:
		hbox.add_child(_make_icon_unit(icon_unit_scene,i["type"],i["amount"]))
	#arrow
	var rect=TextureRect.new()
	rect.texture=load("res://arts/texture/order_arrow.png")
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.custom_minimum_size=Vector2(64,64)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	#rect.size_flags_horizontal = Control.SIZE_EXPAND | Control.SIZE_FILL
	hbox.add_child(rect)
	#rewards
	for i in rewards:
		hbox.add_child(_make_icon_unit(icon_unit_scene,i.get("item_name",i["type"]),i["amount"]))
	#deal
	var deal_button=TextureButton.new()
	deal_button.texture_normal=load("res://arts/texture/deal_button.png")
	deal_button.ignore_texture_size=true
	deal_button.stretch_mode=TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	deal_button.custom_minimum_size=Vector2(64,64)
	#deal_button.size=Vector2(64,64)
	deal_button.visible=false
	dealbutton=deal_button
	deal_button.button_down.connect(deal)
	hbox.add_child(deal_button)

#每个条目单独一个图标单元（原来在循环里复用同一个实例，多个条目会互相覆盖）
func _make_icon_unit(icon_unit_scene:PackedScene,icon_name:String,amount:int) -> IconUnit:
	var unit:IconUnit=icon_unit_scene.instantiate()
	unit.set_icon_and_count(icon_name,amount)
	unit.size_flags_horizontal = Control.SIZE_EXPAND | Control.SIZE_FILL
	unit.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return unit

func setup(dic:Dictionary):
	contents=dic

func set_deal_button():
	dealbutton.visible=true
