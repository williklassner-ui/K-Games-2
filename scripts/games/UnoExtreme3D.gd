extends Node3D

class_name UnoExtreme3D

func _ready():
	setup_stage()

func setup_stage():
	# Poker-Tisch
	var table_m = CylinderMesh.new()
	table_m.top_radius = 4.5
	table_m.bottom_radius = 4.8
	table_m.height = 0.4
	var t_inst = MeshInstance3D.new()
	t_inst.mesh = table_m
	var t_mat = StandardMaterial3D.new()
	t_mat.albedo_color = Color(0.18, 0.12, 0.28)
	t_mat.roughness = 0.4
	t_inst.material_override = t_mat
	t_inst.position = Vector3(0, 0.15, 0)
	add_child(t_inst)

	# 3D Elektronischer UNO Extreme Kartenwerfer (Launcher)
	spawn_launcher(Vector3(0, 0.35, -0.4))

	# Ausgeworfene Karten
	spawn_card(Vector3(-1.2, 0.38, 1.2), Color(0.9, 0.15, 0.15))
	spawn_card(Vector3(0.0, 0.38, 1.6), Color(0.15, 0.45, 0.9))
	spawn_card(Vector3(1.2, 0.38, 1.2), Color(0.95, 0.8, 0.1))

func spawn_launcher(pos: Vector3):
	var l = Node3D.new()
	l.position = pos

	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.15, 0.15, 0.18)
	mat.metallic = 0.6
	mat.roughness = 0.25

	# Gehäuse
	var body = MeshInstance3D.new()
	var bm = BoxMesh.new()
	bm.size = Vector3(1.4, 0.7, 1.8)
	body.mesh = bm
	body.material_override = mat
	body.position = Vector3(0, 0.35, 0)
	l.add_child(body)

	# Auswurfschlitz
	var slot = MeshInstance3D.new()
	var sm = BoxMesh.new()
	sm.size = Vector3(0.9, 0.12, 0.3)
	slot.mesh = sm
	var smat = StandardMaterial3D.new()
	smat.albedo_color = Color(0.02, 0.02, 0.02)
	slot.material_override = smat
	slot.position = Vector3(0, 0.5, 0.85)
	l.add_child(slot)

	# Großer roter Auslöser-Knopf oben
	var btn = MeshInstance3D.new()
	var btm = CylinderMesh.new()
	btm.top_radius = 0.35
	btm.bottom_radius = 0.38
	btm.height = 0.15
	btn.mesh = btm
	var bmat = StandardMaterial3D.new()
	bmat.albedo_color = Color(0.95, 0.15, 0.15)
	bmat.emission_enabled = true
	bmat.emission = Color(0.95, 0.15, 0.15)
	bmat.emission_energy_multiplier = 0.5
	btn.material_override = bmat
	btn.position = Vector3(0, 0.75, 0)
	l.add_child(btn)

	add_child(l)

func spawn_card(pos: Vector3, col: Color):
	var card = MeshInstance3D.new()
	var cm = BoxMesh.new()
	cm.size = Vector3(0.65, 0.02, 0.95)
	card.mesh = cm
	var mat = StandardMaterial3D.new()
	mat.albedo_color = col
	card.material_override = mat
	card.position = pos
	add_child(card)
