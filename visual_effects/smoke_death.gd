extends AnimatedSprite2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	play("default")
	# 0.33 秒内逐渐透明
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.33)
	await tween.finished
	queue_free()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
