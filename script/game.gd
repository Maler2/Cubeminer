extends Node2D

@onready var player = $CharacterBody2D
@onready var input_layer = $InputLayer
@onready var pause_menu = $PauseMenu

# Node tombol berada di bawah InputLayer
@onready var jump_button = $InputLayer/JumpButton
@onready var btn_left = $InputLayer/LeftButton
@onready var btn_right = $InputLayer/RightButton
@onready var btn_run = $InputLayer/RunButton

func _ready():
	get_window().content_scale_factor = 4.0
	FpsCounter.set_fps_label_scale(0.25)
	FpsCounter.set_fps_offset(Vector2(1, 156))
	# 1. Atur visibilitas UI (Sembunyi di PC, tampil di Mobile/Touchscreen)
	if OS.has_feature("pc") and not DisplayServer.is_touchscreen_available():
		if input_layer:
			input_layer.hide()
	else:
		if input_layer:
			input_layer.show()

	# 2. SAMBUNGKAN SINYAL TOMBOL
	if jump_button:
		jump_button.button_down.connect(_on_jump_button_pressed)
	
	if btn_left:
		btn_left.button_down.connect(func(): if player: player.set_move_direction(-1.0))
		btn_left.button_up.connect(func(): if player: player.set_move_direction(0.0))
		
	if btn_right:
		btn_right.button_down.connect(func(): if player: player.set_move_direction(1.0))
		btn_right.button_up.connect(func(): if player: player.set_move_direction(0.0))

	if btn_run:
		btn_run.button_down.connect(func(): if player: player.set_running(true))
		run_button_up()

	var pause_button = get_node_or_null("UILayer/UI/PauseButton")
	if pause_button:
		if OS.has_feature("pc") and not DisplayServer.is_touchscreen_available():
			pause_button.hide()
		else:
			pause_button.pressed.connect(func(): pause_menu.toggle_pause())

func run_button_up():
	if btn_run:
		btn_run.button_up.connect(func(): if player: player.set_running(false))

func _on_jump_button_pressed():
	if player and player.has_method("jump"):
		player.jump()