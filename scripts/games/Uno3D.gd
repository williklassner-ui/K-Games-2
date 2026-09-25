extends Node3D

class_name Uno3D

func _ready():
	setup_stage()

func setup_stage():
	# Runder Holztisch mit grünem Samt
	var table_m = CylinderMesh.new()
	table_m.top_radius = 4.5
	table_m.bottom_radius = 4.8
	table_m.height = 0.4
	var t_inst = MeshInstance3D.new()
	t_inst.mesh = table_m
	var t_mat = StandardMaterial3D.new()
	t_mat.albedo_color = Color(0.12, 0.35, 0.18)
	t_mat.roughness = 0.5
	t_inst.material_override = t_mat
	t_inst.position = Vector3(0, 0.15, 0)
	add_child(t_inst)

	# Kartenstapel in der Mitte (Ablage & Nachziehstapel)
	spawn_card_deck(Vector3(-0.6, 0.36, 0), 15, Color(0.1, 0.1, 0.1))
	spawn_card(Vector3(0.6, 0.36, 0), Color(0.9, 0.15, 0.15), "7")

	# Spielerhand (4 Farbkarten aufgefächert)
	var colors = [Color(0.85, 0.15, 0.15), Color(0.15, 0.45, 0.9), Color(0.15, 0.8, 0.25), Color(0.95, 0.8, 0.1)]
	for i in range(4):
		var card_pos = Vector3((i - 1.5) * 0.75, 0.4, 2.4)
		spawn_card(card_pos, colors[i], str(i + 1))

func spawn_card(pos: Vector3, col: Color, label: String):
	var card = Node3D.new()
	card.position = pos

	var cm = BoxMesh.new()
	cm.size = Vector3(0.65, 0.02, 0.95)
	var inst = MeshInstance3D.new()
	inst.mesh = cm
	var mat = StandardMaterial3D.new()
	mat.albedo_color = col
	mat.roughness = 0.2
	inst.material_override = mat
	card.add_child(inst)

	# Weißes Symbolfeld
	var sym = MeshInstance3D.new()
	var sm = BoxMesh.new()
	sm.size = Vector3(0.4, 0.03, 0.6)
	sym.mesh = sm
	var s_mat = StandardMaterial3D.new()
	s_mat.albedo_color = Color(0.95, 0.95, 0.95)
	sym.material_override = s_mat
	sym.position = Vector3(0, 0.01, 0)
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
	mat.roughness = 0.3
	inst.material_override = mat
	inst.position = Vector3(0, count * 0.01, 0)
	deck.add_child(inst)
	add_child(deck)
