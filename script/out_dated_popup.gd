extends CanvasLayer

const GITHUB_RELEASES_URL := "https://github.com/Maler2/Cubeminer/releases"

@onready var text_label: Label = $TextureRect/VBoxContainer/TextLabel
@onready var no_button: Button = $TextureRect/VBoxContainer/HBoxContainer/NoButton
@onready var yes_button: Button = $TextureRect/VBoxContainer/HBoxContainer/YesButton

func _ready() -> void:
	visible = false
	no_button.pressed.connect(_on_no_pressed)
	yes_button.pressed.connect(_on_yes_pressed)

func show_popup(current_version: String, latest_version: String) -> void:
	text_label.text = "Oops!\nAre You Still On %s?\nWanna Update To %s?" % [current_version, latest_version]
	visible = true

func _on_no_pressed() -> void:
	visible = false

func _on_yes_pressed() -> void:
	OS.shell_open(GITHUB_RELEASES_URL)
	visible = false
