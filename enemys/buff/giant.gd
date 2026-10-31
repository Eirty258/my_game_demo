extends Buff

@export var size:float=2
var original_close_attack_damage
var original_scale
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super._ready()
	setup()
	apply_giant()


func _init() -> void:
	type="giant"


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func setup():
	size=params["size"]

func apply_giant():
	carrier.health*=size
	original_close_attack_damage=carrier.close_attack_damage
	carrier.close_attack_damage*=size
	original_scale=carrier.scale
	#carrier.scale*=size
	var tween=carrier.create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(carrier,"scale",original_scale*size,1)

func remove():
	carrier.health/=size
	carrier.close_attack_damage=original_close_attack_damage
	#carrier.scale=original_scale
	var tween=carrier.create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(carrier,"scale",original_scale,1)
