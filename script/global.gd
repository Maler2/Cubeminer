extends Node

var current_world_name: String = ""
var current_world_seed: int = 0
var current_temp_seed_text: String = ""
var build_version: String = ""

var is_outdated: bool = false
var latest_version: String = ""

# Muat tekstur kursor
var cursor_normal = preload("res://assets/ui/cursor.png")
var cursor_select = preload("res://assets/ui/cursor-select.png")

func _ready() -> void:
	# Set kursor kustom secara global begitu game dinyalakan
	if cursor_normal:
		Input.set_custom_mouse_cursor(cursor_normal, Input.CURSOR_ARROW, Vector2(0, 0))
		print("✅ GLOBAL: Kursor kustom berhasil dipasang!")
	else:
		print("❌ GLOBAL: Tekstur kursor tidak ditemukan!")
	
	if cursor_select:
		Input.set_custom_mouse_cursor(cursor_select, Input.CURSOR_POINTING_HAND, Vector2(0, 0))

# Fungsi pembantu untuk set world aktif sekaligus sync ke SaveManager
func set_active_world(world_name: String, world_seed: int, temp_text: String = "") -> void:
	current_world_name = world_name
	current_world_seed = world_seed
	current_temp_seed_text = temp_text if temp_text != "" else str(world_seed)
	
	# Simpan seed dunia baru ke SaveManager
	if get_node_or_null("/root/SaveManager"):
		SaveManager.save_world(world_name, world_seed)
		print("🌐 GLOBAL: Active world diset ke '", world_name, "' dengan Seed: ", world_seed)
	print("📌 Status cursor default: ", "OK" if cursor_normal else "❌ NULL")

# Fungsi untuk mengosongkan/reset data saat keluar ke Main Menu
func clear_world_data() -> void:
	current_world_name = ""
	current_world_seed = 0
	current_temp_seed_text = ""