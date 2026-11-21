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

	if grapple.get_overlapping_bodies() and Input.is_action_just_pressed("grapple"):
		is_grappling = true
		grapple_pos = get_global_mouse_position()

	if Input.is_action_just_released("grapple"):
		is_grappling = false
