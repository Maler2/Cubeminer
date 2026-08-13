extends Control

@export_file("*.tscn") var target_scene_path: String = "res://scene/game.tscn"

# Kecepatan pengisian bar (semakin besar semakin cepat)
@export var fill_speed: float = 1.5
@export var delay_after_full: float = 0.3

# --- DAFTAR TIPS ACAK ---
@export var tips_list: Array[String] = [
	"Tips: Hancurkan blok batu untuk mendapatkan bahan bangunan yang lebih kuat!",
	"Tips: Ore langka seperti Berlian lebih sering ditemukan di kedalaman bawah tanah.",
	"Tips: Gunakan Hotbar untuk berpindah blok dengan cepat.",
	"Tips: Dinding latar (Background) bisa dipasang di area yang kosong.",
	"Tips: Pohon tidak akan tumbuh di area yang tertutup oleh blok lain."
]

@onready var progress_bar: ProgressBar = $ProgressBar
@onready var label_status: Label = $Label
@onready var label_tips: Label = $LabelTips # 💡 Node Label untuk Tips

# --- PERBAIKAN DI SINI: Dihapus : Array[float] nya ---
var progress: Array = []
var target_progress: float = 0.0
var current_display_progress: float = 0.0
var is_loaded: bool = false
var packed_scene: PackedScene = null

func _ready() -> void:
	get_window().content_scale_factor = 4.0
	FpsCounter.set_fps_label_scale(0.25)
	FpsCounter.set_fps_offset(Vector2(1, 156))
	progress_bar.value = 0.0
	
	# 💡 Tampilkan tips acak saat loading screen muncul
	tampilkan_tips_acak()
	
	if target_scene_path.is_empty():
		print("⚠️ Target scene belum diisi!")
		return
		
	ResourceLoader.load_threaded_request(target_scene_path)

func tampilkan_tips_acak() -> void:
	if label_tips and tips_list.size() > 0:
		# Pick acak satu pesan dari tips_list
		var random_index = randi() % tips_list.size()
		label_tips.text = tips_list[random_index]

func _process(delta: float) -> void:
	if target_scene_path.is_empty(): return
	
	# 1. Update status loading
	if not is_loaded:
		var status = ResourceLoader.load_threaded_get_status(target_scene_path, progress)
		
		if status == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			if progress.size() > 0:
				target_progress = progress[0] * 100.0
				
		elif status == ResourceLoader.THREAD_LOAD_LOADED:
			target_progress = 100.0
			packed_scene = ResourceLoader.load_threaded_get(target_scene_path) as PackedScene
			is_loaded = true
			
		elif status == ResourceLoader.THREAD_LOAD_FAILED:
			label_status.text = "Gagal memuat scene!"
			set_process(false)
			return

	# 2. Gerakkan progress bar secara halus
	current_display_progress = move_toward(current_display_progress, target_progress, fill_speed * 100.0 * delta)
	progress_bar.value = current_display_progress

	# 3. Pindah scene setelah bar 100%
	if is_loaded and current_display_progress >= 100.0:
		set_process(false)
		label_status.text = "Done!"
		
		await get_tree().create_timer(delay_after_full).timeout
		
		if packed_scene:
			get_tree().change_scene_to_packed(packed_scene)