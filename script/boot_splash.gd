extends Control

@export var next_scene: PackedScene

@onready var logo: TextureRect = $TextureRect

var total_loaded_files: int = 0
var is_loading_finished: bool = false
var start_time_msec: int = 0

func _ready() -> void:
	get_window().content_scale_factor = 1.0
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	
	# 1. Animasi Fade In Logo
	logo.modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(logo, "modulate:a", 1.0, 0.8)
	
	# 2. Mulai preload aset dari semua folder
	_preload_assets()

func _preload_assets() -> void:
	# Catat waktu awal mulai preload (dalam milidetik)
	start_time_msec = Time.get_ticks_msec()
	
	print("==========================================")
	print("[BootSplash] [%.3fs] Memulai Preload Seluruh Folder Proyek..." % _get_elapsed_time())
	print("==========================================")
	
	total_loaded_files = 0
	
	# Daftar semua folder utama yang ingin di-preload
	var folders_to_load: Array[String] = [
		"res://assets/",
		"res://scene/",
		"res://script/",
		"res://sound/"
	]
	
	# Pindai setiap folder satu per satu
	for folder in folders_to_load:
		if DirAccess.dir_exists_absolute(folder):
			_load_folder_recursive(folder)
	
	print("==========================================")
	print("[BootSplash] [%.3fs] Selesai! Total %d file di-load ke RAM." % [_get_elapsed_time(), total_loaded_files])
	print("==========================================")
	
	# Tandai bahwa loading sudah selesai
	is_loading_finished = true
	
	# Jeda 1 detik agar logo terlihat sebentar sebelum fade out
	await get_tree().create_timer(1.0).timeout
	pindah_ke_scene_berikutnya()

func _load_folder_recursive(path: String) -> void:
	var dir = DirAccess.open(path)
	if not dir:
		return

	dir.list_dir_begin()
	var file_name = dir.get_next()

	while file_name != "":
		if file_name != "." and file_name != "..":
			var full_path = path + file_name
			
			if dir.current_is_dir():
				_load_folder_recursive(full_path + "/")
			else:
				var is_import = file_name.ends_with(".import")
				var is_self = full_path.contains("boot_splash")
				
				# Abaikan file .import dan boot_splash itu sendiri
				if not is_import and not is_self and ResourceLoader.exists(full_path):
					var res = load(full_path)
					if res:
						total_loaded_files += 1
						# Cetak urutan, timestamp detik (3 angka desimal), path file, dan tipe class
						print("[%d] [%.3fs] Loaded: %s (%s)" % [total_loaded_files, _get_elapsed_time(), full_path, res.get_class()])
					
		file_name = dir.get_next()
	dir.list_dir_end()

# Helper function untuk menghitung selisih waktu dalam satuan detik (float)
func _get_elapsed_time() -> float:
	return (Time.get_ticks_msec() - start_time_msec) / 1000.0

func _input(event: InputEvent) -> void:
	# Bolehkan player men-skip HANYA JIKA proses loading sudah selesai
	if is_loading_finished:
		if (event is InputEventScreenTouch or event is InputEventMouseButton or event is InputEventKey) and event.pressed:
			pindah_ke_scene_berikutnya()

func pindah_ke_scene_berikutnya() -> void:
	# Hentikan proses input agar tidak terpanggil ganda
	set_process_input(false)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	# Animasi Fade Out Logo
	var tween = create_tween()
	tween.tween_property(logo, "modulate:a", 0.0, 0.5)
	tween.tween_callback(_ganti_scene)

func _ganti_scene() -> void:
	if next_scene:
		get_tree().change_scene_to_packed(next_scene)
	else:
		push_error("Scene tujuan belum dimasukkan di Inspector!")