extends Area2D

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var audio: AudioStreamPlayer = $AudioStreamPlayer

func _ready() -> void:
	var scale_tween: Tween = create_tween() \
		.set_ease(Tween.EASE_OUT) \
		.set_trans(Tween.TRANS_EXPO)
	
	scale_tween.tween_property(sprite, "scale", Vector2(2, 2), 0.5)
	
	audio.play(0.25)
	
	# I have no idea why I have to wait 4 frames here
	# but it doesn't work otherwise
	for i in range(4):
		await get_tree().process_frame
	
	for body in get_overlapping_bodies():
		if not body is Player:
			continue
		
		var player: Player = body
		player.stun()
	
	await get_tree().create_timer(0.5).timeout
	queue_free()
