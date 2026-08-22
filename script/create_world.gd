extends Control

# Referensi Node sesuai struktur VBoxContainer kamu
@onready var world_name_input: LineEdit = $Middlething/VBoxContainer/WorldNameInput
@onready var seed_input: LineEdit = $Middlething/VBoxContainer/SeedInput
@onready var create_button: Button = $Middlething/VBoxContainer/CreateButton
@onready var back_button: Button = $Middlething/VBoxContainer/BackButton

func _ready() -> void:
	get_window().content_scale_factor = 1.0
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

	# 2. Simpan seed via SaveManager (Gunakan file.flush di SaveManager)
	SaveManager.save_world(world_name, final_seed)
	
	# 3. Beri delay mikro/tunggu 1 frame agar OS selesai menulis file fisik
	await get_tree().process_frame
	
	# 4. Pindah ke Loading Screen
	get_tree().change_scene_to_file("res://scene/loading-screen.tscn")

func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scene/select_world.tscn")
