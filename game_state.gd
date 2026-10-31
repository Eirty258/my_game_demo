extends Node

@export var egg_shards:int=0:
	set(value):
		egg_shards=max(0,value)
		SignalBus.egg_shards_updated.emit(egg_shards)
@export var energy_mode="energy"
@export var energy:float=0:
	set(value):
		if energy_mode=="energy":
			if energy<50&&value>=50:
				print(energy)
				SignalBus.dove_spawned.emit()
		energy=clamp(value,0,100)
		SignalBus.energy_updated.emit(energy)
		if energy==100&&energy_mode=="energy":
			energy_mode="boss"
			SignalBus.energy_full.emit()
			print(energy_mode)

var min_chain:int=3
var is_boss_cleared:bool=false
var is_floor_cleared:bool=false
var floor:int=0:
	set(value):
		floor=min(value,1)
var tutorial_step:int=0:
	set(value):
		if tutorial_step!=value:
			tutorial_step=value
		if value==-1:
			SignalBus.tutorial_finished.emit()
var tutorial_count=0
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#SignalBus.tutorial_enemy_died.connect(tutorial)
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func modify_egg_shards(value:int)->bool:
	if egg_shards+value<0:
		return false
	egg_shards+=value
	return true

func modify_energy(value:float)->bool:
	if energy_mode=="boss":
		return false
	if energy+value<0:
		return false
	energy+=value
	return true

func init():
	energy_mode="energy"
	energy=0
	is_boss_cleared=false
	is_floor_cleared=false

func restart():
	egg_shards=0
	energy_mode="energy"
	energy=0
	min_chain=3
	is_boss_cleared=false
	is_floor_cleared=false
	floor=0
