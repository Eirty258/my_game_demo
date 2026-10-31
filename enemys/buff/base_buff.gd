extends Node
class_name Buff

var type="null"
@export var duration:float=3.0
@export var carrier:Node=null
@export var params:Dictionary={}
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	carrier=get_parent().get_parent()
	add_to_group("buff")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func setup():
	pass

func remove():
	get_parent().active_buff.erase(type)
	queue_free()
