extends Enemy





func _ready() -> void:
	add_to_group("enemy")#这个子类没有调用 super._ready()，分组自己补
	speed=0
	close_attack_damage=0
	health=1
	$AnimatedSprite2D.play("idle")
	drop_table={
		"null":1
	}
	pass

func _physics_process(delta: float) -> void:
	pass



func remove():
	get_parent().total_enemy_number_reduce()
	get_parent().remove_enemy(self)
