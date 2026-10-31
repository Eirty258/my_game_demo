extends VBoxContainer
class_name IconUnit

var icon_name:String="double_yolk_egg"
var count:int=0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$PanelContainer/Icon.texture=load("res://arts/texture/%s.png"%icon_name)
	$Count.text=str(count)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func set_icon_and_count(name:String,count_:int):
	icon_name=name
	count=count_
