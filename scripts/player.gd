extends RigidBody2D
class_name Player

@onready var grapple: Area2D = $Grapple
var is_grappling: bool = false
var grapple_pos: Vector2

func _physics_process(_delta: float) -> void:
	grapple.global_rotation = 0
	
	if is_grappling:
		grapple.global_position = grapple_pos
		apply_central_force((grapple.global_position - global_position).normalized() * 2000)
	else:
		grapple.global_position = get_global_mouse_position()
	
	if grapple.get_overlapping_bodies() and Input.is_action_just_pressed("grapple"):
		is_grappling = true
		grapple_pos = get_global_mouse_position()
	
	if Input.is_action_just_released("grapple"):
		is_grappling = false
