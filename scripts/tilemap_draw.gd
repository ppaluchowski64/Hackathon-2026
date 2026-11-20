extends Node2D
class_name TilemapDraw

var alt_tile_rects: Array[Dictionary] = []

func _draw() -> void:
	for data in alt_tile_rects:
		draw_rect(data.rect, data.color)
