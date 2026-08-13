extends Control

# --- REFERENSI UI ---
@onready var back_button: Button = %BackButton
@onready var sound_button: Button = %SoundButton
@onready var video_button: Button = %VideoButton

# --- REFERENSI HALAMAN ---
@onready var audio_page: VBoxContainer = %AudioPage
@onready var video_page: VBoxContainer = %VideoPage

# --- REFERENSI SLIDER AUDIO ---
@onready var master_slider: HSlider = %MasterSlider
@onready var sfx_slider: HSlider = %SFXSlider
@onready var music_slider: HSlider = %MusicSlider

# --- REFERENSI VIDEO SETTING ---
@onready var switch_button: Button = %SwitchButton # VSync
@onready var switch_fps_button: Button = %SwitchFPSButton # Toggle FPS Show
@onready var fps_label: Label = %FPSLabel # Label teks FPS di pojok layar

var show_fps: bool = false

func _ready() -> void:
	print("--- 🛠️ PENGATURAN LOG: Memulai Inisialisasi Settings ---")
	_check_node_status()
	
	# Connect tombol navigasi
	if sound_button and not sound_button.is_connected("pressed", _on_sound_button_pressed):
		sound_button.pressed.connect(_on_sound_button_pressed)
	if video_button and not video_button.is_connected("pressed", _on_video_button_pressed):
		video_button.pressed.connect(_on_video_button_pressed)
	if back_button and not back_button.is_connected("pressed", _on_back_button_pressed):
		back_button.pressed.connect(_on_back_button_pressed)
	
	_setup_sliders()
	_setup_video_settings()
	
	# Connect event slider audio
	if master_slider:
		master_slider.value_changed.connect(func(val): _set_bus_volume("Master", val))
	if sfx_slider:
		sfx_slider.value_changed.connect(func(val): _set_bus_volume("SFX", val))
	if music_slider:
		music_slider.value_changed.connect(func(val): _set_bus_volume("BGM", val))
		
	print("--- ✅ PENGATURAN LOG: Inisialisasi Selesai ---")

func _process(_delta: float) -> void:
	# Update angka FPS tiap frame HANYA jika opsinya dinyalakan
	if show_fps and fps_label:
		fps_label.text = "FPS: " + str(Engine.get_frames_per_second())

# --- FUNGSI LOG UNTUK PENGECEKAN SELURUH NODE ---
func _check_node_status() -> void:
	print("📌 Status BackButton: ", "OK" if back_button else "❌ NULL")
	print("📌 Status SoundButton: ", "OK" if sound_button else "❌ NULL")
	print("📌 Status VideoButton: ", "OK" if video_button else "❌ NULL")
	print("---")
	print("📌 Status AudioPage: ", "OK" if audio_page else "❌ NULL")
	print("📌 Status VideoPage: ", "OK" if video_page else "❌ NULL")
	print("---")
	print("📌 Status MasterSlider: ", "OK" if master_slider else "❌ NULL")
	print("📌 Status SFXSlider: ", "OK" if sfx_slider else "❌ NULL")
	print("📌 Status MusicSlider: ", "OK" if music_slider else "❌ NULL")
	print("---")
	print("📌 Status SwitchButton (VSync): ", "OK" if switch_button else "❌ NULL")
	print("📌 Status SwitchFPSButton: ", "OK" if switch_fps_button else "❌ NULL")
	print("📌 Status FPSLabel: ", "OK" if fps_label else "❌ NULL")

# --- FUNGSI TOMBOL NAVIGASI TAB ---
func _on_sound_button_pressed() -> void:
	if audio_page: audio_page.visible = true
	if video_page: video_page.visible = false

func _on_video_button_pressed() -> void:
	if audio_page: audio_page.visible = false
	if video_page: video_page.visible = true

func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scene/MainMenu.tscn")

# --- KONTROL VIDEO & FPS ---
func _setup_video_settings() -> void:
	# 1. Setup VSync
	if switch_button:
		switch_button.toggle_mode = true
		var is_vsync_on = DisplayServer.window_get_vsync_mode() == DisplayServer.VSYNC_ENABLED
		switch_button.button_pressed = is_vsync_on
		switch_button.text = "ON" if is_vsync_on else "OFF"
		if not switch_button.is_connected("toggled", _on_vsync_toggled):
			switch_button.toggled.connect(_on_vsync_toggled)

	# 2. Setup FPS Show Switch
	if switch_fps_button:
		switch_fps_button.toggle_mode = true
		switch_fps_button.button_pressed = show_fps
		switch_fps_button.text = "ON" if show_fps else "OFF"
		if not switch_fps_button.is_connected("toggled", _on_fps_toggled):
			switch_fps_button.toggled.connect(_on_fps_toggled)
			
	if fps_label:
		fps_label.visible = show_fps

func _on_vsync_toggled(toggled_on: bool) -> void:
	if toggled_on:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
		switch_button.text = "ON"
	else:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
		switch_button.text = "OFF"

func _on_fps_toggled(toggled_on: bool) -> void:
	show_fps = toggled_on
	if switch_fps_button:
		switch_fps_button.text = "ON" if toggled_on else "OFF"
	if fps_label:
		fps_label.visible = toggled_on
	print("📊 Tampilan FPS: ", "ON" if toggled_on else "OFF")

# --- KONTROL AUDIO BUS ---
func _set_bus_volume(bus_name: String, value_0_to_100: float) -> void:
	var bus_idx = AudioServer.get_bus_index(bus_name)
	if bus_idx != -1:
		var normalized_val = max(0.0001, value_0_to_100 / 100.0)
		AudioServer.set_bus_volume_db(bus_idx, linear_to_db(normalized_val))

func _setup_sliders() -> void:
	for slider in [master_slider, sfx_slider, music_slider]:
		if slider:
			slider.min_value = 0.0
			slider.max_value = 100.0
			slider.step = 1.0

	if master_slider:
		master_slider.value = db_to_linear(AudioServer.get_bus_volume_db(0)) * 100.0
	
	var sfx_idx = AudioServer.get_bus_index("SFX")
	if sfx_idx != -1 and sfx_slider:
		sfx_slider.value = db_to_linear(AudioServer.get_bus_volume_db(sfx_idx)) * 100.0
		
	var bgm_idx = AudioServer.get_bus_index("BGM")
	if bgm_idx != -1 and music_slider:
		music_slider.value = db_to_linear(AudioServer.get_bus_volume_db(bgm_idx)) * 100.0
