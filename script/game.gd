extends Node2D

@onready var player = $CharacterBody2D
@onready var ui_layer = $CanvasLayer

@onready var jump_button = $CanvasLayer/JumpButton
@onready var btn_left = $CanvasLayer/LeftButton
@onready var btn_right = $CanvasLayer/RightButton
@onready var btn_run = $CanvasLayer/RunButton

func _ready():
	# 1. Atur visibilitas UI (PC = Sembunyi, Mobile = Tampil)
	if OS.has_feature("pc"):
		if ui_layer:
			ui_layer.hide()
	else:
		if ui_layer:
			ui_layer.show()

	# 2. SAMBUNGKAN SINYAL TOMBOL (Berjalan di PC untuk pengetesan & di HP untuk gameplay)
	if jump_button:
		jump_button.pressed.connect(_on_jump_button_pressed)
	
	if btn_left:
		btn_left.button_down.connect(func(): player.set_move_direction(-1.0))
		btn_left.button_up.connect(func(): player.set_move_direction(0.0))
		
	if btn_right:
		btn_right.button_down.connect(func(): player.set_move_direction(1.0))
		btn_right.button_up.connect(func(): player.set_move_direction(0.0))

	if btn_run:
		btn_run.button_down.connect(func(): player.set_running(true))
		btn_run.button_up.connect(func(): player.set_running(false))

func _on_jump_button_pressed():
	if player and player.has_method("jump"):
		player.jump()