shader_type canvas_item;

//镀金描边：贴图本身为透明、但附近有实心像素的像素涂成金色 → 沿着贴图外轮廓镀一圈
//要求贴图自带透明留白（现在敌人/蛋的序列图都是 512 带留白，够用）
//用法见 visual_effects/gold_outline.gd：套在 AnimatedSprite2D 的 material 上

uniform vec4 outline_color : source_color = vec4(1.0,0.84,0.30,1.0);
uniform vec4 glow_color : source_color = vec4(1.0,0.55,0.08,1.0);
uniform float outline_px = 6.0;
uniform float glow_px = 14.0;
uniform float pulse_speed = 1.5;
uniform float pulse_amount = 0.22;

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	if (tex.a <= 0.02) {
		//透明像素：看周围一圈有没有实心像素
		vec2 px = TEXTURE_PIXEL_SIZE;
		float outline = 0.0;
		float glow = 0.0;
		for (int i = 0; i < 8; i++) {
			float ang = float(i) * 0.785398163;
			vec2 dir = vec2(cos(ang), sin(ang));
			outline = max(outline, texture(TEXTURE, UV + dir * px * outline_px).a);
			glow = max(glow, texture(TEXTURE, UV + dir * px * glow_px).a);
		}
		float pulse = 1.0 - pulse_amount + pulse_amount * sin(TIME * pulse_speed);
		if (outline > 0.02) {
			COLOR = vec4(outline_color.rgb, outline_color.a * pulse);
		} else if (glow > 0.02) {
			COLOR = vec4(glow_color.rgb, glow_color.a * pulse * 0.45);
		} else {
			discard;
		}
	}
	//本体像素什么都不做：保持默认的 贴图 × modulate（受击闪红/死亡淡出都还在）
}
