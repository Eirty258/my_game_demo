extends Sprite2D

func _ready() -> void:
	flicker(2.5)

func flicker(duration: float = 3.0) -> void:
	var elapsed: float = 0.0
	var interval: float = 0.3
	var min_interval: float = 0.03

	while elapsed < duration:
		visible = not visible
		await get_tree().create_timer(interval).timeout
		elapsed += interval
		# 间隔逐渐缩短，越来越快
		interval = maxf(interval * 0.85, min_interval)

	visible = true
	queue_free()
