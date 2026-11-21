extends Area2D

func _on_body_entered(body: Node2D) -> void:
	if not body is Player:
		return
	
	get_tree().call_deferred("reload_current_scene")
