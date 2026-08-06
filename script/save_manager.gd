extends Node

# --- FITUR SIMPAN DATA DUNIA (JSON) ---
func save_world_data(player_pos: Vector2, modified_tiles: Array) -> void:
	var world_name = Global.current_world_name.strip_edges()
	if world_name.is_empty():
		print("⚠️ Gagal simpan: Nama World kosong!")
		return

	var world_folder = "user://worlds/" + world_name
	if not DirAccess.dir_exists_absolute(world_folder):
		DirAccess.make_dir_recursive_absolute(world_folder)

	# Format data yang akan disimpan
	var save_dict = {
		"player_position": {
			"x": player_pos.x,
			"y": player_pos.y
		},
		"modified_tiles": modified_tiles # Format: [{"coords": [x, y], "layer": 0, "tile_id": -1}, ...]
	}

	var save_path = world_folder + "/world_data.json"
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	if file:
		var json_string = JSON.stringify(save_dict, "\t")
		file.store_string(json_string)
		file.close()
		print("✅ Data World & Player berhasil disimpan ke JSON!")
	else:
		print("❌ Gagal menyimpan world_data.json! Error: ", FileAccess.get_open_error())


# --- FITUR LOAD DATA DUNIA (JSON) ---
func load_world_data() -> Dictionary:
	var world_name = Global.current_world_name.strip_edges()
	var save_path = "user://worlds/" + world_name + "/world_data.json"

	if not FileAccess.file_exists(save_path):
		print("ℹ️ File world_data.json tidak ditemukan (Dunia Baru).")
		return {}

	var file = FileAccess.open(save_path, FileAccess.READ)
	if file:
		var json_string = file.get_as_text()
		file.close()

		var json = JSON.new()
		var parse_result = json.parse(json_string)
		if parse_result == OK:
			print("✅ Data World & Player berhasil dimuat dari JSON!")
			return json.data
		else:
			print("❌ Error parsing JSON! Line: ", json.get_error_line(), " Msg: ", json.get_error_message())

	return {}