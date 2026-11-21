extends Node2D
class_name CollectableSpawner

func spawn(tilemap: TileMapLayer) -> void:
	var y: int = -4
	while y > -30:
		var tile_pos: Vector2 = Vector2(randi_range(-8, 7), y)
		var dir: float = -1 if randi_range(0, 1) == 0 else 1
		
		while tilemap.get_cell_atlas_coords(tile_pos).x == 0:
			tile_pos.x += dir
		
		var col := Collectable.instantiate()
		col.global_position = Vector2(16, 16) + tile_pos * 32
		add_child(col)
		
		y -= randi_range(7, 15)
