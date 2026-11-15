extends Sprite2D

#关卡背景
#挂在 Camera2D 下面，所以它和世界一起平移、一起缩放：镜头拉近/拉远时背景跟着放大缩小，
#而不是像以前放在 CanvasLayer 里那样，永远是屏幕上不动的一张图。
#
#贴图本身是 1920x1080 的"地面"，按参考缩放（默认 0.15，正好是游戏里的镜头缩放）铺满画面来定世界尺寸：
#	世界尺寸 = 设计分辨率 / 参考缩放
#这样默认缩放下和以前一模一样铺满屏幕，镜头拉近到 0.3 时背景跟着放大一倍，拉远也不会露边。
#用设计分辨率而不是窗口尺寸：stretch 是 canvas_items + keep，画面永远是 1920x1080 那一块。

@export var reference_zoom:float=0.15

func _ready() -> void:
	_fit_to_screen()

#换背景（每层背景不同）：换完按新贴图重新对齐尺寸
func set_texture_path(path:String) -> void:
	var tex:=load(path) as Texture2D
	if tex==null:
		return
	texture=tex
	_fit_to_screen()

func _fit_to_screen() -> void:
	if texture==null:
		return
	var design:=Vector2(
		float(ProjectSettings.get_setting("display/window/size/viewport_width",1920)),
		float(ProjectSettings.get_setting("display/window/size/viewport_height",1080))
	)
	var zoom:=maxf(reference_zoom,0.001)
	scale=Vector2(design.x/(float(texture.get_width())*zoom),design.y/(float(texture.get_height())*zoom))
