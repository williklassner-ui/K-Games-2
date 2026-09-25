extends Node3D

class_name SnakesAndLadders3D

func _ready():
	setup_stage()

func setup_stage():
	# 10x10 Spielfeld (Felder 1 bis 100)
	var board_mesh = BoxMesh.new()
	board_mesh.size = Vector3(10.5, 0.4, 10.5)
	var board = MeshInstance3D.new()
	board.mesh = board_mesh
	var b_mat = StandardMaterial3D.new()
	b_mat.albedo_color = Color(0.12, 0.15, 0.2)
	board.material_override = b_mat
	board.position = Vector3(0, 0.15, 0)
	add_child(board)

	# 100 Felder
	for i in range(100):
		var row = int(i / 10)
		var col = i % 10
		if row % 2 == 1:
			col = 9 - col
		var pos = Vector3((col - 4.5) * 0.95, 0.38, (4.5 - row) * 0.95)

		var tile = MeshInstance3D.new()
		var tm = BoxMesh.new()
		tm.size = Vector3(0.9, 0.05, 0.9)
		tile.mesh = tm
		var t_mat = StandardMaterial3D.new()
		var colors = [Color(0.85, 0.25, 0.25), Color(0.25, 0.65, 0.85), Color(0.95, 0.8, 0.2), Color(0.25, 0.8, 0.4)]
		t_mat.albedo_color = colors[(row + col) % 4]
		tile.material_override = t_mat
		tile.position = pos
		add_child(tile)

	# 3D Leitern (Gold)
	spawn_ladder(Vector3(-3.0, 0.4, 3.5), Vector3(-1.0, 0.9, 0.5))
	spawn_ladder(Vector3(1.5, 0.4, 2.5), Vector3(3.0, 1.1, -1.5))
	spawn_ladder(Vector3(-2.5, 0.4, -0.5), Vector3(-3.5, 1.3, -3.5))

	# 3D Schlangen (Rot/Grün geschwungen)
	spawn_snake(Vector3(2.5, 0.4, -3.5), Vector3(1.0, 0.4, 0.5))
	spawn_snake(Vector3(-1.5, 0.4, -2.5), Vector3(-2.0, 0.4, 1.5))

	# Spielfiguren
	spawn_pawn(Vector3(-4.0, 0.45, 4.0), Color(0.9, 0.1, 0.1))
	spawn_pawn(Vector3(-3.0, 0.45, 4.0), Color(0.1, 0.4, 0.9))

func spawn_ladder(start_p: Vector3, end_p: Vector3):
	var ladder = Node3D.new()
	var mid = (start_p + end_p) * 0.5
	ladder.position = mid

	var l_mat = StandardMaterial3D.new()
	l_mat.albedo_color = Color(0.95, 0.8, 0.2)
	l_mat.metallic = 0.8

	# Holme
	for offset in [-0.2, 0.2]:
		var r = MeshInstance3D.new()
		var rm = BoxMesh.new()
		var dist = start_p.distance_to(end_p)
		rm.size = Vector3(0.06, 0.06, dist)
		r.mesh = rm
		r.material_override = l_mat
		r.position = Vector3(offset, 0, 0)
		ladder.add_child(r)

	ladder.look_at(end_p)
	add_child(ladder)

func spawn_snake(head_p: Vector3, tail_p: Vector3):
	var s_mat = StandardMaterial3D.new()
	s_mat.albedo_color = Color(0.15, 0.75, 0.25)
	s_mat.roughness = 0.3

	for i in range(6):
		var t = float(i) / 5.0
		var pos = head_p.lerp(tail_p, t) + Vector3(sin(t * PI * 2) * 0.4, 0.05, 0)
		var seg = MeshInstance3D.new()
		var sm = SphereMesh.new()
		sm.radius = 0.16 * (1.0 - t * 0.4)
		sm.height = sm.radius * 2
		seg.mesh = sm
		seg.material_override = s_mat
		seg.position = pos
		add_child(seg)

func spawn_pawn(pos: Vector3, col: Color):
	var p = Node3D.new()
	p.position = pos
	var mat = StandardMaterial3D.new()
	mat.albedo_color = col
	mat.metallic = 0.3

	var body = MeshInstance3D.new()
	var bm = CylinderMesh.new()
	bm.top_radius = 0.1
	bm.bottom_radius = 0.2
	bm.height = 0.5
	body.mesh = bm
	body.material_override = mat
	body.position = Vector3(0, 0.25, 0)
	p.add_child(body)

	var head = MeshInstance3D.new()
	var hm = SphereMesh.new()
	hm.radius = 0.16
	hm.height = 0.32
	head.mesh = hm
	head.material_override = mat
	head.position = Vector3(0, 0.58, 0)
	p.add_child(head)

	add_child(p)
