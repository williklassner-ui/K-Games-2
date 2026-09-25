extends Node3D

class_name ScotlandYard3D

func _ready():
	setup_stage()

func setup_stage():
	# Londons 3D Stadtkarte mit Themse-Flusslauf & Straßennetz
	var map_mesh = BoxMesh.new()
	map_mesh.size = Vector3(12.0, 0.35, 9.0)
	var map_inst = MeshInstance3D.new()
	map_inst.mesh = map_mesh
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.14, 0.15, 0.18)
	mat.roughness = 0.5
	map_inst.material_override = mat
	map_inst.position = Vector3(0, 0.15, 0)
	add_child(map_inst)

	# Themse (Flusslauf) geschwungen in 3D
	var river_points = [Vector3(-5.5, 0.36, -1.0), Vector3(-2.0, 0.36, -0.2), Vector3(1.5, 0.36, 1.2), Vector3(5.5, 0.36, 0.8)]
	for p in river_points:
		var r_mesh = BoxMesh.new()
		r_mesh.size = Vector3(3.2, 0.05, 1.2)
		var r_inst = MeshInstance3D.new()
		r_inst.mesh = r_mesh
		var r_mat = StandardMaterial3D.new()
		r_mat.albedo_color = Color(0.05, 0.28, 0.55, 0.85)
		r_mat.roughness = 0.1
		r_inst.material_override = r_mat
		r_inst.position = p
		add_child(r_inst)

	# Haltestellen / Stationen (Taxi=Gelb, Bus=Blau, U-Bahn=Rot)
	var stations = [
		{"pos": Vector3(-3.5, 0.38, -2.5), "type": "metro", "col": Color(0.9, 0.15, 0.15)},
		{"pos": Vector3(-1.0, 0.38, -2.0), "type": "bus", "col": Color(0.15, 0.4, 0.9)},
		{"pos": Vector3(2.5, 0.38, -2.5), "type": "taxi", "col": Color(0.95, 0.8, 0.1)},
		{"pos": Vector3(-2.5, 0.38, 2.0), "type": "metro", "col": Color(0.9, 0.15, 0.15)},
		{"pos": Vector3(0.5, 0.38, 2.5), "type": "bus", "col": Color(0.15, 0.4, 0.9)},
		{"pos": Vector3(3.5, 0.38, 2.0), "type": "taxi", "col": Color(0.95, 0.8, 0.1)}
	]

	for s in stations:
		var st_mesh = CylinderMesh.new()
		st_mesh.top_radius = 0.28
		st_mesh.bottom_radius = 0.28
		st_mesh.height = 0.06
		var st = MeshInstance3D.new()
		st.mesh = st_mesh
		var st_mat = StandardMaterial3D.new()
		st_mat.albedo_color = s.col
		st.material_override = st_mat
		st.position = s.pos
		add_child(st)

	# Mister X Figur (Schwarz mit Zylinder) & 2 Detektive (Farbig)
	spawn_detective(Vector3(-1.0, 0.45, -2.0), Color(0.15, 0.4, 0.9))
	spawn_detective(Vector3(0.5, 0.45, 2.5), Color(0.85, 0.2, 0.2))
	spawn_mister_x(Vector3(3.5, 0.45, 2.0))

func spawn_detective(pos: Vector3, col: Color):
	var d = Node3D.new()
	d.position = pos
	var mat = StandardMaterial3D.new()
	mat.albedo_color = col

	var body = MeshInstance3D.new()
	var b_m = CylinderMesh.new()
	b_m.top_radius = 0.12
	b_m.bottom_radius = 0.22
	b_m.height = 0.55
	body.mesh = b_m
	body.material_override = mat
	body.position = Vector3(0, 0.28, 0)
	d.add_child(body)
	add_child(d)

func spawn_mister_x(pos: Vector3):
	var x = Node3D.new()
	x.position = pos
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.08, 0.08, 0.1)
	mat.roughness = 0.2

	var body = MeshInstance3D.new()
	var b_m = CylinderMesh.new()
	b_m.top_radius = 0.12
	b_m.bottom_radius = 0.22
	b_m.height = 0.55
	body.mesh = b_m
	body.material_override = mat
	body.position = Vector3(0, 0.28, 0)
	x.add_child(body)

	# Zylinder-Hut
	var hat = MeshInstance3D.new()
	var h_m = CylinderMesh.new()
	h_m.top_radius = 0.14
	h_m.bottom_radius = 0.14
	h_m.height = 0.22
	hat.mesh = h_m
	hat.material_override = mat
	hat.position = Vector3(0, 0.65, 0)
	x.add_child(hat)

	add_child(x)
