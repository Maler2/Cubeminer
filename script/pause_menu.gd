extends CanvasLayer

@onready var resume_button: Button = $VBoxContainer/ResumeButton
@onready var main_menu_button: Button = $VBoxContainer/MainMenuButton

var current_seed = Global.current_world_seed

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

func _on_resume_button_pressed() -> void:
	toggle_pause()

func _on_main_menu_button_pressed() -> void:
	get_tree().paused = false
	
	var active_seed = Global.current_world_seed
	var active_world = Global.current_world_name
	SaveManager.save_seed(active_seed, active_world)
	
	get_tree().change_scene_to_file("res://scene/MainMenu.tscn")
