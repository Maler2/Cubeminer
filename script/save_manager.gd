extends Node

# Path folder penyimpanan dunia
const WORLDS_DIR = "user://worlds/"

# --- FUNGSI MENYIMPAN SEED & DATA DUNIA ---
func save_world(world_name: String, world_seed: int) -> void:
	if world_name.strip_edges() == "":
		world_name = "My World"
		
	var dir_path = WORLDS_DIR + world_name + "/"
	
	# Buat folder jika belum ada
	if not DirAccess.dir_exists_absolute(dir_path):
		DirAccess.make_dir_recursive_absolute(dir_path)
		
	var file_path = dir_path + "seed.txt"
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	
	if file:
		# Simpan seed sebagai String angka yang bersih
		file.store_string(str(world_seed))
		file.close()
		print("✅ SaveManager: Berhasil menyimpan seed [", world_seed, "] ke: ", file_path)
	else:
		print("❌ SaveManager: Gagal membuka file untuk menulis! Error code: ", FileAccess.get_open_error())

# --- FUNGSI MEMUAT SEED ---
func load_world_seed(world_name: String) -> int:
	if world_name.strip_edges() == "":
		world_name = "My World"
		
	var file_path = WORLDS_DIR + world_name + "/seed.txt"
	
	if FileAccess.file_exists(file_path):
		var file = FileAccess.open(file_path, FileAccess.READ)
		if file:
			var content = file.get_as_text().strip_edges()
			file.close()
			
			# Pastikan teks tidak kosong sebelum diubah ke integer
			if content.is_valid_int():
				var loaded_seed = content.to_int()
				print("✅ SaveManager: Berhasil memuat seed [", loaded_seed, "] dari file.")
				return loaded_seed
			else:
				print("⚠️ SaveManager: Isi file seed bukan angka valid ('", content, "'). Refactor ke angka acak.")
	else:
		print("⚠️ SaveManager: File seed tidak ditemukan di: ", file_path)
		
	return 0 # Fallback jika file tidak ada