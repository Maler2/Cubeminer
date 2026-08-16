extends Node
# Autoload: HoverManager
# Memberikan efek hover "gelap" pada background (NinePatchRect bernama "BGButton")
# milik Control/Button mana pun di semua scene, tanpa perlu wiring manual.
# Cukup letakkan NinePatchRect bernama "BGButton" sebagai anak tombol.

const HOVER_SELECT: Color = Color(1.2, 1.2, 1.2, 1)
const HOVER_NORMAL: Color = Color(1, 1, 1, 1)

func _ready() -> void:
	get_tree().node_added.connect(_on_node_added)

func _on_node_added(node: Node) -> void:
	if node.name != "BGButton":
		return
	var parent: Node = node.get_parent()
	if parent is Control:
		parent.mouse_entered.connect(_on_hovered.bind(node))
		parent.mouse_exited.connect(_on_hover_exited.bind(node))

func _on_hovered(bg: NinePatchRect) -> void:
	bg.modulate = HOVER_SELECT

func _on_hover_exited(bg: NinePatchRect) -> void:
	bg.modulate = HOVER_NORMAL
