extends TileMapLayer

# --- HOTBAR & NOTIFIKASI ---
@export var hotbar_slots: Array[int] = [-1, -1, -1, -1, -1, -1, -1]

var item_names: Dictionary = {
	1: "Rumput",
	2: "Tanah",
	3: "Batu",
	4: "Coal",
	5: "Iron",
	6: "Emas",
	7: "Berlian",
	8: "Kayu",
	9: "Daun"
}

# --- REFERENSI BACKGROUND TILEMAP ---
@export var background_layer: TileMapLayer

# --- BATAS JANGKAUAN PLAYER ---
@export_group("Jangkauan Aksi")
@export var max_build_distance: int = 4

# --- CHUNK ---
@export var render_distance: int = 30

var generated_columns: Dictionary = {}
var last_player_grid_pos: Vector2i

# --- PENGATURAN TILESET ---
@export_group("Tileset Settings")
@export var grass_source_id: int = 1
@export var grass_atlas_coord: Vector2i = Vector2i(0, 0)

@export var dirt_source_id: int = 2
@export var dirt_atlas_coord: Vector2i = Vector2i(0, 0)

@export var stone_source_id: int = 3
@export var stone_atlas_coord: Vector2i = Vector2i(0, 0)

# --- TREE SETTINGS ---
@export var wood_source_id: int = 8
@export var leaves_source_id: int = 9

# ⛏️ PENGATURAN ORE (ID 4 - 7)
@export_group("Ore Settings")
@export var coal_source_id: int = 4
@export var coal_atlas_coord: Vector2i = Vector2i(0, 0)

@export var iron_source_id: int = 5
@export var iron_atlas_coord: Vector2i = Vector2i(0, 0)

@export var gold_source_id: int = 6
@export var gold_atlas_coord: Vector2i = Vector2i(0, 0)

@export var diamond_source_id: int = 7
@export var diamond_atlas_coord: Vector2i = Vector2i(0, 0)

# --- BATAS TINGGI DUNIA ---
@export_group("Batas Tinggi Dunia")
@export var min_y_limit: int = 0
@export var surface_y: int = 64
@export var max_y_limit: int = 128

# --- PENGATURAN GENERASI DINAMIS ---
@export_group("Generator Dinamis")
@export var player: Node2D
@export_range(-1.0, 1.0) var spawn_threshold: float = -0.1
@export var frequency: float = 0.025

# --- PENGATURAN GUA ---
@export_group("Generator Gua")
@export var cave_threshold: float = 0.25
@export var cave_frequency: float = 0.05

# ⛏️ FREKUENSI SPAWN ORE
@export_group("Ore Generator Thresholds")
@export var ore_frequency: float = 0.15
@export var coal_threshold: float = 0.45
@export var iron_threshold: float = 0.55
@export var gold_threshold: float = 0.63
@export var diamond_threshold: float = 0.70

# --- PENGATURAN OUTLINE & DEV ---
@export_group("Outline Selection")
@export var color_destroy: Color = Color(1.0, 0.2, 0.2, 0.8)
@export var color_place: Color = Color(0.2, 1.0, 0.2, 0.8)
@export var line_thickness: float = 2.0

@export_group("Dev Settings")
@export var dev_mode: bool = true
@export var debug_font_size: int = 12

# --- SCENE DROPPED ITEM ---
var dropped_item_scene = preload("res://scene/dropped_item.tscn")

# --- VARIABEL HOTBAR & SELEKSI BLOK ---
var selected_block_id: int = 2
var hovered_grid_pos: Vector2i

var noise: FastNoiseLite
var dirt_depth_noise: FastNoiseLite
var cave_noise: FastNoiseLite
var ore_noise: FastNoiseLite

# --- MEMORI RUBAHAN PLAYER ---
var destroyed_tiles: Dictionary = {}        # Foreground hancur
var placed_tiles: Dictionary = {}           # Foreground dipasang
var destroyed_bg_tiles: Dictionary = {}     # Background hancur
var placed_bg_tiles: Dictionary = {}        # Background dipasang

# Array untuk menyimpan posisi pohon yang sudah pernah di-spawn
var spawned_trees: Dictionary = {}

# --- SISTEM TIMER HOLD UNTUK TOUCH / HP ---
var touch_timer: Timer
var touch_start_pos: Vector2 = Vector2.ZERO
var touch_target_grid: Vector2i = Vector2i.MIN
var is_holding_touch: bool = false
@export var hold_duration: float = 0.25  # Waktu tahan (detik) untuk menghancurkan blok

func _ready() -> void:
	# Inisialisasi Timer Hold
	touch_timer = Timer.new()
	touch_timer.one_shot = true
	touch_timer.wait_time = hold_duration
	touch_timer.timeout.connect(_on_touch_hold_timeout)
	add_child(touch_timer)

	# Ambil Nama & Seed dari Global
	var world_name: String = Global.current_world_name
	var current_seed: int = Global.current_world_seed
	var current_temp_seed: String = Global.current_temp_seed_text
	
	if world_name == "":
		world_name = "My World"
		
	var seed_file_path = "user://worlds/" + world_name + "/seed.txt"
	if FileAccess.file_exists(seed_file_path):
		var file = FileAccess.open(seed_file_path, FileAccess.READ)
		if file:
			current_seed = file.get_as_text().to_int()
			file.close()
	elif current_seed == 0:
		current_seed = randi()

	if current_temp_seed == "":
		current_temp_seed = str(current_seed)

	seed(current_seed)
	
	noise = FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise.seed = current_seed
	noise.frequency = frequency
	
	dirt_depth_noise = FastNoiseLite.new()
	dirt_depth_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	dirt_depth_noise.seed = current_seed + 1
	dirt_depth_noise.frequency = 0.05
	
	cave_noise = FastNoiseLite.new()
	cave_noise.noise_type = FastNoiseLite.TYPE_PERLIN
	cave_noise.seed = current_seed + 2
	cave_noise.frequency = cave_frequency
	
	ore_noise = FastNoiseLite.new()
	ore_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	ore_noise.seed = current_seed + 3
	ore_noise.frequency = ore_frequency
	
	clear()
	if background_layer:
		background_layer.clear()
		
	call_deferred("inisialisasi_dunia")
	call_deferred("connect_hotbar_signal")

func _process(_delta: float) -> void:
	if not player: return
	
	var mouse_grid = local_to_map(to_local(get_global_mouse_position()))
	if mouse_grid != hovered_grid_pos:
		hovered_grid_pos = mouse_grid
		queue_redraw()
		
	var current_player_grid = local_to_map(to_local(player.global_position))
	if current_player_grid != last_player_grid_pos:
		update_terrain_around_player(current_player_grid)
		last_player_grid_pos = current_player_grid

func inisialisasi_dunia() -> void:
	if not player:
		var players = get_tree().get_nodes_in_group("players")
		if players.size() > 0:
			player = players[0] as Node2D

	if player:
		player.global_position = Vector2.ZERO
		if "velocity" in player:
			player.velocity = Vector2.ZERO
			
		var height_offset_x0 = int(noise.get_noise_1d(0) * 10.0)
		var surface_y_at_x0 = surface_y + height_offset_x0
		
		var tile_size_y: float = 16.0
		if tile_set:
			tile_size_y = float(tile_set.tile_size.y)
			
		position.y = -(surface_y_at_x0 * tile_size_y) + (tile_size_y / 2.0)
		if background_layer:
			background_layer.position.y = position.y
		
		var grid_awal = local_to_map(to_local(Vector2.ZERO))
		update_terrain_around_player(grid_awal)
		last_player_grid_pos = grid_awal

# --- LOGIKA GENERASI TERRAIN, BACKGROUND & MEMORI ---
func update_terrain_around_player(center_pos: Vector2i) -> void:
	var start_x = center_pos.x - render_distance
	var end_x = center_pos.x + render_distance
	
	for x in range(start_x, end_x + 1):
		if generated_columns.has(x) and generated_columns[x] == true:
			continue
			
		var height_offset = int(noise.get_noise_1d(x) * 10.0)
		var current_surface_y = surface_y + height_offset
		
		var depth_val = dirt_depth_noise.get_noise_1d(x)
		var dirt_depth: int = int(remap(depth_val, -1.0, 1.0, 1.0, 3.99))
		var stone_start_y = current_surface_y + 1 + dirt_depth
		
		for y in range(min_y_limit, max_y_limit + 1):
			var current_coord = Vector2i(x, y)
			
			var fg_handled = handle_foreground_memory(current_coord)
			var bg_handled = handle_background_memory(current_coord)
			
			if fg_handled and bg_handled:
				continue
				
			if y < current_surface_y:
				if not fg_handled:
					var current_tile = get_cell_source_id(current_coord)
					if current_tile != leaves_source_id and current_tile != wood_source_id:
						set_cell(current_coord, -1)
						
					if background_layer:
						var bg_tile = background_layer.get_cell_source_id(current_coord)
						if bg_tile != leaves_source_id and bg_tile != wood_source_id:
							background_layer.set_cell(current_coord, -1)
			else:
				var bg_id = dirt_source_id if y < stone_start_y else stone_source_id
				
				if not bg_handled and background_layer:
					background_layer.set_cell(current_coord, bg_id, Vector2i(0, 0))

				if not fg_handled:
					var cave_val = cave_noise.get_noise_2d(x, y)
					
					if cave_val > cave_threshold:
						set_cell(current_coord, -1)
					elif y == current_surface_y:
						set_cell(current_coord, grass_source_id, grass_atlas_coord)

						if x % 7 == 0 and not spawned_trees.has(x):
							var above_coord = current_coord + Vector2i(0, -1)
							if not destroyed_tiles.has(above_coord) and not placed_tiles.has(above_coord):
								var random_pattern = randi() % 3
								spawn_tree_pattern(current_coord, random_pattern)
					else:
						var ore_val = abs(ore_noise.get_noise_2d(x, y))
						var is_ore_spawned: bool = false
						var depth_ratio = float(y - current_surface_y) / float(max_y_limit - current_surface_y)

						if depth_ratio > 0.70 and ore_val > diamond_threshold:
							set_cell(current_coord, diamond_source_id, diamond_atlas_coord)
							is_ore_spawned = true
						elif depth_ratio > 0.45 and ore_val > gold_threshold:
							set_cell(current_coord, gold_source_id, gold_atlas_coord)
							is_ore_spawned = true
						elif y >= stone_start_y and ore_val > iron_threshold:
							set_cell(current_coord, iron_source_id, iron_atlas_coord)
							is_ore_spawned = true
						elif y >= current_surface_y + 2 and ore_val > coal_threshold:
							set_cell(current_coord, coal_source_id, coal_atlas_coord)
							is_ore_spawned = true

						if not is_ore_spawned:
							if y < stone_start_y:
								set_cell(current_coord, dirt_source_id, dirt_atlas_coord)
							else:
								set_cell(current_coord, stone_source_id, stone_atlas_coord)
		
		generated_columns[x] = true

	unload_far_tiles(center_pos.x)

func handle_foreground_memory(coord: Vector2i) -> bool:
	if destroyed_tiles.has(coord):
		set_cell(coord, -1)
		return true
	if placed_tiles.has(coord):
		set_cell(coord, placed_tiles[coord], Vector2i(0, 0))
		return true
	return false

func handle_background_memory(coord: Vector2i) -> bool:
	if not background_layer: return true
	if destroyed_bg_tiles.has(coord):
		background_layer.set_cell(coord, -1)
		return true
	if placed_bg_tiles.has(coord):
		background_layer.set_cell(coord, placed_bg_tiles[coord], Vector2i(0, 0))
		return true
	return false

func unload_far_tiles(player_x: int) -> void:
	var min_keep_x = player_x - (render_distance + 3)
	var max_keep_x = player_x + (render_distance + 3)
	var columns_to_erase = []
	
	for x in generated_columns.keys():
		if x < min_keep_x or x > max_keep_x:
			for y in range(min_y_limit, max_y_limit + 1):
				var coord = Vector2i(x, y)
				if not placed_tiles.has(coord) and not destroyed_tiles.has(coord):
					set_cell(coord, -1)
					if background_layer:
						background_layer.set_cell(coord, -1)
			columns_to_erase.append(x)
			
	for x in columns_to_erase:
		generated_columns.erase(x)
		spawned_trees.erase(x)

# --- INPUT & LOGIKA PASANG / HANCUR (TAP & HOLD SUPPORT) ---
func _input(event: InputEvent) -> void:
	# 📱 INPUT LAYAR SENTUH HP
	if event is InputEventScreenTouch:
		if event.pressed:
			touch_start_pos = event.position
			var touch_world = get_canvas_transform().affine_inverse() * event.position
			touch_target_grid = local_to_map(to_local(touch_world))
			hovered_grid_pos = touch_target_grid
			is_holding_touch = false
			
			touch_timer.start()
		else:
			touch_timer.stop()
			if not is_holding_touch:
				pasang_blok(touch_target_grid)
			is_holding_touch = false

	elif event is InputEventScreenDrag:
		if event.position.distance_to(touch_start_pos) > 15.0:
			touch_timer.stop()
			is_holding_touch = false

	# 🖱️ INPUT MOUSE PC
	elif event is InputEventMouseButton and event.pressed:
		var mouse_grid = local_to_map(to_local(get_global_mouse_position()))
		if event.button_index == MOUSE_BUTTON_RIGHT:
			pasang_blok(mouse_grid)
		elif event.button_index == MOUSE_BUTTON_LEFT:
			hancurkan_blok(mouse_grid)

func _on_touch_hold_timeout() -> void:
	is_holding_touch = true
	hancurkan_blok(touch_target_grid)

func pasang_blok(grid_pos: Vector2i = Vector2i.MIN) -> void:
	if not player: return
	if grid_pos == Vector2i.MIN:
		grid_pos = local_to_map(to_local(get_global_mouse_position()))
		
	var player_grid_pos = local_to_map(to_local(player.global_position))
	
	if not is_in_range_box(player_grid_pos, grid_pos): return
	if grid_pos.y < min_y_limit or grid_pos.y > max_y_limit: return
	
	var fg_id = get_cell_source_id(grid_pos)
	var bg_id = background_layer.get_cell_source_id(grid_pos) if background_layer else -1

	# 1. Pasang BACKGROUND jika background masih kosong
	if bg_id == -1 and background_layer:
		if destroyed_bg_tiles.has(grid_pos): destroyed_bg_tiles.erase(grid_pos)
		placed_bg_tiles[grid_pos] = selected_block_id
		background_layer.set_cell(grid_pos, selected_block_id, Vector2i(0, 0))
		queue_redraw()

	# 2. Pasang FOREGROUND jika background sudah ada & foreground kosong
	elif fg_id == -1:
		var player_head_grid = player_grid_pos + Vector2i(0, -1)
		if grid_pos == player_grid_pos or grid_pos == player_head_grid: return

		if destroyed_tiles.has(grid_pos): destroyed_tiles.erase(grid_pos)
		placed_tiles[grid_pos] = selected_block_id
		set_cell(grid_pos, selected_block_id, Vector2i(0, 0))
		queue_redraw()

func hancurkan_blok(grid_pos: Vector2i = Vector2i.MIN) -> void:
	if not player: return
	if grid_pos == Vector2i.MIN:
		grid_pos = local_to_map(to_local(get_global_mouse_position()))
		
	var player_grid_pos = local_to_map(to_local(player.global_position))
	
	if not is_in_range_box(player_grid_pos, grid_pos): return

	var fg_id = get_cell_source_id(grid_pos)
	var bg_id = background_layer.get_cell_source_id(grid_pos) if background_layer else -1

	# Prioritas 1: Hancurkan Foreground
	if fg_id != -1:
		if placed_tiles.has(grid_pos): placed_tiles.erase(grid_pos)
		destroyed_tiles[grid_pos] = true
		set_cell(grid_pos, -1)
		spawn_dropped_item(grid_pos, fg_id)
		queue_redraw()
		
	# Prioritas 2: Hancurkan Background
	elif bg_id != -1 and background_layer:
		if placed_bg_tiles.has(grid_pos): placed_bg_tiles.erase(grid_pos)
		destroyed_bg_tiles[grid_pos] = true
		background_layer.set_cell(grid_pos, -1)
		spawn_dropped_item(grid_pos, bg_id)
		queue_redraw()

func spawn_dropped_item(grid_pos: Vector2i, tile_id: int) -> void:
	if not dropped_item_scene: return
	
	var item_instance = dropped_item_scene.instantiate()
	var world_pos = map_to_local(grid_pos)
	item_instance.global_position = to_global(world_pos)
	
	var item_texture: Texture2D = null
	if tile_set and tile_set.has_source(tile_id):
		var source = tile_set.get_source(tile_id) as TileSetAtlasSource
		if source:
			item_texture = source.texture
	
	get_parent().add_child(item_instance)
	
	if item_instance.has_method("setup_item"):
		item_instance.setup_item(tile_id, item_texture)

func is_in_range_box(player_grid: Vector2i, target_grid: Vector2i) -> bool:
	return abs(player_grid.x - target_grid.x) <= max_build_distance and abs(player_grid.y - target_grid.y) <= max_build_distance

func _draw() -> void:
	if not player: return
	var player_grid_pos = local_to_map(to_local(player.global_position))

	if hovered_grid_pos.y >= min_y_limit and hovered_grid_pos.y <= max_y_limit:
		if is_in_range_box(player_grid_pos, hovered_grid_pos):
			var tile_size = Vector2(16, 16)
			if tile_set: tile_size = Vector2(tile_set.tile_size)

			var tile_local_center = map_to_local(hovered_grid_pos)
			var rect = Rect2(tile_local_center - (tile_size / 2.0), tile_size)
			
			var fg_exist = get_cell_source_id(hovered_grid_pos) != -1
			var bg_exist = background_layer and background_layer.get_cell_source_id(hovered_grid_pos) != -1
			
			var is_block_exist = fg_exist or bg_exist
			draw_rect(rect, color_destroy if is_block_exist else color_place, false, line_thickness)

func _on_hotbar_slot_changed(_index: int, tile_id: int) -> void:
	selected_block_id = tile_id

func connect_hotbar_signal() -> void:
	var hotbar = get_tree().root.find_child("HotbarUI", true, false)
	if hotbar:
		if not hotbar.slot_changed.is_connected(_on_hotbar_slot_changed):
			hotbar.slot_changed.connect(_on_hotbar_slot_changed)

func spawn_tree_pattern(surface_coord: Vector2i, pattern_index: int = 0) -> void:
	if not tile_set: return
	
	var tree_pattern: TileMapPattern = tile_set.get_pattern(pattern_index)
	if not tree_pattern: return
	
	var pattern_size = tree_pattern.get_size()
	var origin_coord = surface_coord + Vector2i(-int(pattern_size.x / 2.0), -pattern_size.y)
	
	for used_cell in tree_pattern.get_used_cells():
		var cell_source_id = tree_pattern.get_cell_source_id(used_cell)
		var cell_atlas_coord = tree_pattern.get_cell_atlas_coords(used_cell)
		var cell_alternative_tile = tree_pattern.get_cell_alternative_tile(used_cell)
		
		if cell_source_id != -1:
			var target_coord = origin_coord + used_cell
			set_cell(target_coord, cell_source_id, cell_atlas_coord, cell_alternative_tile)
			
	spawned_trees[surface_coord.x] = true

func add_item_to_hotbar(tile_id: int) -> bool:
	var hotbar_ui = get_tree().root.find_child("HotbarUI", true, false)
	if hotbar_ui and hotbar_ui.has_method("add_item_to_hotbar"):
		return hotbar_ui.add_item_to_hotbar(tile_id)
		
	return false