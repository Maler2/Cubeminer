extends CanvasLayer
class_name InventoryUI

@export var slot_scene: PackedScene = preload("res://scene/inventory_slot.tscn")
@export var total_slots: int = 20

# Referensi Tekstur Item (Samakan dengan Hotbar)
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

# data block
var inventory_data: Array = []

@onready var grid_container: GridContainer = $PanelContainer/VBoxContainer/ScrollContainer/GridContainer

func _ready() -> void:
	visible = false
	create_slots()

func create_slots() -> void:
	# Bersihkan slot lama
	for child in grid_container.get_children():
		child.queue_free()
		
	# Instansiasi slot-slot baru
	for i in range(total_slots):
		var new_slot = slot_scene.instantiate()
		grid_container.add_child(new_slot)
		
		# Cek apakah ada data item untuk slot ke-i ini
		if i < inventory_data.size() and inventory_data[i] != null:
			var item_info = inventory_data[i]
			var tile_id = item_info["tile_id"]
			var amount = item_info["amount"]
			
			var texture = tile_textures.get(tile_id, null)
			if new_slot.has_method("set_slot_data"):
				new_slot.set_slot_data(texture, amount)
		else:
			# Slot Kosong
			if new_slot.has_method("set_slot_data"):
				new_slot.set_slot_data(null, 0)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_E or event.keycode == KEY_TAB:
			toggle_inventory()

func toggle_inventory() -> void:
	visible = !visible
	get_tree().paused = visible
	
	# Refresh tampilan slot setiap kali inventory dibuka
	if visible:
		create_slots()

func add_item(tile_id: int, amount: int = 1) -> bool:
	# 1. Cek apakah item sudah ada di inventory (stack item)
	for item in inventory_data:
		if item["tile_id"] == tile_id:
			item["amount"] += amount
			create_slots() # Refresh UI
			return true
			
	# 2. Jika item belum ada, tambah ke slot baru jika kapasitas belum penuh
	if inventory_data.size() < total_slots:
		inventory_data.append({"tile_id": tile_id, "amount": amount})
		create_slots() # Refresh UI
		return true
		
	print("⚠️ Inventory Penuh!")
	return false