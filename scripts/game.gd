extends Node2D

@onready var camera: Camera2D = $Camera2D
@onready var tilemap: TileMapLayer = $TileMapLayer
@export var collectables: CollectableSpawner

func _ready() -> void:
	tilemap.clear()
	
	for i in range(3):
		var origin_pos := Vector2i(-5, -8 - 10 * i)
		var pattern_idx: int = randi_range(0, tilemap.tile_set.get_patterns_count() - 1)
		var pattern: TileMapPattern = tilemap.tile_set.get_pattern(pattern_idx)
	
		tilemap.set_pattern(origin_pos, pattern)
	
	collectables.spawn(tilemap)

func _physics_process(delta: float) -> void:
	camera.offset.y -= 30 * delta
