extends Node2D

@onready var player: Player = get_parent()

func _draw() -> void:
	if not player.is_grappling:
		return
	
	draw_line(Vector2.ZERO, player.grapple_pos - player.position, Color("#363D52"), 10)

func _physics_process(_delta: float) -> void:
	global_rotation = 0
	queue_redraw()
