extends CanvasLayer

@onready var button_container: VBoxContainer = $MarginContainer/VBoxContainer/ButtonContainer
@onready var player_name_input_container: HBoxContainer = $MarginContainer/VBoxContainer/MarginContainer/PlayerNameInputContainer
@onready var player_name_input: LineEdit = $MarginContainer/VBoxContainer/MarginContainer/PlayerNameInputContainer/PlayerNameInput

@onready var create_lobby: CanvasLayer = $MarginContainer/VBoxContainer/CreateLobby
@onready var lobby_list: CanvasLayer = $MarginContainer/VBoxContainer/LobbyList

func _ready() -> void:
	lobby_list.hide()
	create_lobby.hide()

func _on_player_name_input_text_submitted(new_nickname: String) -> void:
	NetworkHandler.local_nickname = new_nickname.strip_edges()
	player_name_input.release_focus()

func _on_create_lobby_button_pressed() -> void:
	button_container.hide()
	player_name_input_container.hide()
	create_lobby.show()

func _on_join_lobby_button_pressed() -> void:
	button_container.hide()
	player_name_input_container.hide()
	lobby_list.show()
