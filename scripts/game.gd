extends Node2D

@onready var player_scene: PackedScene = preload("res://scenes/player.tscn")

@onready var camera: Camera2D = $Camera2D
@onready var tilemap: TileMapLayer = $TileMapLayer
@onready var lobby: CanvasLayer = $Lobby

@export var collectables: CollectableSpawner

@onready var spawn_points: Array[Node] = get_spawn_points()

@onready var start_button: Button = $Lobby/VBoxContainer/StartGameButton

var game_started: bool = false
var spawned_players: Dictionary = {}

func _ready() -> void:
	tilemap.clear()

	for i in range(3):
		var origin_pos := Vector2i(-5, -8 - 10 * i)
		var pattern_idx: int = randi_range(0, tilemap.tile_set.get_patterns_count() - 1)
		var pattern: TileMapPattern = tilemap.tile_set.get_pattern(pattern_idx)

		tilemap.set_pattern(origin_pos, pattern)

	collectables.spawn(tilemap)

	NetworkHandler.lobby_updated.connect(_on_lobby_updated)
	NetworkHandler.game_started.connect(_on_game_started)

	_on_lobby_updated(NetworkHandler.peer_ids, NetworkHandler.player_names)

func _exit_tree() -> void:
	if NetworkHandler.lobby_updated.is_connected(_on_lobby_updated):
		NetworkHandler.lobby_updated.disconnect(_on_lobby_updated)
	if NetworkHandler.game_started.is_connected(_on_game_started):
		NetworkHandler.game_started.disconnect(_on_game_started)

func _physics_process(delta: float) -> void:
	if not game_started:
		return
	camera.offset.y -= 30 * delta

func get_spawn_points() -> Array[Node]:
	var group_node := get_tree().get_first_node_in_group("spawn_points")
	if group_node == null:
		return []
	return group_node.get_children()

func _sync_host_start_button() -> void:
	var should_have_button: bool = NetworkHandler.is_lobby_host() and not game_started
	start_button.visible = should_have_button
	if should_have_button:
		start_button.pressed.connect(_on_start_button_pressed)
	
func _on_lobby_updated(peer_ids: Array, player_names: Dictionary) -> void:
	_sync_host_start_button()

	for existing_id in spawned_players.keys():
		if existing_id not in peer_ids:
			if is_instance_valid(spawned_players[existing_id]):
				spawned_players[existing_id].queue_free()
			spawned_players.erase(existing_id)

	for i in range(min(peer_ids.size(), spawn_points.size())):
		var peer_id: int = peer_ids[i]
		var spawn_point: Marker2D = spawn_points[i]
		var player_name: String = player_names.get(peer_id, "Player")

		var player_instance: Node
		if spawned_players.has(peer_id) and is_instance_valid(spawned_players[peer_id]):
			player_instance = spawned_players[peer_id]
		else:
			player_instance = player_scene.instantiate()
			player_instance.name = str(peer_id)
			player_instance.set_multiplayer_authority(peer_id)
			if player_instance is RigidBody2D:
				player_instance.freeze = true

			var sync := player_instance.get_node_or_null("MultiplayerSynchronizer") as MultiplayerSynchronizer
			if sync:
				sync.public_visibility = false
				sync.set_process(false)
				sync.set_physics_process(false)

			spawn_point.add_child(player_instance)
			spawned_players[peer_id] = player_instance

		if player_instance.get_parent() != spawn_point:
			player_instance.reparent(spawn_point)

		player_instance.position = Vector2.ZERO
		if "player_nickname" in player_instance:
			player_instance.player_nickname = player_name

func _on_start_button_pressed() -> void:
	start_button.disabled = true
	lobby.visible = false
	for player_instance in spawned_players.values():
		if is_instance_valid(player_instance) and player_instance is RigidBody2D:
			player_instance.freeze = false

	NetworkHandler.start_game()

func _on_game_started() -> void:
	game_started = true
	
