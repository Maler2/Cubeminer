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

# --- PENGATURAN MOB ---
@export_group("Mob Settings")
@export var mob_spawn_chance: float = 0.12
@export var max_active_mobs: int = 12

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
var last_player_grid_pos: Vector2i

# --- MEMORI RUBAHAN PLAYER ---
var destroyed_tiles: Dictionary = {}        # Foreground hancur
var placed_tiles: Dictionary = {}           # Foreground dipasang
var destroyed_bg_tiles: Dictionary = {}     # Background hancur
var placed_bg_tiles: Dictionary = {}        # Background dipasang

# --- KOMPONEN (PISAH PER TANGGUNG JAWAB) ---
var world_generator = null
var block_interaction = null

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

	# Buat komponen
	world_generator = preload("res://script/world_generator.gd").new()
	world_generator.setup(self, current_seed)
	block_interaction = preload("res://script/block_interaction.gd").new()
	block_interaction.setup(self)

	clear()
	if background_layer:
		background_layer.clear()
		
	call_deferred("inisialisasi_dunia")
	call_deferred("connect_hotbar_signal")

func inisialisasi_dunia() -> void:
	world_generator.inisialisasi_dunia()

func _process(_delta: float) -> void:
	if not player: return
	
	var mouse_grid = local_to_map(to_local(get_global_mouse_position()))
	if mouse_grid != hovered_grid_pos:
		hovered_grid_pos = mouse_grid
		queue_redraw()
		
	var current_player_grid = local_to_map(to_local(player.global_position))
	if current_player_grid != last_player_grid_pos:
		world_generator.update_terrain_around_player(current_player_grid)
		last_player_grid_pos = current_player_grid

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
				block_interaction.pasang_blok(touch_target_grid)
			is_holding_touch = false

	elif event is InputEventScreenDrag:
		if event.position.distance_to(touch_start_pos) > 15.0:
			touch_timer.stop()
			is_holding_touch = false

	# 🖱️ INPUT MOUSE PC
	elif event is InputEventMouseButton and event.pressed:
		var mouse_grid = local_to_map(to_local(get_global_mouse_position()))
		if event.button_index == MOUSE_BUTTON_RIGHT:
			block_interaction.pasang_blok(mouse_grid)
		elif event.button_index == MOUSE_BUTTON_LEFT:
			block_interaction.hancurkan_blok(mouse_grid)

func _on_touch_hold_timeout() -> void:
	is_holding_touch = true
	block_interaction.hancurkan_blok(touch_target_grid)

# --- FUNGSI PEMBANTU UNTUK KOMPONEN ---
func pasang_blok(grid_pos: Vector2i = Vector2i.MIN) -> void:
	block_interaction.pasang_blok(grid_pos)

func hancurkan_blok(grid_pos: Vector2i = Vector2i.MIN) -> void:
	block_interaction.hancurkan_blok(grid_pos)

func is_in_range_box(player_grid: Vector2i, target_grid: Vector2i) -> bool:
	return block_interaction.is_in_range_box(player_grid, target_grid)

func add_item_to_hotbar(tile_id: int) -> bool:
	var hotbar_ui = get_tree().root.find_child("HotbarUI", true, false)
	if hotbar_ui and hotbar_ui.has_method("add_item_to_hotbar"):
		return hotbar_ui.add_item_to_hotbar(tile_id)
		
	return false

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
