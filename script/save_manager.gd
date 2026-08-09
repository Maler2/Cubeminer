extends Node

# --- FITUR SIMPAN SEED DUNIA ---
func save_seed(seed_value: int, world_name: String) -> void:
	var clean_world_name = world_name.strip_edges()
	if clean_world_name.is_empty():
		print("⚠️ Gagal simpan seed: Nama World kosong!")
		return

	var world_folder = "user://worlds/" + clean_world_name
	if not DirAccess.dir_exists_absolute(world_folder):
		DirAccess.make_dir_recursive_absolute(world_folder)

	# Simpan seed ke file seed.json di folder world terkait
	var save_path = world_folder + "/seed.json"
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	if file:
		var seed_data = {
			"world_seed": seed_value
		}
		var json_string = JSON.stringify(seed_data, "\t")
		file.store_string(json_string)
		file.close()
		print("✅ Seed (", seed_value, ") berhasil disimpan untuk world: ", clean_world_name)
	else:
		print("❌ Gagal menyimpan seed.json! Error: ", FileAccess.get_open_error())


# --- FITUR LOAD SEED DUNIA ---
func load_seed(world_name: String) -> int:
	var clean_world_name = world_name.strip_edges()
	var save_path = "user://worlds/" + clean_world_name + "/seed.json"

	if not FileAccess.file_exists(save_path):
		print("ℹ️ File seed.json tidak ditemukan untuk world: ", clean_world_name)
		return 0

	var file = FileAccess.open(save_path, FileAccess.READ)
	if file:
		var json_string = file.get_as_text()
		file.close()

		var json = JSON.new()
		if json.parse(json_string) == OK:
			return int(json.data.get("world_seed", 0))

	return 0