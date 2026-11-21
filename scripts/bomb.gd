extends RigidBody2D

@onready var label: Label = $Label
@onready var area: Area2D = $Area2D

func _ready() -> void:
	get_tree().create_timer(0.05).timeout.connect(func():
		set_collision_layer_value(1, true)
		set_collision_mask_value(1, true)
	)
	
	for i in range(5):
		await get_tree().create_timer(0.2).timeout
		label.text = str(4 - i)
	
	await get_tree().create_timer(0.2).timeout
	
	for body in area.get_overlapping_bodies():
		if not body is Player:
			continue
		
		var player: Player = body
		var diff: Vector2 = player.global_position - global_position
		player.apply_central_force(diff.normalized() * 300000 / sqrt(diff.length()))
	
	queue_free()
