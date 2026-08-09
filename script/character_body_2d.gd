extends CharacterBody2D

const SPEED = 150.0
const JUMP_VELOCITY = -300.0

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

@onready var anim_player = $AnimationPlayer
# Hubungkan node penampung tubuh (Body) ke skrip
@onready var body_container = $Body 

func _physics_process(delta):
	# 1. Logika Gravitasi
	if not is_on_floor():
		velocity.y += gravity * delta

	# 2. Logika Lompat
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# 3. Logika Arah Jalan (Kiri/Kanan)
	var direction = Input.get_axis("ui_left", "ui_right")
	if direction:
		velocity.x = direction * SPEED
		# Membalikkan hanya node penampung tubuh, bukan player utama
		if direction > 0:
			body_container.scale.x = 1.0 # Hadap Kanan
		elif direction < 0:
			body_container.scale.x = -1.0 # Hadap Kiri
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	# 4. Pemicu Animasi (Dengan Efek Transisi Mulus)
	var blend_time = 0.3 # Waktu transisi (0.15 detik). Naikkan nilainya agar lebih lambat/mulus.

	if is_on_floor():
		if direction != 0:
			if anim_player.current_animation != "walk":
				anim_player.play("walk", blend_time)
		else:
			if anim_player.current_animation != "idle":
				anim_player.play("idle", blend_time)
	else:
		# KONDISI DI UDARA (LOMPAT ATAU JATUH)
		if velocity.y > 0:
			# Jika Y positif, karakter bergerak ke bawah (jatuh)
			if anim_player.current_animation != "fall":
				anim_player.play("fall", blend_time)
		else:
			# Jika Y negatif, karakter bergerak ke atas (melompat)
			if anim_player.current_animation != "jump":
				anim_player.play("jump", blend_time)

	move_and_slide()
