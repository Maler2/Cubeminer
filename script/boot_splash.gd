extends Control

@export var next_scene: PackedScene

@onready var logo: TextureRect = $TextureRect
@onready var progress_bar: ProgressBar = $ProgressBar
@onready var audio: AudioStreamPlayer2D = $BootSound

var is_loading_finished: bool = false
var start_time_msec: int = 0

func _ready() -> void:
	start_time_msec = Time.get_ticks_msec()
	get_window().content_scale_factor = 1.0
	FpsCounter.set_fps_offset(Vector2(1, 624))
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	
	_build_version()
	
	if progress_bar:
		progress_bar.value = 0
		progress_bar.visible = true
		
	_mulai_proses_splash()

func _mulai_proses_splash() -> void:
	print("==========================================")
	print("[BootSplash] [%.3fs] Memulai Inisialisasi Booting..." % _get_elapsed_time())
	print("==========================================")
	
	# 1. Cek apakah scene tujuan sudah dimasukkan di Inspector
	if not next_scene:
		print("❌ ERROR FATAL: 'next_scene' belum diisi di Inspector Godot!")
		return

	print("[%.3fs] 📦 Target Scene: %s" % [_get_elapsed_time(), next_scene.resource_path])

	# 2. Animasi Logo Fade In
	logo.modulate.a = 0.0
	var tween_in = create_tween()
	tween_in.tween_property(logo, "modulate:a", 1.0, 0.5)
	
	# 3. Log Tahapan Progres
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
	# Matikan input agar tidak terpanggil 2x
	set_process_input(false)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	# Animasi Fade Out
	var tween_out = create_tween().set_parallel(true)
	tween_out.tween_property(logo, "modulate:a", 0.0, 0.3)
	if progress_bar:
		tween_out.tween_property(progress_bar, "modulate:a", 0.0, 0.3)
		
	# Begitu fade out selesai, panggil _ganti_scene
	tween_out.chain().tween_callback(_ganti_scene)

func _ganti_scene() -> void:
	if next_scene:
		print("[BootSplash] Mengalihkan ke scene: ", next_scene.resource_path)
		get_tree().change_scene_to_packed(next_scene)
	else:
		print("❌ Gagal pindah scene: next_scene bernilai null.")

func _build_version() -> void:
	var version_name: String = ProjectSettings.get_setting("application/config/version")
	var commit_count: int = _get_git_commit_count()
	
	var version_text: String = "v" + str(version_name)
	
	if (version_name.contains("b") or version_name.contains("B")) and (version_name.contains("d") or version_name.contains("D")):
		version_text += " (Beta Dev)"
	elif version_name.contains("b") or version_name.contains("B"):
		version_text += " (Beta)"
	elif version_name.contains("d") or version_name.contains("D"):
		version_text += " (Dev)"
	
	version_text += " | " + str(commit_count) + " commits"
	Global.build_version = version_text

func _get_git_commit_count() -> int:
	# 1. Coba GitHub API (works everywhere with internet)
	var github_count = _fetch_commit_count_from_github()
	if github_count >= 0:
		_save_version_file(str(github_count))
		return github_count

	# 2. Debug PC: ambil dari local git
	if OS.is_debug_build():
		var output: Array = []
		var exit_code = OS.execute("git", ["rev-list", "--count", "HEAD"], output, true)
		if exit_code == 0 and output.size() > 0:
			var count_str: String = output[0].strip_edges()
			_save_version_file(count_str)
			return int(count_str)

	# 3. Fallback: baca version.txt
	if FileAccess.file_exists("res://version.txt"):
		var file = FileAccess.open("res://version.txt", FileAccess.READ)
		if file:
			var count_str = file.get_as_text().strip_edges()
			file.close()
			return int(count_str)

	return 0

func _save_version_file(count_str: String) -> void:
	var file = FileAccess.open("res://version.txt", FileAccess.WRITE)
	if file:
		file.store_string(count_str)
		file.close()

func _fetch_commit_count_from_github() -> int:
	var http = HTTPClient.new()
	var err = http.connect_to_host("api.github.com", 443, TLSOptions.client())
	if err != OK:
		return -1

	var timeout: float = 0.0
	while http.get_status() == HTTPClient.STATUS_CONNECTING:
		http.poll()
		OS.delay_msec(10)
		timeout += 0.01
		if timeout > 3.0:
			http.close()
			return -1

	if http.get_status() != HTTPClient.STATUS_CONNECTED:
		http.close()
		return -1

	var headers = ["User-Agent: Cubeminer", "Accept: application/vnd.github.v3+json"]
	var req_err = http.request(HTTPClient.METHOD_GET, "/repos/Maler2/Cubeminer/commits?per_page=1", headers)
	if req_err != OK:
		http.close()
		return -1

	timeout = 0.0
	while http.get_status() == HTTPClient.STATUS_REQUESTING:
		http.poll()
		OS.delay_msec(10)
		timeout += 0.01
		if timeout > 3.0:
			http.close()
			return -1

	if http.get_status() != HTTPClient.STATUS_BODY:
		http.close()
		return -1

	# Drain response body
	while http.get_status() == HTTPClient.STATUS_BODY:
		http.poll()
		if http.read_response_body_chunk().size() == 0:
			break

	# Parse Link header untuk total count
	var resp_headers = http.get_response_headers()
	http.close()

	for h in resp_headers:
		if h.begins_with("Link:"):
			var link: String = h
			var regex = RegEx.new()
			regex.compile("page=(\\d+)>; rel=\"last\"")
			var result = regex.search(link)
			if result:
				return int(result.get_string(1))

	return -1