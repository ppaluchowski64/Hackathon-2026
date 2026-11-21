extends Node

signal lobby_list_received(lobby_list: Array)
signal join_lobby_result(success: bool, message: String)
signal lobby_updated(peers: Array, names: Dictionary)

var multiplayer_peer = ENetMultiplayerPeer.new()

const PORT: int = 36864
const ADDRESS: String = "127.0.0.1"

const MAX_PLAYER_SIZE: int = 4

var rooms: Dictionary = {}
var peer_to_room: Dictionary = {}

var local_room_id: String = ""
var peer_ids: Array[int] = []
var player_names: Dictionary = {}

var local_nickname: String

func _ready() -> void:
	if DisplayServer.get_name() == "headless" or "--server" in OS.get_cmdline_args():
		initialize_server()

func initialize_server() -> void:
	var err = multiplayer_peer.create_server(PORT)
	if err != OK:
		push_error("Failed to Create Server", str(err))
		return

	multiplayer.multiplayer_peer = multiplayer_peer

	multiplayer_peer.peer_connected.connect(
		func(_new_peer_id: int):
			rpc_id(1, "request_lobby_list")
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

	var room = rooms[room_id]

	add_peer_to_room(sender_id, room_id)
	rpc_id(sender_id, "join_lobby_response", true, "Lobby created!", room_id, room["peers"], room["names"])

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

	if not rooms.has(room_id):
		rpc_id(sender_id, "join_lobby_response", false, "Lobby no longer exists.", "", [], {})
		return

	var room = rooms[room_id]

	if room["in_game"]:
		rpc_id(sender_id, "join_lobby_response", false, "Lobby is already in game.", "", [], {})
		return

	if room["peers"].size() >= MAX_PLAYER_SIZE:
		rpc_id(sender_id, "join_lobby_response", false, "lobby is full.", "", [], {})
		return

	add_peer_to_room(sender_id, room_id)
	rpc_id(sender_id, "join_lobby_response", true, "joined!", room_id, room["peers"], room["names"])

	for existing_peer in room["peers"]:
		if existing_peer != sender_id:
			rpc_id(existing_peer, "receive_lobby_update", room["peers"], room["names"])

@rpc("any_peer", "reliable")
func receive_lobby_update(peers: Array, names: Dictionary) -> void:
	peer_ids.assign(peers)
	player_names = names
	lobby_updated.emit(peers, names)

@rpc("authority", "reliable")
func join_lobby_response(success: bool, msg: String, room_id: String, peers: Array, names: Dictionary) -> void:
	if success:
		local_room_id = room_id
		peer_ids.assign(peers)
		player_names = names

	join_lobby_result.emit(success, msg)

func add_peer_to_room(sender_id: int, room_id: String) -> void:
	var room = rooms[room_id]
	room["peers"].append(sender_id)
	peer_to_room[sender_id] = room_id
