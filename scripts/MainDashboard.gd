extends Node3D

# K-Games 2: Native Vulkan 3D Game Suite
const VERSION = "0.004"

@onready var camera_pivot = $CameraPivot
@onready var status_label = $UI/TopBar/StatusLabel
@onready var version_label = $UI/TopBar/VersionLabel
@onready var world_3d = $World3D

var current_game_instance: Node3D = null
var current_game = "overview"
var is_dragging = false
var drag_start_mouse = Vector2.ZERO
var rot_y = 0.0
var rot_x = -0.4

# Modulare 3D-Spiele
const CHESS_SCRIPT = preload("res://scripts/games/Chess3D.gd")
const BATTLESHIP_SCRIPT = preload("res://scripts/games/Battleship3D.gd")
const MENSCH_SCRIPT = preload("res://scripts/games/MenschAergereDichNicht3D.gd")
const RISIKO_SCRIPT = preload("res://scripts/games/Risiko3D.gd")
const CIV_SCRIPT = preload("res://scripts/games/Civilization3D.gd")
const MONOPOLY_SCRIPT = preload("res://scripts/games/Monopoly3D.gd")
const KNIFFEL_SCRIPT = preload("res://scripts/games/Kniffel3D.gd")
const LOTTI_SCRIPT = preload("res://scripts/games/LottiKarotti3D.gd")
const KATAN_SCRIPT = preload("res://scripts/games/Katan3D.gd")
const SCOTLAND_SCRIPT = preload("res://scripts/games/ScotlandYard3D.gd")

func _ready():
	print("=== K-Games 2 (Vulkan Engine Forward+) Initialized ===")
	print("Version: ", VERSION)
	if version_label:
		version_label.text = "v" + VERSION + " (Vulkan Forward+)"
	setup_3d_tabletop_scene()
	create_game_selection_ui()
	# Standardmäßig mit Schach starten
	switch_game("chess")

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT or event.button_index == MOUSE_BUTTON_RIGHT:
			is_dragging = event.pressed
			drag_start_mouse = event.position
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			$CameraPivot/Camera3D.position.z = max(5.0, $CameraPivot/Camera3D.position.z - 0.5)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			$CameraPivot/Camera3D.position.z = min(25.0, $CameraPivot/Camera3D.position.z + 0.5)
			
	elif event is InputEventMouseMotion and is_dragging:
		var delta = event.position - drag_start_mouse
		drag_start_mouse = event.position
		rot_y -= delta.x * 0.005
		rot_x = clamp(rot_x - delta.y * 0.005, -1.2, 0.2)
		camera_pivot.rotation.y = rot_y
		camera_pivot.rotation.x = rot_x

func setup_3d_tabletop_scene():
	var table_mesh = BoxMesh.new()
	table_mesh.size = Vector3(18.0, 0.6, 18.0)
	var table_inst = MeshInstance3D.new()
	table_inst.mesh = table_mesh
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.06, 0.09, 0.14)
	mat.roughness = 0.25
	mat.metallic = 0.5
	table_inst.material_override = mat
	table_inst.position = Vector3(0, -0.3, 0)
	world_3d.add_child(table_inst)

func switch_game(game_name: String):
	current_game = game_name
	if current_game_instance:
		current_game_instance.queue_free()
		current_game_instance = null

	var game_node = Node3D.new()
	game_node.name = game_name.capitalize() + "Instance"

	match game_name:
		"chess":
			game_node.set_script(CHESS_SCRIPT)
			if status_label: status_label.text = "Aktives 3D-Spiel: Schach (3D Marmor & PBR Figuren)"
		"battleship":
			game_node.set_script(BATTLESHIP_SCRIPT)
			if status_label: status_label.text = "Aktives 3D-Spiel: Schiffe versenken (3D Ozean & Schlachtschiffe)"
		"mensch":
			game_node.set_script(MENSCH_SCRIPT)
			if status_label: status_label.text = "Aktives 3D-Spiel: Mensch ärgere dich nicht (3D Holzbrett)"
		"risiko":
			game_node.set_script(RISIKO_SCRIPT)
			if status_label: status_label.text = "Aktives 3D-Spiel: Risiko (3D Weltkarte & Armeen)"
		"civ":
			game_node.set_script(CIV_SCRIPT)
			if status_label: status_label.text = "Aktives 3D-Spiel: Civilization (3D Geländerelief, Berge & Städte)"
		"monopoly":
			game_node.set_script(MONOPOLY_SCRIPT)
			if status_label: status_label.text = "Aktives 3D-Spiel: Monopoly (3D City-Board, Häuser & Hotels)"
		"kniffel":
			game_node.set_script(KNIFFEL_SCRIPT)
			if status_label: status_label.text = "Aktives 3D-Spiel: Kniffel (3D Lederteller & PBR-Würfel)"
		"lotti":
			game_node.set_script(LOTTI_SCRIPT)
			if status_label: status_label.text = "Aktives 3D-Spiel: Lotti Karotti (3D Karottenhügel & Hasen)"
		"katan":
			game_node.set_script(KATAN_SCRIPT)
			if status_label: status_label.text = "Aktives 3D-Spiel: Siedler von Katan (3D Hex-Insel, Dörfer & Straßen)"
		"scotland":
			game_node.set_script(SCOTLAND_SCRIPT)
			if status_label: status_label.text = "Aktives 3D-Spiel: Scotland Yard (3D London-City & Themse)"

	world_3d.add_child(game_node)
	current_game_instance = game_node
	print("Switched to 3D Game: ", game_name)

func create_game_selection_ui():
	var ui = $UI
	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 60)
	scroll.anchors_preset = Control.PRESET_BOTTOM_WIDE
	scroll.offset_top = -68
	scroll.offset_bottom = -8
	scroll.offset_left = 20
	scroll.offset_right = -20
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)
	scroll.add_child(hbox)

	var games = [
		{"id": "chess", "name": "♟️ Schach 3D"},
		{"id": "risiko", "name": "🌍 Risiko 3D"},
		{"id": "battleship", "name": "🚢 Schiffe versenken 3D"},
		{"id": "civ", "name": "🏛️ Civilization 3D"},
		{"id": "mensch", "name": "🎲 Mensch ärgere dich nicht 3D"},
		{"id": "monopoly", "name": "🎩 Monopoly 3D"},
		{"id": "kniffel", "name": "🎯 Kniffel 3D"},
		{"id": "lotti", "name": "🥕 Lotti Karotti 3D"},
		{"id": "katan", "name": "🌾 Katan 3D"},
		{"id": "scotland", "name": "🕵️ Scotland Yard 3D"}
	]

	for g in games:
		var btn = Button.new()
		btn.text = g.name
		btn.custom_minimum_size = Vector2(160, 48)
		btn.pressed.connect(func(): switch_game(g.id))
		hbox.add_child(btn)

	ui.add_child(scroll)
