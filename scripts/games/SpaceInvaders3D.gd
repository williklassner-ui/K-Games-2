extends Node3D

class_name SpaceInvaders3D

func _ready():
	setup_stage()

func setup_stage():
	# 3D Arcade Gehäuse & Sternenfeld
	var floor_m = BoxMesh.new()
	floor_m.size = Vector3(12.0, 0.4, 9.0)
	var fl = MeshInstance3D.new()
	fl.mesh = floor_m
	var f_mat = StandardMaterial3D.new()
	f_mat.albedo_color = Color(0.04, 0.05, 0.08)
	fl.material_override = f_mat
	fl.position = Vector3(0, 0.15, 0)
	add_child(fl)

	# 3D-Aliens in Staffeln (Rot, Grün, Cyan)
	for row in range(4):
		for col in range(8):
			var a_pos = Vector3((col - 3.5) * 1.1, 0.45, (row - 3.0) * 1.0)
			var a_col = Color(0.9, 0.2, 0.3) if row == 0 else (Color(0.2, 0.9, 0.4) if row <= 2 else Color(0.2, 0.8, 1.0))
			spawn_alien(a_pos, a_col)

	# 3D Verteidiger-Kanone (Grün)
	spawn_cannon(Vector3(0, 0.4, 3.2))

	# Schutzbunker (Bunker-Meshes)
	for b in range(4):
		var b_pos = Vector3((b - 1.5) * 2.5, 0.4, 2.0)
		spawn_bunker(b_pos)

func spawn_alien(pos: Vector3, col: Color):
	var a = Node3D.new()
	a.position = pos
	var mat = StandardMaterial3D.new()
	mat.albedo_color = col
	mat.emission_enabled = true
	mat.emission = col
	mat.emission_energy_multiplier = 0.5

	var body = MeshInstance3D.new()
	var bm = BoxMesh.new()
	bm.size = Vector3(0.6, 0.35, 0.5)
	body.mesh = bm
	body.material_override = mat
	body.position = Vector3(0, 0.2, 0)
	a.add_child(body)

	# Tentakel / Hörner
	for side in [-0.22, 0.22]:
		var eye = MeshInstance3D.new()
		var em = CylinderMesh.new()
		em.top_radius = 0.06
		em.bottom_radius = 0.06
		em.height = 0.25
		eye.mesh = em
		eye.material_override = mat
		eye.position = Vector3(side, 0.4, 0)
		a.add_child(eye)

	add_child(a)

func spawn_cannon(pos: Vector3):
	var can = Node3D.new()
	can.position = pos
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.15, 0.85, 0.35)
	mat.metallic = 0.7

	var base = MeshInstance3D.new()
	var bm = BoxMesh.new()
	bm.size = Vector3(0.9, 0.3, 0.7)
	base.mesh = bm
	base.material_override = mat
	base.position = Vector3(0, 0.15, 0)
	can.add_child(base)

	var barrel = MeshInstance3D.new()
	var barm = CylinderMesh.new()
	barm.top_radius = 0.08
	barm.bottom_radius = 0.1
	barm.height = 0.5
	barrel.mesh = barm
	barrel.material_override = mat
	barrel.position = Vector3(0, 0.45, 0)
	can.add_child(barrel)

	add_child(can)

func spawn_bunker(pos: Vector3):
	var bun = MeshInstance3D.new()
	var bm = PrismMesh.new()
	bm.size = Vector3(1.1, 0.5, 0.6)
	bun.mesh = bm
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.2, 0.7, 0.8)
	bun.material_override = mat
	bun.position = pos + Vector3(0, 0.25, 0)
	add_child(bun)
