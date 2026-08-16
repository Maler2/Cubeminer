extends CanvasLayer

@onready var resume_button: Button = $VBoxContainer/ResumeButton
@onready var main_menu_button: Button = $VBoxContainer/MainMenuButton
@onready var world_label: Label = $VBoxInfoContainer/WorldLabel
@onready var seed_label: Label = $VBoxInfoContainer/SeedLabel

# Node Hotbar (Sesuaikan path jika posisinya berbeda di scene kamu)
@onready var hotbar = get_node_or_null("../UILayer/Hotbar")

func _ready() -> void:
	# Memaksa PauseMenu & Tombol tetap aktif saat game di-pause
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	hide()
	
	resume_button.pressed.connect(_on_resume_button_pressed)
	main_menu_button.pressed.connect(_on_main_menu_button_pressed)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		toggle_pause()

func toggle_pause() -> void:
	var is_paused: bool = not get_tree().paused
	get_tree().paused = is_paused
	visible = is_paused
	
	# Memastikan kursor terlihat & bebas bergerak
	if is_paused:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		# Tampilkan info dunia & seed saat pause
		world_label.text = "World: " + str(Global.current_world_name)
		seed_label.text = "Seed: " + str(Global.current_world_seed)

func _on_resume_button_pressed() -> void:
	toggle_pause()

func _on_main_menu_button_pressed() -> void:
	# 1. Ambil data dari Global Autoload
	var active_seed = Global.current_world_seed
	var active_world = Global.current_world_name
	
	# 2. Ambil data array ID item dari Hotbar
	var hotbar_data: Array = []
	
	if hotbar and hotbar.has_method("get_hotbar_data"):
		hotbar_data = hotbar.get_hotbar_data()
	elif "hotbar_slots" in Global: # Fallback jika data simpan di Global
		hotbar_data = Global.hotbar_slots
	
	# 3. Simpan seed & hotbar via SaveManager ke info.txt
	if SaveManager:
		SaveManager.save_world(active_world, active_seed, hotbar_data)

	var player = get_tree().get_first_node_in_group("players")
	if player and player.has_method("simpan_posisi_player"):
		player.simpan_posisi_player()
	
	# 4. Unpause game setelah proses simpan selesai
	get_tree().paused = false
	
	# 5. Baru pindah ke Main Menu
	get_tree().change_scene_to_file("res://scene/MainMenu.tscn")