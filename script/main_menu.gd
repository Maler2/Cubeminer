extends Control

@onready var title_image: TextureRect = $ButtonLayer/VBoxContainer/TitleImage
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
	
	# Ambil nama game dari Project Settings (fallback title teks)
	var game_name: String = ProjectSettings.get_setting("application/config/name")
	if game_name != "":
		title_label.text = game_name

	# 🖼️ TITLE HIBRID:
	# - Kalau file title.png ada → tampilkan gambar title (TitleImage)
	# - Kalau tidak ada → fallback ke TitleLabel (nama game dari project settings)
	var title_path := "res://assets/menu/title.png"
	if ResourceLoader.exists(title_path):
		title_image.visible = true
		var tex: Texture2D = load(title_path)
		if tex:
			title_image.texture = tex
		title_label.visible = false
	else:
		title_image.visible = false
		title_label.visible = true

	version_label.text = Global.build_version if Global.build_version != "" else "vunknown"
	
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
