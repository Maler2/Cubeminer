extends Control

@onready var title_label: Label = $ButtonLayer/VBoxContainer/TitleLabel
@onready var play_button: Button = $ButtonLayer/VBoxContainer/PlayButton
@onready var setting_button: Button = $ButtonLayer/VBoxContainer/SettingButton
@onready var quit_button: Button = $ButtonLayer/VBoxContainer/QuitButton
@onready var version_label: Label = $UILayer/VersionLabel

# Node kamera untuk menggeser background
@onready var camera: Camera2D = $Camera2D

# ⚙️ PENGATURAN CAMERA LOOP
@export var scroll_speed: float = 30.0 # Kecepatan geser kamera (pixel/detik)
@export var start_x: float = -896.0  # Koordinat paling kiri
@export var reset_x: float = 2048.0  # Koordinat paling kanan (titik loop)

func _ready() -> void:
	get_window().content_scale_factor = 1.0
	FpsCounter.set_fps_label_scale(1.0)
	
	# Ambil nama game dari Project Settings
	var game_name: String = ProjectSettings.get_setting("application/config/name")
	if game_name != "":
		title_label.text = game_name

	var version_name: String = ProjectSettings.get_setting("application/config/version")

	if version_name == "":
		version_label.text = "vnull"
	elif (version_name.contains("b") or version_name.contains("B")) and (version_name.contains("d") or version_name.contains("D")):
		version_label.text = "v" + str(version_name) + " (Beta Development)"
	elif version_name.contains("b") or version_name.contains("B"):
		# Jika ada huruf 'b' atau 'B' (misal: "1.0b")
		version_label.text = "v" + str(version_name) + " (Beta)"
	elif version_name.contains("d") or version_name.contains("D"):
		version_label.text = "v" + str(version_name) + " (Dev)"
	else:
		# Versi rilis normal tanpa huruf 'b'
		version_label.text = "v" + str(version_name)
	
	# Hubungkan tombol dengan fungsinya
	play_button.pressed.connect(_on_play_button_pressed)
	setting_button.pressed.connect(_on_setting_button_pressed)
	quit_button.pressed.connect(_on_quit_button_pressed)

# 🔄 PERGERAKAN LOOP KAMERA
func _process(delta: float) -> void:
	if camera:
		# Geser kamera pelan ke kanan
		camera.position.x += scroll_speed * delta
		
		# Jika posisi kamera sudah melebihi reset_x, kembalikan ke start_x secara mulus
		if camera.position.x >= reset_x:
			camera.position.x = start_x

func _on_play_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scene/select_world.tscn")

func _on_setting_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scene/setting.tscn")

func _on_quit_button_pressed() -> void:
	get_tree().quit()
