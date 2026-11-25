extends Node

@onready var story_sprite: Sprite2D = get_tree().get_first_node_in_group("story")
@onready var story_rect: ColorRect = get_tree().get_first_node_in_group("story_rect")

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
#	story_sprite.visible = true
#	story_rect.visible = true
	# get_tree().paused = true

func _physics_process(_delta: float) -> void:
	if Input.is_action_just_pressed("grapple") and story_sprite and story_rect:
		story_sprite.visible = false
		story_rect.visible = false
		get_tree().paused = false
