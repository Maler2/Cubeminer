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

# --- SIMPAN BLOK PER CHUNK (16 lebar x TINGGI PENUH) ---
var blocks_dirty: bool = false
var autosave_interval: float = 300.0        # 5 menit
var autosave_timer: float = 0.0

# --- KOMPONEN (PISAH PER TANGGUNG JAWAB) ---
var world_generator = null
var block_interaction = null

# --- SISTEM TIMER HOLD UNTUK TOUCH / HP ---
var touch_timer: Timer
var touch_start_pos: Vector2 = Vector2.ZERO
var touch_target_grid: Vector2i = Vector2i.MIN
var is_holding_touch: bool = false
var touch_index: int = -1
var touch_on_ui: bool = false
var touch_gesture_cancelled: bool = false
@export var hold_duration: float = 1.0  # Waktu tahan (detik) untuk menghancurkan blok
@export var touch_drag_cancel: float = 30.0  # Jarak drag (px) yang membatalkan tahan-hancur

# --- BREAKING ANIMATION OVERLAY ---
var _break_overlay: Sprite2D
var _break_texture: Texture2D
var _break_frame_count: int = 7
var _break_frame_size: Vector2 = Vector2(16, 16)

# --- PC MINING STATE ---
var _pc_mining: bool = false
var _pc_mining_grid: Vector2i = Vector2i.MIN
var _pc_mining_timer: float = 0.0
var _pc_mining_source: int = -1  # 0=fg, 1=bg

func _ready() -> void:
	# Inisialisasi Timer Hold
	touch_timer = Timer.new()
	touch_timer.one_shot = true
	touch_timer.wait_time = hold_duration
	touch_timer.timeout.connect(_on_touch_hold_timeout)
	add_child(touch_timer)
	
	# Breaking animation overlay
	_break_texture = load("res://assets/animation/breaking-animation.png")
	_break_overlay = Sprite2D.new()
	_break_overlay.texture = _break_texture
	_break_overlay.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_break_overlay.region_enabled = true
	_break_overlay.region_rect = Rect2(0, 0, _break_frame_size.x, _break_frame_size.y)
	_break_overlay.z_index = 10
	_break_overlay.visible = false
	add_child(_break_overlay)

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

	# Muat perubahan blok tersimpan (per chunk) SEBELUM terrain digenerate,
	# supaya blok yang dihancurkan/dipasang player dipulihkan dengan benar
	var saved_blocks: Dictionary = SaveManager.load_blocks(world_name)
	destroyed_tiles = saved_blocks.get("destroyed_tiles", {})
	placed_tiles = saved_blocks.get("placed_tiles", {})
	destroyed_bg_tiles = saved_blocks.get("destroyed_bg_tiles", {})
	placed_bg_tiles = saved_blocks.get("placed_bg_tiles", {})

	clear()
	if background_layer:
		background_layer.clear()
		
	call_deferred("inisialisasi_dunia")
	call_deferred("connect_hotbar_signal")

func inisialisasi_dunia() -> void:
	world_generator.inisialisasi_dunia()

func _process(delta: float) -> void:
	if not player: return
	
	# Autosave berkala (5 menit) kalau ada perubahan blok
	if blocks_dirty:
		autosave_timer += delta
		if autosave_timer >= autosave_interval:
			autosave_timer = 0.0
			save_blocks_now()
	
	# PC mining timer
	if _pc_mining:
		var current_grid = local_to_map(to_local(get_global_mouse_position()))
		var fg = get_cell_source_id(_pc_mining_grid)
		var bg = background_layer.get_cell_source_id(_pc_mining_grid) if background_layer else -1
		if (_pc_mining_source == 0 and fg == -1) or (_pc_mining_source == 1 and bg == -1) or current_grid != _pc_mining_grid:
			_stop_pc_mining()
		else:
			_pc_mining_timer += delta
			_update_break_overlay(_pc_mining_grid, _pc_mining_timer)
			if _pc_mining_timer >= hold_duration:
				block_interaction.hancurkan_blok(_pc_mining_grid)
				_stop_pc_mining()
	
	# Touch mining overlay (show while timer is running, before block breaks)
	elif touch_index != -1 and not is_holding_touch and not touch_on_ui and not touch_gesture_cancelled:
		_update_break_overlay(touch_target_grid, touch_timer.wait_time - touch_timer.time_left)
	
	# Indikator tile target
	var target_grid: Vector2i = hovered_grid_pos
	if touch_index != -1:
		if touch_on_ui or touch_gesture_cancelled:
			target_grid.y = min_y_limit - 1
		else:
			target_grid = touch_target_grid
	elif OS.has_feature("mobile"):
		target_grid.y = min_y_limit - 1
	else:
		target_grid = local_to_map(to_local(get_global_mouse_position()))
	if target_grid != hovered_grid_pos:
		hovered_grid_pos = target_grid
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
			touch_index = event.index
			# Deteksi langsung dari posisi sentuhan: kalau di atas tombol UI
			# (gerak/run/jump), batalkan agar tidak ikut hancur/pasang blok.
			# Tidak pakai gui_get_hovered_control() karena tidak andal di HP.
			touch_on_ui = _is_point_over_ui(event.position)
			touch_gesture_cancelled = false
			
			touch_start_pos = event.position
			var touch_world = get_canvas_transform().affine_inverse() * event.position
			touch_target_grid = local_to_map(to_local(touch_world))
			hovered_grid_pos = touch_target_grid
			queue_redraw()
			is_holding_touch = false
			
			if not touch_on_ui:
				touch_timer.start()
		else:
			if event.index != touch_index:
				return
			touch_timer.stop()
			_break_overlay.visible = false
			# Pasang blok HANYA kalau ini gesture baru (tidak ada tahan-hancur
			# sebelumnya) dan tidak dibatalkan oleh drag/jatuh di atas tombol UI.
			if not is_holding_touch and not touch_on_ui and not touch_gesture_cancelled:
				block_interaction.pasang_blok(touch_target_grid)
			is_holding_touch = false
			touch_gesture_cancelled = false
			touch_index = -1

	elif event is InputEventScreenDrag:
		if event.index != touch_index:
			return
		if not touch_on_ui and event.position.distance_to(touch_start_pos) > touch_drag_cancel:
			# Drag jauh = bukan maksud hancur. Batalkan sisa gesture.
			# Jangan reset is_holding_touch: kalau tahan-hancur sudah terlanjur
			# terjadi, release tetap TIDAK boleh memasang blok lagi.
			touch_timer.stop()
			touch_gesture_cancelled = true

	# 🖱️ INPUT MOUSE PC (di HP event mouse hanyalah emulasi dari sentuhan —
	# sudah dimatikan lewat project.godot; guard ini untuk pengaman ganda)
	elif event is InputEventMouseButton:
		if OS.has_feature("mobile"):
			return
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			var mouse_grid = local_to_map(to_local(get_global_mouse_position()))
			var fg = get_cell_source_id(mouse_grid)
			var bg = background_layer.get_cell_source_id(mouse_grid) if background_layer else -1
			if fg != -1 or bg != -1:
				_pc_mining = true
				_pc_mining_grid = mouse_grid
				_pc_mining_timer = 0.0
				_pc_mining_source = 0 if fg != -1 else 1
		elif not event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_stop_pc_mining()
		elif event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
			var mouse_grid = local_to_map(to_local(get_global_mouse_position()))
			block_interaction.pasang_blok(mouse_grid)

func _is_point_over_ui(pos: Vector2) -> bool:
	# Berjalan dari root, cari Control terlihat yang rect-nya memuat posisi.
	# Ini mencakup tombol InputLayer, Hotbar, dll. (rect = ruang koordinat viewport,
	# sama dengan event.position dari sentuhan layar).
	return _ui_contains_point(get_tree().root, pos)

func _ui_contains_point(node: Node, pos: Vector2) -> bool:
	for child in node.get_children():
		if child is Control and child.visible:
			if child.mouse_filter != Control.MOUSE_FILTER_IGNORE:
				if child.get_global_rect().has_point(pos):
					return true
			if _ui_contains_point(child, pos):
				return true
	return false

func _on_touch_hold_timeout() -> void:
	if touch_on_ui:
		return
	is_holding_touch = true
	block_interaction.hancurkan_blok(touch_target_grid)
	_break_overlay.visible = false

func _stop_pc_mining() -> void:
	_pc_mining = false
	_pc_mining_timer = 0.0
	_break_overlay.visible = false

func _update_break_overlay(grid: Vector2i, progress: float) -> void:
	var clamped = clampf(progress / hold_duration, 0.0, 1.0)
	var frame = mini(int(clamped * _break_frame_count), _break_frame_count - 1)
	_break_overlay.region_rect = Rect2(frame * _break_frame_size.x, 0, _break_frame_size.x, _break_frame_size.y)
	_break_overlay.position = map_to_local(grid)
	_break_overlay.visible = true
	if clamped >= 1.0:
		_break_overlay.visible = false

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

# --- SIMPAN PERUBAHAN BLOK KE DISK (PER CHUNK 16 x TINGGI PENUH) ---
func save_blocks_now() -> void:
	if not blocks_dirty:
		return
	var world_name: String = Global.current_world_name
	if world_name.strip_edges() == "":
		world_name = "My World"
	SaveManager.save_blocks(world_name, destroyed_tiles, placed_tiles, destroyed_bg_tiles, placed_bg_tiles)
	blocks_dirty = false
	autosave_timer = 0.0

func _exit_tree() -> void:
	save_blocks_now()
