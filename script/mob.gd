extends CharacterBody2D

const GRAVITY = 980.0
const JUMP_VELOCITY = -240.0

# --- PENGATURAN WANDER ---
@export var walk_speed: float = 25.0
@export var decision_min_time: float = 0.8
@export var decision_max_time: float = 2.5
@export var ledge_ray_length: float = 26.0
@export var max_climb_attempts: int = 2

var direction: int = 0
var is_facing_right: bool = true
var decision_timer: float = 0.0
var jump_cooldown: float = 0.0
var climb_attempts: int = 0

@onready var visual: Node2D = $Visual
@onready var ledge_ray: RayCast2D = $LedgeRay

func _ready() -> void:
	add_to_group("mobs")
	make_decision()

func _physics_process(delta: float) -> void:
	jump_cooldown = max(jump_cooldown - delta, 0.0)
	
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	else:
		if is_on_wall():
			# Coba nanjak 1 blok dengan lompat. Kalau gagal setelah beberapa kali → balik arah.
			if jump_cooldown <= 0.0:
				if climb_attempts >= max_climb_attempts:
					climb_attempts = 0
					set_direction(-direction)
				else:
					climb_attempts += 1
					jump_cooldown = 0.5
					velocity.y = JUMP_VELOCITY
		else:
			climb_attempts = 0
			# Balik arah hanya jika di depan ada jurang yang dalam (bukan tangga 1 blok)
			if direction != 0 and ledge_ray and not ledge_ray.is_colliding():
				set_direction(-direction)
	
	# Kecepatan horizontal selalu diterapkan (di darat maupun di udara)
	velocity.x = direction * walk_speed
	
	decision_timer -= delta
	if decision_timer <= 0.0:
		make_decision()
	
	move_and_slide()

func make_decision() -> void:
	var r = randi() % 10
	if r < 3:
		set_direction(0)
	elif r < 7:
		set_direction(1)
	else:
		set_direction(-1)
	decision_timer = randf_range(decision_min_time, decision_max_time)

func set_direction(new_dir: int) -> void:
	direction = new_dir
	if direction == 0:
		return
		
	var facing_right = direction > 0
	if facing_right != is_facing_right:
		is_facing_right = facing_right
		if visual:
			visual.scale.x = 1.0 if facing_right else -1.0
			
	if ledge_ray:
		ledge_ray.target_position = Vector2(ledge_ray_length * direction, ledge_ray_length)
