extends Node2D

@onready var player: Player = get_parent()

var texture: Texture2D = preload("res://graphics/hand.png")

func _draw() -> void:
	if not player.is_grappling:
		return
	
	draw_line(Vector2(-8, 5).rotated(player.global_rotation), player.grapple_pos - player.global_position, Color("#000000"), 10)
	draw_line(Vector2(-8, 5).rotated(player.global_rotation), player.grapple_pos - player.global_position, Color("#8a423a"), 8)
	
	var rot: float = (Vector2(-8, 5).rotated(player.global_rotation) - (player.grapple_pos - player.global_position)).angle() - PI / 2
	draw_set_transform(player.grapple_pos - player.global_position, rot)
	draw_texture(texture, -texture.get_size() / 2)
	draw_set_transform(Vector2.ZERO)

func _physics_process(_delta: float) -> void:
	global_rotation = 0
	queue_redraw()
