extends CanvasLayer

@onready var player_scene: PackedScene = preload("res://scenes/player.tscn")

@onready var spawn_points: Array[Marker2D] = [
	$MarginContainer/HBoxContainer/Control/Player1SpawnPoint,
	$MarginContainer/HBoxContainer/Control2/Player2SpawnPoint,
	$MarginContainer/HBoxContainer/Control3/Player3SpawnPoint,
	$MarginContainer/HBoxContainer/Control4/Player4SpawnPoint
]

var spawned_players: Dictionary = {}

func _ready() -> void:
	NetworkHandler.lobby_updated.connect(_on_lobby_updated)

func _on_lobby_updated(peer_ids: Array, player_names: Dictionary) -> void:
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
			if player_instance is RigidBody2D:
				player_instance.freeze()

			spawn_point.add_child(player_instance)
			spawned_players[peer_id] = player_instance

		if player_instance.get_parent() != spawn_point:
			player_instance.reparent(spawn_point)

		player_instance.position = Vector2.ZERO
		if "player_nickname" in player_instance:
			player_instance.player_nickname = player_name
