extends Node2D
class_name ReachDraw

var radius: float = 200
var dash_count: int = 24
var dash_ratio: float = 0.5
var color := Color("#FFFFFF74")
var width: float = 2

var anim: float = 0

func _draw() -> void:
	var step: float = TAU / float(dash_count)
	var arc_len: float = step * dash_ratio
	
	for i in range(dash_count):
		var start_angle := i * step
		var end_angle := start_angle + arc_len
		draw_arc(Vector2.ZERO, radius, start_angle, end_angle, 8, color, width)

func _physics_process(delta: float) -> void:
	anim += delta
	global_rotation = anim * 0.2
