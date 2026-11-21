extends RigidBody2D
class_name Player

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
@onready var gouda_sprite: Sprite2D = $GoudaSprite
@onready var audio_gouda: AudioStreamPlayer = $AudioStreamPlayerGouda
@onready var audio_grapple: AudioStreamPlayer = $AudioStreamPlayerGrapple
@onready var audio_exhaust: AudioStreamPlayer = $AudioStreamPlayerExhaust

@onready var collectable_sprite: Sprite2D = $CollectableRoot/CollectableSprite
var spring_strength: float = 1
var damping: float = 10
var collectable_vel := Vector2.ZERO

var collectable := Collectable.Type.NULL

var is_stunned: bool = false
var is_exhausted: bool = false

var reach: float = 400
@onready var reach_draw: ReachDraw = $ReachDraw

var height: float = 0
@onready var camera: Camera2D = get_tree().get_first_node_in_group("camera")

@onready var danger_timer: Timer = $DangerTimer
@onready var exhaustion_timer: Timer = $ExhaustionTimer

var is_gouda: bool = false

@onready var gouda_collisions: Array[CollisionShape2D] = [
	$CollisionGouda1, $CollisionGouda2
]

var is_mobile: bool = false

func _ready() -> void:
	match OS.get_name():
		"Android", "iOS":
			is_mobile = true
			mobile_button.visible = true

func gouda() -> void:
	is_gouda = true
	sprite.visible = false
	gouda_sprite.visible = true
	audio_gouda.play()
	
	gravity_scale = 0.5
	
	for collision in gouda_collisions:
		collision.disabled = false

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
	audio_exhaust.play()
	await get_tree().create_timer(2).timeout
	is_exhausted = false
	sprite.frame = 0

func _physics_process(delta: float) -> void:
	grapple.global_rotation = 0
	
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
		stamina = clampf(stamina - delta * 6 * (exhaustion / 50 + 1) * (2 if is_gouda else 1), 0, 100)
		exhaustion = clampf(exhaustion + delta * 24, 0, 100)
	else:
		grapple.global_position = get_global_mouse_position()
		stamina = clampf(stamina + delta * 4.5, 0, 100)
		exhaustion = clampf(exhaustion - delta * 48, 0, 100)
	
	if is_mobile:
		if grapple.get_overlapping_bodies() and Input.is_action_just_pressed("grapple") and not is_stunned and not is_exhausted and get_local_mouse_position().length_squared() <= reach ** 2 and not mobile_use_collectable:
			is_grappling = true
			grapple_pos = get_global_mouse_position()
			
			audio_grapple.pitch_scale = randf_range(0.8, 1.2)
			audio_grapple.play()
	else:
		if grapple.get_overlapping_bodies() and Input.is_action_just_pressed("grapple") and not is_stunned and not is_exhausted and get_local_mouse_position().length_squared() <= reach ** 2:
			is_grappling = true
			grapple_pos = get_global_mouse_position()
			
			audio_grapple.pitch_scale = randf_range(0.8, 1.2)
			audio_grapple.play()
	
	if Input.is_action_just_released("grapple"):
		is_grappling = false
	
	if Input.is_action_just_pressed("use_collectable") or is_mobile and Input.is_action_just_pressed("grapple") and mobile_use_collectable:
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
		
		elif collectable == Collectable.Type.GOUDA:
			gouda()
			
			collectable = Collectable.Type.NULL
		
		if is_mobile: _on_mobile_button_toggled(false)
	
	if stamina == 0:
		exhaust()
	
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
	get_tree().call_deferred("reload_current_scene")
	
@export var mobile_button: Button
var mobile_use_collectable: bool = false
func _on_mobile_button_toggled(toggled_on: bool) -> void:
	mobile_use_collectable = toggled_on
	mobile_button.text = "use item off" if toggled_on else "use item on"
	
