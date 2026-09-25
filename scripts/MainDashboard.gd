extends Node3D

# K-Games 2: Native Vulkan 3D Game Suite
const VERSION = "0.001"

@onready var camera_pivot = \
@onready var status_label = \/TopBar/StatusLabel
@onready var version_label = \/TopBar/VersionLabel
@onready var world_3d = \

var current_game = "overview"
var is_dragging = false
var drag_start_mouse = Vector2.ZERO
var rot_y = 0.0
var rot_x = -0.4

func _ready():
	print("=== K-Games 2 (Vulkan Engine Forward+) Initialized ===")
	print("Version: ", VERSION)
	if version_label:
		version_label.text = "v" + VERSION + " (Vulkan Forward+)"
	setup_3d_tabletop_scene()

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT or event.button_index == MOUSE_BUTTON_RIGHT:
			is_dragging = event.pressed
			drag_start_mouse = event.position
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			\/Camera3D.position.z = max(5.0, \/Camera3D.position.z - 0.5)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			\/Camera3D.position.z = min(25.0, \/Camera3D.position.z + 0.5)
			
	elif event is InputEventMouseMotion and is_dragging:
		var delta = event.position - drag_start_mouse
		drag_start_mouse = event.position
		rot_y -= delta.x * 0.005
		rot_x = clamp(rot_x - delta.y * 0.005, -1.2, 0.2)
		camera_pivot.rotation.y = rot_y
		camera_pivot.rotation.x = rot_x

func setup_3d_tabletop_scene():
	# Procedural 3D Stage / Board Generation with Real Elevation & PBR Materials
	var table_mesh = BoxMesh.new()
	table_mesh.size = Vector3(16.0, 0.6, 16.0)
	var table_inst = MeshInstance3D.new()
	table_inst.mesh = table_mesh
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.08, 0.12, 0.18)
	mat.roughness = 0.35
	mat.metallic = 0.4
	table_inst.material_override = mat
	table_inst.position = Vector3(0, -0.3, 0)
	world_3d.add_child(table_inst)

func switch_game(game_name: String):
	current_game = game_name
	if status_label:
		status_label.text = "Aktives 3D-Spiel: " + game_name.capitalize()
	print("Switched to 3D Game: ", game_name)
