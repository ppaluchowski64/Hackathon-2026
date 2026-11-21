extends Node2D

@onready var player: Player = get_parent()

var texture: Texture2D = preload("res://graphics/hand.png")

func _draw() -> void:
	if player.collectable == -1:
		return
	
	draw_line(Vector2(8, 5).rotated(player.global_rotation), player.collectable_sprite.global_position - player.position, Color("#000000"), 10)
	draw_line(Vector2(8, 5).rotated(player.global_rotation), player.collectable_sprite.global_position - player.position, Color("#8a423a"), 8)
	
	var rot: float = (Vector2(8, 5).rotated(player.global_rotation) - (player.collectable_sprite.global_position - player.position)).angle() - PI / 2
	draw_set_transform(player.collectable_sprite.global_position - player.position, rot)
	draw_texture(texture, -texture.get_size() / 2)
	draw_set_transform(Vector2.ZERO)

func _physics_process(_delta: float) -> void:
	global_rotation = 0
	queue_redraw()
