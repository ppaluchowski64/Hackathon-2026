extends Node2D

@export var player: Player
var size := Vector2(400, 50)
var sub_size := Vector2(350, 20)

func _draw() -> void:
	draw_rect(Rect2((960 - sub_size.x) / 2, 50, sub_size.x, sub_size.y).grow(4), Color("#000000"))
	draw_rect(Rect2((960 - sub_size.x) / 2, 50, sub_size.x, sub_size.y), Color("#322947"))
	draw_rect(Rect2((960 - sub_size.x) / 2, 50, sub_size.x * player.exhaustion / 100, sub_size.y), Color("#ff9166"))
	
	draw_rect(Rect2((960 - size.x) / 2, 0, size.x, size.y).grow(4), Color("#000000"))
	draw_rect(Rect2((960 - size.x) / 2, 0, size.x, size.y), Color("#322947"))
	draw_rect(Rect2((960 - size.x) / 2, 0, size.x * player.stamina / 100, size.y), Color("#8fde5d"))

func _physics_process(_delta: float) -> void:
	if not player:
		return
	
	queue_redraw()
