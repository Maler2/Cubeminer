extends CharacterBody2D

const SPEED = 100.0 # Kecepatan jalan biasa
const RUN_SPEED = 150.0 # Kecepatan lari
const JUMP_VELOCITY = -200.0 # Ditingkatkan agar lompatan terasa pas
const JUMP_CUT_MAGNITUDE = 0.4 # Pemotong tinggi lompatan jika tombol dilepas cepat
const GRAVITY = 980.0
const MAX_FALL_SPEED = 400.0 # Bounded Terminal Velocity

# --- PENGATURAN FALL DAMAGE ---
@export var min_fall_height: float = 64.0 # Jarak aman minimal (dalam piksel)
@export var pixels_per_damage: float = 16.0 # Setiap berapa piksel damage bertambah 1
var start_fall_y: float = 0.0 # Menampung titik Y awal saat lepas dari tanah
var is_falling: bool = false

# --- NODE REFERENCES ---
@export var hotbar: Node # Tarik Node Hotbar kamu ke kolom ini di Inspector
@onready var ui = get_node_or_null("../UILayer/UI")
@onready var input_layer = get_node_or_null("../InputLayer") # Referensi ke InputLayer
@onready var anim_player = $AnimationPlayer
@onready var body_container = $Body # Node penampung semua part sprite tubuh

# Variabel untuk input dari Tombol UI HP
var ui_move_direction = 0.0
var is_ui_running = false

var footstep_timer: float = 0.0
@export var step_interval: float = 0.45 # Jeda antar langkah kaki (detik)

@onready var sfx_player: AudioStreamPlayer2D = $FootstepAudioPlayer
@onready var held_item_sprite: Sprite2D = $Body/RightArm/ItemHeldSprite # Sesuaikan path Node tanganmu

func _ready() -> void:
	add_to_group("players")
	
	# Hubungkan tombol InputLayer ke fungsi Player secara otomatis jika kodenya ada
	_setup_mobile_controls()
	
	# Hubungkan sinyal dari Hotbar
	_setup_hotbar_connection()

func _setup_hotbar_connection() -> void:
	# Jika hotbar belum di-assign lewat Inspector, coba cari via path
	if not hotbar:
		hotbar = get_node_or_null("../UILayer/Hotbar")
		
	if hotbar:
		if hotbar.has_signal("slot_changed"):
			if not hotbar.is_connected("slot_changed", _on_hotbar_slot_changed):
				hotbar.slot_changed.connect(_on_hotbar_slot_changed)
				print("✅ PLAYER: Berhasil connect ke sinyal Hotbar!")
	else:
		print("⚠️ PLAYER: Node Hotbar tidak ditemukan! Drag Node Hotbar ke Inspector Player.")

# Callback saat slot di Hotbar berubah / dimasukkan item
func _on_hotbar_slot_changed(_slot_index: int, tile_id: int) -> void:
	if not held_item_sprite:
		return
		
	# Jika slot kosong (-1) atau ID tidak ada di Dictionary Hotbar
	if tile_id == -1 or not hotbar or not hotbar.tile_textures.has(tile_id):
		update_held_item(null)
	else:
		# Ambil Texture2D dari dictionary milik hotbar
		var new_tex = hotbar.tile_textures[tile_id]
		update_held_item(new_tex)

# Fungsi untuk mengubah item yang dipegang
func update_held_item(new_texture: Texture2D) -> void:
	if not held_item_sprite:
		return
		
	if new_texture:
		held_item_sprite.texture = new_texture
		held_item_sprite.visible = true
	else:
		# Jika slot hotbar kosong/tangan kosong
		held_item_sprite.texture = null
		held_item_sprite.visible = false

func handle_footstep_sfx(delta: float) -> void:
	if is_on_floor() and abs(velocity.x) > 10:
		# Jika lari interval 0.2s, jika jalan biasa interval 0.35s
		var current_interval = 0.2 if (is_ui_running or Input.is_action_pressed("run")) else step_interval
		
		footstep_timer += delta
		if footstep_timer >= current_interval:
			footstep_timer = 0.0
			play_footstep_sfx()
	else:
		footstep_timer = step_interval

func play_footstep_sfx() -> void:
	if sfx_player:
		sfx_player.pitch_scale = randf_range(0.9, 1.1)
		sfx_player.play()

func _setup_mobile_controls() -> void:
	if not input_layer:
		return
		
	var left_btn = input_layer.get_node_or_null("LeftButton")
	var right_btn = input_layer.get_node_or_null("RightButton")
	var jump_btn = input_layer.get_node_or_null("JumpButton")
	var run_btn = input_layer.get_node_or_null("RunButton")
	
	if left_btn:
		left_btn.button_down.connect(func(): set_move_direction(-1.0))
		left_btn.button_up.connect(func(): set_move_direction(0.0))
		
	if right_btn:
		right_btn.button_down.connect(func(): set_move_direction(1.0))
		right_btn.button_up.connect(func(): set_move_direction(0.0))
		
	if jump_btn:
		jump_btn.button_down.connect(func(): jump())
		
	if run_btn:
		run_btn.button_down.connect(func(): set_running(true))
		run_btn.button_up.connect(func(): set_running(false))

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

	# 2. Input Keyboard PC
	var keyboard_dir = Input.get_axis("left", "right")
	var is_keyboard_running = Input.is_action_pressed("run")

	# 3. Kecepatan (Lari vs Jalan)
	var is_running = is_keyboard_running or is_ui_running
	var current_speed = SPEED
	if is_running:
		current_speed = RUN_SPEED

	# 4. Pergerakan Horisontal
	var final_dir = keyboard_dir
	if ui_move_direction != 0.0:
		final_dir = ui_move_direction
	velocity.x = final_dir * current_speed

	# 5. Membalikkan Arah Visual (Flip Body Container)
	if final_dir > 0:
		body_container.scale.x = 1.0   # Hadap Kanan
	elif final_dir < 0:
		body_container.scale.x = -1.0  # Hadap Kiri

	# 6. Lompat
	if Input.is_action_pressed("jump") and is_on_floor():
		jump()

	# Tahan Lompat: Jika tombol dilepas saat meluncur ke atas, lompatan terhenti lebih cepat
	if Input.is_action_just_released("jump") and velocity.y < 0:
		velocity.y *= JUMP_CUT_MAGNITUDE

	move_and_slide()

	# --- PANGGIL FUNGSI SFX DI SINI ---
	handle_footstep_sfx(delta)

	# 7. PEMICU ANIMASI
	var blend_time = 0.3

	if is_on_floor():
		if final_dir != 0:
			if is_running:
				anim_player.speed_scale = 2.5
			else:
				anim_player.speed_scale = 1.0
			
			if anim_player.current_animation != "walk":
				anim_player.play("walk", blend_time)
		else:
			anim_player.speed_scale = 1.0
			if anim_player.current_animation != "idle":
				anim_player.play("idle", blend_time)
	else:
		anim_player.speed_scale = 1.0
		if velocity.y > 0:
			if anim_player.current_animation != "fall":
				anim_player.play("fall", blend_time)
		else:
			if anim_player.current_animation != "jump":
				anim_player.play("jump", blend_time)

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