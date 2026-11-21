extends Node2D

const PLAYER_SCENE: PackedScene = preload("res://scenes/player.tscn")

@onready var camera: Camera2D = $Camera2D
@onready var tilemap: TileMapLayer = $TileMapLayer
@onready var lobby: Lobby = $Lobby
@onready var players_root: Node2D = $Players
@onready var ui = $UI
@onready var stamina_bar = $UI/StaminaBar

@export var collectables: CollectableSpawner

@onready var spawn_points: Array[Marker2D] = [
	$SpawnPoints/SpawnPoint1,
	$SpawnPoints/SpawnPoint2,
	$SpawnPoints/SpawnPoint3,
	$SpawnPoints/SpawnPoint4
]

var game_started: bool = false
var spawned_players: Dictionary = {}

func _ready() -> void:
	if not NetworkHandler.local_room_id.is_empty():
		seed(NetworkHandler.lobby_seed)

	tilemap.clear()

	for i in range(3):
		var origin_pos := Vector2i(-5, -8 - 10 * i)
		var pattern_idx: int = randi_range(0, tilemap.tile_set.get_patterns_count() - 1)
		var pattern: TileMapPattern = tilemap.tile_set.get_pattern(pattern_idx)

		tilemap.set_pattern(origin_pos, pattern)

	collectables.spawn(tilemap)

	lobby.start_requested.connect(NetworkHandler.start_game)
	NetworkHandler.lobby_updated.connect(_on_lobby_updated)
	NetworkHandler.game_started.connect(_on_game_started)

	_on_lobby_updated(NetworkHandler.peer_ids, NetworkHandler.player_names, NetworkHandler.ready_peer_ids)

	NetworkHandler.notify_scene_ready()

func _exit_tree() -> void:
	if NetworkHandler.lobby_updated.is_connected(_on_lobby_updated):
		NetworkHandler.lobby_updated.disconnect(_on_lobby_updated)
	if NetworkHandler.game_started.is_connected(_on_game_started):
		NetworkHandler.game_started.disconnect(_on_game_started)

func _physics_process(delta: float) -> void:
	if not game_started:
		return
	camera.offset.y -= 30 * delta

func _on_lobby_updated(peer_ids: Array, player_names: Dictionary, ready_peer_ids: Array) -> void:
	for existing_id in spawned_players.keys():
		if existing_id not in peer_ids:
			if is_instance_valid(spawned_players[existing_id]):
				spawned_players[existing_id].queue_free()
			spawned_players.erase(existing_id)

	for i in range(mini(peer_ids.size(), spawn_points.size())):
		var peer_id: int = peer_ids[i]
		var spawn_position := players_root.to_local(spawn_points[i].global_position)

		if not spawned_players.has(peer_id):
			spawned_players[peer_id] = _spawn_player(peer_id, spawn_position)

		var player = spawned_players[peer_id]
		if not is_instance_valid(player):
			continue

		player.player_nickname = player_names.get(peer_id, "Player")
		player.set_sync_peers(ready_peer_ids)

		if not game_started and player.is_multiplayer_authority():
			player.place_at(spawn_position)

	lobby.refresh(NetworkHandler.is_lobby_host(), ready_peer_ids.size() >= peer_ids.size())

func _spawn_player(peer_id: int, spawn_position: Vector2) -> Player:
	var player := PLAYER_SCENE.instantiate() as Player
	player.name = str(peer_id)
	player.position = spawn_position
	player.set_multiplayer_authority(peer_id)
	players_root.add_child(player)

	if peer_id == multiplayer.get_unique_id():
		ui.player = player
		stamina_bar.player = player

	return player

func _on_game_started() -> void:
	game_started = true
	lobby.hide()

	for player in spawned_players.values():
		if is_instance_valid(player):
			player.activate()
