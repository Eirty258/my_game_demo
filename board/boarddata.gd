extends Resource
class_name BoardData

@export var size:Vector2i=Vector2i(8,8)
@export var grid:Array[CellData]=[]
@export var enemy_spawn_point_left:Array[int]=[]
@export var enemy_spawn_point_right:Array[int]=[]
@export var enemy_spawn_point_up:Array[int]=[]
@export var enemy_spawn_point_down:Array[int]=[]
