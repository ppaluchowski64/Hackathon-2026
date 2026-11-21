extends CanvasLayer

@export var player: Player

@onready var reach_label: Label = $ReachLabel
@onready var height_label: Label = $HeightLabel
@onready var color_rect: ColorRect = $ColorRect
@onready var notion_label: Label = $ColorRect/NotionLabel

func _physics_process(_delta: float) -> void:
	if not player:
		return
	
	reach_label.text = "reach: %d" % player.reach
	height_label.text = "height: %d" % player.height
	
	color_rect.visible = player.danger_timer.time_left > 0
	notion_label.text = "out of reach! get back in %.2f" % player.danger_timer.time_left
