extends Node2D

@onready var player: Player = get_parent()

func _draw() -> void:
	if player.collectable == -1:
		return
	
	draw_line(Vector2(-8, 5).rotated(player.global_rotation), player.collectable_sprite.global_position - player.position, Color("#000000"), 10)
	draw_line(Vector2(-8, 5).rotated(player.global_rotation), player.collectable_sprite.global_position - player.position, Color("#8a423a"), 8)

func _physics_process(_delta: float) -> void:
	global_rotation = 0
	queue_redraw()
