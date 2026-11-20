extends TileMapLayer

@export var outline_color := Color.BLACK
@export var tilemap_draw: TilemapDraw

func _draw() -> void:
	var tile_size = tile_set.tile_size
	tilemap_draw.alt_tile_rects.clear()
	
	var rng := RandomNumberGenerator.new()
	rng.seed = 2137
	
	for cell in get_used_cells():
		if get_cell_atlas_coords(cell).x != 0:
			continue
		
		var rect = Rect2(map_to_local(cell) - Vector2(tile_size) / 2, tile_size)
		if rng.randi_range(0, 3) == 0:
			tilemap_draw.alt_tile_rects.append({"rect": rect, "color": Color("4f4f4f") if randi_range(0, 1) == 0 else Color("424242")})
		
		if get_cell_atlas_coords(cell + Vector2i.UP).x != 0:
			draw_line(rect.position + Vector2(-1, 0), rect.position + Vector2(tile_size.x + 1, 0), outline_color, 2)
		
		if get_cell_atlas_coords(cell + Vector2i.DOWN).x != 0:
			draw_line(rect.end - Vector2(tile_size.x + 1, 0), rect.end + Vector2(1, 0), outline_color, 2)
		
		if get_cell_atlas_coords(cell + Vector2i.LEFT).x != 0:
			draw_line(rect.position, rect.position + Vector2(0, tile_size.y), outline_color, 2)
		
		if get_cell_atlas_coords(cell + Vector2i.RIGHT).x != 0:
			draw_line(rect.position + Vector2(tile_size.x, 0), rect.end, outline_color, 2)
	
	tilemap_draw.queue_redraw()
