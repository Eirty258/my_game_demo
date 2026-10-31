extends Area2D
class_name Projectile

@export var speed:float=4096
@export var direction:Vector2=Vector2.ZERO
@export var type:String="null"
@export var final_damage_scale:float=1.0:
	set(value):
		final_damage_scale=value
		update_scale()
@export var scale_factor:float=1.0:
	set(value):
		scale_factor=value
		update_scale()
@export var base_damage_for_scale: float = 3.5
@export var damage_add:float=0:
	set(value):
		damage_add=value
		update_scale()
@export var damage_extra:float=0:
	set(value):
		damage_extra
		update_scale()
@export var damage_mul:float=1:
	set(value):
		damage_mul=value
		update_scale()
@export var damage:float=3.5:
	set(value):
		damage=value
		update_scale()
var final_damage:float:
	#set(value):
		#final_damage=value
		#final_damage_scale=1.0+log(final_damage/3.5)
	get:
		return damage_mul *( damage * sqrt(1.0 + 1.2 * damage_add)+damage_extra)
@export var knocked_back:Vector2=Vector2.ZERO
@export var has_hit:bool=false#防重复标记
@export var pierce_flag:bool=false
var hit_targets: Dictionary = {}
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$AnimatedSprite2D.play("default")
	if direction==Vector2.DOWN:
		$AnimatedSprite2D.rotation=Vector2.DOWN.angle()
	if direction==Vector2.LEFT:
		$AnimatedSprite2D.rotation=Vector2.LEFT.angle()
	if direction==Vector2.UP:
		$AnimatedSprite2D.rotation=Vector2.UP.angle()
	SignalBus.projectile_spawned.emit(self)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	position+=speed*direction*delta


func _on_area_entered(area: Area2D) -> void:
	if has_hit&&!pierce_flag:#防止同一帧击中多个敌人
		return
	var body=area.get_parent()
	if body is Enemy:
		if hit_targets.has(body):
			return
		hit_targets[body]=true
		has_hit=true
		body.take_hit(final_damage,knocked_back,type)
		if pierce_flag:
			return
		queue_free()

#func update_scale():
	#scale=Vector2(1,1)*final_damage_scale*scale_factor
	#print("scale:",scale)

func update_scale() -> void:
	var ratio = final_damage / base_damage_for_scale
	var s = 1.0 + log(ratio)
	#s = clampf(s, 0.6, 2.0)
	scale = Vector2(s, s) * scale_factor

func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	#if GameState.tutorial_step==0||GameState.tutorial_step==1:
		#SignalBus.projectile_disappeard.emit()
	queue_free()
