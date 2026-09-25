extends Node3D

class_name Risiko3D

func _ready():
	setup_stage()

func setup_stage():
	# Weltkarten-Sockel
	var map_mesh = BoxMesh.new()
	map_mesh.size = Vector3(13.0, 0.4, 8.5)
	var map_inst = MeshInstance3D.new()
	map_inst.mesh = map_mesh
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.08, 0.16, 0.24)
	mat.roughness = 0.4
	map_inst.material_override = mat
	map_inst.position = Vector3(0, 0.15, 0)
	add_child(map_inst)

	# 3D-Kontinente mit Höhenplateaus
	var continents = [
		{"name": "Nordamerika", "pos": Vector3(-4.0, 0.38, -1.8), "size": Vector3(3.2, 0.15, 2.5), "col": Color(0.85, 0.75, 0.25)},
		{"name": "Südamerika", "pos": Vector3(-3.2, 0.38, 1.8), "size": Vector3(2.0, 0.15, 2.8), "col": Color(0.82, 0.38, 0.15)},
		{"name": "Europa", "pos": Vector3(0.2, 0.38, -2.0), "size": Vector3(2.4, 0.15, 1.8), "col": Color(0.22, 0.55, 0.85)},
		{"name": "Afrika", "pos": Vector3(0.3, 0.38, 1.2), "size": Vector3(2.6, 0.15, 2.8), "col": Color(0.75, 0.65, 0.2)},
		{"name": "Asien", "pos": Vector3(3.8, 0.38, -1.5), "size": Vector3(4.2, 0.15, 3.2), "col": Color(0.25, 0.75, 0.4)},
		{"name": "Australien", "pos": Vector3(4.2, 0.38, 2.2), "size": Vector3(2.2, 0.15, 1.8), "col": Color(0.65, 0.3, 0.75)}
	]

	for c in continents:
		var c_mesh = BoxMesh.new()
		c_mesh.size = c.size
		var c_inst = MeshInstance3D.new()
		c_inst.mesh = c_mesh
		
		var c_mat = StandardMaterial3D.new()
		c_mat.albedo_color = c.col
		c_mat.roughness = 0.35
		c_inst.material_override = c_mat
		c_inst.position = c.pos
		add_child(c_inst)

		# Armee-Einheiten (Infanterie-Würfel, Kavallerie-Prismen, Kanonen-Zylinder)
		spawn_army(c.pos + Vector3(-0.4, 0.15, 0), Color(0.9, 0.1, 0.1), "infantry")
		spawn_army(c.pos + Vector3(0.4, 0.15, 0), Color(0.1, 0.3, 0.9), "cavalry")

func spawn_army(pos: Vector3, col: Color, unit_type: String):
	var unit = Node3D.new()
	unit.position = pos
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = col
	mat.metallic = 0.6
	mat.roughness = 0.25

	if unit_type == "infantry":
		var m = BoxMesh.new()
		m.size = Vector3(0.25, 0.5, 0.25)
		var inst = MeshInstance3D.new()
		inst.mesh = m
		inst.material_override = mat
		inst.position = Vector3(0, 0.25, 0)
		unit.add_child(inst)
	else:
		var m = CylinderMesh.new()
		m.top_radius = 0.15
		m.bottom_radius = 0.22
		m.height = 0.45
		var inst = MeshInstance3D.new()
		inst.mesh = m
		inst.material_override = mat
		inst.position = Vector3(0, 0.22, 0)
		unit.add_child(inst)

	add_child(unit)
