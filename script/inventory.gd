extends CanvasLayer
class_name InventoryUI

@export var tile_textures: Dictionary = {
	1: preload("res://assets/block/grass_block.png"),
	2: preload("res://assets/block/dirt_block.png"),
	3: preload("res://assets/block/stone_block.png"),
	4: preload("res://assets/block/coal_block.png"),
	5: preload("res://assets/block/iron_block.png"),
	6: preload("res://assets/block/gold_block.png"),
	7: preload("res://assets/block/diamond_block.png"),
	8: preload("res://assets/block/wood_block.png"),
	9: preload("res://assets/block/leave_block.png"),
	10: preload("res://assets/block/plank.png"),
	11: preload("res://assets/block/stick.png")
}

const INVENTORY_SIZE: int = 14
const CRAFTING_GRID_SIZE: int = 4
const MAX_STACK: int = 128

var inventory_data: Array = []
var crafting_data: Array = []
var held_item: Dictionary = {}
var recipes: Array = []
var held_icon: TextureRect

@onready var inventory_grid: GridContainer = $InventoryGrid
@onready var crafting_grid: GridContainer = $CraftingGrid
@onready var crafting_result: GridContainer = $CraftingResultSlot

func _ready() -> void:
	visible = false
	_init_data()
	_load_recipes()
	_create_held_icon()
	_connect_slots()

func _init_data() -> void:
	inventory_data.resize(INVENTORY_SIZE)
	for i in range(INVENTORY_SIZE):
		inventory_data[i] = null
	crafting_data.resize(CRAFTING_GRID_SIZE)
	for i in range(CRAFTING_GRID_SIZE):
		crafting_data[i] = null

func _load_recipes() -> void:
	var file = FileAccess.open("res://data/recipes.json", FileAccess.READ)
	if not file:
		return
	var json = JSON.new()
	var error = json.parse(file.get_as_text())
	file.close()
	if error == OK and json.data is Dictionary:
		recipes = json.data.get("recipes", [])

func _create_held_icon() -> void:
	held_icon = TextureRect.new()
	held_icon.custom_minimum_size = Vector2(8, 8)
	held_icon.size = Vector2(8, 8)
	held_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	held_icon.z_index = 100
	add_child(held_icon)
	held_icon.visible = false

func _connect_slots() -> void:
	var idx: int = 0
	for slot in inventory_grid.get_children():
		if slot is InventorySlotUI:
			slot.gui_input.connect(_on_slot_input.bind(inventory_data, idx))
			idx += 1

	idx = 0
	for slot in crafting_grid.get_children():
		if slot is InventorySlotUI:
			slot.gui_input.connect(_on_slot_input.bind(crafting_data, idx))
			idx += 1

	var result_slot = crafting_result.get_child(0)
	if result_slot is InventorySlotUI:
		result_slot.gui_input.connect(_on_result_slot_input)

func _process(_delta: float) -> void:
	if visible and held_item.size() > 0:
		held_icon.global_position = get_viewport().get_mouse_position() - Vector2(4, 4)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_E or event.keycode == KEY_TAB:
			toggle_inventory()

func toggle_inventory() -> void:
	visible = !visible
	get_tree().paused = visible
	if visible:
		_return_held_to_inventory()
		_sync_hotbar_to_inventory()
		_refresh_all_slots()
	else:
		_sync_inventory_to_hotbar()

func _return_held_to_inventory() -> void:
	if held_item.size() == 0:
		return
	add_item_to_inventory(held_item["tile_id"], held_item["amount"])
	held_item = {}
	held_icon.visible = false

func _get_hotbar() -> Node:
	return get_tree().root.find_child("HotbarUI", true, false)

func _sync_hotbar_to_inventory() -> void:
	var hotbar = _get_hotbar()
	if not hotbar:
		return
	for i in range(7):
		var inv_idx = 7 + i
		var tile_id = hotbar.slot_tile_ids[i] if i < hotbar.slot_tile_ids.size() else -1
		var count = hotbar.slot_counts[i] if i < hotbar.slot_counts.size() else 0
		if tile_id != -1 and count > 0:
			inventory_data[inv_idx] = {"tile_id": tile_id, "amount": count}
		else:
			inventory_data[inv_idx] = null

func _sync_inventory_to_hotbar() -> void:
	var hotbar = _get_hotbar()
	if not hotbar:
		return
	for i in range(7):
		var inv_idx = 7 + i
		var item = inventory_data[inv_idx] if inv_idx < inventory_data.size() else null
		if item != null:
			hotbar.slot_tile_ids[i] = item["tile_id"]
			hotbar.slot_counts[i] = item["amount"]
		else:
			hotbar.slot_tile_ids[i] = -1
			hotbar.slot_counts[i] = 0
	hotbar.update_item_indicators()
	hotbar.simpan_hotbar_ke_file()

func _refresh_all_slots() -> void:
	_sync_grid_visuals(inventory_grid, inventory_data)
	_sync_grid_visuals(crafting_grid, crafting_data)
	_check_crafting()
	inventory_grid.queue_redraw()
	crafting_grid.queue_redraw()

func _sync_grid_visuals(grid: GridContainer, data: Array) -> void:
	var slots = grid.get_children()
	for i in range(slots.size()):
		if i < data.size() and data[i] != null:
			var tex = tile_textures.get(data[i]["tile_id"], null)
			slots[i].set_slot_data(tex, data[i]["amount"])
		else:
			slots[i].set_slot_data(null, 0)

func _on_slot_input(event: InputEvent, data: Array, index: int) -> void:
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return
	_handle_slot_click(data, index)
	_refresh_all_slots()
	if data == inventory_data and index >= 7 and index <= 13:
		_sync_inventory_to_hotbar()

func _handle_slot_click(data: Array, index: int) -> void:
	if index >= data.size():
		return
	var slot_item = data[index]

	if held_item.size() == 0:
		if slot_item != null:
			held_item = slot_item.duplicate()
			data[index] = null
			held_icon.texture = tile_textures.get(held_item["tile_id"], null)
			held_icon.visible = true
	else:
		if slot_item == null:
			data[index] = held_item.duplicate()
			held_item = {}
			held_icon.visible = false
		elif slot_item["tile_id"] == held_item["tile_id"]:
			var can_add = min(held_item["amount"], MAX_STACK - slot_item["amount"])
			slot_item["amount"] += can_add
			held_item["amount"] -= can_add
			if held_item["amount"] <= 0:
				held_item = {}
				held_icon.visible = false
		else:
			var temp = slot_item.duplicate()
			data[index] = held_item.duplicate()
			held_item = temp
			held_icon.texture = tile_textures.get(held_item["tile_id"], null)

func _on_result_slot_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return
	if held_item.size() > 0:
		return

	var result = _find_matching_recipe()
	if result.size() == 0:
		return

	var result_info = result["result"]
	var result_id = result_info["id"]
	var result_amount = result_info["amount"]

	held_item = {"tile_id": result_id, "amount": result_amount}
	held_icon.texture = tile_textures.get(result_id, null)
	held_icon.visible = true

	_consume_crafting_inputs(result)
	_refresh_all_slots()

func _get_grid_ingredients() -> Dictionary:
	var ingredients: Dictionary = {}
	for item in crafting_data:
		if item != null:
			var id = str(item["tile_id"])
			ingredients[id] = ingredients.get(id, 0) + item["amount"]
	return ingredients

func _find_matching_recipe() -> Dictionary:
	var grid = _get_grid_ingredients()
	for recipe in recipes:
		var r_ingredients = recipe.get("ingredients", {})
		if r_ingredients.size() == 0:
			continue
		var matches = true
		for id in r_ingredients:
			if grid.get(id, 0) < r_ingredients[id]:
				matches = false
				break
		if matches:
			return recipe
	return {}

func _consume_crafting_inputs(recipe: Dictionary) -> void:
	var to_consume = {}
	for id in recipe["ingredients"]:
		to_consume[id] = recipe["ingredients"][id]

	for i in range(crafting_data.size()):
		if crafting_data[i] == null:
			continue
		var id = str(crafting_data[i]["tile_id"])
		if to_consume.has(id) and to_consume[id] > 0:
			var consume = min(crafting_data[i]["amount"], to_consume[id])
			crafting_data[i]["amount"] -= consume
			to_consume[id] -= consume
			if crafting_data[i]["amount"] <= 0:
				crafting_data[i] = null

func _check_crafting() -> void:
	var result_slot = crafting_result.get_child(0)
	if not (result_slot is InventorySlotUI):
		return
	var result = _find_matching_recipe()
	if result.size() > 0:
		var info = result["result"]
		var tex = tile_textures.get(info["id"], null)
		result_slot.visible = false
		result_slot.visible = true
		result_slot.set_slot_data(tex, info["amount"])
	else:
		result_slot.visible = false
		result_slot.visible = true
		result_slot.set_slot_data(null, 0)

func add_item_to_inventory(tile_id: int, amount: int = 1) -> bool:
	for item in inventory_data:
		if item != null and item["tile_id"] == tile_id:
			var can_add = min(amount, MAX_STACK - item["amount"])
			item["amount"] += can_add
			amount -= can_add
			if amount <= 0:
				if visible:
					_refresh_all_slots()
				return true

	while amount > 0:
		var empty_idx = inventory_data.find(null)
		if empty_idx == -1:
			break
		var stack = min(amount, MAX_STACK)
		inventory_data[empty_idx] = {"tile_id": tile_id, "amount": stack}
		amount -= stack

	if visible:
		_refresh_all_slots()
	return amount <= 0
