extends Node

var current_world_name: String = ""
var current_world_seed: int = 0
var current_temp_seed_text: String = ""

# Fungsi pembantu untuk set world aktif sekaligus sync ke SaveManager
func set_active_world(world_name: String, world_seed: int, temp_text: String = "") -> void:
	current_world_name = world_name
	current_world_seed = world_seed
	current_temp_seed_text = temp_text if temp_text != "" else str(world_seed)
	
	# Langsung simpan ke file txt di folder world-nya
	if Engine.has_singleton("SaveManager") or get_node_or_null("/root/SaveManager"):
		SaveManager.save_seed(current_world_seed, current_world_name)

# Fungsi untuk mengosongkan/reset data saat keluar ke Main Menu
func clear_world_data() -> void:
	current_world_name = ""
	current_world_seed = 0
	current_temp_seed_text = ""