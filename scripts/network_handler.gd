extends Node

signal lobby_list_received(lobby_list: Array)

var multiplayer_peer = ENetMultiplayerPeer.new()

const PORT: int = 36864
const ADDRESS: String = "127.0.0.1"

const MAX_PLAYER_SIZE: int = 4

var rooms: Dictionary = {}
var peer_to_room: Dictionary = {}

var local_room_id: String = ""
var peer_ids: Array[int] = []
var player_names: Dictionary = {}

func _ready() -> void:
	if DisplayServer.get_name() == "--server" or "--headless" in OS.get_cmdline_args():
		initialize_server()

func initialize_server() -> void:
	var err = multiplayer_peer.create_server(PORT)
	if err != OK:
		push_error("Failed to Create Server", str(err))
		return

	multiplayer.multiplayer_peer = multiplayer_peer

	multiplayer_peer.peer_connected.connect(
		func(new_peer_id):
			if new_peer_id not in peer_ids:
				peer_ids.append(new_peer_id)
			if new_peer_id not in player_names:
				var id_str = str(new_peer_id)
				player_names[new_peer_id] = "Player " + id_str.substr(0, 2)

			var curr_lobby = get_tree().get_first_node_in_group("lobby")
			curr_lobby.rpc("update_lobby", peer_ids, player_names)
			curr_lobby.rpc("play_join_animation", peer_ids.size() - 1)
			curr_lobby.rpc_id(new_peer_id, "add_prev_players", peer_ids, player_names)
	)

	multiplayer_peer.peer_disconnected.connect(
		func(disconnected_peer_id):
			var chat_box = get_tree().get_first_node_in_group("chat_box")
			chat_box.rpc("create_disconnected_message", disconnected_peer_id, player_names)
			
			var main = get_tree().get_first_node_in_group("main")
			print(main)
			main.rpc_id(1, "disconnect_player", disconnected_peer_id)
			if disconnected_peer_id in peer_ids:
				peer_ids.erase(disconnected_peer_id)
			
			if peer_ids.size() == 1:
				chat_box.rpc("create_winner_message", player_names.get(1))
	)

@rpc("any_peer", "reliable")
func request_create_lobby(lobby_name: String) -> void:
	if not multiplayer.is_server():
		return
	
	var sender_id = multiplayer.get_remote_sender_id()
	if peer_to_room.has(sender_id):
		return
	
	var clean_name = lobby_name.strip_edges()
	if clean_name.is_empty():
		clean_name = "Lobby #" + str(rooms.size() + 1)
	
	var room_id: String = "room_" + str(Time.get_ticks_usec())
	
	rooms[room_id] = {
		"name": clean_name,
		"peers": [],
		"names": {},
		"in_game": false,
		"match_node": null
	}
	
	add_peer_to_room(sender_id, room_id)

func add_peer_to_room(sender_id: int, room_id: String) -> void:
	var room = rooms[room_id]
	room["peers"].append(sender_id)

@rpc("any_peer", "reliable")
func request_lobby_list() -> void:
	if not multiplayer.is_server():
		return
	
	var sender_id = multiplayer.get_remote_sender_id()
	var lobby_list: Array = []
	
	for room_id in rooms.keys():
		var room = rooms[room_id]
		lobby_list.append({
			"room_id": room_id,
			"name": room["name"],
			"player_count": room["peers"].size(),
			"max_players": MAX_PLAYER_SIZE,
			"in_game": room["in_game"]
		})

	rpc_id(sender_id, "receive_lobby_list", lobby_list)

@rpc("authority", "reliable")
func receive_lobby_list(lobby_list: Array) -> void:
	lobby_list_received.emit(lobby_list)

@rpc("any_peer", "reliable")
func request_join_lobby(room_id: String) -> void:
	if not multiplayer.is_server():
		return
	
	var sender_id = multiplayer.get_remote_sender_id()
	
	var room = rooms[room_id]

	if not rooms.has(room_id):
		rpc_id(sender_id, "join_lobby_response", false, "Lobby no longer exists.", "", [], {})
		return

	if room["in_game"]:
		rpc_id(sender_id, "join_lobby_response", false, "Lobby is already in game.", "", [], {})
		return

	if room["peers"].size() >= MAX_PLAYER_SIZE:
		rpc_id(sender_id, "join_lobby_response", false, "lobby is full.", "", [], {})

	add_peer_to_room(sender_id, room_id)
	rpc_id(sender_id, "join_lobby_response", true, "joined!", room_id, room["peers"], room["names"])

	var curr_lobby = get_tree().get_first_node_in_group("lobby")
	if curr_lobby:
		for existing_peer in room["peers"]:
			if existing_peer != sender_id:
				rpc_id(existing_peer, "update_lobby", room["peers"], room["names"])

@rpc("authority", "reliable")
func join_lobby_response(success: bool, msg: String, room_id: String, peers: Array[int], names: Dictionary) -> void:
	if success:
		local_room_id = room_id
		peer_ids = peers
		player_names = names
