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
		if has_node("PlayerName"):
			$PlayerName.text = value

@onready var sprite: Sprite2D = $Sprite2D

@onready var collectable_sprite: Sprite2D = $CollectableRoot/CollectableSprite
var spring_strength: float = 1
var damping: float = 10
var collectable_vel := Vector2.ZERO

var collectable := Collectable.Type.NULL

var is_stunned: bool = false

func stun() -> void:
	is_stunned = true
	sprite.frame = 2
	await get_tree().create_timer(1).timeout
	is_stunned = false
	sprite.frame = 0

func _physics_process(delta: float) -> void:
	grapple.global_rotation = 0
	
	if is_grappling:
		grapple.global_position = grapple_pos
		apply_central_force((grapple.global_position - global_position).normalized() * 2000)
		stamina = clampf(stamina - delta * 6 * (exhaustion / 50 + 1), 0, 100)
		exhaustion = clampf(exhaustion + delta * 24, 0, 100)
	else:
		grapple.global_position = get_global_mouse_position()
		stamina = clampf(stamina + delta * 4.5, 0, 100)
		exhaustion = clampf(exhaustion - delta * 48, 0, 100)
	
	if grapple.get_overlapping_bodies() and Input.is_action_just_pressed("grapple") and not is_stunned:
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
			bomb.linear_velocity = get_local_mouse_position().normalized() * 500
			get_tree().root.add_child(bomb)
			
			collectable = Collectable.Type.NULL
		
		elif collectable == Collectable.Type.SLAP:
			var slap: Area2D = preload("res://scenes/slap.tscn").instantiate()
			slap.global_position = get_global_mouse_position()
			get_tree().root.add_child(slap)
			
			collectable = Collectable.Type.NULL
	
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
