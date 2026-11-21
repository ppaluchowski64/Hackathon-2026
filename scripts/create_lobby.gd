extends CanvasLayer

@onready var lobby_name_input = $VBoxContainer/LobbyNameInput

func _ready() -> void:
	NetworkHandler.join_lobby_result.connect(_on_join_lobby_result)

func _exit_tree() -> void:
	if NetworkHandler.join_lobby_result.is_connected(_on_join_lobby_result):
		NetworkHandler.join_lobby_result.disconnect(_on_join_lobby_result)

func _on_lobby_name_input_text_submitted(new_lobby_name: String) -> void:
	NetworkHandler.create_lobby(new_lobby_name)

func _on_join_lobby_result(success: bool, message: String) -> void:
	print("result:", success)
	if success and is_inside_tree():
		get_tree().change_scene_to_file("res://scenes/root/game.tscn")
	else:
		push_warning(message)


func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _on_create_lobby_button_pressed() -> void:
	NetworkHandler.create_lobby(lobby_name_input.text)
