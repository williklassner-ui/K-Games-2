extends Node3D

class_name LottiKarotti3D

func _ready():
	setup_stage()

func setup_stage():
	# Grüner 3D-Karottenhügel mit Spirallaufpfad
	var hill_mesh = CylinderMesh.new()
	hill_mesh.top_radius = 2.0
	hill_mesh.bottom_radius = 4.8
	hill_mesh.height = 2.2
	var hill_inst = MeshInstance3D.new()
	hill_inst.mesh = hill_mesh

	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.2, 0.65, 0.25)
	mat.roughness = 0.5
	hill_inst.material_override = mat
	hill_inst.position = Vector3(0, 1.1, 0)
	add_child(hill_inst)

	# Die Riesenkarotte auf dem Gipfel
	var carrot_mesh = PrismMesh.new()
	carrot_mesh.size = Vector3(0.9, 1.6, 0.9)
	var carrot_inst = MeshInstance3D.new()
	carrot_inst.mesh = carrot_mesh
	var carrot_mat = StandardMaterial3D.new()
	carrot_mat.albedo_color = Color(0.98, 0.45, 0.05)
	carrot_mat.roughness = 0.25
	carrot_inst.material_override = carrot_mat
	carrot_inst.position = Vector3(0, 2.8, 0)
	carrot_inst.rotation_degrees = Vector3(180, 0, 0)
	add_child(carrot_inst)

	# Karotten-Kraut (Grünzeug)
	var leaves_mesh = SphereMesh.new()
	leaves_mesh.radius = 0.4
	leaves_mesh.height = 0.5
	var leaves_inst = MeshInstance3D.new()
	leaves_inst.mesh = leaves_mesh
	var leaves_mat = StandardMaterial3D.new()
	leaves_mat.albedo_color = Color(0.1, 0.8, 0.2)
	leaves_inst.material_override = leaves_mat
	leaves_inst.position = Vector3(0, 3.5, 0)
	add_child(leaves_inst)

	# Hasenfiguren auf dem Spiralpfad
	spawn_bunny(Vector3(2.5, 0.8, 1.2), Color(0.95, 0.4, 0.8))
	spawn_bunny(Vector3(-1.8, 1.3, 1.8), Color(0.3, 0.6, 0.95))
	spawn_bunny(Vector3(-1.2, 1.9, -1.2), Color(0.95, 0.85, 0.2))

func spawn_bunny(pos: Vector3, col: Color):
	var bunny = Node3D.new()
	bunny.position = pos

	var mat = StandardMaterial3D.new()
	mat.albedo_color = col
	mat.roughness = 0.3

	# Körper
	var body = MeshInstance3D.new()
	var b_m = SphereMesh.new()
	b_m.radius = 0.25
	b_m.height = 0.45
	body.mesh = b_m
	body.material_override = mat
	body.position = Vector3(0, 0.25, 0)
	bunny.add_child(body)

	# Ohren
	for o in [-0.1, 0.1]:
		var ear = MeshInstance3D.new()
		var e_m = CylinderMesh.new()
		e_m.top_radius = 0.04
		e_m.bottom_radius = 0.06
		e_m.height = 0.3
		ear.mesh = e_m
		ear.material_override = mat
		ear.position = Vector3(o, 0.55, 0)
		bunny.add_child(ear)

	add_child(bunny)
