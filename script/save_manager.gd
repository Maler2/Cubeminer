extends Node

const WORLDS_DIR = "user://worlds/"

# Lebar chunk dalam blok (tinggi chunk = penuh dari min_y sampai max_y)
const CHUNK_SIZE: int = 16

# --- FUNGSI SIMPAN (SEED, HOTBAR, & PLAYER POSITION) ---
func save_world(world_name: String, world_seed: int, hotbar_data: Array = [], player_pos: Vector2 = Vector2.ZERO, hotbar_counts: Array = []) -> void:
	if world_name.strip_edges() == "":
		world_name = "My World"
		
	var dir_path = WORLDS_DIR + world_name + "/"
	if not DirAccess.dir_exists_absolute(dir_path):
		DirAccess.make_dir_recursive_absolute(dir_path)
		
	var file_path = dir_path + "info.txt"
	
	# 1. Read data lama jika ada
	var data_dict: Dictionary = {}
	if FileAccess.file_exists(file_path):
		var file_read = FileAccess.open(file_path, FileAccess.READ)
		if file_read:
			var json_helper = JSON.new()
			if json_helper.parse(file_read.get_as_text()) == OK:
				if json_helper.data is Dictionary:
					data_dict = json_helper.data
			file_read.close()

	# 2. Update Seed (FIX BUG SEED 0.0)
	var existing_seed: int = int(data_dict.get("seed", 0))
	
	if world_seed != 0:
		data_dict["seed"] = int(world_seed)
	elif existing_seed != 0:
		data_dict["seed"] = existing_seed
	else:
		data_dict["seed"] = int(randi() % 1000000)

	# 3. Update Hotbar (jika belum ada, buatkan default)
	if hotbar_data.size() > 0:
		data_dict["hotbar"] = hotbar_data
	elif not data_dict.has("hotbar"):
		data_dict["hotbar"] = [-1, -1, -1, -1, -1, -1, -1]

	if hotbar_counts.size() > 0:
		data_dict["hotbar_counts"] = hotbar_counts
	elif not data_dict.has("hotbar_counts"):
		data_dict["hotbar_counts"] = [0, 0, 0, 0, 0, 0, 0]

	# 4. Update Posisi Player (pastikan selalu ada struktur default)
	if player_pos != Vector2.ZERO:
		data_dict["player_pos"] = {"x": player_pos.x, "y": player_pos.y}
	elif not data_dict.has("player_pos"):
		data_dict["player_pos"] = {"x": 0, "y": 0}

	# 5. Tulis kembali sebagai JSON
	var file_write = FileAccess.open(file_path, FileAccess.WRITE)
	if file_write:
		file_write.store_string(JSON.stringify(data_dict, "\t"))
		
		# 🔑 PAKSA OS TULIS KE STORAGE HP SEKARANG JUGA
		file_write.flush()
		file_write.close()
		
		print("✅ SaveManager: Berhasil menyimpan info dunia. Seed: ", data_dict["seed"])
	else:
		print("❌ SaveManager: Gagal menulis file!")

# --- FUNGSI LOAD SEMUA INFO (SEED & HOTBAR) ---
func load_world_info(world_name: String) -> Dictionary:
	if world_name.strip_edges() == "":
		world_name = "My World"
		
	var file_path = WORLDS_DIR + world_name + "/info.txt"
	var default_result = {"seed": 0, "hotbar": [-1, -1, -1, -1, -1, -1, -1]}
	
	if FileAccess.file_exists(file_path):
		var file = FileAccess.open(file_path, FileAccess.READ)
		if file:
			var json_helper = JSON.new()
			var parse_result = json_helper.parse(file.get_as_text())
			file.close()
			
			if parse_result == OK and json_helper.data is Dictionary:
				print("✅ SaveManager: Berhasil memuat info.txt (JSON) untuk dunia '", world_name, "'")
				# Pastikan seed yang dibaca dipaksa konversi ke integer
				if json_helper.data.has("seed"):
					json_helper.data["seed"] = int(json_helper.data["seed"])
				return json_helper.data
				
	return default_result

# --- HELPER KECIL ---
func load_world_seed(world_name: String) -> int:
	var info = load_world_info(world_name)
	return int(info.get("seed", 0))

# --- HELPER LOAD POSISI PLAYER ---
func load_player_position(world_name: String) -> Vector2:
	var info = load_world_info(world_name)
	if info.has("player_pos") and info["player_pos"] is Dictionary:
		var pos_dict = info["player_pos"]
		return Vector2(pos_dict.get("x", 0.0), pos_dict.get("y", 0.0))
	return Vector2.ZERO

# --- CHUNK BLOCK SAVE (16 lebar x TINGGI PENUH) ---

func _chunk_x(coord: Vector2i) -> int:
	return floori(float(coord.x) / float(CHUNK_SIZE))

func _ensure_chunk(chunks: Dictionary, coord: Vector2i) -> Dictionary:
	var key: String = str(_chunk_x(coord))
	if not chunks.has(key):
		chunks[key] = {"dfg": [], "pfg": {}, "dbg": [], "pbg": {}}
	return chunks[key]

# --- FUNGSI SIMPAN PERUBAHAN BLOK (DIKELOMPOKKAN PER CHUNK) ---
func save_blocks(world_name: String, destroyed_tiles: Dictionary, placed_tiles: Dictionary, destroyed_bg_tiles: Dictionary, placed_bg_tiles: Dictionary) -> void:
	if world_name.strip_edges() == "":
		world_name = "My World"
		
	var dir_path = WORLDS_DIR + world_name + "/"
	if not DirAccess.dir_exists_absolute(dir_path):
		DirAccess.make_dir_recursive_absolute(dir_path)
		
	if destroyed_tiles.is_empty() and placed_tiles.is_empty() \
		and destroyed_bg_tiles.is_empty() and placed_bg_tiles.is_empty():
		return
		
	var chunks: Dictionary = {}
	
	for coord in destroyed_tiles:
		var chunk_data = _ensure_chunk(chunks, coord)
		chunk_data["dfg"].append([coord.x, coord.y])
		
	for coord in placed_tiles:
		var chunk_data = _ensure_chunk(chunks, coord)
		chunk_data["pfg"]["%d,%d" % [coord.x, coord.y]] = int(placed_tiles[coord])
		
	for coord in destroyed_bg_tiles:
		var chunk_data = _ensure_chunk(chunks, coord)
		chunk_data["dbg"].append([coord.x, coord.y])
		
	for coord in placed_bg_tiles:
		var chunk_data = _ensure_chunk(chunks, coord)
		chunk_data["pbg"]["%d,%d" % [coord.x, coord.y]] = int(placed_bg_tiles[coord])
		
	var data_dict: Dictionary = {
		"version": 1,
		"chunk_width": CHUNK_SIZE,
		"chunks": chunks
	}
	
	var file_path = dir_path + "blocks.json"
	var file_write = FileAccess.open(file_path, FileAccess.WRITE)
	if file_write:
		file_write.store_string(JSON.stringify(data_dict, "\t"))
		file_write.flush()
		file_write.close()
		print("✅ SaveManager: Berhasil menyimpan blocks.json (", chunks.size(), " chunk)")
	else:
		print("❌ SaveManager: Gagal menulis blocks.json!")

# --- FUNGSI LOAD PERUBAHAN BLOK (DARI blocks.json) ---
func load_blocks(world_name: String) -> Dictionary:
	var result: Dictionary = {
		"destroyed_tiles": {},
		"placed_tiles": {},
		"destroyed_bg_tiles": {},
		"placed_bg_tiles": {}
	}
	if world_name.strip_edges() == "":
		world_name = "My World"
		
	var file_path = WORLDS_DIR + world_name + "/blocks.json"
	if not FileAccess.file_exists(file_path):
		return result
		
	var file = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		return result
		
	var json_helper = JSON.new()
	var parse_result = json_helper.parse(file.get_as_text())
	file.close()
	
	if parse_result != OK or not (json_helper.data is Dictionary):
		return result
		
	var chunks = json_helper.data.get("chunks", {})
	for chunk_key in chunks:
		var chunk_data = chunks[chunk_key]
		if not (chunk_data is Dictionary):
			continue
			
		for tile_pair in chunk_data.get("dfg", []):
			if tile_pair is Array and tile_pair.size() == 2:
				result["destroyed_tiles"][Vector2i(int(tile_pair[0]), int(tile_pair[1]))] = true
				
		for pair_key in chunk_data.get("pfg", {}):
			var parts = String(pair_key).split(",")
			if parts.size() == 2:
				result["placed_tiles"][Vector2i(int(parts[0]), int(parts[1]))] = int(chunk_data["pfg"][pair_key])
				
		for tile_pair in chunk_data.get("dbg", []):
			if tile_pair is Array and tile_pair.size() == 2:
				result["destroyed_bg_tiles"][Vector2i(int(tile_pair[0]), int(tile_pair[1]))] = true
				
		for pair_key in chunk_data.get("pbg", {}):
			var parts = String(pair_key).split(",")
			if parts.size() == 2:
				result["placed_bg_tiles"][Vector2i(int(parts[0]), int(parts[1]))] = int(chunk_data["pbg"][pair_key])
				
	print("✅ SaveManager: Berhasil memuat blocks.json (", chunks.size(), " chunk)")
	return result