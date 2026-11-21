extends Node2D
class_name ForegroundDraw

var rects: Array[Rect2]

func _draw() -> void:
	for rect in rects:
		draw_rect(Rect2(rect.position.x, rect.position.y * 1.1, rect.size.x, rect.size.y * 1.1), Color("#333333"))
