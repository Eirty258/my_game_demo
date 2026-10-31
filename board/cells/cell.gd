extends Node
class_name Cell


var is_edge:bool=false
var is_collidable:bool=false
var is_available:bool=true
var direction:Vector2=Vector2.ZERO
var is_exist_egg:bool=false
#新加的变量
var max_durability:float=100
var durability:float=100:
	set(value):
		if durability==value:
			return
		durability=clamp(value,0,max_durability)
		_on_durability_changed()
var coord:Vector2i=Vector2i.ZERO
var board:Board#TODO 循环引用了?
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func output():
	print("is_edge:",is_edge)
	print("is_collidable:",is_collidable)
	print("is_available:",is_available)
	print("direction:",direction)

func edge():
	is_edge=true
	is_collidable=true

func take_hit(damage:float):
	durability-=damage
	board.turn_red_tile(coord)
	

func _on_durability_changed():
	if durability/(max_durability)>=1:
		board.turn_tile(coord,0)
	elif durability/(max_durability)<1&&durability/(max_durability)>0.6:
		board.turn_tile(coord,1)
	elif durability/(max_durability)<=0.6&&durability/(max_durability)>0.3:
		board.turn_tile(coord,2)
	elif durability/(max_durability)<=0.3&&durability/(max_durability)>0:
		board.turn_tile(coord,3)
	if durability<=0:
		SignalBus.edge_destroyed.emit(self)
