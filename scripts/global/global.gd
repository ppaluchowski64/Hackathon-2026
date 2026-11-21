extends Node

@onready var story_sprite: Sprite2D = get_tree().get_first_node_in_group("story")

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	story_sprite.visible = true
	get_tree().paused = true

func _physics_process(_delta: float) -> void:
	if Input.is_action_just_pressed("grapple") and story_sprite:
		story_sprite.visible = false
		get_tree().paused = false
