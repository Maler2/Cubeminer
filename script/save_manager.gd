extends Node

const WORLDS_DIR = "user://worlds/"

# --- FUNGSI SIMPAN (SEED, HOTBAR, & PLAYER POSITION) ---
func save_world(world_name: String, world_seed: int, hotbar_data: Array = [], player_pos: Vector2 = Vector2.ZERO) -> void:
	if world_name.strip_edges() == "":
		world_name = "My World"
		
	var dir_path = WORLDS_DIR + world_name + "/"
	if not DirAccess.dir_exists_absolute(dir_path):
		DirAccess.make_dir_recursive_absolute(dir_path)
		
	var file_path = dir_path + "info.txt"
	
	# Baca data lama jika ada
	var data_dict: Dictionary = {}
	if FileAccess.file_exists(file_path):
		var file_read = FileAccess.open(file_path, FileAccess.READ)
		if file_read:
			var json_helper = JSON.new()
			if json_helper.parse(file_read.get_as_text()) == OK:
				if json_helper.data is Dictionary:
					data_dict = json_helper.data
			file_read.close()

	# Update data
	if world_seed != 0 or not data_dict.has("seed"):
		data_dict["seed"] = world_seed
	if hotbar_data.size() > 0:
		data_dict["hotbar"] = hotbar_data
	if player_pos != Vector2.ZERO:
		data_dict["player_pos"] = {"x": player_pos.x, "y": player_pos.y}

	# Tulis kembali sebagai JSON
	var file_write = FileAccess.open(file_path, FileAccess.WRITE)
	if file_write:
		file_write.store_string(JSON.stringify(data_dict, "\t"))
		file_write.close()
		print("✅ SaveManager: Berhasil menyimpan posisi player & info dunia ke: ", file_path)
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