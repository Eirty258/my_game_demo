extends Drop
class_name Chess

var is_holding:bool=false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func handle_click():
	pass

func hold():
	is_holding=true
	$AnimatedSprite2D.visible=false
	$Shadow.visible=false
	$CollisionShape2D.disabled=true
