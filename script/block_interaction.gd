extends RefCounted

var tilemap: TileMapLayer
var background_layer: TileMapLayer

func setup(tilemap_ref: TileMapLayer) -> void:
	tilemap = tilemap_ref
	background_layer = tilemap_ref.background_layer

func pasang_blok(grid_pos: Vector2i = Vector2i.MIN) -> void:
	if not tilemap.player: return
	if grid_pos == Vector2i.MIN:
		grid_pos = tilemap.local_to_map(tilemap.to_local(tilemap.get_global_mouse_position()))
		
	var player_grid_pos = tilemap.local_to_map(tilemap.to_local(tilemap.player.global_position))
	
	if not is_in_range_box(player_grid_pos, grid_pos): return
	if grid_pos.y < tilemap.min_y_limit or grid_pos.y > tilemap.max_y_limit: return
	
	var fg_id = tilemap.get_cell_source_id(grid_pos)
	var bg_id = background_layer.get_cell_source_id(grid_pos) if background_layer else -1

	if bg_id == -1 and background_layer:
		if tilemap.destroyed_bg_tiles.has(grid_pos): tilemap.destroyed_bg_tiles.erase(grid_pos)
		tilemap.placed_bg_tiles[grid_pos] = tilemap.selected_block_id
		background_layer.set_cell(grid_pos, tilemap.selected_block_id, Vector2i(0, 0))
		tilemap.queue_redraw()

	elif fg_id == -1:
		var player_head_grid = player_grid_pos + Vector2i(0, -1)
		if grid_pos == player_grid_pos or grid_pos == player_head_grid: return

		if tilemap.destroyed_tiles.has(grid_pos): tilemap.destroyed_tiles.erase(grid_pos)
		tilemap.placed_tiles[grid_pos] = tilemap.selected_block_id
		tilemap.set_cell(grid_pos, tilemap.selected_block_id, Vector2i(0, 0))
		tilemap.queue_redraw()

func hancurkan_blok(grid_pos: Vector2i = Vector2i.MIN) -> void:
	if not tilemap.player: return
	if grid_pos == Vector2i.MIN:
		grid_pos = tilemap.local_to_map(tilemap.to_local(tilemap.get_global_mouse_position()))
		
	var player_grid_pos = tilemap.local_to_map(tilemap.to_local(tilemap.player.global_position))
	
	if not is_in_range_box(player_grid_pos, grid_pos): return

	var fg_id = tilemap.get_cell_source_id(grid_pos)
	var bg_id = background_layer.get_cell_source_id(grid_pos) if background_layer else -1

	if fg_id != -1:
		if tilemap.placed_tiles.has(grid_pos): tilemap.placed_tiles.erase(grid_pos)
		tilemap.destroyed_tiles[grid_pos] = true
		tilemap.set_cell(grid_pos, -1)
		spawn_dropped_item(grid_pos, fg_id)
		tilemap.queue_redraw()
		
	elif bg_id != -1 and background_layer:
		if tilemap.placed_bg_tiles.has(grid_pos): tilemap.placed_bg_tiles.erase(grid_pos)
		tilemap.destroyed_bg_tiles[grid_pos] = true
		background_layer.set_cell(grid_pos, -1)
		spawn_dropped_item(grid_pos, bg_id)
		tilemap.queue_redraw()

func spawn_dropped_item(grid_pos: Vector2i, tile_id: int) -> void:
	if not tilemap.dropped_item_scene: return
	
	var item_instance = tilemap.dropped_item_scene.instantiate()
	var world_pos = tilemap.map_to_local(grid_pos)
	item_instance.global_position = tilemap.to_global(world_pos)
	
	var item_texture: Texture2D = null
	if tilemap.tile_set and tilemap.tile_set.has_source(tile_id):
		var source = tilemap.tile_set.get_source(tile_id) as TileSetAtlasSource
		if source:
			item_texture = source.texture
	
	tilemap.get_parent().add_child(item_instance)
	
	if item_instance.has_method("setup_item"):
		item_instance.setup_item(tile_id, item_texture)

func is_in_range_box(player_grid: Vector2i, target_grid: Vector2i) -> bool:
	return abs(player_grid.x - target_grid.x) <= tilemap.max_build_distance and abs(player_grid.y - target_grid.y) <= tilemap.max_build_distance
