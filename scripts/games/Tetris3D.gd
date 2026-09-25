extends Node3D

class_name Tetris3D

func _ready():
	setup_stage()

func setup_stage():
	# 3D Tetris Glasschacht
	var floor_m = BoxMesh.new()
	floor_m.size = Vector3(8.0, 0.4, 8.0)
	var fl = MeshInstance3D.new()
	fl.mesh = floor_m
	var f_mat = StandardMaterial3D.new()
	f_mat.albedo_color = Color(0.08, 0.1, 0.15)
	fl.material_override = f_mat
	fl.position = Vector3(0, 0.15, 0)
	add_child(fl)

	# Tetriminos (I, J, L, O, S, T, Z)
	# O-Block (Gelb)
	spawn_tetrimino([Vector2i(0,0), Vector2i(1,0), Vector2i(0,1), Vector2i(1,1)], Vector3(-1.5, 0.4, 1.0), Color(0.95, 0.85, 0.15))
	# T-Block (Violett)
	spawn_tetrimino([Vector2i(0,0), Vector2i(-1,0), Vector2i(1,0), Vector2i(0,1)], Vector3(1.5, 0.4, 1.0), Color(0.7, 0.2, 0.9))
	# I-Block (Cyan)
	spawn_tetrimino([Vector2i(-1,0), Vector2i(0,0), Vector2i(1,0), Vector2i(2,0)], Vector3(0, 0.4, -0.5), Color(0.15, 0.85, 0.95))
	# L-Block (Orange)
	spawn_tetrimino([Vector2i(0,0), Vector2i(0,1), Vector2i(0,2), Vector2i(1,0)], Vector3(-2.0, 0.4, -1.8), Color(0.95, 0.55, 0.1))
	# S-Block (Grün)
	spawn_tetrimino([Vector2i(0,0), Vector2i(1,0), Vector2i(0,1), Vector2i(-1,1)], Vector3(2.0, 0.4, -1.8), Color(0.2, 0.85, 0.3))

func spawn_tetrimino(blocks: Array, pos: Vector3, col: Color):
	var root = Node3D.new()
	root.position = pos

	var mat = StandardMaterial3D.new()
	mat.albedo_color = col
	mat.metallic = 0.4
	mat.roughness = 0.2
	mat.emission_enabled = true
	mat.emission = col
	mat.emission_energy_multiplier = 0.35

	for b in blocks:
		var cube = MeshInstance3D.new()
		var cm = BoxMesh.new()
		cm.size = Vector3(0.55, 0.55, 0.55)
		cube.mesh = cm
		cube.material_override = mat
		cube.position = Vector3(b.x * 0.6, 0.3, b.y * 0.6)
		root.add_child(cube)

	add_child(root)
