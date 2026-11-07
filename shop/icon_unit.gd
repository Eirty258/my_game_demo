extends VBoxContainer
class_name IconUnit

const TooltipStyle=preload("res://ui/tooltip_style.gd")

var icon_name:String="double_yolk_egg"
var count:int=0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var icon:TextureRect=$PanelContainer/Icon
	icon.texture=ItemData.get_icon_texture(icon_name)
	$Count.text=str(count)
	#是道具就带悬浮说明（需求里的蛋片之类没有）
	var tip:=ItemData.get_tooltip(icon_name)
	if tip!="":
		icon.tooltip_text=tip
		TooltipStyle.apply(icon)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func set_icon_and_count(name:String,count_:int):
	icon_name=name
	count=count_
