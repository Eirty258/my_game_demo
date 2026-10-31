extends Buff

const BURN_TINT := Color(1.0, 0.5, 0.3)

@export var burn_damage: float = 3.5

func _init() -> void:
	type = "burn"

func _ready() -> void:
	super._ready()
	setup()
	tint_burn()
	apply_damage(carrier)
	await get_tree().create_timer(duration).timeout
	if is_instance_valid(self):
		remove()

func setup() -> void:
	burn_damage = params.get("burn_damage", 3.5)
	duration = params.get("duration", 3.0)

func apply_damage(enemy: Enemy) -> void:
	if not is_instance_valid(enemy):
		return
	enemy.health -= burn_damage
	flash_red()
	$BurnDamageTimer.start()

func _on_burn_damage_timer_timeout() -> void:
	apply_damage(carrier)

func tint_burn() -> void:
	var sprite: AnimatedSprite2D = carrier.get_node_or_null("AnimatedSprite2D")
	if sprite == null:
		return

	var count: int = sprite.get_meta("burn_count", 0)
	if count == 0:
		sprite.set_meta("burn_original_modulate", sprite.modulate)

	count += 1
	sprite.set_meta("burn_count", count)
	sprite.modulate = sprite.get_meta("burn_original_modulate") * BURN_TINT

func untint_burn() -> void:
	var sprite: AnimatedSprite2D = carrier.get_node_or_null("AnimatedSprite2D")
	if sprite == null:
		return

	var count: int = sprite.get_meta("burn_count", 0)
	if count <= 0:
		return

	count -= 1
	sprite.set_meta("burn_count", count)

	if count == 0:
		sprite.modulate = sprite.get_meta("burn_original_modulate")

func flash_red(duration: float = 0.12) -> void:
	var sprite: AnimatedSprite2D = carrier.get_node_or_null("AnimatedSprite2D")
	if sprite == null or not is_instance_valid(sprite):
		return

	# 从共享状态读恢复色
	var count: int = sprite.get_meta("burn_count", 0)
	var restore_color: Color
	if count > 0:
		restore_color = sprite.get_meta("burn_original_modulate", Color.WHITE) * BURN_TINT
	else:
		restore_color = sprite.modulate

	# 防止连续闪红时 Tween 打架
	if sprite.has_meta("flash_tween"):
		var old = sprite.get_meta("flash_tween")
		if old and old.is_valid():
			old.kill()

	var tween = sprite.create_tween()
	sprite.set_meta("flash_tween", tween)
	tween.tween_property(sprite, "modulate", Color(1.0, 0.0, 0.0), duration * 0.5)
	tween.tween_property(sprite, "modulate", restore_color, duration * 0.5)

func remove() -> void:
	untint_burn()
	super.remove()
