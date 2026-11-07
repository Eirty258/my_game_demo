extends RefCounted

#悬浮提示的统一外观（暂停页道具栏、订单页共用同一套，改这里两边一起变）
#用法：TooltipStyle.apply(哪个控件) —— 会顺便把 mouse_filter 打开，否则收不到鼠标

static func apply(control:Control) -> void:
	if control==null:
		return
	control.mouse_filter=Control.MOUSE_FILTER_STOP
	var theme:=Theme.new()
	#字体颜色
	theme.set_color("font_color","TooltipLabel",Color.WHITE)
	#字体大小
	theme.set_font_size("font_size","TooltipLabel",32)
	#背景 StyleBox
	var stylebox:=StyleBoxFlat.new()
	stylebox.bg_color=Color(0.1,0.1,0.1,0.95)
	stylebox.border_width_left=2
	stylebox.border_width_top=2
	stylebox.border_width_right=2
	stylebox.border_width_bottom=2
	stylebox.border_color=Color(0.8,0.8,0.8)
	stylebox.corner_radius_top_left=4
	stylebox.corner_radius_top_right=4
	stylebox.corner_radius_bottom_left=4
	stylebox.corner_radius_bottom_right=4
	stylebox.content_margin_left=8
	stylebox.content_margin_top=4
	stylebox.content_margin_right=8
	stylebox.content_margin_bottom=4
	theme.set_stylebox("panel","TooltipPanel",stylebox)
	control.theme=theme
