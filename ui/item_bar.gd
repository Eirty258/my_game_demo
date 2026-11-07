extends Control

const TooltipStyle=preload("res://ui/tooltip_style.gd")

var item_name:String="charcoal"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	setup()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func setup():
	$TextureRect.texture=ItemData.get_icon_texture(item_name)
	$TextureRect.tooltip_text=ItemData.get_tooltip(item_name)
	TooltipStyle.apply($TextureRect)
