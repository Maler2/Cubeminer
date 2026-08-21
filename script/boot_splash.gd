extends Control

@export var next_scene: PackedScene

@onready var logo: TextureRect = $TextureRect
@onready var progress_bar: ProgressBar = $ProgressBar
@onready var audio: AudioStreamPlayer2D = $BootSound

var is_loading_finished: bool = false
var start_time_msec: int = 0
var _http: HTTPRequest

func _ready() -> void:
	start_time_msec = Time.get_ticks_msec()
	get_window().content_scale_factor = 1.0
	FpsCounter.set_fps_offset(Vector2(1, 624))
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	
	_apply_saved_volume()
	_build_version()
	
	if progress_bar:
		progress_bar.value = 0
		progress_bar.visible = true
		
	_mulai_proses_splash()

func _mulai_proses_splash() -> void:
	print("==========================================")
	print("[BootSplash] [%.3fs] Memulai Inisialisasi Booting..." % _get_elapsed_time())
	print("==========================================")
	
	if not next_scene:
		print("ERROR FATAL: 'next_scene' belum diisi di Inspector Godot!")
		return

	print("[%.3fs] Target Scene: %s" % [_get_elapsed_time(), next_scene.resource_path])

	logo.modulate.a = 0.0
	var tween_in = create_tween()
	tween_in.tween_property(logo, "modulate:a", 1.0, 0.5)
	
	_update_progress(25.0, "Memuat Konfigurasi & State...")
	await get_tree().create_timer(0.2).timeout
	
	_update_progress(60.0, "Memverifikasi Aset Scene...")
	await get_tree().create_timer(0.3).timeout
	
	_update_progress(100.0, "Selesai! Mempersiapkan Pindah Scene...")
	await get_tree().create_timer(0.2).timeout
	
	print("==========================================")
	print("[BootSplash] [%.3fs] Booting Selesai!" % _get_elapsed_time())
	print("==========================================")
	
	is_loading_finished = true
	
	if audio and audio.playing:
		await audio.finished
	
	pindah_ke_scene_berikutnya()

func _update_progress(val: float, message: String) -> void:
	if progress_bar:
		progress_bar.value = val
	print("[%d%%] [%.3fs] %s" % [int(val), _get_elapsed_time(), message])

func _get_elapsed_time() -> float:
	return (Time.get_ticks_msec() - start_time_msec) / 1000.0

func _input(event: InputEvent) -> void:
	if is_loading_finished:
		if (event is InputEventScreenTouch or event is InputEventMouseButton or event is InputEventKey) and event.pressed:
			pindah_ke_scene_berikutnya()

func pindah_ke_scene_berikutnya() -> void:
	set_process_input(false)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	var tween_out = create_tween().set_parallel(true)
	tween_out.tween_property(logo, "modulate:a", 0.0, 0.3)
	if progress_bar:
		tween_out.tween_property(progress_bar, "modulate:a", 0.0, 0.3)
		
	tween_out.chain().tween_callback(_ganti_scene)

func _ganti_scene() -> void:
	if next_scene:
		print("[BootSplash] Mengalihkan ke scene: ", next_scene.resource_path)
		get_tree().change_scene_to_packed(next_scene)
	else:
		print("Gagal pindah scene: next_scene bernilai null.")

func _apply_saved_volume() -> void:
	var config_path = "user://config.json"
	if not FileAccess.file_exists(config_path):
		return
	var file = FileAccess.open(config_path, FileAccess.READ)
	if not file:
		return
	var json = JSON.new()
	var err = json.parse(file.get_as_text())
	file.close()
	if err != OK:
		return
	var data = json.data
	if not data is Dictionary:
		return
	var bus_names = {"master_volume": "Master", "sfx_volume": "SFX", "music_volume": "Music"}
	for key in bus_names:
		if data.has(key):
			var bus_idx = AudioServer.get_bus_index(bus_names[key])
			if bus_idx != -1:
				var val = max(0.0001, float(data[key]) / 100.0)
				AudioServer.set_bus_volume_db(bus_idx, linear_to_db(val))

func _build_version() -> void:
	var version_name: String = ProjectSettings.get_setting("application/config/version")
	var commit_count: int = _read_version_file()
	
	_set_build_version(version_name, commit_count)
	_fetch_commit_count_async(version_name)

func _set_build_version(version_name: String, commit_count: int) -> void:
	var version_text: String = "v" + str(version_name)
	
	if (version_name.contains("b") or version_name.contains("B")) and (version_name.contains("d") or version_name.contains("D")):
		version_text += " (Beta Dev)"
	elif version_name.contains("b") or version_name.contains("B"):
		version_text += " (Beta)"
	elif version_name.contains("d") or version_name.contains("D"):
		version_text += " (Dev)"
	
	version_text += " | " + str(commit_count) + " commits"
	Global.build_version = version_text

func _read_version_file() -> int:
	for path in ["user://version.txt", "res://version.txt"]:
		if FileAccess.file_exists(path):
			var file = FileAccess.open(path, FileAccess.READ)
			if file:
				var count_str = file.get_as_text().strip_edges()
				file.close()
				if count_str.is_valid_int():
					return int(count_str)
	return 0

func _save_version_file(count_str: String) -> void:
	var file = FileAccess.open("user://version.txt", FileAccess.WRITE)
	if file:
		file.store_string(count_str)
		file.close()

func _fetch_commit_count_async(version_name: String) -> void:
	_http = HTTPRequest.new()
	add_child(_http)
	_http.request_completed.connect(_on_github_response.bind(version_name))
	var err = _http.request(
		"https://api.github.com/repos/Maler2/Cubeminer/commits?per_page=1",
		["User-Agent: Cubeminer", "Accept: application/vnd.github.v3+json"]
	)
	if err != OK:
		_http.queue_free()

func _on_github_response(result: int, code: int, _headers: PackedStringArray, body: PackedByteArray, version_name: String) -> void:
	if _http:
		_http.queue_free()
		_http = null
	
	if result != HTTPRequest.RESULT_SUCCESS or code != 200:
		return
	
	var text: String = body.get_string_from_utf8()
	var data = JSON.parse_string(text)
	if not data is Array or data.size() == 0:
		return
	
	# Parse Link header dari _headers untuk total count
	for h in _headers:
		if h.begins_with("Link:"):
			var regex = RegEx.new()
			regex.compile("page=(\\d+)>; rel=\"last\"")
			var match = regex.search(h)
			if match:
				var count = int(match.get_string(1))
				_save_version_file(str(count))
				_set_build_version(version_name, count)
				print("[BootSplash] GitHub commit count: ", count)
				return
