extends CanvasLayer

@onready var button_container: VBoxContainer = $MarginContainer/VBoxContainer/ButtonContainer
@onready var player_name_input_container: HBoxContainer = $MarginContainer/VBoxContainer/MarginContainer/PlayerNameInputContainer
@onready var lobby: CanvasLayer = $LobbyList
func _on_player_name_input_text_submitted(new_text: String) -> void:
	pass

func _on_create_lobby_button_pressed() -> void:
	button_container.hide()
	player_name_input_container.hide()

func _on_join_lobby_button_pressed() -> void:
	button_container.hide()
	player_name_input_container.hide()
