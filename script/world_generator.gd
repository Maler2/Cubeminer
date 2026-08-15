extends RefCounted

var tilemap: TileMapLayer
var background_layer: TileMapLayer

var noise: FastNoiseLite
var dirt_depth_noise: FastNoiseLite
var cave_noise: FastNoiseLite
var ore_noise: FastNoiseLite

var generated_columns: Dictionary = {}
var spawned_trees: Dictionary = {}

func setup(tilemap_ref: TileMapLayer, current_seed: int) -> void:
	tilemap = tilemap_ref
	background_layer = tilemap_ref.background_layer
	
	noise = FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise.seed = current_seed
	noise.frequency = tilemap.frequency
	
	dirt_depth_noise = FastNoiseLite.new()
	dirt_depth_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	dirt_depth_noise.seed = current_seed + 1
	dirt_depth_noise.frequency = 0.05
	
	cave_noise = FastNoiseLite.new()
	cave_noise.noise_type = FastNoiseLite.TYPE_PERLIN
	cave_noise.seed = current_seed + 2
	cave_noise.frequency = tilemap.cave_frequency
	
	ore_noise = FastNoiseLite.new()
	ore_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	ore_noise.seed = current_seed + 3
	ore_noise.frequency = tilemap.ore_frequency

func inisialisasi_dunia() -> void:
	if not tilemap.player:
		var players = tilemap.get_tree().get_nodes_in_group("players")
		if players.size() > 0:
			tilemap.player = players[0] as Node2D

	var player = tilemap.player
	if player:
		player.global_position = Vector2.ZERO
		if "velocity" in player:
			player.velocity = Vector2.ZERO
			
		var height_offset_x0 = int(noise.get_noise_1d(0) * 10.0)
		var surface_y_at_x0 = tilemap.surface_y + height_offset_x0
		
		var tile_size_y: float = 16.0
		if tilemap.tile_set:
			tile_size_y = float(tilemap.tile_set.tile_size.y)
			
		tilemap.position.y = -(surface_y_at_x0 * tile_size_y) + (tile_size_y / 2.0)
		if background_layer:
			background_layer.position.y = tilemap.position.y
		
		var grid_awal = tilemap.local_to_map(tilemap.to_local(Vector2.ZERO))
		update_terrain_around_player(grid_awal)
		tilemap.last_player_grid_pos = grid_awal

func update_terrain_around_player(center_pos: Vector2i) -> void:
	var start_x = center_pos.x - tilemap.render_distance
	var end_x = center_pos.x + tilemap.render_distance
	
	for x in range(start_x, end_x + 1):
		if generated_columns.has(x) and generated_columns[x] == true:
			continue
			
		var height_offset = int(noise.get_noise_1d(x) * 10.0)
		var current_surface_y = tilemap.surface_y + height_offset
		
		var depth_val = dirt_depth_noise.get_noise_1d(x)
		var dirt_depth: int = int(remap(depth_val, -1.0, 1.0, 1.0, 3.99))
		var stone_start_y = current_surface_y + 1 + dirt_depth
		
		for y in range(tilemap.min_y_limit, tilemap.max_y_limit + 1):
			var current_coord = Vector2i(x, y)
			
			var fg_handled = handle_foreground_memory(current_coord)
			var bg_handled = handle_background_memory(current_coord)
			
			if fg_handled and bg_handled:
				continue
				
			if y < current_surface_y:
				if not fg_handled:
					var current_tile = tilemap.get_cell_source_id(current_coord)
					if current_tile != tilemap.leaves_source_id and current_tile != tilemap.wood_source_id:
						tilemap.set_cell(current_coord, -1)
						
					if background_layer:
						var bg_tile = background_layer.get_cell_source_id(current_coord)
						if bg_tile != tilemap.leaves_source_id and bg_tile != tilemap.wood_source_id:
							background_layer.set_cell(current_coord, -1)
			else:
				var bg_id = tilemap.dirt_source_id if y < stone_start_y else tilemap.stone_source_id
				
				if not bg_handled and background_layer:
					background_layer.set_cell(current_coord, bg_id, Vector2i(0, 0))

				if not fg_handled:
					var cave_val = cave_noise.get_noise_2d(x, y)
					
					if cave_val > tilemap.cave_threshold:
						tilemap.set_cell(current_coord, -1)
					elif y == current_surface_y:
						tilemap.set_cell(current_coord, tilemap.grass_source_id, tilemap.grass_atlas_coord)

						if x % 7 == 0 and not spawned_trees.has(x):
							var above_coord = current_coord + Vector2i(0, -1)
							if not tilemap.destroyed_tiles.has(above_coord) and not tilemap.placed_tiles.has(above_coord):
								var random_pattern = randi() % 3
								spawn_tree_pattern(current_coord, random_pattern)
					else:
						var ore_val = abs(ore_noise.get_noise_2d(x, y))
						var is_ore_spawned: bool = false
						var depth_ratio = float(y - current_surface_y) / float(tilemap.max_y_limit - current_surface_y)

						if depth_ratio > 0.70 and ore_val > tilemap.diamond_threshold:
							tilemap.set_cell(current_coord, tilemap.diamond_source_id, tilemap.diamond_atlas_coord)
							is_ore_spawned = true
						elif depth_ratio > 0.45 and ore_val > tilemap.gold_threshold:
							tilemap.set_cell(current_coord, tilemap.gold_source_id, tilemap.gold_atlas_coord)
							is_ore_spawned = true
						elif y >= stone_start_y and ore_val > tilemap.iron_threshold:
							tilemap.set_cell(current_coord, tilemap.iron_source_id, tilemap.iron_atlas_coord)
							is_ore_spawned = true
						elif y >= current_surface_y + 2 and ore_val > tilemap.coal_threshold:
							tilemap.set_cell(current_coord, tilemap.coal_source_id, tilemap.coal_atlas_coord)
							is_ore_spawned = true

						if not is_ore_spawned:
							if y < stone_start_y:
								tilemap.set_cell(current_coord, tilemap.dirt_source_id, tilemap.dirt_atlas_coord)
							else:
								tilemap.set_cell(current_coord, tilemap.stone_source_id, tilemap.stone_atlas_coord)
		
		generated_columns[x] = true

	unload_far_tiles(center_pos.x)

func handle_foreground_memory(coord: Vector2i) -> bool:
	if tilemap.destroyed_tiles.has(coord):
		tilemap.set_cell(coord, -1)
		return true
	if tilemap.placed_tiles.has(coord):
		tilemap.set_cell(coord, tilemap.placed_tiles[coord], Vector2i(0, 0))
		return true
	return false

func handle_background_memory(coord: Vector2i) -> bool:
	if not background_layer: return true
	if tilemap.destroyed_bg_tiles.has(coord):
		background_layer.set_cell(coord, -1)
		return true
	if tilemap.placed_bg_tiles.has(coord):
		background_layer.set_cell(coord, tilemap.placed_bg_tiles[coord], Vector2i(0, 0))
		return true
	return false

func unload_far_tiles(player_x: int) -> void:
	var min_keep_x = player_x - (tilemap.render_distance + 3)
	var max_keep_x = player_x + (tilemap.render_distance + 3)
	var columns_to_erase = []
	
	for x in generated_columns.keys():
		if x < min_keep_x or x > max_keep_x:
			for y in range(tilemap.min_y_limit, tilemap.max_y_limit + 1):
				var coord = Vector2i(x, y)
				if not tilemap.placed_tiles.has(coord) and not tilemap.destroyed_tiles.has(coord):
					tilemap.set_cell(coord, -1)
					if background_layer:
						background_layer.set_cell(coord, -1)
			columns_to_erase.append(x)
			
	for x in columns_to_erase:
		generated_columns.erase(x)
		spawned_trees.erase(x)

func spawn_tree_pattern(surface_coord: Vector2i, pattern_index: int = 0) -> void:
	if not tilemap.tile_set: return
	
	var tree_pattern: TileMapPattern = tilemap.tile_set.get_pattern(pattern_index)
	if not tree_pattern: return
	
	var pattern_size = tree_pattern.get_size()
	var origin_coord = surface_coord + Vector2i(-int(pattern_size.x / 2.0), -pattern_size.y)
	
	for used_cell in tree_pattern.get_used_cells():
		var cell_source_id = tree_pattern.get_cell_source_id(used_cell)
		var cell_atlas_coord = tree_pattern.get_cell_atlas_coords(used_cell)
		var cell_alternative_tile = tree_pattern.get_cell_alternative_tile(used_cell)
		
		if cell_source_id != -1:
			var target_coord = origin_coord + used_cell
			tilemap.set_cell(target_coord, cell_source_id, cell_atlas_coord, cell_alternative_tile)
			
	spawned_trees[surface_coord.x] = true
