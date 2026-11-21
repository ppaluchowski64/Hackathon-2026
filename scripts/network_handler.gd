extends Node

signal lobby_list_received(lobby_list: Array)
signal join_lobby_result(success: bool, message: String)
signal lobby_updated(peers: Array, names: Dictionary, ready_peers: Array)
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

var ready_peer_ids: Array[int] = []
var lobby_seed: int = 0

var local_nickname: String

func _ready() -> void:
	if DisplayServer.get_name() == "headless" or "--server" in OS.get_cmdline_args():
		initialize_server()
	else:
		join_client()

func initialize_server() -> void:
	var err = multiplayer_peer.create_server(PORT)
	if err != OK:
		push_error("Failed to Create Server", str(err))
		return

	multiplayer.multiplayer_peer = multiplayer_peer

	print("[Server] Listening on port ", PORT)

	multiplayer.peer_disconnected.connect(remove_peer_from_room)

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
		"ready": [],
		"seed": randi(),
		"in_game": false,
		"match_node": null
	}

	add_peer_to_room(sender_id, room_id, clean_nick)
	print("join lobby response")

	rpc_id(sender_id, "join_lobby_response", true, "Lobby created!", build_lobby_state(room_id))
	broadcast_lobby_list()

func build_lobby_list() -> Array[Dictionary]:
	var lobby_list: Array[Dictionary] = []

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

func build_lobby_state(room_id: String) -> Dictionary:
	var room: Dictionary = rooms[room_id]
	return {
		"room_id": room_id,
		"peers": room["peers"],
		"names": room["names"],
		"ready": room["ready"],
		"seed": room["seed"]
	}

func send_lobby_update(room_id: String, except_peer: int = 0) -> void:
	var lobby_state := build_lobby_state(room_id)
	for peer_id in rooms[room_id]["peers"]:
		if peer_id != except_peer:
			rpc_id(peer_id, "receive_lobby_update", lobby_state)

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

	if peer_to_room.has(sender_id):
		return

	if not rooms.has(room_id):
		rpc_id(sender_id, "join_lobby_response", false, "Lobby no longer exists.", {})
		return

	var room = rooms[room_id]

	if room["in_game"]:
		rpc_id(sender_id, "join_lobby_response", false, "Lobby is already in game.", {})
		return

	if room["peers"].size() >= MAX_PLAYER_SIZE:
		rpc_id(sender_id, "join_lobby_response", false, "lobby is full.", {})
		return

	var clean_nick := nickname.strip_edges().left(20)
	if clean_nick.is_empty():
		var trimmed_sender_id = str(sender_id).substr(0,2)
		clean_nick = ("Player_%d" % int(trimmed_sender_id))

	add_peer_to_room(sender_id, room_id, clean_nick)
	rpc_id(sender_id, "join_lobby_response", true, "joined!", build_lobby_state(room_id))

	send_lobby_update(room_id, sender_id)

	broadcast_lobby_list()

@rpc("any_peer", "reliable")
func request_scene_ready() -> void:
	if not multiplayer.is_server():
		return

	var sender_id = multiplayer.get_remote_sender_id()
	if not peer_to_room.has(sender_id):
		return

	var room_id: String = peer_to_room[sender_id]
	var room: Dictionary = rooms[room_id]

	if sender_id not in room["ready"]:
		room["ready"].append(sender_id)

	send_lobby_update(room_id)

@rpc("authority", "reliable")
func receive_lobby_update(lobby_state: Dictionary) -> void:
	apply_lobby_state(lobby_state)
	lobby_updated.emit(peer_ids, player_names, ready_peer_ids)

@rpc("authority", "reliable")
func join_lobby_response(success: bool, msg: String, lobby_state: Dictionary) -> void:
	if success:
		apply_lobby_state(lobby_state)

	join_lobby_result.emit(success, msg)

func apply_lobby_state(lobby_state: Dictionary) -> void:
	local_room_id = lobby_state["room_id"]
	peer_ids.assign(lobby_state["peers"])
	player_names = lobby_state["names"]
	ready_peer_ids.assign(lobby_state["ready"])
	lobby_seed = lobby_state["seed"]

func add_peer_to_room(peer_id: int, room_id: String, nickname: String) -> void:
	var room = rooms[room_id]
	room["peers"].append(peer_id)
	room["names"][peer_id] = nickname
	peer_to_room[peer_id] = room_id

func remove_peer_from_room(peer_id: int) -> void:
	if not peer_to_room.has(peer_id):
		return

	var room_id: String = peer_to_room[peer_id]
	peer_to_room.erase(peer_id)

	var room: Dictionary = rooms[room_id]
	room["peers"].erase(peer_id)
	room["names"].erase(peer_id)
	room["ready"].erase(peer_id)

	if room["peers"].is_empty():
		rooms.erase(room_id)
	else:
		send_lobby_update(room_id)

	broadcast_lobby_list()

func can_send_to_server() -> bool:
	if not multiplayer.has_multiplayer_peer() or multiplayer.is_server():
		return false
	return multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED

func wait_until_connected() -> bool:
	if can_send_to_server():
		return true
	if not multiplayer.has_multiplayer_peer() or multiplayer.is_server():
		return false
	if multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTING:
		await multiplayer.connected_to_server
		return can_send_to_server()
	return false

func create_lobby(lobby_name: String) -> void:
	print("create lobby request")
	if await wait_until_connected():
		rpc_id(1, "request_create_lobby", lobby_name.strip_edges(), local_nickname)
		print("can send to server")

func join_lobby(room_id: String) -> void:
	if await wait_until_connected():
		rpc_id(1, "request_join_lobby", room_id, local_nickname)

func fetch_lobby_list() -> void:
	if await wait_until_connected():
		rpc_id(1, "request_lobby_list")

func notify_scene_ready() -> void:
	if local_room_id.is_empty():
		return
	if await wait_until_connected():
		rpc_id(1, "request_scene_ready")

func is_lobby_host() -> bool:
	return not peer_ids.is_empty() and peer_ids[0] == multiplayer.get_unique_id()

func start_game() -> void:
	if await wait_until_connected():
		rpc_id(1, "request_start_game")

@rpc("any_peer", "reliable")
func request_start_game() -> void:
	if not multiplayer.is_server():
		return

	var sender_id = multiplayer.get_remote_sender_id()

	if not peer_to_room.has(sender_id):
		return

	var room_id: String = peer_to_room[sender_id]
	var room: Dictionary = rooms[room_id]

	if room["peers"].is_empty() or room["peers"][0] != sender_id:
		return

	if room["in_game"]:
		return

	if room["ready"].size() < room["peers"].size():
		return

	room["in_game"] = true

	for peer_id in room["peers"]:
		rpc_id(peer_id, "receive_game_started")

	broadcast_lobby_list()

@rpc("authority", "reliable")
func receive_game_started() -> void:
	game_started.emit()
