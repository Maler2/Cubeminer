extends PanelContainer
class_name InventorySlotUI

@onready var item_icon: TextureRect = $ItemIcon
@onready var amount_label: Label = $AmountLabel

func set_slot_data(texture: Texture2D, amount: int) -> void:
	if texture and amount > 0:
		item_icon.texture = texture
		item_icon.visible = true
		amount_label.text = str(amount) if amount > 1 else ""
		amount_label.visible = true
	else:
		# Slot Kosong
		item_icon.texture = null
		item_icon.visible = false
		amount_label.text = ""
		amount_label.visible = false
