extends CharacterBody2D

@export var tile_id: int = 1
@export var amount: int = 1

@onready var sprite: Sprite2D = $Sprite2D
@onready var pickup_area: Area2D = $PickupArea
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
var bounce_strength: float = -120.0

var is_being_picked_up: bool = false
var target_player: Node2D = null

# ⏱️ Variabel Cooldown Pickup
var can_be_picked_up: bool = false
@export var pickup_delay: float = 0.25 # Cooldown 0.25 detik

func _ready() -> void:
		# Bikin cipratan acak pas item baru dijatuhkan
		velocity.y = bounce_strength
		velocity.x = randf_range(-30.0, 30.0)
		
		if pickup_area:
				pickup_area.body_entered.connect(_on_pickup_area_body_entered)
		
		# ⏳ Buat Timer 0.2 detik sebelum item BISA diambil
		get_tree().create_timer(pickup_delay).timeout.connect(func():
				can_be_picked_up = true
				
				# Cek ulang: kalau player dari awal sudah berdiri di dalam area item pas cooldown selesai, langsung pickup!
				if pickup_area:
						for body in pickup_area.get_overlapping_bodies():
								if body.is_in_group("players") and not is_being_picked_up:
										start_pickup(body)
										break
		)

func _physics_process(delta: float) -> void:
		if is_being_picked_up and target_player:
				# 🧲 Terbang tersedot ke player
				global_position = global_position.lerp(target_player.global_position, delta * 14.0)
				
				if global_position.distance_to(target_player.global_position) < 12.0:
						collect_item()
		else:
				# 🍎 Jatuh pakai gravitasi
				if not is_on_floor():
						velocity.y += gravity * delta
				else:
						velocity.x = move_toward(velocity.x, 0, 300 * delta)
						
				move_and_slide()

func setup_item(id: int, item_texture: Texture2D) -> void:
		tile_id = id
		if sprite:
				sprite.texture = item_texture

func _on_pickup_area_body_entered(body: Node2D) -> void:
		# Hanya jalankan jika cooldown sudah selesai!
		if can_be_picked_up and body.is_in_group("players") and not is_being_picked_up:
				start_pickup(body)

func start_pickup(player: Node2D) -> void:
		is_being_picked_up = true
		target_player = player
		
		# Matikan kolisi fisika & hapus mask agar tidak saling dorong
		set_deferred("collision_layer", 0)
		set_deferred("collision_mask", 0)
		if collision_shape:
				collision_shape.set_deferred("disabled", true)

func collect_item() -> void:
		var hotbar = get_tree().root.find_child("HotbarUI", true, false)
		if hotbar and hotbar.has_method("add_item_to_hotbar"):
				hotbar.add_item_to_hotbar(tile_id, amount)
		
		queue_free()