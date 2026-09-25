extends Node3D

class_name Ra23D

func _ready():
	setup_stage()

func setup_stage():
	# Wüsten- & Tundra-Terrain
	var ground_mesh = BoxMesh.new()
	ground_mesh.size = Vector3(14.0, 0.4, 10.0)
	var ground = MeshInstance3D.new()
	ground.mesh = ground_mesh
	var g_mat = StandardMaterial3D.new()
	g_mat.albedo_color = Color(0.25, 0.22, 0.18)
	g_mat.roughness = 0.6
	ground.material_override = g_mat
	ground.position = Vector3(0, 0.15, 0)
	add_child(ground)

	# Alliierte Basis (Bauhof, Kaserne, Erz-Raffinerie)
	spawn_building(Vector3(-4.0, 0.4, -2.5), Vector3(1.6, 0.9, 1.4), Color(0.15, 0.35, 0.85), "Allied ConYard")
	spawn_building(Vector3(-2.2, 0.4, -2.8), Vector3(1.1, 0.7, 1.0), Color(0.18, 0.45, 0.88), "Barracks")
	spawn_building(Vector3(-4.2, 0.4, -0.6), Vector3(1.4, 0.8, 1.2), Color(0.2, 0.5, 0.9), "Ore Refinery")

	# Sowjetische Basis (Bauhof, Kaserne, Teslaspule)
	spawn_building(Vector3(4.0, 0.4, 2.5), Vector3(1.6, 0.9, 1.4), Color(0.85, 0.15, 0.15), "Soviet ConYard")
	spawn_building(Vector3(2.2, 0.4, 2.8), Vector3(1.1, 0.7, 1.0), Color(0.88, 0.18, 0.18), "Soviet Barracks")
	spawn_tesla_coil(Vector3(2.5, 0.4, 0.8))

	# 3D Panzer (Rhino & Grizzly)
	spawn_tank(Vector3(-1.0, 0.42, -0.5), Color(0.2, 0.4, 0.8), false)
	spawn_tank(Vector3(1.0, 0.42, 0.5), Color(0.8, 0.2, 0.2), true)

	# Erzfeld (Goldene Kristalle)
	for i in range(8):
		var crystal = MeshInstance3D.new()
		var p = PrismMesh.new()
		p.size = Vector3(0.25, 0.5, 0.25)
		crystal.mesh = p
		var c_mat = StandardMaterial3D.new()
		c_mat.albedo_color = Color(0.95, 0.8, 0.1)
		c_mat.emission_enabled = true
		c_mat.emission = Color(0.95, 0.8, 0.1)
		c_mat.emission_energy_multiplier = 0.4
		crystal.material_override = c_mat
		crystal.position = Vector3(randf_range(-1.5, 1.5), 0.4, randf_range(-1.5, 1.5))
		add_child(crystal)

func spawn_building(pos: Vector3, size: Vector3, col: Color, b_name: String):
	var b = Node3D.new()
	b.position = pos
	var m = BoxMesh.new()
	m.size = size
	var inst = MeshInstance3D.new()
	inst.mesh = m
	var mat = StandardMaterial3D.new()
	mat.albedo_color = col
	mat.metallic = 0.5
	mat.roughness = 0.3
	inst.material_override = mat
	inst.position = Vector3(0, size.y * 0.5, 0)
	b.add_child(inst)
	add_child(b)

func spawn_tesla_coil(pos: Vector3):
	var coil = Node3D.new()
	coil.position = pos
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.8, 0.2, 0.2)
	mat.metallic = 0.7

	var base = MeshInstance3D.new()
	var b_m = CylinderMesh.new()
	b_m.top_radius = 0.18
	b_m.bottom_radius = 0.3
	b_m.height = 0.9
	base.mesh = b_m
	base.material_override = mat
	base.position = Vector3(0, 0.45, 0)
	coil.add_child(base)

	var ring = MeshInstance3D.new()
	var r_m = SphereMesh.new()
	r_m.radius = 0.22
	r_m.height = 0.35
	ring.mesh = r_m
	var ring_mat = StandardMaterial3D.new()
	ring_mat.albedo_color = Color(0.3, 0.7, 1.0)
	ring_mat.emission_enabled = true
	ring_mat.emission = Color(0.3, 0.7, 1.0)
	ring_mat.emission_energy_multiplier = 1.0
	ring.material_override = ring_mat
	ring.position = Vector3(0, 1.0, 0)
	coil.add_child(ring)

	add_child(coil)

func spawn_tank(pos: Vector3, col: Color, is_heavy: bool):
	var tank = Node3D.new()
	tank.position = pos
	var mat = StandardMaterial3D.new()
	mat.albedo_color = col
	mat.metallic = 0.6
	mat.roughness = 0.35

	# Wanne
	var hull = MeshInstance3D.new()
	var h_m = BoxMesh.new()
	h_m.size = Vector3(0.9 if not is_heavy else 1.2, 0.25, 0.6 if not is_heavy else 0.8)
	hull.mesh = h_m
	hull.material_override = mat
	hull.position = Vector3(0, 0.15, 0)
	tank.add_child(hull)

	# Turm
	var turret = MeshInstance3D.new()
	var t_m = CylinderMesh.new()
	t_m.top_radius = 0.22 if not is_heavy else 0.3
	t_m.bottom_radius = 0.25 if not is_heavy else 0.35
	t_m.height = 0.2
	turret.mesh = t_m
	turret.material_override = mat
	turret.position = Vector3(0, 0.35, 0)
	tank.add_child(turret)

	# Rohr
	var barrel = MeshInstance3D.new()
	var bar_m = CylinderMesh.new()
	bar_m.top_radius = 0.05
	bar_m.bottom_radius = 0.05
	bar_m.height = 0.6 if not is_heavy else 0.8
	barrel.mesh = bar_m
	barrel.material_override = mat
	barrel.rotation_degrees = Vector3(0, 0, 90)
	barrel.position = Vector3(0.4, 0.35, 0)
	tank.add_child(barrel)

	add_child(tank)
