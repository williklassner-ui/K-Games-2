extends Node3D

class_name Kniffel3D

func _ready():
	setup_stage()

func setup_stage():
	# Lederner 3D-Würfelteller
	var tray_mesh = CylinderMesh.new()
	tray_mesh.top_radius = 4.0
	tray_mesh.bottom_radius = 4.2
	tray_mesh.height = 0.5
	var tray_inst = MeshInstance3D.new()
	tray_inst.mesh = tray_mesh
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.08, 0.28, 0.15)
	mat.roughness = 0.45
	tray_inst.material_override = mat
	tray_inst.position = Vector3(0, 0.2, 0)
	add_child(tray_inst)

	# 5 physikalische 3D-Würfel mit abgerundeten Kanten & Augen
	var dice_coords = [
		Vector3(-1.8, 0.55, -0.8),
		Vector3(-0.9, 0.55, 0.9),
		Vector3(0.0, 0.55, -0.6),
		Vector3(1.1, 0.55, 0.8),
		Vector3(2.0, 0.55, -0.4)
	]

	for i in range(5):
		spawn_die(dice_coords[i], i + 1)

func spawn_die(pos: Vector3, face_val: int):
	var die = Node3D.new()
	die.position = pos
	die.rotation_degrees = Vector3(randf_range(-15, 15), randf_range(0, 360), randf_range(-15, 15))

	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.96, 0.96, 0.94)
	mat.roughness = 0.12
	mat.metallic = 0.05

	var m = BoxMesh.new()
	m.size = Vector3(0.7, 0.7, 0.7)
	var inst = MeshInstance3D.new()
	inst.mesh = m
	inst.material_override = mat
	inst.position = Vector3(0, 0.35, 0)
	die.add_child(inst)

	# Würfelpunkte (Pips)
	var pip_mesh = SphereMesh.new()
	pip_mesh.radius = 0.06
	pip_mesh.height = 0.1
	var pip_mat = StandardMaterial3D.new()
	pip_mat.albedo_color = Color(0.1, 0.1, 0.1)

	var pip_inst = MeshInstance3D.new()
	pip_inst.mesh = pip_mesh
	pip_inst.material_override = pip_mat
	pip_inst.position = Vector3(0, 0.71, 0)
	die.add_child(pip_inst)

	add_child(die)
