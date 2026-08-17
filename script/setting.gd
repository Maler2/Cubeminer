extends Control

# --- PATH SIMPAN FILE ---
const SAVE_PATH: String = "user://config.json"

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

@onready var master_label: Label = %MasterLabel
@onready var sfx_label: Label = %SFXLabel
@onready var music_label: Label = %MusicLabel

# --- REFERENSI VIDEO SETTING ---
@onready var switch_button: Button = %SwitchButton # VSync
@onready var switch_fps_button: Button = %SwitchFPSButton # Toggle FPS Show

var show_fps: bool = false
var is_loading_settings: bool = false # Flag untuk cegah save berulang saat loading

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
	
	# Set label awal
	_update_label_pct(master_label, master_slider.value if master_slider else 100.0)
	_update_label_pct(sfx_label, sfx_slider.value if sfx_slider else 100.0)
	_update_label_pct(music_label, music_slider.value if music_slider else 100.0)
	
	# Load data yang tersimpan dari JSON (atau set default jika belum ada)
	_load_settings_from_json()
	
	# Connect event slider audio
	if master_slider:
		master_slider.value_changed.connect(func(val): 
			_set_bus_volume("Master", val)
			_update_label_pct(master_label, val)
			_save_settings_to_json()
		)
	if sfx_slider:
		sfx_slider.value_changed.connect(func(val): 
			_set_bus_volume("SFX", val)
			_update_label_pct(sfx_label, val)
			_save_settings_to_json()
		)
	if music_slider:
		music_slider.value_changed.connect(func(val): 
			_set_bus_volume("BGM", val)
			_update_label_pct(music_label, val)
			_save_settings_to_json()
		)
		
	print("--- ✅ PENGATURAN LOG: Inisialisasi Selesai ---")

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
	if switch_button:
		switch_button.toggle_mode = true
		if not switch_button.is_connected("toggled", _on_vsync_toggled):
			switch_button.toggled.connect(_on_vsync_toggled)

	if switch_fps_button:
		switch_fps_button.toggle_mode = true
		if not switch_fps_button.is_connected("toggled", _on_fps_toggled):
			switch_fps_button.toggled.connect(_on_fps_toggled)

func _on_vsync_toggled(toggled_on: bool) -> void:
	_apply_vsync(toggled_on)
	_save_settings_to_json()

func _apply_vsync(enabled: bool) -> void:
	if enabled:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
		if switch_button: 
			switch_button.button_pressed = true
			switch_button.text = "ON"
	else:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
		if switch_button: 
			switch_button.button_pressed = false
			switch_button.text = "OFF"

func _on_fps_toggled(toggled_on: bool) -> void:
	_apply_fps_show(toggled_on)
	_save_settings_to_json()

func _apply_fps_show(enabled: bool) -> void:
	show_fps = enabled
	if switch_fps_button:
		switch_fps_button.button_pressed = enabled
		switch_fps_button.text = "ON" if enabled else "OFF"

	if FpsCounter:
		FpsCounter.set_fps_visible(enabled)

# --- KONTROL AUDIO BUS ---
func _set_bus_volume(bus_name: String, value_0_to_100: float) -> void:
	var bus_idx = AudioServer.get_bus_index(bus_name)
	if bus_idx != -1:
		var normalized_val = max(0.0001, value_0_to_100 / 100.0)
		AudioServer.set_bus_volume_db(bus_idx, linear_to_db(normalized_val))

func _update_label_pct(label: Label, value: float) -> void:
	if label:
		var parts = label.text.split(":")
		var base_name = parts[0].strip_edges()
		if base_name == "":
			base_name = "Volume"
		label.text = base_name + ": " + str(int(value)) + "%"

func _setup_sliders() -> void:
	for slider in [master_slider, sfx_slider, music_slider]:
		if slider:
			slider.min_value = 0.0
			slider.max_value = 100.0
			slider.step = 1.0
			slider.value = 100.0 # Default awal di 100%

# ==========================================
# --- SISTEM SAVE / LOAD SETTING JSON ---
# ==========================================

func _save_settings_to_json() -> void:
	# Abaikan simpan jika proses loading JSON masih berlangsung
	if is_loading_settings:
		return
		
	var config_data: Dictionary = {
		"master_volume": master_slider.value if master_slider else 100.0,
		"sfx_volume": sfx_slider.value if sfx_slider else 100.0,
		"music_volume": music_slider.value if music_slider else 100.0,
		"vsync": switch_button.button_pressed if switch_button else true,
		"show_fps": show_fps
	}
	
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		var json_string = JSON.stringify(config_data, "\t")
		file.store_string(json_string)
		file.close()

func _load_settings_from_json() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		print("ℹ️ File config.json belum ada. Menggunakan settingan default.")
		# Terapkan VSync default ON saat pertama kali main
		_apply_vsync(true)
		return
		
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file:
		var json_string = file.get_as_text()
		file.close()
		
		var json = JSON.new()
		var error = json.parse(json_string)
		if error == OK:
			var data: Dictionary = json.data
			is_loading_settings = true # Aktifkan perlindungan agar sinyal value_changed tidak mentrigger save
			
			# Applied Audio Data
			if master_slider and data.has("master_volume"):
				master_slider.value = data["master_volume"]
				_set_bus_volume("Master", data["master_volume"])
				_update_label_pct(master_label, data["master_volume"])
				
			if sfx_slider and data.has("sfx_volume"):
				sfx_slider.value = data["sfx_volume"]
				_set_bus_volume("SFX", data["sfx_volume"])
				_update_label_pct(sfx_label, data["sfx_volume"])
				
			if music_slider and data.has("music_volume"):
				music_slider.value = data["music_volume"]
				_set_bus_volume("BGM", data["music_volume"])
				_update_label_pct(music_label, data["music_volume"])
				
			# Applied Video Data
			if data.has("vsync"):
				_apply_vsync(data["vsync"])
				
			if data.has("show_fps"):
				_apply_fps_show(data["show_fps"])
				
			is_loading_settings = false # Matikan perlindungan
			print("💾 Log: Berhasil memuat settingan dari config.json!")