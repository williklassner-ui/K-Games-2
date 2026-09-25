extends Node3D

class_name Battleship3D

var ocean_root: Node3D
var grid_root: Node3D

func _ready():
	setup_stage()

func setup_stage():
	ocean_root = Node3D.new()
	ocean_root.name = "OceanRoot"
	add_child(ocean_root)

	# 3D Wasserbecken mit Wasser-Shader PBR
	var water_mesh = BoxMesh.new()
	water_mesh.size = Vector3(14.0, 0.4, 14.0)
	var water_inst = MeshInstance3D.new()
	water_inst.mesh = water_mesh
	
	var water_mat = StandardMaterial3D.new()
	water_mat.albedo_color = Color(0.02, 0.25, 0.45, 0.85)
	water_mat.roughness = 0.08
	water_mat.metallic = 0.6
	water_inst.material_override = water_mat
	water_inst.position = Vector3(0, 0.15, 0)
	ocean_root.add_child(water_inst)

	# 10x10 Taktisches 3D-Gitter
	grid_root = Node3D.new()
	grid_root.name = "GridRoot"
	add_child(grid_root)

	for x in range(10):
		for z in range(10):
			var tile_mesh = BoxMesh.new()
			tile_mesh.size = Vector3(0.85, 0.05, 0.85)
			var tile = MeshInstance3D.new()
			tile.mesh = tile_mesh
			var mat = StandardMaterial3D.new()
			mat.albedo_color = Color(0.05, 0.35, 0.55, 0.5)
			mat.roughness = 0.2
			tile.material_override = mat
			tile.position = Vector3((x - 4.5) * 0.95, 0.38, (z - 4.5) * 0.95)
			grid_root.add_child(tile)

	# 3D Kriegsschiffe platzieren
	spawn_warship(Vector3(-2.5, 0.45, -2.0), 5, "Carrier")
	spawn_warship(Vector3(1.5, 0.45, -1.0), 4, "Battleship")
	spawn_warship(Vector3(-1.0, 0.45, 1.5), 3, "Cruiser")
	spawn_warship(Vector3(2.5, 0.45, 2.5), 3, "Submarine")
	spawn_warship(Vector3(-3.0, 0.45, 3.5), 2, "Destroyer")

func spawn_warship(pos: Vector3, length_cells: int, ship_name: String):
	var ship = Node3D.new()
	ship.position = pos
	
	var hull_mat = StandardMaterial3D.new()
	hull_mat.albedo_color = Color(0.22, 0.26, 0.32)
	hull_mat.roughness = 0.4
	hull_mat.metallic = 0.65

	# Rumpf
	var hull_mesh = BoxMesh.new()
	var l = length_cells * 0.85
	hull_mesh.size = Vector3(l, 0.3, 0.5)
	var hull_inst = MeshInstance3D.new()
	hull_inst.mesh = hull_mesh
	hull_inst.material_override = hull_mat
	hull_inst.position = Vector3(0, 0.15, 0)
	ship.add_child(hull_inst)

	# Bug (Spitze)
	var bow_mesh = PrismMesh.new()
	bow_mesh.size = Vector3(0.5, 0.3, 0.4)
	var bow_inst = MeshInstance3D.new()
	bow_inst.mesh = bow_mesh
	bow_inst.material_override = hull_mat
	bow_inst.rotation_degrees = Vector3(0, -90, 0)
	bow_inst.position = Vector3(l * 0.5 + 0.2, 0.15, 0)
	ship.add_child(bow_inst)

	# Aufbauten / Geschütztürme
	var deck_mesh = BoxMesh.new()
	deck_mesh.size = Vector3(l * 0.5, 0.25, 0.3)
	var deck_inst = MeshInstance3D.new()
	deck_inst.mesh = deck_mesh
	var deck_mat = StandardMaterial3D.new()
	deck_mat.albedo_color = Color(0.15, 0.18, 0.22)
	deck_mat.metallic = 0.7
	deck_inst.material_override = deck_mat
	deck_inst.position = Vector3(-0.1, 0.38, 0)
	ship.add_child(deck_inst)

	grid_root.add_child(ship)
