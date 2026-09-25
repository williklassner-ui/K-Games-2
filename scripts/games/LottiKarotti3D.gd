extends Node3D

class_name LottiKarotti3D

signal status_changed(msg: String)
signal sound_triggered(sound_name: String)

var path_positions: Array = []
var path_tiles: Array = []
var player_bunnies: Array = [] # [0] = Spieler 1 (Rosa), [1] = Spieler 2 / Bot (Blau)
var bunny_steps = [0, 0]
var active_player = 0 # 0 oder 1
var is_bot_opponent = true
var carrot_node: Node3D = null
var trap_hole_index = 6
var ui_layer: CanvasLayer

func _ready():
	setup_stage()
	setup_game_ui()
	emit_signal("status_changed", "Lotti Karotti 3D: Ziehe eine Karte oder tippe auf die Karotte/deinen Hasen!")

func setup_stage():
	# 1. Grüner 3D-Karottenhügel mit Grastopologie
	var hill_mesh = CylinderMesh.new()
	hill_mesh.top_radius = 2.2
	hill_mesh.bottom_radius = 5.2
	hill_mesh.height = 2.4
	var hill_inst = MeshInstance3D.new()
	hill_inst.mesh = hill_mesh

	var grass_mat = StandardMaterial3D.new()
	grass_mat.albedo_color = Color(0.24, 0.68, 0.28)
	grass_mat.roughness = 0.6
	grass_mat.metallic = 0.05
	grass_mat.rim_enabled = true
	grass_mat.rim = 0.3
	hill_inst.material_override = grass_mat
	hill_inst.position = Vector3(0, 1.2, 0)
	add_child(hill_inst)

	# 2. Riesenkarotte auf dem Hügelgipfel
	carrot_node = Node3D.new()
	carrot_node.name = "CarrotSummit"
	var carrot_mesh = PrismMesh.new()
	carrot_mesh.size = Vector3(0.9, 1.7, 0.9)
	var carrot_inst = MeshInstance3D.new()
	carrot_inst.mesh = carrot_mesh
	
	var carrot_mat = StandardMaterial3D.new()
	carrot_mat.albedo_color = Color(0.98, 0.44, 0.04)
	carrot_mat.roughness = 0.3
	carrot_mat.metallic = 0.1
	carrot_inst.material_override = carrot_mat
	carrot_inst.position = Vector3(0, 3.0, 0)
	carrot_inst.rotation_degrees = Vector3(180, 0, 0)
	carrot_node.add_child(carrot_inst)

	# Karotten-Kraut (Grüne Blätterkrone)
	for i in range(4):
		var leaf_mesh = SphereMesh.new()
		leaf_mesh.radius = 0.28
		leaf_mesh.height = 0.45
		var leaf_inst = MeshInstance3D.new()
		leaf_inst.mesh = leaf_mesh
		var leaf_mat = StandardMaterial3D.new()
		leaf_mat.albedo_color = Color(0.12, 0.78, 0.22)
		leaf_inst.material_override = leaf_mat
		var rot_ang = float(i) * (PI * 0.5)
		leaf_inst.position = Vector3(cos(rot_ang) * 0.2, 3.8, sin(rot_ang) * 0.2)
		carrot_node.add_child(leaf_inst)

	# StaticBody für Karotten-Klick / Touch-Drehung
	var c_sb = StaticBody3D.new()
	var c_col = CollisionShape3D.new()
	var c_box = BoxShape3D.new()
	c_box.size = Vector3(1.2, 2.2, 1.2)
	c_col.shape = c_box
	c_sb.add_child(c_col)
	c_sb.position = Vector3(0, 3.0, 0)
	c_sb.set_meta("grid_pos", Vector2i(999, 999)) # Spezieller Karotten-Code
	carrot_node.add_child(c_sb)
	add_child(carrot_node)

	# 3. Einzelne Trittsteine/Lauffelder auf dem Hügel (16 detaillierte Felder in Spirale)
	path_positions.clear()
	path_tiles.clear()
	var num_fields = 16
	for i in range(num_fields):
		var t = float(i) / float(num_fields - 1)
		var angle = t * TAU * 1.8
		var radius = lerp(4.2, 1.7, t)
		var height = lerp(0.38, 2.45, t)
		var pos = Vector3(cos(angle) * radius, height, sin(angle) * radius)
		path_positions.append(pos)

		# Steinfeld-Mesh
		var tile = MeshInstance3D.new()
		var tm = CylinderMesh.new()
		tm.top_radius = 0.32
		tm.bottom_radius = 0.35
		tm.height = 0.12
		tile.mesh = tm
		
		# Stein-Textur Material mit Wegmarkierung
		var tmat = StandardMaterial3D.new()
		if i == 0:
			tmat.albedo_color = Color(0.3, 0.8, 0.4) # Startfeld
		elif i == num_fields - 1:
			tmat.albedo_color = Color(0.95, 0.8, 0.1) # Zielfeld vor Karotte
		elif i % 3 == 0:
			tmat.albedo_color = Color(0.78, 0.68, 0.52) # Stein hell
		else:
			tmat.albedo_color = Color(0.62, 0.54, 0.44) # Stein dunkel
		tmat.roughness = 0.7
		tile.material_override = tmat
		tile.position = pos

		# StaticBody für Touch / Klick auf jedes Feld
		var t_sb = StaticBody3D.new()
		var t_col = CollisionShape3D.new()
		var t_shape = CylinderShape3D.new()
		t_shape.radius = 0.36
		t_shape.height = 0.3
		t_col.shape = t_shape
		t_sb.add_child(t_col)
		t_sb.set_meta("grid_pos", Vector2i(i, 0))
		tile.add_child(t_sb)

		add_child(tile)
		path_tiles.append(tile)

	# 4. Spielfiguren: Hase 1 (Spieler) und Hase 2 (Gegner / Bot)
	player_bunnies.clear()
	var b1 = spawn_bunny(path_positions[0], Color(0.98, 0.45, 0.75), 0)
	var b2 = spawn_bunny(path_positions[0] + Vector3(0.3, 0, 0.3), Color(0.25, 0.65, 0.95), 1)
	player_bunnies.append(b1)
	player_bunnies.append(b2)

func spawn_bunny(pos: Vector3, col: Color, b_idx: int) -> Node3D:
	var bunny = Node3D.new()
	bunny.position = pos

	var mat = StandardMaterial3D.new()
	mat.albedo_color = col
	mat.roughness = 0.25
	mat.metallic = 0.1

	var body = MeshInstance3D.new()
	var b_m = SphereMesh.new()
	b_m.radius = 0.26
	b_m.height = 0.48
	body.mesh = b_m
	body.material_override = mat
	body.position = Vector3(0, 0.26, 0)
	bunny.add_child(body)

	# Hasenohren
	for o in [-0.1, 0.1]:
		var ear = MeshInstance3D.new()
		var e_m = CylinderMesh.new()
		e_m.top_radius = 0.04
		e_m.bottom_radius = 0.07
		e_m.height = 0.34
		ear.mesh = e_m
		ear.material_override = mat
		ear.position = Vector3(o, 0.62, 0)
		bunny.add_child(ear)

	# Hasenaugen
	for o in [-0.08, 0.08]:
		var eye = MeshInstance3D.new()
		var eye_m = SphereMesh.new()
		eye_m.radius = 0.035
		eye_m.height = 0.07
		eye.mesh = eye_m
		var eye_mat = StandardMaterial3D.new()
		eye_mat.albedo_color = Color(0.1, 0.1, 0.1)
		eye.material_override = eye_mat
		eye.position = Vector3(o, 0.36, 0.22)
		bunny.add_child(eye)

	# StaticBody für Touch auf den Hasen
	var b_sb = StaticBody3D.new()
	var b_col = CollisionShape3D.new()
	var b_shape = CylinderShape3D.new()
	b_shape.radius = 0.32
	b_shape.height = 0.8
	b_col.shape = b_shape
	b_sb.add_child(b_col)
	b_sb.set_meta("grid_pos", Vector2i(500 + b_idx, 0))
	bunny.add_child(b_sb)

	add_child(bunny)
	return bunny

func setup_game_ui():
	ui_layer = CanvasLayer.new()
	add_child(ui_layer)

	var panel = PanelContainer.new()
	panel.anchors_preset = Control.PRESET_BOTTOM_RIGHT
	panel.offset_left = -330
	panel.offset_top = -160
	panel.offset_right = -15
	panel.offset_bottom = -75
	ui_layer.add_child(panel)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	panel.add_child(vbox)

	var card_btn = Button.new()
	card_btn.name = "DrawCardBtn"
	card_btn.text = "🎴 Aktionskarte ziehen (1-3 oder Karotte)"
	card_btn.custom_minimum_size = Vector2(0, 48)
	card_btn.pressed.connect(draw_action_card)
	vbox.add_child(card_btn)

	var turn_carrot_btn = Button.new()
	turn_carrot_btn.text = "🥕 Riesenkarotte drehen (Klick-Klack)"
	turn_carrot_btn.custom_minimum_size = Vector2(0, 42)
	turn_carrot_btn.pressed.connect(twist_carrot)
	vbox.add_child(turn_carrot_btn)

func handle_tile_clicked(grid_pos: Vector2i):
	# 1. Klick auf Karotte
	if grid_pos.x == 999:
		twist_carrot()
		return

	# 2. Klick auf eigenen Hasen -> Zieht Karte
	if grid_pos.x == 500 or grid_pos.x == 501:
		draw_action_card()
		return

	# 3. Klick auf ein Zielfeld
	if grid_pos.x >= 0 and grid_pos.x < path_positions.size():
		var diff = grid_pos.x - bunny_steps[active_player]
		if diff in [1, 2, 3]:
			advance_bunny(active_player, diff)
		else:
			draw_action_card()

func draw_action_card():
	var cards = ["1 Schritt", "2 Schritte", "3 Schritte", "Karotte drehen"]
	var pick = cards.pick_random()
	emit_signal("sound_triggered", "card")

	var player_name = "Spieler 1 (Rosa)" if active_player == 0 else ("Bot / Spieler 2 (Blau)" if is_bot_opponent else "Spieler 2 (Blau)")
	if pick == "Karotte drehen":
		emit_signal("status_changed", player_name + " zieht 'Karotte drehen'! Klick-Klack...")
		twist_carrot()
	else:
		var steps = 1 if pick == "1 Schritt" else (2 if pick == "2 Schritte" else 3)
		advance_bunny(active_player, steps)

func advance_bunny(p_idx: int, steps: int):
	var next_step = min(path_positions.size() - 1, bunny_steps[p_idx] + steps)
	bunny_steps[p_idx] = next_step
	var target = path_positions[next_step]
	var b_node = player_bunnies[p_idx]
	emit_signal("sound_triggered", "move")

	var tween = create_tween()
	var mid = (b_node.position + target) * 0.5 + Vector3(0, 0.8, 0)
	tween.tween_property(b_node, "position", mid, 0.18)
	tween.tween_property(b_node, "position", target, 0.18)

	var p_name = "Spieler 1" if p_idx == 0 else "Spieler 2"
	if next_step >= path_positions.size() - 1:
		emit_signal("sound_triggered", "win")
		emit_signal("status_changed", "🏆 GEWONNEN! " + p_name + " hat die Riesenkarotte auf dem Gipfel erreicht!")
		return
	else:
		emit_signal("status_changed", p_name + " hüpft " + str(steps) + " Felder vor auf Feld " + str(next_step + 1) + "/" + str(path_positions.size()) + "!")

	switch_turn()

func switch_turn():
	active_player = 1 if active_player == 0 else 0
	if active_player == 1 and is_bot_opponent:
		emit_signal("status_changed", "Bot überlegt und zieht als nächstes...")
		get_tree().create_timer(0.8).timeout.connect(bot_take_turn)

func bot_take_turn():
	if active_player != 1: return
	draw_action_card()

func twist_carrot():
	emit_signal("sound_triggered", "click")
	if carrot_node:
		var tween = create_tween()
		tween.tween_property(carrot_node, "rotation_degrees:y", carrot_node.rotation_degrees.y + 60, 0.35)

	# Zufälliges Fallenloch öffnen (Stufen 2 bis 13)
	trap_hole_index = randi_range(2, 13)
	
	# Loch optisch auf dem Feld darstellen
	if trap_hole_index < path_tiles.size():
		var hole_tile = path_tiles[trap_hole_index]
		var h_mat = StandardMaterial3D.new()
		h_mat.albedo_color = Color(0.05, 0.05, 0.05)
		h_mat.metallic = 0.9
		hole_tile.material_override = h_mat

	# Prüfen, ob ein Hase in das Loch fällt
	var fell = false
	for i in range(2):
		if bunny_steps[i] == trap_hole_index and bunny_steps[i] > 0:
			fell = true
			emit_signal("sound_triggered", "shoot")
			var p_name = "Spieler 1" if i == 0 else "Spieler 2"
			emit_signal("status_changed", "🕳️ PLUMPS! Ein Loch öffnet sich unter " + p_name + "! Zurück zum Start!")
			bunny_steps[i] = 0
			var b = player_bunnies[i]
			var f_tween = create_tween()
			f_tween.tween_property(b, "position:y", b.position.y - 0.6, 0.2)
			f_tween.tween_callback(func():
				b.position = path_positions[0]
			)

	if not fell:
		emit_signal("status_changed", "Klick-Klack! Die Karotte dreht sich, aber alle Hasen stehen sicher!")

	switch_turn()
