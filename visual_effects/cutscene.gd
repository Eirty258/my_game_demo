extends CanvasLayer


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func iris_out(duration: float = 2.0) -> void:
	var mat = $ColorRect.material as ShaderMaterial
	var tween = create_tween()
	tween.tween_method(
		func(v): mat.set_shader_parameter("progress", v),
		1.0, -0.1, duration
	)
	await tween.finished

func iris_in(duration: float = 2.0) -> void:
	var mat = $ColorRect.material as ShaderMaterial
	var tween = create_tween()
	tween.tween_method(
		func(v): mat.set_shader_parameter("progress", v),
		-0.1, 1.0, duration
	)
	await tween.finished
