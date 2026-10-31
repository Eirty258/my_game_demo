extends Control

var item_name:String="charcoal"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	setup()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func setup():
	$TextureRect.texture=load("res://arts/texture/%s.png"%item_name)
	var name=ItemData.item_chinese_name[item_name]
	var description=ItemData.item_description[item_name]
	$TextureRect.tooltip_text="%s：%s" % [name, description]
	
	var theme = Theme.new()

	# 字体颜色
	theme.set_color("font_color", "TooltipLabel", Color.WHITE)

	# 字体大小
	theme.set_font_size("font_size", "TooltipLabel", 32)

	# 背景 StyleBox
	var stylebox = StyleBoxFlat.new()
	stylebox.bg_color = Color(0.1, 0.1, 0.1, 0.95)
	stylebox.border_width_left = 2
	stylebox.border_width_top = 2
	stylebox.border_width_right = 2
	stylebox.border_width_bottom = 2
	stylebox.border_color = Color(0.8, 0.8, 0.8)
	stylebox.corner_radius_top_left = 4
	stylebox.corner_radius_top_right = 4
	stylebox.corner_radius_bottom_left = 4
	stylebox.corner_radius_bottom_right = 4
	stylebox.content_margin_left = 8
	stylebox.content_margin_top = 4
	stylebox.content_margin_right = 8
	stylebox.content_margin_bottom = 4
	theme.set_stylebox("panel", "TooltipPanel", stylebox)
	$TextureRect.theme = theme
