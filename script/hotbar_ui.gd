extends CanvasLayer

signal slot_changed(selected_slot_index: int, selected_tile_id: int)

# Masking ID Tile ke Tekstur Gambar
@export var tile_textures: Dictionary = {
	1: preload("res://assets/block/grass_block.png"),
	2: preload("res://assets/block/dirt_block.png"),
	3: preload("res://assets/block/stone_block.png"),
	4: preload("res://assets/block/coal_block.png"),
	5: preload("res://assets/block/iron_block.png"),
	6: preload("res://assets/block/gold_block.png"),
	7: preload("res://assets/block/diamond_block.png"),
	8: preload("res://assets/block/wood_block.png"),
	9: preload("res://assets/block/leave_block.png")
}

# Inisialisasi 7 slot kosong (-1 artinya kosong)
@export var slot_tile_ids: Array[int] = [-1, -1, -1, -1, -1, -1, -1]

var current_slot: int = 0
@onready var item_slots: Control = $HotbarContainer/MarginContainer/HotbarBG/ItemSlots

func _ready() -> void:
	if slot_tile_ids.is_empty() or slot_tile_ids.size() != 7:
		slot_tile_ids = [-1, -1, -1, -1, -1, -1, -1]
	else:
		for i in range(slot_tile_ids.size()):
			if slot_tile_ids[i] == 0:
				slot_tile_ids[i] = -1

	# 🔄 COBA LOAD HOTBAR DARI FILE SAAAT START
	muat_hotbar_dari_file()

	call_deferred("update_and_emit")
	
	var items = item_slots.get_children()
	for i in range(items.size()):
		var item = items[i]
		if item is Control:
			item.gui_input.connect(_on_item_gui_input.bind(i))

# --- FUNGSI SIMPAN DI HotbarUI.gd ---
func simpan_hotbar_ke_file() -> void:
	var world_name: String = Global.current_world_name
	if world_name == "":
		world_name = "My World"
		
	var current_seed: int = SaveManager.load_world_seed(world_name)
	# Panggil SaveManager untuk simpan JSON
	SaveManager.save_world(world_name, current_seed, slot_tile_ids)

func muat_hotbar_dari_file() -> void:
	var world_name: String = Global.current_world_name
	if world_name == "":
		world_name = "My World"
		
	var world_info = SaveManager.load_world_info(world_name)
	var loaded_hotbar = world_info.get("hotbar", [])
	
	if loaded_hotbar is Array and loaded_hotbar.size() == 7:
		for i in range(7):
			slot_tile_ids[i] = int(loaded_hotbar[i])
		print("📂 HotbarUI: Hotbar berhasil dimuat: ", slot_tile_ids)

func _on_item_gui_input(event: InputEvent, slot_index: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		select_slot(slot_index)

func update_and_emit() -> void:
	update_item_indicators()
	if current_slot < slot_tile_ids.size():
		emit_signal("slot_changed", current_slot, slot_tile_ids[current_slot])

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_1: select_slot(0)
		elif event.keycode == KEY_2: select_slot(1)
		elif event.keycode == KEY_3: select_slot(2)
		elif event.keycode == KEY_4: select_slot(3)
		elif event.keycode == KEY_5: select_slot(4)
		elif event.keycode == KEY_6: select_slot(5)
		elif event.keycode == KEY_7: select_slot(6)

	if event is InputEventMouseButton and event.pressed:
		if slot_tile_ids.is_empty() or slot_tile_ids.size() == 0: 
			return
			
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			var prev_slot = (current_slot - 1 + slot_tile_ids.size()) % slot_tile_ids.size()
			select_slot(prev_slot)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			var next_slot = (current_slot + 1) % slot_tile_ids.size()
			select_slot(next_slot)

func select_slot(index: int) -> void:
	if index >= 0 and index < slot_tile_ids.size():
		current_slot = index
		update_item_indicators()
		emit_signal("slot_changed", current_slot, slot_tile_ids[current_slot])

func update_item_indicators() -> void:
	var items = item_slots.get_children()
	for i in range(items.size()):
		var item_slot = items[i]
		if not item_slot: continue
		
		item_slot.pivot_offset = item_slot.size / 2.0
		
		var current_tile_id = slot_tile_ids[i] if i < slot_tile_ids.size() else -1
		
		var icon_rect: TextureRect = item_slot as TextureRect
		if item_slot.get_child_count() > 0 and item_slot.get_child(0) is TextureRect:
			icon_rect = item_slot.get_child(0) as TextureRect

		if icon_rect:
			if current_tile_id != -1 and tile_textures.has(current_tile_id):
				icon_rect.texture = tile_textures[current_tile_id]
				icon_rect.visible = true
			else:
				icon_rect.visible = false

		if i == current_slot:
			item_slot.modulate = Color(1.3, 1.3, 1.3, 1.0)
			item_slot.scale = Vector2(1.1, 1.1)
		else:
			item_slot.modulate = Color(0.7, 0.7, 0.7, 0.85)
			item_slot.scale = Vector2(1.0, 1.0)

func add_item_to_hotbar(tile_id: int, _amount: int = 1) -> bool:
	var target_index = slot_tile_ids.find(tile_id)
	if target_index != -1:
		select_slot(target_index)
		update_item_indicators()
		return true

	var empty_index = slot_tile_ids.find(-1)
	if empty_index != -1:
		slot_tile_ids[empty_index] = tile_id
		select_slot(empty_index)
		update_item_indicators()
		
		# 💾 Otomatis simpan setiap kali ada item baru yang diambil
		simpan_hotbar_ke_file()
		return true

	return false

func remove_current_item() -> bool:
	var tile_id: int = -1
	if current_slot < slot_tile_ids.size():
		tile_id = slot_tile_ids[current_slot]
		
	if tile_id == -1:
		return false
		
	slot_tile_ids[current_slot] = -1
	update_item_indicators()
	emit_signal("slot_changed", current_slot, -1)
	simpan_hotbar_ke_file()
	return true