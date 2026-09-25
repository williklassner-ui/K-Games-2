extends Node3D

class_name Monopoly3D

func _ready():
	setup_stage()

func setup_stage():
	# Monopoly 3D Tisch und Außenrahmen
	var board_mesh = BoxMesh.new()
	board_mesh.size = Vector3(10.0, 0.4, 10.0)
	var board_inst = MeshInstance3D.new()
	board_inst.mesh = board_mesh
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.12, 0.14, 0.18)
	mat.roughness = 0.35
	board_inst.material_override = mat
	board_inst.position = Vector3(0, 0.15, 0)
	add_child(board_inst)

	# 40 Spielfelder im Quadrat
	for i in range(40):
		var pos = Vector3.ZERO
		var edge_idx = i % 10
		var side = int(i / 10)
		var coord = (edge_idx - 4.5) * 0.95
		
		if side == 0:
			pos = Vector3(coord, 0.38, 4.4)
		elif side == 1:
			pos = Vector3(-4.4, 0.38, -coord)
		elif side == 2:
			pos = Vector3(-coord, 0.38, -4.4)
		else:
			pos = Vector3(4.4, 0.38, coord)

		var tile_mesh = BoxMesh.new()
		tile_mesh.size = Vector3(0.9, 0.08, 0.9)
		var tile = MeshInstance3D.new()
		tile.mesh = tile_mesh
		
		var t_mat = StandardMaterial3D.new()
		if edge_idx == 0:
			t_mat.albedo_color = Color(0.95, 0.2, 0.2)
		else:
			var str_colors = [Color(0.55, 0.27, 0.07), Color(0.68, 0.85, 0.9), Color(0.85, 0.3, 0.7), Color(0.95, 0.55, 0.1), Color(0.9, 0.1, 0.1), Color(0.95, 0.9, 0.15), Color(0.15, 0.7, 0.25), Color(0.1, 0.2, 0.8)]
			t_mat.albedo_color = str_colors[int(i / 5) % 8]
		
		t_mat.roughness = 0.2
		tile.material_override = t_mat
		tile.position = pos
		add_child(tile)

	# 3D Häuser (Grün) und Hotels (Rot) auf Straßen
	spawn_property(Vector3(-2.5, 0.45, 4.4), Color(0.1, 0.8, 0.2), "house")
	spawn_property(Vector3(-1.5, 0.45, 4.4), Color(0.1, 0.8, 0.2), "house")
	spawn_property(Vector3(1.5, 0.45, 4.4), Color(0.9, 0.15, 0.15), "hotel")

func spawn_property(pos: Vector3, col: Color, type: String):
	var prop = Node3D.new()
	prop.position = pos

	var mat = StandardMaterial3D.new()
	mat.albedo_color = col
	mat.roughness = 0.2

	var m = BoxMesh.new()
	if type == "hotel":
		m.size = Vector3(0.5, 0.4, 0.4)
	else:
		m.size = Vector3(0.3, 0.3, 0.3)

	var inst = MeshInstance3D.new()
	inst.mesh = m
	inst.material_override = mat
	inst.position = Vector3(0, 0.2, 0)
	prop.add_child(inst)
	add_child(prop)
