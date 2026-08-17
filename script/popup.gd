extends CanvasLayer

@onready var label: Label = $Container/popupLabel
@onready var bg: NinePatchRect = $Container/NinePatchRect
@onready var container: Control = $Container

var padding: Vector2 = Vector2(16, 6)
var tween: Tween

func _ready() -> void:
	await ready
	container = $Container
	label = $Container/popupLabel
	bg = $Container/NinePatchRect
	container.modulate.a = 0.0
	bg.visible = false
	label.text = ""

func show_popup(text: String, args: Array = []) -> void:
	if tween and tween.is_valid():
		tween.kill()
	
	var final_text = text % args if args.size() > 0 else text
	label.text = final_text
	bg.visible = true
	_update_bg_size()
	
	tween = create_tween()
	tween.tween_property(container, "modulate:a", 1.0, 0.5)
	tween.tween_interval(3.0)
	tween.tween_property(container, "modulate:a", 0.0, 0.5)
	tween.tween_callback(func():
		label.text = ""
		bg.visible = false
	)

func _update_bg_size() -> void:
	await get_tree().process_frame
	var label_size = label.get_minimum_size()
	var bg_size = label_size + padding * 2
	var viewport_w = get_viewport().get_visible_rect().size.x
	bg_size.x = min(bg_size.x, viewport_w - 40)
	var x_offset = (viewport_w - bg_size.x) / 2.0
	bg.offset_left = x_offset
	bg.offset_right = -x_offset
	bg.offset_top = -(bg_size.y)
	bg.offset_bottom = 0
	label.offset_left = x_offset + padding.x
	label.offset_right = -(x_offset + padding.x)
	label.offset_top = -(bg_size.y) + padding.y
	label.offset_bottom = -padding.y
