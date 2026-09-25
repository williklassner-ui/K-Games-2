extends Node3D

class_name MenschAergereDichNicht3D

func _ready():
	setup_stage()

func setup_stage():
	# Hölzernes Spielbrett
	var board_mesh = CylinderMesh.new()
	board_mesh.top_radius = 5.2
	board_mesh.bottom_radius = 5.4
	board_mesh.height = 0.35
	var board_inst = MeshInstance3D.new()
	board_inst.mesh = board_mesh
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.85, 0.76, 0.58)
	mat.roughness = 0.3
	board_inst.material_override = mat
	board_inst.position = Vector3(0, 0.15, 0)
	add_child(board_inst)

	# 40 Lauffelder im Kreis angeordnet
	var radius = 3.6
	for i in range(40):
		var angle = (float(i) / 40.0) * TAU
		var x = cos(angle) * radius
		var z = sin(angle) * radius
		
		var tile_mesh = CylinderMesh.new()
		tile_mesh.top_radius = 0.22
		tile_mesh.bottom_radius = 0.22
		tile_mesh.height = 0.05
		var tile = MeshInstance3D.new()
		tile.mesh = tile_mesh
		
		var tile_mat = StandardMaterial3D.new()
		if i % 10 == 0:
			# Startfelder der 4 Farben
			var colors = [Color(0.85, 0.15, 0.15), Color(0.15, 0.75, 0.25), Color(0.95, 0.75, 0.1), Color(0.15, 0.45, 0.95)]
			tile_mat.albedo_color = colors[int(i / 10)]
		else:
			tile_mat.albedo_color = Color(0.98, 0.98, 0.95)
			
		tile_mat.roughness = 0.25
		tile.material_override = tile_mat
		tile.position = Vector3(x, 0.35, z)
		add_child(tile)

	# 4 Spielfarben-Figuren (Rot, Grün, Gelb, Blau) in Startbasen und auf Feldern
	var colors = [
		{"col": Color(0.9, 0.12, 0.12), "base": Vector3(-3.2, 0.4, -3.2)},
		{"col": Color(0.12, 0.8, 0.25), "base": Vector3(3.2, 0.4, -3.2)},
		{"col": Color(0.95, 0.8, 0.1), "base": Vector3(3.2, 0.4, 3.2)},
		{"col": Color(0.15, 0.4, 0.95), "base": Vector3(-3.2, 0.4, 3.2)}
	]

	for c in colors:
		for f in range(4):
			var ox = (f % 2) * 0.6 - 0.3
			var oz = (int(f / 2)) * 0.6 - 0.3
			spawn_pawn(c.base + Vector3(ox, 0, oz), c.col)

func spawn_pawn(pos: Vector3, col: Color):
	var pawn = Node3D.new()
	pawn.position = pos
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = col
	mat.roughness = 0.2
	mat.metallic = 0.25

	# Kegelkörper
	var body_mesh = CylinderMesh.new()
	body_mesh.top_radius = 0.12
	body_mesh.bottom_radius = 0.25
	body_mesh.height = 0.65
	var body = MeshInstance3D.new()
	body.mesh = body_mesh
	body.material_override = mat
	body.position = Vector3(0, 0.35, 0)
	pawn.add_child(body)

	# Kopfkugel
	var head_mesh = SphereMesh.new()
	head_mesh.radius = 0.18
	head_mesh.height = 0.36
	var head = MeshInstance3D.new()
	head.mesh = head_mesh
	head.material_override = mat
	head.position = Vector3(0, 0.78, 0)
	pawn.add_child(head)

	add_child(pawn)
