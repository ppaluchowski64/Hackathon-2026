extends Area2D

@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	var scale_tween: Tween = create_tween() \
		.set_ease(Tween.EASE_IN_OUT) \
		.set_trans(Tween.TRANS_SPRING)
	
	scale_tween.tween_property(sprite, "scale", Vector2(1.25, 1.25), 0.5)
	
	# I have no idea why I have to wait 4 frames here
	# but it doesn't work otherwise
	for i in range(4):
		await get_tree().process_frame
	
	for body in get_overlapping_bodies():
		if not body is Player:
			continue
		
		var player: Player = body
		player.stun()
