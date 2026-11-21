extends Node2D
class_name TilemapDraw

var alt_tile_rects: Array[Dictionary] = []
var texture: Texture2D

var anim: float = 0

func _ready() -> void:
	texture = preload("res://graphics/tile_alt.png")

func _draw() -> void:
	var rot_data: Array[Dictionary]
	
	for data in alt_tile_rects:
		if data.rotating:
			rot_data.append(data)
		else:
			draw_texture(texture, data.rect.position)
	
	for data in rot_data:
		draw_rect(data.rect, data.color)
		draw_set_transform(data.rect.position, sin(anim * 4) * PI / 8 + PI / 4)
		draw_texture(texture, Vector2.ZERO)
		draw_set_transform(Vector2.ZERO, 0)

func _physics_process(delta: float) -> void:
	anim += delta
	queue_redraw()
