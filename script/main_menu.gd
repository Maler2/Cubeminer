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

var outdated_popup_instance: CanvasLayer
var _http_version: HTTPRequest

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
	
	_check_outdated()

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

func _check_outdated() -> void:
	var current_ver = ""
	for path in ["user://versionid.txt", "res://versionid.txt"]:
		var file = FileAccess.open(path, FileAccess.READ)
		if file:
			current_ver = file.get_as_text().strip_edges()
			file.close()
			if current_ver != "":
				break

	if current_ver == "":
		return

	_http_version = HTTPRequest.new()
	add_child(_http_version)
	_http_version.request_completed.connect(_on_version_check_completed.bind(current_ver))
	var url = "https://api.github.com/repos/Maler2/Cubeminer/releases/latest?_t=" + str(Time.get_ticks_msec())
	var headers = [
		"User-Agent: Cubeminer",
		"Cache-Control: no-cache, no-store, must-revalidate"
	]
	_http_version.request(url, headers)

func _on_version_check_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray, current_ver: String) -> void:
	if _http_version:
		_http_version.queue_free()
		_http_version = null

	if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
		return

	var json = JSON.new()
	if json.parse(body.get_string_from_utf8()) != OK:
		return

	var data = json.data
	if not data is Dictionary:
		return

	var latest_version: String = data.get("tag_name", "").trim_prefix("v")
	if latest_version == "" or latest_version == current_ver:
		return

	var packed = load("res://scene/out_dated_popup.tscn") as PackedScene
	if not packed:
		return

	outdated_popup_instance = packed.instantiate()
	add_child(outdated_popup_instance)
	outdated_popup_instance.show_popup(current_ver, latest_version)
