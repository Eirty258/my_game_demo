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
	#requirements
	var icon_unit_scene:PackedScene=load("res://shop/icon_unit.tscn")
	var icon_unit_1=icon_unit_scene.instantiate()
	for i in requirements:
		icon_unit_1.set_icon_and_count(i["type"],i["amount"])
		icon_unit_1.size_flags_horizontal = Control.SIZE_EXPAND | Control.SIZE_FILL
		icon_unit_1.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hbox.add_child(icon_unit_1)
	#arrow
	var rect=TextureRect.new()
	rect.texture=load("res://arts/texture/order_arrow.png")
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.custom_minimum_size=Vector2(64,64)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	#rect.size_flags_horizontal = Control.SIZE_EXPAND | Control.SIZE_FILL
	hbox.add_child(rect)
	#rewards
	var icon_unit_2=icon_unit_scene.instantiate()
	for i in rewards:
		icon_unit_2.set_icon_and_count(i["item_name"],i["amount"])
		icon_unit_2.size_flags_horizontal = Control.SIZE_EXPAND | Control.SIZE_FILL
		icon_unit_2.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hbox.add_child(icon_unit_2)
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

func setup(dic:Dictionary):
	contents=dic

func set_deal_button():
	dealbutton.visible=true
