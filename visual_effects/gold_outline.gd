extends RefCounted

#给 CanvasItem（敌人/蛋的 AnimatedSprite2D）套"镀金描边"材质的工具
#只加材质，不改原节点；摘下来时把原来的 material 还回去

const SHADER=preload("res://visual_effects/gold_outline.gdshader")

static func make_material(outline_px:float=6.0,glow_px:float=14.0) -> ShaderMaterial:
	var mat:=ShaderMaterial.new()
	mat.shader=SHADER
	mat.set_shader_parameter("outline_px",outline_px)
	mat.set_shader_parameter("glow_px",glow_px)
	return mat

static func apply(sprite:CanvasItem,outline_px:float=6.0,glow_px:float=14.0) -> ShaderMaterial:
	if sprite==null:
		return null
	var mat:=make_material(outline_px,glow_px)
	sprite.material=mat
	return mat
