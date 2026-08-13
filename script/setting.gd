extends Control

@onready var back_button: Button = $VBoxContainer/BackButton

func _ready() -> void:
	get_window().content_scale_factor = 1.0

func _on_back_button_pressed() -> void:
	# Kembali ke Main Menu
	get_tree().change_scene_to_file("res://scene/MainMenu.tscn")