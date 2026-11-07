extends "res://projectiles/vehicle_ball.gd"

#摩托车：横向贴图是一张 4列×3行 的序列图，单帧 910×512
#进场时切成 12 帧循环播放；竖直方向用另一张朝下的单帧图（由父类处理）

const SHEET=preload("res://arts/texture/projectile/vehicles/red_ju_motorcycle_right.png")
const FRAME_WIDTH:=910
const FRAME_HEIGHT:=512
const COLUMNS:=4
const ROWS:=3
const FPS:=12.0

func _ready() -> void:
	_build_sheet_frames()
	super._ready()

func _build_sheet_frames() -> void:
	var sprite:AnimatedSprite2D=$AnimatedSprite2D
	if sprite==null:
		return
	var frames:=SpriteFrames.new()
	frames.set_animation_loop("default",true)
	frames.set_animation_speed("default",FPS)
	for i in range(COLUMNS*ROWS):
		var col:int=i%COLUMNS
		var row:=floori(float(i)/float(COLUMNS))
		var atlas:=AtlasTexture.new()
		atlas.atlas=SHEET
		atlas.region=Rect2(col*FRAME_WIDTH,row*FRAME_HEIGHT,FRAME_WIDTH,FRAME_HEIGHT)
		frames.add_frame("default",atlas)
	sprite.sprite_frames=frames
