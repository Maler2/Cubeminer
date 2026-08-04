extends CharacterBody2D

const SPEED = 100.0         # Kecepatan jalan biasa
const RUN_SPEED = 150.0     # Kecepatan lari
const JUMP_VELOCITY = -200.0 # Ditingkatkan agar lompatan terasa pas
const JUMP_CUT_MAGNITUDE = 0.4 # Pemotong tinggi lompatan jika tombol dilepas cepat
const GRAVITY = 980.0
const MAX_FALL_SPEED = 400.0 # Bounded Terminal Velocity

# --- PENGATURAN FALL DAMAGE ---
@export var min_fall_height: float = 64.0  # Jarak aman minimal (dalam piksel)
@export var pixels_per_damage: float = 16.0 # Setiap berapa piksel damage bertambah 1

var start_fall_y: float = 0.0                 # Menampung titik Y awal saat lepas dari tanah
var is_falling: bool = false

# Hubungkan node UI
@onready var ui = get_node_or_null("../UILayer/UI")

# Variabel untuk input dari Tombol UI HP
var ui_move_direction = 0.0
var is_ui_running = false

func _ready() -> void:
	add_to_group("players")

func _physics_process(delta: float) -> void:
	# 1. GRAVITASI & FALL DAMAGE
	if not is_on_floor():
		if not is_falling:
			start_fall_y = global_position.y
			is_falling = true
		
		velocity.y = move_toward(velocity.y, MAX_FALL_SPEED, GRAVITY * delta)
	else:
		if is_falling:
			is_falling = false
			var fall_distance = global_position.y - start_fall_y
			if fall_distance > min_fall_height:
				_apply_fall_damage(fall_distance)

		if velocity.y > 0:
			velocity.y = 0

	# 2. Input Keyboard PC
	var keyboard_dir = Input.get_axis("left", "right")
	var is_keyboard_running = Input.is_action_pressed("run")

	# 3. Kecepatan (Lari vs Jalan)
	var current_speed = SPEED
	if is_keyboard_running or is_ui_running:
		current_speed = RUN_SPEED

	# 4. Pergerakan Horisontal
	var final_dir = keyboard_dir
	if ui_move_direction != 0.0:
		final_dir = ui_move_direction

	velocity.x = final_dir * current_speed

	# 5. Lompat (Bisa ditahan pakai is_action_pressed)
	if Input.is_action_pressed("jump") and is_on_floor():
		jump()

	# 🌟 Tahan Lompat: Jika tombol dilepas saat meluncur ke atas, lompatan terhenti lebih cepat
	if Input.is_action_just_released("jump") and velocity.y < 0:
		velocity.y *= JUMP_CUT_MAGNITUDE

	move_and_slide()

# --- FUNGSI MENGHITUNG FALL DAMAGE ---
func _apply_fall_damage(distance: float) -> void:
	var excess_distance = distance - min_fall_height
	var damage_amount: int = 1 + int(excess_distance / pixels_per_damage)
	
	print("[FALL DAMAGE] Jarak Jatuh: ", distance, " px | Damage: ", damage_amount)
	
	if ui and ui.has_method("take_damage"):
		ui.take_damage(damage_amount)

# --- FUNGSI UNTUK TOMBOL UI HP ---
func set_move_direction(dir: float):
	ui_move_direction = dir

func set_running(running: bool):
	is_ui_running = running

func jump():
	if is_on_floor():
		velocity.y = JUMP_VELOCITY