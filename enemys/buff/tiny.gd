extends Buff

@export var size:float=0.7
var original_scale
var original_speed
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super._ready()
	setup()
	apply_chill()


func _init() -> void:
	type="tiny"


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func setup():
	size=params["size"]

func apply_chill():
	carrier.health*=size
	original_scale=carrier.scale
	#carrier.scale*=size
	carrier.apply_chill(1/size)
	var tween=carrier.create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(carrier,"scale",original_scale*size,1)

func remove():
	carrier.health/=size
	#carrier.scale=original_scale
	carrier.remove_chill()
	var tween=carrier.create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(carrier,"scale",original_scale,1)
