extends TextureRect

signal dpad_pressed(direction: String)
signal dpad_released()

@onready var btn_up: CanvasItem = $BtnUp
@onready var btn_down: CanvasItem = $BtnDown
@onready var btn_left: CanvasItem = $BtnLeft
@onready var btn_right: CanvasItem = $BtnRight

var active_direction: String = ""
var touch_index: int = -1

var color_normal: Color = Color(1, 1, 1, 0)
var color_pressed: Color = Color(0, 0, 0, 0.4)

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			if get_global_rect().has_point(event.position):
				touch_index = event.index
				var local_pos = event.position - global_position
				var center = size / 2.0
				var diff = local_pos - center
				
				if abs(diff.x) > abs(diff.y):
					if diff.x < 0:
						active_direction = "left"
					else:
						active_direction = "right"
				else:
					if diff.y < 0:
						active_direction = "up"
					else:
						active_direction = "down"
				
				dpad_pressed.emit(active_direction)
				_update_visuals(active_direction)
		else:
			if event.index == touch_index:
				touch_index = -1
				active_direction = ""
				dpad_released.emit()
				_update_visuals("")

func _update_visuals(dir: String) -> void:
	if btn_up: btn_up.modulate = color_normal
	if btn_down: btn_down.modulate = color_normal
	if btn_left: btn_left.modulate = color_normal
	if btn_right: btn_right.modulate = color_normal
	
	match dir:
		"up":
			if btn_up: btn_up.modulate = color_pressed
		"down":
			if btn_down: btn_down.modulate = color_pressed
		"left":
			if btn_left: btn_left.modulate = color_pressed
		"right":
			if btn_right: btn_right.modulate = color_pressed
