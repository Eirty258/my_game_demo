extends Node2D

@export var active_buff:Array=[]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func add_buff(buff_name:String,params:Dictionary):
	var path="res://enemys/buff/%s.tscn"%buff_name
	var buff_scene:PackedScene=load(path)
	var buff=buff_scene.instantiate()
	buff.params=params
	if active_buff.has(buff.type)&&buff.type!="burn":
		remove_buff(buff.type)
	add_child(buff)
	active_buff.append(buff.type)

func remove_buff(type:String):
	var buff_nodes=get_tree().get_nodes_in_group("buff")
	for buff in buff_nodes:
		if buff.type==type:
			active_buff.erase(type)
			buff.remove()
#func add_burn(duration:float=3.0,burn_damage:float=3.5):
	#var path=buff_list["burn"]
	#var burn_scene:PackedScene=load(path)
	#var burn=burn_scene.instantiate()
	#burn.duration=duration
	#burn.burn_damage=burn_damage
#
#func add_chill(duration:float=3.0,time_scale:float=0.7):
	#var path=buff_list["chill"]
	#var chill_scene:PackedScene=load(path)
	#var chill=chill_scene.instantiate()
	#chill.duration=duration
	#chill.time_scale=time_scale
