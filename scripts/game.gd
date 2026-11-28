extends Node2D

@onready var player_scene: PackedScene = preload("res://scenes/player.tscn")

@onready var camera: Camera2D = $Camera2D
@onready var tilemap: TileMapLayer = $TileMapLayer
@onready var lobby: CanvasLayer = $Lobby

@export var collectables: CollectableSpawner

@onready var spawn_points: Array[Node] = get_spawn_points()

@onready var music_player: AudioStreamPlayer = $MusicPlayer

@onready var start_button: Button = $Lobby/VBoxContainer/StartGameButton

var spawned_players: Dictionary = {}
var dead_players: Dictionary = {}

func _ready() -> void:
	tilemap.clear()

	NetworkHandler.lobby_updated.connect(_on_lobby_updated)
	NetworkHandler.game_started.connect(_on_game_started)
	NetworkHandler.level_seed_ready.connect(_on_level_seed_ready)

	_on_lobby_updated(NetworkHandler.peer_ids, NetworkHandler.player_names)

	if NetworkHandler.local_world_seed != 0:
		_on_level_seed_ready(NetworkHandler.local_world_seed)

func _exit_tree() -> void:
	if NetworkHandler.lobby_updated.is_connected(_on_lobby_updated):
		NetworkHandler.lobby_updated.disconnect(_on_lobby_updated)
	if NetworkHandler.game_started.is_connected(_on_game_started):
		NetworkHandler.game_started.disconnect(_on_game_started)
	if NetworkHandler.level_seed_ready.is_connected(_on_level_seed_ready):
		NetworkHandler.level_seed_ready.disconnect(_on_level_seed_ready)

func _physics_process(delta: float) -> void:
	if not Global.game_started:
		return

	camera.offset.y -= 30 * delta

func get_spawn_points() -> Array[Node]:
	var group_node := get_tree().get_first_node_in_group("spawn_points")
	if group_node == null:
		return []
	return group_node.get_children()

func _sync_host_start_button() -> void:
	var should_have_button: bool = NetworkHandler.is_lobby_host() and not Global.game_started
	start_button.visible = should_have_button
	if should_have_button:
		if not start_button.pressed.is_connected(_on_start_button_pressed):
			start_button.pressed.connect(_on_start_button_pressed)
	else:
		if start_button.pressed.is_connected(_on_start_button_pressed):
			start_button.pressed.disconnect(_on_start_button_pressed)

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

		var player_instance: Player
		if spawned_players.has(peer_id) and is_instance_valid(spawned_players[peer_id]):
			player_instance = spawned_players[peer_id]
		else:
			player_instance = player_scene.instantiate()
			player_instance.name = str(peer_id)
			player_instance.set_multiplayer_authority(peer_id)

			if player_instance is RigidBody2D:
				player_instance.set_deferred("freeze", true)
			
			player_instance.player_died.connect(_on_player_died)

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

func _on_level_seed_ready(world_seed: int) -> void:
	Global.game_started = false
	dead_players.clear()
	# clear_spawned_collectables()
	generate_level(world_seed)
	
	if camera:
		camera.offset = Vector2.ZERO

	if start_button:
		start_button.disabled = false

	if lobby:
		lobby.visible = true

	_sync_host_start_button()
	
	for player_instance in spawned_players.values():
		if is_instance_valid(player_instance):
			player_instance.visible = true
			if player_instance is RigidBody2D:
				player_instance.set_deferred("freeze", true)
				player_instance.linear_velocity = Vector2.ZERO
				player_instance.angular_velocity = 0.0
				player_instance.position = Vector2.ZERO

func _on_start_button_pressed() -> void:
	start_button.disabled = true
	NetworkHandler.start_game()

func _on_player_died(peer_id: int) -> void:
	dead_players[peer_id] = true

	if spawned_players.has(peer_id) and is_instance_valid(spawned_players[peer_id]):
		var dead_player: Player = spawned_players[peer_id]
		dead_player.visible = false
		if dead_player is RigidBody2D:
			dead_player.set_deferred("freeze", true)
	
	if peer_id == multiplayer.get_unique_id():
		NetworkHandler.rpc_id(1, "report_player_died")

func generate_level(world_seed: int) -> void:
	var rng = RandomNumberGenerator.new()
	rng.seed = world_seed

	tilemap.clear()

	var pattern_count: int = tilemap.tile_set.get_patterns_count()
	if pattern_count > 0:
		for i in range(3):
			var origin_pos := Vector2i(-5, -8 - 10 * i)
			var pattern_idx: int = rng.randi_range(0, tilemap.tile_set.get_patterns_count() - 1)
			var pattern: TileMapPattern = tilemap.tile_set.get_pattern(pattern_idx)

			tilemap.set_pattern(origin_pos, pattern)

	if collectables and collectables.has_method("spawn"):
		collectables.spawn(tilemap)

func _on_game_started() -> void:
	Global.game_started = true
	music_player.play()

	if lobby:
		lobby.visible = false

	_sync_host_start_button()

	for peer_id in spawned_players.keys():
		if peer_id == multiplayer.get_unique_id():
			SignalBus.setup_player.emit(spawned_players[peer_id])

	for player_instance in spawned_players.values():
		if is_instance_valid(player_instance) and player_instance is RigidBody2D:
			player_instance.freeze = false
