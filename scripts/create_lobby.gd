extends CanvasLayer

func _on_lobby_name_input_text_submitted(new_lobby_name: String) -> void:
	var clean_lobby_name = new_lobby_name.strip_edges()
	NetworkHandler.rpc_id(1, "request_create_lobby", clean_lobby_name)
	get_tree().change_scene_to_file("res://scenes/root/game.tscn")
