extends Buff

@export var time_scale=0.7
var original_modulate: Color = Color.WHITE
var is_chill_tinted: bool = false
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super._ready()
	setup()
	
	tint_chill()
	apply_chill(carrier)
	await get_tree().create_timer(duration).timeout
	remove()


func _init() -> void:
	type="chill"

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func apply_chill(enemy:Enemy):
	enemy.apply_chill(time_scale)



func remove():
	untint_chill()
	carrier.remove_chill()
	super.remove()


func setup():
	time_scale=params["time_scale"]
	duration=params["duration"]

func tint_chill() -> void:
	var sprite: AnimatedSprite2D = carrier.get_node_or_null("AnimatedSprite2D")
	if sprite == null:
		return
	if not is_chill_tinted:
		original_modulate = sprite.modulate
		is_chill_tinted = true
	sprite.modulate = original_modulate * Color(0.3, 0.7, 1.0)

func untint_chill() -> void:
	var sprite: AnimatedSprite2D = carrier.get_node_or_null("AnimatedSprite2D")
	if sprite == null:
		return
	if is_chill_tinted:
		sprite.modulate = original_modulate
		is_chill_tinted = false
