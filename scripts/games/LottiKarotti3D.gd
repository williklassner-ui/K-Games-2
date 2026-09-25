extends Node3D

class_name LottiKarotti3D

signal status_changed(msg: String)
signal sound_triggered(sound_name: String)

var path_positions: Array = []
var player_bunny: Node3D = null
var current_step = 0
var carrot_node: Node3D = null
var trap_hole_index = 6
var ui_layer: CanvasLayer

func _ready():
	setup_stage()
	setup_game_ui()
	emit_signal("status_changed", "Lotti Karotti 3D: Ziehe eine Karte! Gehe 1-3 Schritte oder drehe die Riesenkarotte!")

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
	carrot_node = Node3D.new()
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
	carrot_node.add_child(carrot_inst)

	var leaves_mesh = SphereMesh.new()
	leaves_mesh.radius = 0.4
	leaves_mesh.height = 0.5
	var leaves_inst = MeshInstance3D.new()
	leaves_inst.mesh = leaves_mesh
	var leaves_mat = StandardMaterial3D.new()
	leaves_mat.albedo_color = Color(0.1, 0.8, 0.2)
	leaves_inst.material_override = leaves_mat
	leaves_inst.position = Vector3(0, 3.5, 0)
	carrot_node.add_child(leaves_inst)
	add_child(carrot_node)

	# Spiralpfad-Felder (12 Felder hoch zur Karotte)
	path_positions.clear()
	for i in range(12):
		var t = float(i) / 11.0
		var angle = t * TAU * 1.5
		var radius = lerp(3.8, 1.6, t)
		var height = lerp(0.35, 2.3, t)
		var pos = Vector3(cos(angle) * radius, height, sin(angle) * radius)
		path_positions.append(pos)

		var tile = MeshInstance3D.new()
		var tm = CylinderMesh.new()
		tm.top_radius = 0.26
		tm.bottom_radius = 0.26
		tm.height = 0.08
		tile.mesh = tm
		var tmat = StandardMaterial3D.new()
		tmat.albedo_color = Color(0.85, 0.75, 0.55)
		tile.material_override = tmat
		tile.position = pos
		add_child(tile)

	player_bunny = spawn_bunny(path_positions[0], Color(0.95, 0.4, 0.8))

func spawn_bunny(pos: Vector3, col: Color) -> Node3D:
	var bunny = Node3D.new()
	bunny.position = pos

	var mat = StandardMaterial3D.new()
	mat.albedo_color = col
	mat.roughness = 0.3

	var body = MeshInstance3D.new()
	var b_m = SphereMesh.new()
	b_m.radius = 0.25
	b_m.height = 0.45
	body.mesh = b_m
	body.material_override = mat
	body.position = Vector3(0, 0.25, 0)
	bunny.add_child(body)

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
	return bunny

func setup_game_ui():
	ui_layer = CanvasLayer.new()
	add_child(ui_layer)

	var panel = PanelContainer.new()
	panel.anchors_preset = Control.PRESET_BOTTOM_RIGHT
	panel.offset_left = -300
	panel.offset_top = -140
	panel.offset_right = -20
	panel.offset_bottom = -20
	ui_layer.add_child(panel)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	panel.add_child(vbox)

	var card_btn = Button.new()
	card_btn.text = "🎴 Aktionskarte ziehen"
	card_btn.custom_minimum_size = Vector2(0, 44)
	card_btn.pressed.connect(draw_action_card)
	vbox.add_child(card_btn)

	var turn_carrot_btn = Button.new()
	turn_carrot_btn.text = "🥕 Karotte drehen (Klick-Klack)"
	turn_carrot_btn.custom_minimum_size = Vector2(0, 38)
	turn_carrot_btn.pressed.connect(twist_carrot)
	vbox.add_child(turn_carrot_btn)

func draw_action_card():
	var cards = ["1 Schritt", "2 Schritte", "3 Schritte", "Karotte drehen"]
	var pick = cards.pick_random()
	emit_signal("sound_triggered", "card")

	if pick == "Karotte drehen":
		emit_signal("status_changed", "Karte gezogen: 'Karotte drehen'! Klick-Klack...")
		twist_carrot()
	else:
		var steps = 1 if pick == "1 Schritt" else (2 if pick == "2 Schritte" else 3)
		advance_bunny(steps)

func advance_bunny(steps: int):
	current_step = min(path_positions.size() - 1, current_step + steps)
	var target = path_positions[current_step]
	emit_signal("sound_triggered", "move")

	var tween = create_tween()
	var mid = (player_bunny.position + target) * 0.5 + Vector3(0, 0.6, 0)
	tween.tween_property(player_bunny, "position", mid, 0.15)
	tween.tween_property(player_bunny, "position", target, 0.15)

	if current_step >= path_positions.size() - 1:
		emit_signal("sound_triggered", "win")
		emit_signal("status_changed", "GEWONNEN! Dein Hase hat die Riesenkarotte auf dem Gipfel erreicht!")
	else:
		emit_signal("status_changed", "Hase hüpft " + str(steps) + " Felder vor auf Stufe " + str(current_step + 1) + "/12!")

func twist_carrot():
	emit_signal("sound_triggered", "click")
	if carrot_node:
		var tween = create_tween()
		tween.tween_property(carrot_node, "rotation_degrees:y", carrot_node.rotation_degrees.y + 60, 0.3)

	# Maulwurfloch öffnen
	trap_hole_index = randi_range(2, 9)
	if current_step == trap_hole_index:
		emit_signal("sound_triggered", "shoot")
		emit_signal("status_changed", "PLUMPS! Ein Loch öffnet sich unter deinem Hasen! Zurück zum Start!")
		current_step = 0
		player_bunny.position = path_positions[0]
	else:
		emit_signal("status_changed", "Klick-Klack! Die Karotte dreht sich, aber dein Hase steht sicher!")
