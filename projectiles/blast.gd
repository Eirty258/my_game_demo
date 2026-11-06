extends RefCounted

#通用爆炸：范围内所有敌人各吃一次伤害，并播放一个扩散的圆环
#给“摩托车”这类需要触发炮式爆炸的弹射物复用


static func explode(tree:SceneTree,center:Vector2,damage:float,radius:float,knock_force:float,attack_type:String,color:Color=Color(1.0,0.35,0.15)) -> void:
	if tree==null:
		return
	for enemy in get_enemies(tree,center,radius):
		var push:Vector2=enemy.global_position-center
		if push==Vector2.ZERO:
			push=Vector2.DOWN
		enemy.take_hit(damage,push.normalized()*knock_force,attack_type)
	spawn_ring(tree,center,radius,color)


static func get_enemies(tree:SceneTree,center:Vector2,radius:float) -> Array:
	var result:=[]
	_collect(tree.root,center,radius,result)
	return result


static func _collect(node:Node,center:Vector2,radius:float,result:Array) -> void:
	if node is Enemy:
		if is_instance_valid(node) and not node.is_dying and center.distance_to(node.global_position)<=radius:
			result.append(node)
	for child in node.get_children():
		_collect(child,center,radius,result)


static func spawn_ring(tree:SceneTree,center:Vector2,radius:float,color:Color) -> void:
	var ring:=Line2D.new()
	ring.width=36.0
	ring.default_color=color
	ring.antialiased=true
	var points:=PackedVector2Array()
	for i in range(49):
		var angle:=TAU*float(i)/48.0
		points.append(center+Vector2(cos(angle),sin(angle))*radius)
	ring.points=points
	tree.root.add_child(ring)
	var tween:=ring.create_tween()
	tween.set_parallel(true)
	tween.tween_property(ring,"modulate:a",0.0,0.3)
	tween.tween_property(ring,"scale",Vector2(1.2,1.2),0.3)
	tween.chain().tween_callback(ring.queue_free)
