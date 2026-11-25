extends Node

signal lobby_list_received(lobby_list: Array)
signal join_lobby_result(success: bool, message: String)
signal lobby_updated(peers: Array, names: Dictionary)
signal game_started

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
	else:
		join_client()

func initialize_server() -> void:
	RenderingServer.set_default_clear_color("#FF0000")
	get_window().title = "SERVER"

	var err = multiplayer_peer.create_server(PORT)
	if err != OK:
		push_error("Failed to Create Server", str(err))
		return

	multiplayer.multiplayer_peer = multiplayer_peer

	print("[Server] Listening on port ", PORT)

	multiplayer_peer.peer_connected.connect(
		func(_new_peer_id: int):
			rpc_id(_new_peer_id, "receive_lobby_list", build_lobby_list())
	)

func join_client() -> void:
	multiplayer_peer.create_client(ADDRESS, PORT)
	multiplayer.multiplayer_peer = multiplayer_peer

	multiplayer.connected_to_server.connect(
		func():
			print("[Client Connected]")
			rpc_id(1, "request_lobby_list")
	)

@rpc("any_peer", "reliable")
func request_create_lobby(lobby_name: String, nickname: String) -> void:
	if not multiplayer.is_server():
		return

	var sender_id = multiplayer.get_remote_sender_id()
	if peer_to_room.has(sender_id):
		return

	var clean_name = lobby_name.strip_edges()
	if clean_name.is_empty():
		clean_name = "Lobby #" + str(rooms.size() + 1)

	var clean_nick := nickname.strip_edges().left(20)
	if clean_nick.is_empty():
		clean_nick = "Player_%d" % sender_id

	var room_id: String = "room_" + str(Time.get_ticks_usec())

	rooms[room_id] = {
		"name": clean_name,
		"peers": [],
		"names": {},
		"in_game": false,
		"match_node": null
	}

	var room = rooms[room_id]

	add_peer_to_room(sender_id, room_id, clean_nick)
	print("join lobby response")

	rpc_id(sender_id, "join_lobby_response", true, "Lobby created!", room_id, room["peers"], room["names"])
	broadcast_lobby_list()

func build_lobby_list() -> Array:
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

	return lobby_list

func broadcast_lobby_list() -> void:
	if not multiplayer.is_server():
		return

	var lobby_list = build_lobby_list()
	for peer_id in multiplayer.get_peers():
		rpc_id(peer_id, "receive_lobby_list", lobby_list)

@rpc("any_peer", "reliable")
func request_lobby_list() -> void:
	if not multiplayer.is_server():
		return

	var sender_id = multiplayer.get_remote_sender_id()

	rpc_id(sender_id, "receive_lobby_list", build_lobby_list())

@rpc("authority", "reliable")
func receive_lobby_list(lobby_list: Array) -> void:
	lobby_list_received.emit(lobby_list)

@rpc("any_peer", "reliable")
func request_join_lobby(room_id: String, nickname: String) -> void:
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

	var clean_nick := nickname.strip_edges().left(20)
	if clean_nick.is_empty():
		clean_nick = "Player_%d" % sender_id

	add_peer_to_room(sender_id, room_id, clean_nick)
	rpc_id(sender_id, "join_lobby_response", true, "joined!", room_id, room["peers"], room["names"])

	for existing_peer in room["peers"]:
		if existing_peer != sender_id:
			rpc_id(existing_peer, "receive_lobby_update", room["peers"], room["names"])

	broadcast_lobby_list()

@rpc("authority", "reliable")
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

func add_peer_to_room(peer_id: int, room_id: String, nickname: String) -> void:
	var room = rooms[room_id]
	room["peers"].append(peer_id)
	room["names"][peer_id] = nickname
	peer_to_room[peer_id] = room_id

func can_send_to_server() -> bool:
	if not multiplayer.has_multiplayer_peer() or multiplayer.is_server():
		return false
	return multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED

func wait_until_connected() -> bool:
	if can_send_to_server():
		return true
	if multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTING:
		await multiplayer.connected_to_server
		return can_send_to_server()
	return false

# helper functions
func create_lobby(lobby_name: String) -> void:
	if await wait_until_connected():
		rpc_id(1, "request_create_lobby", lobby_name.strip_edges(), local_nickname)

func join_lobby(room_id: String) -> void:
	if await wait_until_connected():
		rpc_id(1, "request_join_lobby", room_id, local_nickname)

func fetch_lobby_list() -> void:
	if await wait_until_connected():
		rpc_id(1, "request_lobby_list")
