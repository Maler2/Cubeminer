extends Control

@onready var world_list_container: VBoxContainer = $middlething/VBoxContainer/ScrollContainer/WorldListContainer
@onready var create_button: Button = $middlething/VBoxContainer/ButtonHBox/CreateButton
@onready var back_button: Button = $middlething/VBoxContainer/ButtonHBox/BackButton

const WORLDS_PATH: String = "user://worlds/"
const WORLD_ROW_SCENE = preload("res://scene/world_row.tscn")

func _ready() -> void:
	get_window().content_scale_factor = 1.0
	create_button.pressed.connect(_on_create_button_pressed)
	back_button.pressed.connect(_on_back_button_pressed)
	load_world_list()

func load_world_list() -> void:
	for child in world_list_container.get_children():
		child.queue_free()
		
	if not DirAccess.dir_exists_absolute(WORLDS_PATH):
		DirAccess.make_dir_absolute(WORLDS_PATH)
		
	var dir = DirAccess.open(WORLDS_PATH)
	var found_worlds: int = 0
	
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		
		while file_name != "":
			if dir.current_is_dir() and not file_name.begins_with("."):
				found_worlds += 1
				_add_world_row(file_name)
			file_name = dir.get_next()
			
	if found_worlds == 0:
		var empty_label = Label.new()
		empty_label.text = "No worlds found."
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		world_list_container.add_child(empty_label)

func _add_world_row(world_name: String) -> void:
	var row = WORLD_ROW_SCENE.instantiate()
	
	var btn_world = row.get_node("WorldBtn")
	btn_world.text = world_name
	btn_world.pressed.connect(func(): _on_world_selected(world_name))
	
	var btn_delete = row.get_node("DeleteBtn")
	btn_delete.pressed.connect(func(): _on_delete_world(world_name, row))
	
	world_list_container.add_child(row)

func _on_world_selected(world_name: String) -> void:
	Global.current_world_name = world_name
	Global.current_world_seed = SaveManager.load_world_seed(world_name)
	get_tree().change_scene_to_file("res://scene/loading-screen.tscn")

func _on_delete_world(world_name: String, row_node: Node) -> void:
	_delete_dir_recursive(WORLDS_PATH + world_name)
	row_node.queue_free()
	
	if world_list_container.get_child_count() == 0:
		var empty_label = Label.new()
		empty_label.text = "No worlds found."
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		world_list_container.add_child(empty_label)

func _delete_dir_recursive(path: String) -> void:
	var dir = DirAccess.open(path)
	if not dir:
		return
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		var full_path = path + "/" + file_name
		if dir.current_is_dir():
			_delete_dir_recursive(full_path)
		else:
			dir.remove(file_name)
		file_name = dir.get_next()
	dir.list_dir_end()
	DirAccess.remove_absolute(path)

func _on_create_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scene/CreateWorld.tscn")

func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scene/MainMenu.tscn")

func load_selected_world(world_name: String) -> void:
	var loaded_seed: int = SaveManager.load_world_seed(world_name)
	Global.current_world_name = world_name
	Global.current_world_seed = loaded_seed
	get_tree().change_scene_to_file("res://scene/loading-screen.tscn")
