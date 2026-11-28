extends Area2D

func _on_body_entered(body: Node2D) -> void:
	if not body is Player:
		return

	Global.game_started = false
	NetworkHandler.rpc_id(1, "request_restart_match")
	
