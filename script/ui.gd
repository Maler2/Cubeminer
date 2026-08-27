extends Control

# Slot Export dengan Default Preload
@export var heart_full: Texture2D = preload("res://assets/icon/heart-full-icon.png")
@export var heart_half: Texture2D = preload("res://assets/icon/heart-half-icon.png")
@export var heart_empty: Texture2D = preload("res://assets/icon/heart-lose-icon.png")

@export var hunger_full: Texture2D = preload("res://assets/icon/hunger-full-icon.png")
@export var hunger_half: Texture2D = preload("res://assets/icon/hunger-half-icon.png")
@export var hunger_empty: Texture2D = preload("res://assets/icon/hunger-lose-icon.png")

# Node Containers
@onready var hearts_container: HBoxContainer = $HeartsContainer
@onready var hunger_container: HBoxContainer = $HungerContainer

# Menggunakan Node HungerTimer dari Scene
@onready var hunger_timer: Timer = $HungerTimer

# Data HP & Hunger
var max_hp: float = 6.0
var current_hp: float = 6.0

var max_hunger: float = 10.0
var current_hunger: float = 10.0

func _ready() -> void:
	update_hearts()
	update_hunger()
	
	# === SETTING TIMER DARI NODE SCENE ===
	hunger_timer.autostart = true
	hunger_timer.one_shot = false
	
	# Hubungkan sinyal jika belum disambungkan dari Editor
	if not hunger_timer.timeout.is_connected(_on_hunger_timer_timeout):
		hunger_timer.timeout.connect(_on_hunger_timer_timeout)
		
	hunger_timer.start()

func _on_hunger_timer_timeout() -> void:
	# Mengurangi 0.2 hunger per tick
	consume_hunger(0.2)

# ==================== HP SYSTEM ====================
func take_damage(amount: float) -> void:
	var hp_sebelumnya = current_hp
	current_hp = clamp(current_hp - amount, 0.0, max_hp)
	
	print("[UI LOG] HP Berkurang: -%.2f | HP: %.2f -> %.2f / %.2f" % [amount, hp_sebelumnya, current_hp, max_hp])
	
	update_hearts()
	
	if current_hp <= 0:
		print("[GAME OVER] Pemain kehabisan HP!")

func update_hearts() -> void:
	if not hearts_container:
		return

	for child in hearts_container.get_children():
		child.queue_free()
		
	var total_hearts = int(max_hp / 2.0)
	
	for i in range(total_hearts):
		var heart_rect = TextureRect.new()
		heart_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		heart_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
		heart_rect.custom_minimum_size = Vector2(16, 16)
		heart_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		heart_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		
		var heart_value = clamp(current_hp - (i * 2.0), 0.0, 2.0)
		
		# LOGIKA: > 1.0 = FULL, > 0.0 = HALF, <= 0.0 = EMPTY
		if heart_value > 1.0:
			heart_rect.texture = heart_full
		elif heart_value > 0.0:
			heart_rect.texture = heart_half
		else:
			heart_rect.texture = heart_empty
			
		hearts_container.add_child(heart_rect)

# ==================== HUNGER SYSTEM ====================
func consume_hunger(amount: float) -> void:
	var hunger_sebelumnya = current_hunger
	current_hunger = clamp(current_hunger - amount, 0.0, max_hunger)
	
	print("[UI LOG] Hunger Berkurang: -%.2f | Hunger: %.2f -> %.2f / %.2f" % [amount, hunger_sebelumnya, current_hunger, max_hunger])
	
	update_hunger()
	
	if current_hunger <= 0:
		print("[WARNING] Pemain kelaparan!")

func eat_food(amount: float) -> void:
	var hunger_sebelumnya = current_hunger
	current_hunger = clamp(current_hunger + amount, 0.0, max_hunger)
	
	print("[UI LOG] Makan: +%.2f | Hunger: %.2f -> %.2f / %.2f" % [amount, hunger_sebelumnya, current_hunger, max_hunger])
	
	update_hunger()

func update_hunger() -> void:
	if not hunger_container:
		return

	for child in hunger_container.get_children():
		child.queue_free()
		
	var total_hunger_icons = int(max_hunger / 2.0)
	
	for i in range(total_hunger_icons):
		var hunger_rect = TextureRect.new()
		hunger_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		hunger_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
		hunger_rect.custom_minimum_size = Vector2(16, 16)
		hunger_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		hunger_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		
		# Hitung sisa poin di slot ke-i (0.0 sampai 2.0)
		var hunger_value = clamp(current_hunger - (i * 2.0), 0.0, 2.0)
		
		# LOGIKA: 1 POINT = HALF (1 SLOT UTUH = 2 POINT)
		if hunger_value > 1.0:
			hunger_rect.texture = hunger_full
		elif hunger_value > 0.0:
			hunger_rect.texture = hunger_half
		else:
			hunger_rect.texture = hunger_empty
			
		hunger_container.add_child(hunger_rect)