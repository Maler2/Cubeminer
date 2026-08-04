extends Control

# Slot untuk drag & drop 3 gambar buatanmu di Inspector
@export var heart_full: Texture2D
@export var heart_half: Texture2D
@export var heart_empty: Texture2D

@onready var hearts_container: HBoxContainer = $HeartsContainer

# Data HP disimpan lokal di sini (tanpa Autoload)
var max_hp: int = 6       # Asumsi: 1 Hati = 2 HP (6 HP = 3 Hati)
var current_hp: int = 6

func _ready() -> void:
	update_hearts()

func take_damage(amount: int) -> void:
	var hp_sebelumnya = current_hp
	current_hp -= amount
	current_hp = clamp(current_hp, 0, max_hp)
	
	# --- LOG PERUBAHAN HP ---
	print("[UI LOG] HP Berkurang: -", amount, " | HP Sebelumnya: ", hp_sebelumnya, " -> HP Sekarang: ", current_hp, "/", max_hp)
	
	update_hearts()
	
	# Cek jika HP habis
	if current_hp <= 0:
		print("[GAME OVER] Pemain telah kehabisan HP!")

func update_hearts() -> void:
	# (Kode pembaruan gambar hati kamu tetap sama)
	for child in hearts_container.get_children():
		child.queue_free()
	@warning_ignore("integer_division")
	var total_hearts = max_hp / 2
	
	for i in range(total_hearts):
		var heart_rect = TextureRect.new()
		heart_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		
		var heart_value = (i + 1) * 2
		
		if current_hp >= heart_value:
			heart_rect.texture = heart_full
		elif current_hp == heart_value - 1:
			heart_rect.texture = heart_half
		else:
			heart_rect.texture = heart_empty
			
		hearts_container.add_child(heart_rect)