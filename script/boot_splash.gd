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