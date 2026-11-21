extends CanvasLayer

@onready var lobby_list_container: VBoxContainer = $VBoxContainer/LobbyListContainer

func _ready() -> void:
	NetworkHandler.lobby_list_received.connect(_on_lobby_list_received)
	NetworkHandler.join_lobby_result.connect(_on_join_lobby_result)

func _on_lobby_list_received(lobby_list: Array) -> void:
	for child in lobby_list_container.get_children():
		child.queue_free()

	for lobby in lobby_list:
		var room_id: String = lobby["room_id"]
		var lobby_name: String = lobby["name"]
		var count: int = lobby["player_count"]
		var max_players: int = lobby["max_players"]
		var in_game: bool = lobby["in_game"]
		var is_joinable = not in_game and count < max_players
		 
		var item_bg := PanelContainer.new()
		item_bg.name = "LobbyListItemBackground"
		item_bg.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if is_joinable else Control.CURSOR_FORBIDDEN

		if not is_joinable:
			item_bg.modulate = Color(0.6, 0.6, 0.6, 0.8)

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
		name_container.add_child(name_label)

		var count_container := HBoxContainer.new()
		count_container.name = "PlayerCountContainer"
		count_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
		lobby_container.add_child(count_container)

		var count_label := Label.new()
		count_label.name = "PlayerCountLabel"
		count_label.text = "IN GAME" if in_game else ("%d/%d" % [count, max_players])
		count_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		count_container.add_child(count_label)
		
		if is_joinable:
			item_bg.gui_input.connect(func(event: InputEvent):
				if event is InputEventMouse and event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT:
					item_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
					NetworkHandler.rpc_id(1, "request_join_lobby", room_id)
			)

func _on_join_lobby_result() -> void:
	pass
