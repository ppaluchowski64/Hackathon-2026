extends CanvasLayer

@onready var lobby_list_container: VBoxContainer = $VBoxContainer/LobbyListContainer

func _ready() -> void:
	NetworkHandler.lobby_list_received.connect(_on_lobby_list_received)
	NetworkHandler.join_lobby_result.connect(_on_join_lobby_result)
	visibility_changed.connect(_on_visibility_changed)

	_load_preview_lobbies() # test of lobby list

func _exit_tree() -> void:
	if NetworkHandler.lobby_list_received.is_connected(_on_lobby_list_received):
		NetworkHandler.lobby_list_received.disconnect(_on_lobby_list_received)
	if NetworkHandler.join_lobby_result.is_connected(_on_join_lobby_result):
		NetworkHandler.join_lobby_result.disconnect(_on_join_lobby_result)

func _on_visibility_changed() -> void:
	if visible:
		NetworkHandler.fetch_lobby_list()

func _load_preview_lobbies() -> void:
	_on_lobby_list_received([
		{"room_id": "room_1", "name": "Lobby #1", "player_count": 3, "max_players": 4, "in_game": false},
		{"room_id": "room_2", "name": "Lobby #2", "player_count": 1, "max_players": 4, "in_game": false},
		{"room_id": "room_3", "name": "Lobby #3", "player_count": 4, "max_players": 4, "in_game": false},
		{"room_id": "room_4", "name": "Lobby #4", "player_count": 2, "max_players": 4, "in_game": true},
	])

func _on_lobby_list_received(lobby_list: Array) -> void:
	for child in lobby_list_container.get_children():
		child.queue_free()

	for lobby in lobby_list:
		var room_id: String = lobby["room_id"]
		var lobby_name: String = lobby["name"]
		var count: int = lobby["player_count"]
		var max_players: int = lobby["max_players"]
		var in_game: bool = lobby["in_game"]
		var is_joinable: bool = not in_game and count < max_players

		var item_bg := PanelContainer.new()
		item_bg.name = "LobbyListItemBackground"
		item_bg.custom_minimum_size = Vector2(250, 38)
		item_bg.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if is_joinable else Control.CURSOR_FORBIDDEN

		var normal_style := StyleBoxFlat.new()
		normal_style.bg_color = Color(0.14, 0.16, 0.20, 0.85)
		normal_style.border_color = Color(0.28, 0.32, 0.40, 0.7)
		normal_style.set_border_width_all(1)
		normal_style.set_corner_radius_all(6)

		var hover_style := normal_style.duplicate() as StyleBoxFlat
		hover_style.bg_color = Color(0.20, 0.24, 0.32, 0.95)
		hover_style.border_color = Color(0.45, 0.65, 0.95, 0.9)

		item_bg.add_theme_stylebox_override("panel", normal_style)

		if is_joinable:
			item_bg.mouse_entered.connect(func(): item_bg.add_theme_stylebox_override("panel", hover_style))
			item_bg.mouse_exited.connect(func(): item_bg.add_theme_stylebox_override("panel", normal_style))
		else:
			item_bg.modulate = Color(0.6, 0.6, 0.6, 0.7)

		var margin := MarginContainer.new()
		margin.name = "MarginContainer"
		margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
		margin.add_theme_constant_override("margin_left", 12)
		margin.add_theme_constant_override("margin_right", 12)
		margin.add_theme_constant_override("margin_top", 8)
		margin.add_theme_constant_override("margin_bottom", 8)
		item_bg.add_child(margin)

		var lobby_container := HBoxContainer.new()
		lobby_container.name = "LobbyContainer"
		lobby_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
		margin.add_child(lobby_container)

		var name_container := HBoxContainer.new()
		name_container.name = "LobbyNameContainer"
		name_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
		lobby_container.add_child(name_container)

		var name_label := Label.new()
		name_label.name = "LobbyNameLabel"
		name_label.text = lobby_name
		name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		name_label.add_theme_color_override("font_color", Color(0.95, 0.95, 0.95))
		name_container.add_child(name_label)

		var count_container := HBoxContainer.new()
		count_container.name = "PlayerCountContainer"
		count_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
		lobby_container.add_child(count_container)

		var count_label := Label.new()
		count_label.name = "PlayerCountLabel"
		count_label.text = "IN GAME" if in_game else ("%d/%d" % [count, max_players])
		count_label.mouse_filter = Control.MOUSE_FILTER_IGNORE

		if in_game:
			count_label.add_theme_color_override("font_color", Color(0.92, 0.60, 0.32))
		elif count >= max_players:
			count_label.add_theme_color_override("font_color", Color(0.85, 0.42, 0.42))
		else:
			count_label.add_theme_color_override("font_color", Color(0.42, 0.88, 0.62))

		count_container.add_child(count_label)

		if is_joinable:
			item_bg.gui_input.connect(func(event: InputEvent):
				if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
					item_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
					if multiplayer.has_multiplayer_peer():
						NetworkHandler.join_lobby(room_id)
			)

		lobby_list_container.add_child(item_bg)

func _on_join_lobby_result(success: bool, _message: String = "") -> void:
	if success:
		get_tree().change_scene_to_file("res://scenes/root/game.tscn")
