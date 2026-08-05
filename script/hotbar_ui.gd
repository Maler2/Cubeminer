extends CanvasLayer

signal slot_changed(selected_slot_index: int, selected_tile_id: int)

# Masking ID Tile ke Tekstur Gambar
# Masukkan gambar item di Inspector Godot sesuai urutan Tile ID (misal: ID 0, ID 1, ID 2, dst)
# Atau kita buat Dictionary/Mapping jika ID tidak berurutan.
@export var tile_textures: Dictionary = {
    1: preload("res://assets/block/grass_block.png"), # Sesuaikan path gambar itemmu
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
	# 🛠️ PAKSA RESET ARRAY KE -1 AGAR TIDAK TERTIMPA NILAI DARI INSPECTOR
	if slot_tile_ids.is_empty() or slot_tile_ids.size() != 7:
		slot_tile_ids = [-1, -1, -1, -1, -1, -1, -1]
	else:
		# Jika di inspector ada data, pastikan slot yang bernilai 0 diubah jadi -1 jika 0 bukan ID item
		for i in range(slot_tile_ids.size()):
			if slot_tile_ids[i] == 0:
				slot_tile_ids[i] = -1

	call_deferred("update_and_emit")
	
	var items = item_slots.get_children()
	for i in range(items.size()):
		var item = items[i]
		if item is Control:
			item.gui_input.connect(_on_item_gui_input.bind(i))

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
			# 💡 TAMBAHKAN PENGECEKAN INI DULU
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
		
		# --- PERBAIKAN UPDATE VISUAL ---
		# Cari node gambar ikon (bisa item_slot itu sendiri atau child pertamanya)
		var icon_rect: TextureRect = item_slot as TextureRect
		if item_slot.get_child_count() > 0 and item_slot.get_child(0) is TextureRect:
			icon_rect = item_slot.get_child(0) as TextureRect

		if icon_rect:
			if current_tile_id != -1 and tile_textures.has(current_tile_id):
				# Jika slot ada isinya, pasang gambar tekstur & tampilkan
				icon_rect.texture = tile_textures[current_tile_id]
				icon_rect.visible = true
			else:
				# Jika slot kosong (-1), sembunyikan gambar ikonnya
				icon_rect.visible = false

		# Highlight Slot Aktif vs Tidak Aktif
		if i == current_slot:
			item_slot.modulate = Color(1.3, 1.3, 1.3, 1.0)
			item_slot.scale = Vector2(1.1, 1.1)
		else:
			item_slot.modulate = Color(0.7, 0.7, 0.7, 0.85)
			item_slot.scale = Vector2(1.0, 1.0)

func add_item_to_hotbar(tile_id: int, _amount: int = 1) -> bool:
	# 1. Cek jika item SUDAH ADA di hotbar
	var target_index = slot_tile_ids.find(tile_id)
	if target_index != -1:
		select_slot(target_index)
		update_item_indicators()
		print("ℹ️ Item sudah ada di Hotbar Slot ", target_index)
		return true

	# 2. Jika BELUM ADA, cari slot kosong (-1)
	var empty_index = slot_tile_ids.find(-1)
	if empty_index != -1:
		slot_tile_ids[empty_index] = tile_id
		select_slot(empty_index)
		print("✨ Item Baru Tile ID ", tile_id, " dimasukkan ke Slot ", empty_index)
		return true

	# 3. Jika benar-benar TIDAK ADA slot kosong (-1)
	print("⚠️ Hotbar Penuh!")
	return false