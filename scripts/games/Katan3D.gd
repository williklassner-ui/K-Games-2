extends Node3D

class_name Katan3D

func _ready():
	setup_stage()

func setup_stage():
	# Hexagonale Catan-Insel mit PBR-Ressourcenfeldern (Weizen, Erz, Holz, Lehm, Wolle, Wüste)
	var hex_coords = [
		{"pos": Vector3(0, 0, 0), "type": "desert", "col": Color(0.85, 0.78, 0.55)},
		{"pos": Vector3(-1.8, 0, 0), "type": "wheat", "col": Color(0.9, 0.8, 0.2)},
		{"pos": Vector3(1.8, 0, 0), "type": "wood", "col": Color(0.18, 0.5, 0.15)},
		{"pos": Vector3(-0.9, 0, -1.6), "type": "ore", "col": Color(0.45, 0.48, 0.52)},
		{"pos": Vector3(0.9, 0, -1.6), "type": "brick", "col": Color(0.78, 0.32, 0.18)},
		{"pos": Vector3(-0.9, 0, 1.6), "type": "wool", "col": Color(0.45, 0.75, 0.3)},
		{"pos": Vector3(0.9, 0, 1.6), "type": "wheat", "col": Color(0.9, 0.8, 0.2)}
	]

	for h in hex_coords:
		var tile_mesh = CylinderMesh.new()
		tile_mesh.top_radius = 1.0
		tile_mesh.bottom_radius = 1.0
		tile_mesh.height = 0.3
		var tile = MeshInstance3D.new()
		tile.mesh = tile_mesh

		var mat = StandardMaterial3D.new()
		mat.albedo_color = h.col
		mat.roughness = 0.4
		tile.material_override = mat
		tile.position = h.pos + Vector3(0, 0.15, 0)
		add_child(tile)

	# 3D Siedlungen, Städte & Straßen
	spawn_settlement(Vector3(-0.9, 0.32, 0.5), Color(0.9, 0.15, 0.15))
	spawn_city(Vector3(0.9, 0.32, -0.5), Color(0.15, 0.4, 0.9))
	spawn_road(Vector3(0.0, 0.31, 0.0), Vector3(0, 45, 0), Color(0.9, 0.15, 0.15))

func spawn_settlement(pos: Vector3, col: Color):
	var s = Node3D.new()
	s.position = pos
	var mat = StandardMaterial3D.new()
	mat.albedo_color = col

	var body = MeshInstance3D.new()
	var b_m = BoxMesh.new()
	b_m.size = Vector3(0.35, 0.3, 0.35)
	body.mesh = b_m
	body.material_override = mat
	body.position = Vector3(0, 0.15, 0)
	s.add_child(body)

	var roof = MeshInstance3D.new()
	var r_m = PrismMesh.new()
	r_m.size = Vector3(0.4, 0.2, 0.4)
	roof.mesh = r_m
	roof.material_override = mat
	roof.position = Vector3(0, 0.35, 0)
	s.add_child(roof)

	add_child(s)

func spawn_city(pos: Vector3, col: Color):
	var c = Node3D.new()
	c.position = pos
	var mat = StandardMaterial3D.new()
	mat.albedo_color = col

	var body = MeshInstance3D.new()
	var b_m = BoxMesh.new()
	b_m.size = Vector3(0.5, 0.45, 0.5)
	body.mesh = b_m
	body.material_override = mat
	body.position = Vector3(0, 0.22, 0)
	c.add_child(body)

	add_child(c)

func spawn_road(pos: Vector3, rot: Vector3, col: Color):
	var road = MeshInstance3D.new()
	var r_m = BoxMesh.new()
	r_m.size = Vector3(0.8, 0.08, 0.15)
	road.mesh = r_m
	var mat = StandardMaterial3D.new()
	mat.albedo_color = col
	road.material_override = mat
	road.position = pos
	road.rotation_degrees = rot
	add_child(road)
