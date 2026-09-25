extends Node3D

# K-Games 2: Native Vulkan 3D Game Suite
const VERSION = "0.005"

@onready var camera_pivot = $CameraPivot
@onready var camera_3d = $CameraPivot/Camera3D
@onready var status_label = $UI/TopBar/StatusLabel
@onready var version_label = $UI/TopBar/VersionLabel
@onready var world_3d = $World3D

var current_game_instance: Node3D = null
var current_game = "overview"

# Touch- und Orbit-Kamerasteuerung
var is_dragging = false
var drag_start_mouse = Vector2.ZERO
var rot_y = 0.0
var rot_x = -0.5
var touch_start_pos = Vector2.ZERO
var is_tap = false

# 10 Modulare 3D-Spiele
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
	switch_game("chess")

func _input(event):
	# Touch & Maus Interaktion
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				is_dragging = true
				is_tap = true
				drag_start_mouse = event.position
				touch_start_pos = event.position
			else:
				is_dragging = false
				if is_tap:
					# 3D-Objekt-Klick / Raycast ausführen
					raycast_click(event.position)
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			is_dragging = event.pressed
			drag_start_mouse = event.position
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			camera_3d.position.z = max(5.0, camera_3d.position.z - 0.5)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			camera_3d.position.z = min(25.0, camera_3d.position.z + 0.5)
			
	elif event is InputEventMouseMotion and is_dragging:
		var delta = event.position - drag_start_mouse
		if delta.length() > 5.0:
			is_tap = false
		drag_start_mouse = event.position
		rot_y -= delta.x * 0.005
		rot_x = clamp(rot_x - delta.y * 0.005, -1.2, 0.2)
		camera_pivot.rotation.y = rot_y
		camera_pivot.rotation.x = rot_x

func raycast_click(screen_pos: Vector2):
	if not current_game_instance: return
	if not is_instance_valid(camera_3d): return

	var ray_origin = camera_3d.project_ray_origin(screen_pos)
	var ray_normal = camera_3d.project_ray_normal(screen_pos)
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(ray_origin, ray_origin + ray_normal * 100.0)
	query.collide_with_areas = true
	query.collide_with_bodies = true
	var result = space_state.intersect_ray(query)

	if result:
		var collider = result.collider
		if collider and collider.has_meta("grid_pos"):
			var g_pos = collider.get_meta("grid_pos")
			if current_game_instance.has_method("handle_tile_clicked"):
				current_game_instance.handle_tile_clicked(g_pos)

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
			if game_node.has_signal("status_changed"):
				game_node.connect("status_changed", Callable(self, "_on_game_status_changed"))
			if status_label: status_label.text = "Schach 3D: Tippe eine Figur an zum Ziehen"
		"battleship":
			game_node.set_script(BATTLESHIP_SCRIPT)
			if status_label: status_label.text = "Schiffe versenken 3D: Taktischer Ozean & Flotte bereit"
		"mensch":
			game_node.set_script(MENSCH_SCRIPT)
			if status_label: status_label.text = "Mensch ärgere dich nicht 3D: 16 Figuren auf 3D-Holzbrett"
		"risiko":
			game_node.set_script(RISIKO_SCRIPT)
			if status_label: status_label.text = "Risiko 3D: Globale Kontinentalbühne mit Armeen"
		"civ":
			game_node.set_script(CIV_SCRIPT)
			if status_label: status_label.text = "Civilization 3D: 3D-Geländerelief, Höhen & Städte"
		"monopoly":
			game_node.set_script(MONOPOLY_SCRIPT)
			if status_label: status_label.text = "Monopoly 3D: Immobilien-Board mit Häusern & Hotels"
		"kniffel":
			game_node.set_script(KNIFFEL_SCRIPT)
			if status_label: status_label.text = "Kniffel 3D: Lederteller & PBR-Würfel"
		"lotti":
			game_node.set_script(LOTTI_SCRIPT)
			if status_label: status_label.text = "Lotti Karotti 3D: Riesenkarotte & Hasenfiguren"
		"katan":
			game_node.set_script(KATAN_SCRIPT)
			if status_label: status_label.text = "Siedler von Katan 3D: Hex-Insel mit Rohstoffen"
		"scotland":
			game_node.set_script(SCOTLAND_SCRIPT)
			if status_label: status_label.text = "Scotland Yard 3D: London City, Themse & Mister X"

	world_3d.add_child(game_node)
	current_game_instance = game_node
	print("Switched to 3D Game: ", game_name)

func _on_game_status_changed(msg: String):
	if status_label:
		status_label.text = msg

func create_game_selection_ui():
	# UI Root Panel für Android & Desktop
	var ui = $UI
	
	# Scroll-Leiste unten mit hohem Z-Index und MOUSE_FILTER_PASS
	var bottom_panel = PanelContainer.new()
	bottom_panel.name = "BottomGamePanel"
	bottom_panel.mouse_filter = Control.MOUSE_FILTER_PASS
	bottom_panel.anchors_preset = Control.PRESET_BOTTOM_WIDE
	bottom_panel.offset_top = -80
	bottom_panel.offset_bottom = -10
	bottom_panel.offset_left = 12
	bottom_panel.offset_right = -12

	var scroll = ScrollContainer.new()
	scroll.mouse_filter = Control.MOUSE_FILTER_PASS
	scroll.custom_minimum_size = Vector2(0, 64)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	bottom_panel.add_child(scroll)
	
	var hbox = HBoxContainer.new()
	hbox.mouse_filter = Control.MOUSE_FILTER_PASS
	hbox.add_theme_constant_override("separation", 12)
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
		btn.mouse_filter = Control.MOUSE_FILTER_STOP
		btn.custom_minimum_size = Vector2(170, 52)
		btn.pressed.connect(func(): switch_game(g.id))
		hbox.add_child(btn)

	ui.add_child(bottom_panel)
