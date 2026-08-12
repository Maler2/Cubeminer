extends Control

@export var next_scene: PackedScene

@onready var logo: TextureRect = $TextureRect
@onready var progress_bar: ProgressBar = $ProgressBar # Pastikan Node ProgressBar ada di Scene

var total_loaded_files: int = 0
var total_files_to_load: int = 0
var is_loading_finished: bool = false
var start_time_msec: int = 0

func _ready() -> void:
	get_window().content_scale_factor = 1.0
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	
	if progress_bar:
		progress_bar.value = 0
		progress_bar.visible = true
	
	# 1. Animasi Fade In Logo
	logo.modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(logo, "modulate:a", 1.0, 0.8)
	
	# 2. Mulai preload aset dari semua folder
	_preload_assets()

func _preload_assets() -> void:
	start_time_msec = Time.get_ticks_msec()
	
	print("==========================================")
	print("[BootSplash] [%.3fs] Memulai Preload Seluruh Folder Proyek..." % _get_elapsed_time())
	print("==========================================")
	
	var folders_to_load: Array[String] = [
		"res://assets/",
		"res://scene/",
		"res://script/",
		"res://sound/"
	]
	
	# Step A: Hitung total semua file dulu agar Progress Bar punya nilai max
	total_files_to_load = 0
	for folder in folders_to_load:
		if DirAccess.dir_exists_absolute(folder):
			total_files_to_load += _count_files_recursive(folder)
			
	total_loaded_files = 0
	
	# Step B: Mulai load file satu per satu seperti biasa
	for folder in folders_to_load:
		if DirAccess.dir_exists_absolute(folder):
			await _load_folder_recursive(folder)
	
	print("==========================================")
	print("[BootSplash] [%.3fs] Selesai! Total %d file di-load ke RAM." % [_get_elapsed_time(), total_loaded_files])
	print("==========================================")
	
	is_loading_finished = true
	
	await get_tree().create_timer(1.0).timeout
	pindah_ke_scene_berikutnya()

# Fungsi untuk menghitung total file di awal
func _count_files_recursive(path: String) -> int:
	var count = 0
	var dir = DirAccess.open(path)
	if not dir:
		return 0

	dir.list_dir_begin()
	var file_name = dir.get_next()

	while file_name != "":
		if file_name != "." and file_name != "..":
			var full_path = path + file_name
			if dir.current_is_dir():
				count += _count_files_recursive(full_path + "/")
			else:
				var is_import = file_name.ends_with(".import")
				var is_self = full_path.contains("boot_splash")
				if not is_import and not is_self and ResourceLoader.exists(full_path):
					count += 1
		file_name = dir.get_next()
	dir.list_dir_end()
	return count

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
				await _load_folder_recursive(full_path + "/")
			else:
				var is_import = file_name.ends_with(".import")
				var is_self = full_path.contains("boot_splash")
				
				if not is_import and not is_self and ResourceLoader.exists(full_path):
					var res = load(full_path)
					if res:
						total_loaded_files += 1
						print("[%d/%d] [%.3fs] Loaded: %s (%s)" % [total_loaded_files, total_files_to_load, _get_elapsed_time(), full_path, res.get_class()])
						
						# Update nilai progress bar
						if progress_bar and total_files_to_load > 0:
							progress_bar.value = (float(total_loaded_files) / float(total_files_to_load)) * 100.0
						
						# Beri jeda 1 frame agar tampilan UI sempat ter-update di layar
						await get_tree().process_frame
					
		file_name = dir.get_next()
	dir.list_dir_end()

func _get_elapsed_time() -> float:
	return (Time.get_ticks_msec() - start_time_msec) / 1000.0

func _input(event: InputEvent) -> void:
	if is_loading_finished:
		if (event is InputEventScreenTouch or event is InputEventMouseButton or event is InputEventKey) and event.pressed:
			pindah_ke_scene_berikutnya()

func pindah_ke_scene_berikutnya() -> void:
	set_process_input(false)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	var tween = create_tween().set_parallel(true)
	tween.tween_property(logo, "modulate:a", 0.0, 0.5)
	if progress_bar:
		tween.tween_property(progress_bar, "modulate:a", 0.0, 0.5)
		
	tween.chain().tween_callback(_ganti_scene)

func _ganti_scene() -> void:
	if next_scene:
		get_tree().change_scene_to_packed(next_scene)
	else:
		push_error("Scene tujuan belum dimasukkan di Inspector!")