extends Node2D

@onready var player = $CharacterBody2D
@onready var input_layer = $InputLayer
@onready var pause_menu = $PauseMenu

# Node tombol berada di bawah InputLayer
@onready var jump_button = $InputLayer/JumpButton
@onready var dpad = $InputLayer/DPad
@onready var btn_run = $InputLayer/RunButton

func _ready():
	get_window().content_scale_factor = 4.0
	FpsCounter.set_fps_label_scale(0.25)
	FpsCounter.set_fps_offset(Vector2(1, 156))
	if OS.has_feature("pc") and not DisplayServer.is_touchscreen_available():
		if input_layer:
			input_layer.hide()
	else:
		if input_layer:
			input_layer.show()

	if jump_button:
		jump_button.button_down.connect(_on_jump_button_pressed)

	if dpad:
		dpad.dpad_pressed.connect(_on_dpad_pressed)

	if btn_run:
		btn_run.button_down.connect(func(): if player: player.set_running(true))
		btn_run.button_up.connect(func(): if player: player.set_running(false))

	var pause_button = get_node_or_null("UILayer/UI/PauseButton")
	if pause_button:
		if OS.has_feature("pc") and not DisplayServer.is_touchscreen_available():
			pause_button.hide()
		else:
			pause_button.pressed.connect(func(): pause_menu.toggle_pause())

	var inv_button = get_node_or_null("HotbarUI/HotbarContainer/MarginContainer/HotbarBG/InventoryPhone/InventoryButton")
	if inv_button:
		if OS.has_feature("pc") and not DisplayServer.is_touchscreen_available():
			inv_button.get_parent().hide()
		else:
			inv_button.pressed.connect(func(): $Inventory.toggle_inventory())

func _on_dpad_pressed(direction: String) -> void:
	if not player:
		return
	match direction:
		"left":
			player.set_move_direction(-1.0)
		"right":
			player.set_move_direction(1.0)
		"":
			player.set_move_direction(0.0)

func _on_jump_button_pressed():
	if player and player.has_method("jump"):
		player.jump()
