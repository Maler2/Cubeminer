extends CanvasLayer

@export var fps_offset: Vector2 = Vector2(10, 10)

@onready var fps_label: Label = $Label
var is_active: bool = false

func _ready() -> void:
	_apply_offset()
	# BACA MEMORY CONFIG (FPS + VSYNC) SEJAK GAME AWAL JALAN
	_load_config_on_startup()

func _process(_delta: float) -> void:
	if is_active and fps_label:
		var fps = Engine.get_frames_per_second()
		fps_label.text = "FPS: " + str(int(fps))
		
		if fps >= 60:
			fps_label.modulate = Color.GREEN
		elif fps >= 30:
			fps_label.modulate = Color.YELLOW
		else:
			fps_label.modulate = Color.RED

# --- FUNGSI MENGATUR OFFSET / POSISI ---
func set_fps_offset(new_offset: Vector2) -> void:
	fps_offset = new_offset
	_apply_offset()

func _apply_offset() -> void:
	if fps_label:
		fps_label.position = fps_offset

func set_fps_visible(enabled: bool) -> void:
	is_active = enabled
	visible = enabled

func set_fps_label_scale(new_scale: float) -> void:
	if fps_label:
		fps_label.scale = Vector2(new_scale, new_scale)

# --- FUNGSI LOAD CONFIG (FPS & VSYNC) SAAT GAME PERTAMA KALI DIBUKA ---
func _load_config_on_startup() -> void:
	var save_path = "user://config.json"
	if FileAccess.file_exists(save_path):
		var file = FileAccess.open(save_path, FileAccess.READ)
		if file:
			var json = JSON.new()
			if json.parse(file.get_as_text()) == OK:
				var data: Dictionary = json.data
				
				# 1. Apply FPS Show Setting
				if data.has("show_fps"):
					set_fps_visible(data["show_fps"])
					
				# 2. Apply VSync Setting Otomatis saat Startup
				if data.has("vsync"):
					_apply_vsync_mode(data["vsync"])
			file.close()
	else:
		set_fps_visible(false)

# --- FUNGSI VSYNC HELPER ---
func _apply_vsync_mode(enabled: bool) -> void:
	if enabled:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
	else:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)