extends Node3D

class_name Durak3D

func _ready():
	setup_stage()

func setup_stage():
	# Russischer Holztisch
	var table_m = BoxMesh.new()
	table_m.size = Vector3(10.0, 0.4, 8.0)
	var t_inst = MeshInstance3D.new()
	t_inst.mesh = table_m
	var t_mat = StandardMaterial3D.new()
	t_mat.albedo_color = Color(0.24, 0.16, 0.1)
	t_mat.roughness = 0.4
	t_inst.material_override = t_mat
	t_inst.position = Vector3(0, 0.15, 0)
	add_child(t_inst)

	# Trumpfkarte quer unter dem Nachziehstapel (36 Karten Deck)
	spawn_card(Vector3(-2.5, 0.36, 0), Color(0.9, 0.15, 0.15), 90)
	spawn_card_deck(Vector3(-2.5, 0.38, 0), 12, Color(0.12, 0.25, 0.6))

	# Ausgespielte Angriffskarte & Verteidigungskarte in der Mitte
	spawn_card(Vector3(-0.4, 0.36, -0.2), Color(0.15, 0.15, 0.15), 0)
	spawn_card(Vector3(0.1, 0.38, 0.3), Color(0.9, 0.15, 0.15), 15)

	# Spielerhand unten (6 Karten)
	for i in range(6):
		var pos = Vector3((i - 2.5) * 0.75, 0.4, 2.6)
		var is_red = (i % 2 == 0)
		spawn_card(pos, Color(0.85, 0.15, 0.15) if is_red else Color(0.15, 0.15, 0.15), 0)

func spawn_card(pos: Vector3, col: Color, rot_deg: float):
	var card = Node3D.new()
	card.position = pos
	card.rotation_degrees = Vector3(0, rot_deg, 0)

	var cm = BoxMesh.new()
	cm.size = Vector3(0.65, 0.02, 0.95)
	var inst = MeshInstance3D.new()
	inst.mesh = cm
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.96, 0.96, 0.94)
	inst.material_override = mat
	card.add_child(inst)

	# Farbsymbol (Pik, Herz, Karo, Kreuz)
	var sym = MeshInstance3D.new()
	var sm = SphereMesh.new()
	sm.radius = 0.12
	sm.height = 0.05
	sym.mesh = sm
	var s_mat = StandardMaterial3D.new()
	s_mat.albedo_color = col
	sym.material_override = s_mat
	sym.position = Vector3(0, 0.02, 0)
	card.add_child(sym)

	add_child(card)

func spawn_card_deck(pos: Vector3, count: int, col: Color):
	var deck = Node3D.new()
	deck.position = pos
	var dm = BoxMesh.new()
	dm.size = Vector3(0.7, count * 0.02, 1.0)
	var inst = MeshInstance3D.new()
	inst.mesh = dm
	var mat = StandardMaterial3D.new()
	mat.albedo_color = col
	inst.material_override = mat
	inst.position = Vector3(0, count * 0.01, 0)
	deck.add_child(inst)
	add_child(deck)
