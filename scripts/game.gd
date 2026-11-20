extends Node2D

@onready var camera: Camera2D = $Camera2D

func _physics_process(delta: float) -> void:
	camera.offset.y -= 10 * delta
