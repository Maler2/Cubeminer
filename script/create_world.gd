extends Control

# Referensi Node sesuai struktur VBoxContainer kamu
@onready var world_name_input: LineEdit = $VBoxContainer/WorldNameInput
@onready var seed_input: LineEdit = $VBoxContainer/SeedInput # Ganti ke SeedInput jika sudah di-rename
@onready var create_button: Button = $VBoxContainer/CreateButton  # Ganti ke CreateButton jika sudah di-rename
@onready var back_button: Button = $VBoxContainer/BackButton   # Ganti ke BackButton jika sudah di-rename

func _ready() -> void:
	get_window().content_scale_factor = 4.0
	# Menghubungkan sinyal klik tombol secara otomatis lewat kode
	create_button.pressed.connect(_on_create_button_pressed)
	back_button.pressed.connect(_on_back_button_pressed)

func _on_create_button_pressed() -> void:
	var world_name: String = world_name_input.text.strip_edges()
	if world_name.is_empty():
		world_name = "My World"

	var seed_text: String = seed_input.text.strip_edges()
	var final_seed: int
	
	if seed_text.is_empty():
		final_seed = randi()
	elif seed_text.is_valid_int():
		final_seed = seed_text.to_int()
	else:
		final_seed = seed_text.hash()

	# 1. Simpan variabel ke Global Autoload
	Global.current_world_name = world_name
	Global.current_world_seed = final_seed
	Global.current_temp_seed_text = seed_text

	# 2. Simpan seed ke txt menggunakan SaveManager
	SaveManager.save_seed(final_seed, world_name)
	
	# 3. Pindah ke Loading Screen
	get_tree().change_scene_to_file("res://scene/loading-screen.tscn")

func _on_back_button_pressed() -> void:
	# Kembali ke Main Menu (sesuaikan path-nya jika ada main menu)
	get_tree().change_scene_to_file("res://scene/select_world.tscn")