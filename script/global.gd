extends Node

var current_world_name: String = ""
var current_world_seed: int = 0
var current_temp_seed_text: String = ""
var build_version: String = ""

# Fungsi pembantu untuk set world aktif sekaligus sync ke SaveManager
func set_active_world(world_name: String, world_seed: int, temp_text: String = "") -> void:
	current_world_name = world_name
	current_world_seed = world_seed
	current_temp_seed_text = temp_text if temp_text != "" else str(world_seed)
	
	# Simpan seed dunia baru ke SaveManager
	if get_node_or_null("/root/SaveManager"):
		SaveManager.save_world(world_name, world_seed)
		print("🌐 GLOBAL: Active world diset ke '", world_name, "' dengan Seed: ", world_seed)

# Fungsi untuk mengosongkan/reset data saat keluar ke Main Menu
func clear_world_data() -> void:
	current_world_name = ""
	current_world_seed = 0
	current_temp_seed_text = ""