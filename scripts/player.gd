extends RigidBody2D
class_name Player

const REMOTE_SMOOTHING: float = 20.0
const REMOTE_SNAP_DISTANCE: float = 128.0

@onready var grapple: Area2D = $Grapple
var is_grappling: bool = false
var grapple_pos: Vector2

var stamina: float = 100
var exhaustion: float = 0

@export var player_nickname: String:
	set(value):
		player_nickname = value
		if has_node("LabelRoot/PlayerName"):
			$LabelRoot/PlayerName.text = value

@onready var sprite: Sprite2D = $Sprite2D

@onready var collectable_sprite: Sprite2D = $CollectableRoot/CollectableSprite
var spring_strength: float = 1
var damping: float = 10
var collectable_vel := Vector2.ZERO

var collectable := Collectable.Type.SLAP

var is_stunned: bool = false
var is_exhausted: bool = false

var reach: float = 400
@onready var reach_draw: ReachDraw = $ReachDraw

var height: float = 0
@onready var camera: Camera2D = get_tree().get_first_node_in_group("camera")

@onready var danger_timer: Timer = $DangerTimer
@onready var exhaustion_timer: Timer = $ExhaustionTimer

@onready var synchronizer: MultiplayerSynchronizer = $MultiplayerSynchronizer

var sync_position: Vector2
var sync_rotation: float

var is_active: bool = false

func _ready() -> void:
	sync_position = position
	sync_rotation = rotation

	freeze_mode = RigidBody2D.FREEZE_MODE_KINEMATIC
	freeze = true

	reach_draw.radius = reach
	reach_draw.visible = is_multiplayer_authority()

func activate() -> void:
	is_active = true
	if is_multiplayer_authority():
		freeze = false

func place_at(new_position: Vector2) -> void:
	position = new_position
	sync_position = new_position

func set_sync_peers(peer_ids: Array) -> void:
	for peer_id in multiplayer.get_peers():
		synchronizer.set_visibility_for(peer_id, peer_id in peer_ids)

func stun() -> void:
	is_stunned = true
	is_grappling = false
	sprite.frame = 2
	await get_tree().create_timer(1).timeout
	is_stunned = false
	sprite.frame = 0

func exhaust() -> void:
	is_exhausted = true
	is_grappling = false
	sprite.frame = 1
	await get_tree().create_timer(2).timeout
	is_exhausted = false
	sprite.frame = 0

func _physics_process(delta: float) -> void:
	grapple.global_rotation = 0

	if not is_multiplayer_authority():
		_follow_network_transform(delta)
		_update_collectable_sprite(delta)
		return

	sync_position = position
	sync_rotation = rotation

	if not is_active:
		_update_collectable_sprite(delta)
		return

	reach = max(reach - 4 * delta, 200)
	reach_draw.radius = reach
	reach_draw.queue_redraw()

	height += delta * 10

	if global_position.distance_squared_to(camera.offset) > 250 ** 2 and global_position.y > camera.offset.y - 250:
		if danger_timer.is_stopped():
			danger_timer.start()
	else:
		danger_timer.stop()

	if is_grappling:
		grapple.global_position = grapple_pos
		apply_central_force((grapple.global_position - global_position).normalized() * 2000)
		stamina = clampf(stamina - delta * 6 * (exhaustion / 50 + 1), 0, 100)
		exhaustion = clampf(exhaustion + delta * 24, 0, 100)
	else:
		grapple.global_position = get_global_mouse_position()
		stamina = clampf(stamina + delta * 4.5, 0, 100)
		exhaustion = clampf(exhaustion - delta * 48, 0, 100)

	if grapple.get_overlapping_bodies() and Input.is_action_just_pressed("grapple") and not is_stunned and not is_exhausted and get_local_mouse_position().length_squared() <= reach ** 2:
		is_grappling = true
		grapple_pos = get_global_mouse_position()

	if Input.is_action_just_released("grapple"):
		is_grappling = false

	if Input.is_action_just_pressed("use_collectable"):
		if collectable == Collectable.Type.ROPE:
			var rope: StaticBody2D = preload("res://scenes/rope.tscn").instantiate()
			rope.global_position = get_global_mouse_position() + Vector2(0, 48)
			get_tree().root.add_child(rope)

			collectable = Collectable.Type.NULL

		elif collectable == Collectable.Type.BOMB:
			var bomb: RigidBody2D = preload("res://scenes/bomb.tscn").instantiate()
			bomb.global_position = global_position
			bomb.linear_velocity = get_local_mouse_position().normalized() * 200
			get_tree().root.add_child(bomb)

			collectable = Collectable.Type.NULL

		elif collectable == Collectable.Type.SLAP:
			var slap: Area2D = preload("res://scenes/slap.tscn").instantiate()
			slap.global_position = get_global_mouse_position()
			get_tree().root.add_child(slap)

			collectable = Collectable.Type.NULL

	if stamina == 0:
		exhaust()

	_update_collectable_sprite(delta)

func _follow_network_transform(delta: float) -> void:
	if position.distance_squared_to(sync_position) > REMOTE_SNAP_DISTANCE ** 2:
		position = sync_position
		rotation = sync_rotation
		return

	var weight := 1.0 - exp(-REMOTE_SMOOTHING * delta)
	position = position.lerp(sync_position, weight)
	rotation = lerp_angle(rotation, sync_rotation, weight)

func _update_collectable_sprite(delta: float) -> void:
	var displacement = global_position - collectable_sprite.global_position

	var force = displacement * spring_strength
	force -= collectable_vel * damping

	collectable_vel += force * delta
	collectable_sprite.global_position += collectable_vel * delta

	collectable_sprite.global_position += collectable_vel

	if collectable == -1:
		collectable_sprite.visible = false
	else:
		collectable_sprite.frame = collectable
		collectable_sprite.visible = true

func _on_danger_timer_timeout() -> void:
	queue_free()
