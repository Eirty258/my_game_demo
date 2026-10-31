extends Node

var board_weights_tables=[
	#一层
	[
		{
			"board_2":1,
			"board_3":1,
		}
	],
	#二层
	[
		{
			"board_1":1,
			"board_4":1,
			"board_5":1,
		}
	],
]

var enemy_weights_tables=[
	#一层
	[
		{
			"flamaleon":1,
			"green_snake":3,
		}
	],
	#二层
	[
		{
			"flamaleon":1,
			"green_snake":3,
		}
	]
]

var boss_weights_tables=[
	#一层
	{
		"black_mole":1
	},
	#二层
	{
		"black_mole":1
	},
]
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
