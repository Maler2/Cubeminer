extends Control

@onready var world_list_container: VBoxContainer = $VBoxContainer/ScrollContainer/WorldListContainer
@onready var create_button: Button = $VBoxContainer/ButtonHBox/CreateButton
@onready var back_button: Button = $VBoxContainer/ButtonHBox/BackButton

# Tempat menyimpan folder/file dunia (nanti kita pakai user://)
const WORLDS_PATH: String = "user://worlds/"

func _ready() -> void:
	get_window().content_scale_factor = 1.0
	create_button.pressed.connect(_on_create_button_pressed)
	back_button.pressed.connect(_on_back_button_pressed)
	
	# Tampilkan daftar dunia saat scene dibuka
	load_world_list()

func load_world_list() -> void:
	# Bersihkan list lama jika ada
	for child in world_list_container.get_children():
		child.queue_free()
		
	# Cek apakah folder worlds ada
	if not DirAccess.dir_exists_absolute(WORLDS_PATH):
		DirAccess.make_dir_absolute(WORLDS_PATH)
		
	var dir = DirAccess.open(WORLDS_PATH)
	var found_worlds: int = 0
	
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		
		while file_name != "":
			# Jika menemukan folder/file dunia
			if dir.current_is_dir() and not file_name.begins_with("."):
				found_worlds += 1
				add_world_button(file_name)
			file_name = dir.get_next()
			
	# Jika belum ada dunia sama sekali
	if found_worlds == 0:
		var empty_label = Label.new()
		empty_label.text = "No worlds found."
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		world_list_container.add_child(empty_label)

func add_world_button(world_name: String) -> void:
	# Membuat tombol interaktif untuk setiap dunia
	var btn = Button.new()
	btn.text = world_name
	btn.custom_minimum_size.y = 40
	btn.pressed.connect(func(): _on_world_selected(world_name))
	world_list_container.add_child(btn)

func _on_world_selected(world_name: String) -> void:
	# Set data dunia ke Global saat dipilih
	Global.current_world_name = world_name
	
	# Lanjut ke loading screen / game
	get_tree().change_scene_to_file("res://scene/loading-screen.tscn")

func _on_create_button_pressed() -> void:
	# Pergi ke layar buat dunia baru
	get_tree().change_scene_to_file("res://scene/CreateWorld.tscn")

func _on_back_button_pressed() -> void:
	# Kembali ke Main Menu
	get_tree().change_scene_to_file("res://scene/MainMenu.tscn")