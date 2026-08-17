extends TextureRect

signal dpad_pressed(direction: String)

var active_direction: String = ""
var touch_index: int = -1

var dir_map = { "": 0, "up": 1, "down": 2, "left": 3, "right": 4 }

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			if get_global_rect().has_point(event.position):
				touch_index = event.index
				_detect_direction(event.position)
		else:
			if event.index == touch_index:
				touch_index = -1
				active_direction = ""
				dpad_pressed.emit(active_direction)
				_update_shader()
	elif event is InputEventScreenDrag:
		if event.index == touch_index:
			_detect_direction(event.position)

func _detect_direction(pos: Vector2) -> void:
	var local_pos = pos - global_position
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
	_update_shader()

func _update_shader() -> void:
	if material and material is ShaderMaterial:
		material.set_shader_parameter("active_dir", dir_map[active_direction])
