extends CharacterBody2D

const SPEED = 100.0 # Kecepatan jalan biasa
const RUN_SPEED = 150.0 # Kecepatan lari
const JUMP_VELOCITY = -200.0 # Ditingkatkan agar lompatan terasa pas
const JUMP_CUT_MAGNITUDE = 0.4 # Pemotong tinggi lompatan jika tombol dilepas cepat
const MAX_AIR_JUMPS = 1 # Jumlah lompatan ekstra yang boleh dilakukan di udara (double jump)
const GRAVITY = 980.0
const MAX_FALL_SPEED = 400.0 # Bounded Terminal Velocity

const dropped_item_scene = preload("res://scene/dropped_item.tscn")

# --- PENGATURAN FALL DAMAGE ---
@export var min_fall_height: float = 128.0 # Jarak aman minimal (dalam piksel)
@export var pixels_per_damage: float = 16.0 # Setiap berapa piksel damage bertambah 1
@export var show_position_info: bool = false
var start_fall_y: float = 0.0 # Menampung titik Y awal saat lepas dari tanah
var is_falling: bool = false

# --- NODE REFERENCES ---
@export var hotbar: Node # Tarik Node Hotbar kamu ke kolom ini di Inspector
@onready var ui = get_node_or_null("../UILayer/UI")
@onready var input_layer = get_node_or_null("../InputLayer") # Referensi ke InputLayer
@onready var anim_player = $AnimationPlayer
@onready var body_container = $Body # Node penampung semua part sprite tubuh

# --- AUDIO REFERENCES ---
@onready var sfx_player: AudioStreamPlayer = $FootstepAudioPlayer
@onready var jump_sfx_player: AudioStreamPlayer = $JumpAudioPlayer # Node Audio Lompat
@onready var double_jump_particles: GPUParticles2D = $DoubleJumpParticles

@onready var held_item_sprite: Sprite2D = $Body/RightArm/ItemHeldSprite # Sesuaikan path Node tanganmu

# Variabel untuk input dari Tombol UI HP
var ui_move_direction = 0.0
var is_ui_running = false

var footstep_timer: float = 0.0
@export var step_interval: float = 0.3333 # Jeda antar langkah kaki (detik)

# --- VARIABEL DOUBLE JUMP ---
var air_jumps_used: int = 0 # Menghitung lompatan udara yang sudah dipakai sebelum mendarat

# --- VARIABEL EFEK FLIP ---
var flip_tween: Tween
var is_facing_right: bool = true # Menyimpan status arah karakter saat ini

func _ready() -> void:
	add_to_group("players")
	
	# Hubungkan tombol InputLayer ke fungsi Player secara otomatis jika kodenya ada
	_setup_mobile_controls()
	
	# Hubungkan sinyal dari Hotbar
	_setup_hotbar_connection()
	
	# --- LOAD POSISI PLAYER SAAT GAME DIMULAI ---
	call_deferred("muat_posisi_player")

# --- FUNGSI SAVE & LOAD POSISI ---
func muat_posisi_player() -> void:
	var world_name: String = Global.current_world_name
	if world_name == "": world_name = "My World"
	
	var saved_pos = SaveManager.load_player_position(world_name)
	if saved_pos != Vector2.ZERO:
		global_position = saved_pos
		print("📍 PLAYER: Berhasil memuat posisi tersimpan di: ", global_position)

func simpan_posisi_player() -> void:
	var world_name: String = Global.current_world_name
	if world_name == "": world_name = "My World"
	
	var current_seed: int = SaveManager.load_world_seed(world_name)
	
	# Ambil data hotbar agar hotbar tidak ikut ter-reset saat simpan posisi
	var hotbar_data: Array = []
	if hotbar and "slot_tile_ids" in hotbar:
		hotbar_data = hotbar.slot_tile_ids
		
	SaveManager.save_world(world_name, current_seed, hotbar_data, global_position)

func _setup_hotbar_connection() -> void:
	if not hotbar:
		hotbar = get_node_or_null("../UILayer/Hotbar")
		
	if hotbar:
		if hotbar.has_signal("slot_changed"):
			if not hotbar.is_connected("slot_changed", _on_hotbar_slot_changed):
				hotbar.slot_changed.connect(_on_hotbar_slot_changed)
				print("✅ PLAYER: Berhasil connect ke sinyal Hotbar!")
	else:
		print("⚠️ PLAYER: Node Hotbar tidak ditemukan! Drag Node Hotbar ke Inspector Player.")

func _on_hotbar_slot_changed(_slot_index: int, tile_id: int) -> void:
	if not held_item_sprite:
		return
		
	if tile_id == -1 or not hotbar or not hotbar.tile_textures.has(tile_id):
		update_held_item(null)
	else:
		var new_tex = hotbar.tile_textures[tile_id]
		update_held_item(new_tex)

func update_held_item(new_texture: Texture2D) -> void:
	if not held_item_sprite:
		return
		
	if new_texture:
		held_item_sprite.texture = new_texture
		held_item_sprite.visible = true
	else:
		held_item_sprite.texture = null
		held_item_sprite.visible = false

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("drop"):
		drop_current_item()

func drop_current_item() -> void:
	if not hotbar or not hotbar.has_method("remove_current_item"):
		return
		
	var current_slot: int = hotbar.current_slot
	if current_slot >= hotbar.slot_tile_ids.size():
		return
		
	var tile_id: int = hotbar.slot_tile_ids[current_slot]
	if tile_id == -1:
		return
		
	var item_instance = dropped_item_scene.instantiate()
	var drop_offset = Vector2(24.0 if is_facing_right else -24.0, -8.0)
	item_instance.global_position = global_position + drop_offset
	
	var item_texture: Texture2D = null
	if hotbar.tile_textures.has(tile_id):
		item_texture = hotbar.tile_textures[tile_id]
		
	if item_instance.has_method("setup_item"):
		item_instance.setup_item(tile_id, item_texture)
		
	get_parent().add_child(item_instance)
	hotbar.consume_current_item(1)

func handle_footstep_sfx(delta: float) -> void:
	if is_on_floor() and abs(velocity.x) > 10:
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
		air_jumps_used = 0 # Reset jumlah lompatan udara saat mendarat

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

	# 5. Membalikkan Arah Visual dengan Efek Smooth Flip (Tween)
	if final_dir > 0 and not is_facing_right:
		_apply_smooth_flip(true)
	elif final_dir < 0 and is_facing_right:
		_apply_smooth_flip(false)

	# 6. Lompat (auto-jump saat ditahan di tanah + double jump dengan tekan baru di udara)
	if Input.is_action_pressed("jump") and is_on_floor():
		jump()
	elif Input.is_action_just_pressed("jump") and not is_on_floor() and air_jumps_used < MAX_AIR_JUMPS:
		jump()

	if Input.is_action_just_released("jump") and velocity.y < 0:
		velocity.y *= JUMP_CUT_MAGNITUDE

	move_and_slide()

	# --- SFX FOOTSTEP ---
	handle_footstep_sfx(delta)

	if show_position_info:
		queue_redraw()

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

# --- FUNGSI EFEK SMOOTH FLIP ---
func _apply_smooth_flip(facing_right: bool) -> void:
	is_facing_right = facing_right
	var target_scale_x = 1.0 if facing_right else -1.0
	
	if flip_tween and flip_tween.is_running():
		flip_tween.kill()
		
	flip_tween = create_tween()
	flip_tween.tween_property(body_container, "scale:x", target_scale_x, 0.1)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_OUT)

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
	# Lompat dari tanah (tidak memakai slot lompatan udara)
	if is_on_floor():
		velocity.y = JUMP_VELOCITY
		
		if jump_sfx_player:
			jump_sfx_player.pitch_scale = randf_range(0.95, 1.05)
			jump_sfx_player.play()
		return
		
	# Double jump di udara (sekali per waktu terbang, naik maupun jatuh)
	if air_jumps_used >= MAX_AIR_JUMPS:
		return
		
	air_jumps_used += 1
	velocity.y = JUMP_VELOCITY
	
	# ✨ Emit partikel double jump
	double_jump_particles.restart()
	
	# Reset pengukuran jarak jatuh → fall damage dihitung dari double jump,
	# bukan dari jatuh sebelumnya (mis. terjun dari tebing lalu double jump)
	start_fall_y = global_position.y
	is_falling = true
	
	# 🔊 Putar SFX khusus double jump
	if jump_sfx_player:
		jump_sfx_player.pitch_scale = randf_range(0.8, 0.9)
		jump_sfx_player.play()

func _draw() -> void:
	if not show_position_info:
		return
	var pos_text = "X: %d  Y: %d" % [int(global_position.x / 16.0), int(global_position.y / 16.0)]
	draw_string(ThemeDB.fallback_font, Vector2(-20, -20), pos_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color.WHITE)
