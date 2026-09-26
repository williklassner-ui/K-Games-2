extends Node3D

class_name LottiKarotti3D

const TextureHelper = preload("res://scripts/TextureHelper.gd")

signal status_changed(msg: String)
signal sound_triggered(sound_name: String)

# Spielfeld-Daten: 24 Stufen im Spiralweg auf den Karottenhügel
var path_positions: Array = []
var path_tiles: Array = []
var trap_doors: Dictionary = {} # tile_idx -> MeshInstance3D

# Hasen-Teams: 4 Hasen pro Spieler
# Spieler 0 (Rosa/Rot), Spieler 1 / Bot (Blau)
var player_bunnies: Array = [[], []]
var bunny_positions: Array = [[-1, -1, -1, -1], [-1, -1, -1, -1]] # -1 = Startwiese, 0-23 = Feld
var active_player: int = 0
var is_bot_opponent: bool = true
var selected_bunny_idx: int = 0

# Fallenfelder auf dem Weg
const TRAP_INDICES = [4, 9, 14, 19]

# 3D Komponenten
var carrot_node: Node3D = null
var deck_node: Node3D = null
var animated_card_node: Node3D = null
var is_animating: bool = false
var last_drawn_card: String = ""

var ui_layer: CanvasLayer = null
var card_display_rect: PanelContainer = null
var victory_modal: PanelContainer = null

func _ready():
	setup_stage()
	setup_game_ui()
	reset_game()

func setup_stage():
	# 1. Großer grüner Spielbrett-Sockel mit Grasteppich (16x16)
	var base_mesh = BoxMesh.new()
	base_mesh.size = Vector3(16.0, 0.4, 16.0)
	var base_inst = MeshInstance3D.new()
	base_inst.mesh = base_mesh
	base_inst.material_override = TextureHelper.get_grass_material(Color(0.22, 0.65, 0.25))
	base_inst.position = Vector3(0, 0.1, 0)
	add_child(base_inst)

	# 2. Hügel mit Terrassen-Topologie (damit alle Felder 100% sichtbar auf Stufen liegen)
	for t in range(4):
		var terr = MeshInstance3D.new()
		var tm = CylinderMesh.new()
		var r_top = lerp(5.2, 1.6, float(t) / 3.0)
		var r_bot = lerp(6.2, 2.6, float(t) / 3.0)
		tm.top_radius = r_top
		tm.bottom_radius = r_bot
		tm.height = 0.8
		terr.mesh = tm
		terr.material_override = TextureHelper.get_grass_material(Color(0.18 + t * 0.03, 0.58 + t * 0.03, 0.22))
		terr.position = Vector3(0, 0.5 + t * 0.75, 0)
		add_child(terr)

	# 3. Riesenkarotte auf dem Gipfel
	carrot_node = Node3D.new()
	carrot_node.name = "GiantCarrot"
	var carrot_mesh = PrismMesh.new()
	carrot_mesh.size = Vector3(1.1, 2.0, 1.1)
	var carrot_inst = MeshInstance3D.new()
	carrot_inst.mesh = carrot_mesh
	var c_mat = StandardMaterial3D.new()
	c_mat.albedo_color = Color(1.0, 0.45, 0.05)
	c_mat.roughness = 0.25
	c_mat.metallic = 0.1
	carrot_inst.material_override = c_mat
	carrot_inst.position = Vector3(0, 3.8, 0)
	carrot_inst.rotation_degrees = Vector3(180, 0, 0)
	carrot_node.add_child(carrot_inst)

	# Karottenblätter
	for i in range(5):
		var leaf = MeshInstance3D.new()
		var lm = SphereMesh.new()
		lm.radius = 0.25
		lm.height = 0.6
		leaf.mesh = lm
		var lmat = StandardMaterial3D.new()
		lmat.albedo_color = Color(0.1, 0.75, 0.2)
		leaf.material_override = lmat
		var a = float(i) * (TAU / 5.0)
		leaf.position = Vector3(cos(a) * 0.25, 4.8, sin(a) * 0.25)
		carrot_node.add_child(leaf)

	# StaticBody für Karottendrehung per Klick
	var c_sb = StaticBody3D.new()
	var c_col = CollisionShape3D.new()
	var c_box = BoxShape3D.new()
	c_box.size = Vector3(1.5, 2.6, 1.5)
	c_col.shape = c_box
	c_sb.add_child(c_col)
	c_sb.position = Vector3(0, 3.8, 0)
	c_sb.set_meta("grid_pos", Vector2i(999, 0)) # Spezial-Code für Karotte
	carrot_node.add_child(c_sb)
	add_child(carrot_node)

	# 4. Der 24-Felder-Laufweg auf den Hügel (Spirale, 100% erhaben und sichtbar)
	path_positions.clear()
	path_tiles.clear()
	trap_doors.clear()

	var num_steps = 24
	for i in range(num_steps):
		var t = float(i) / float(num_steps - 1)
		var angle = t * TAU * 2.2 - PI * 0.5
		var radius = lerp(5.4, 1.5, t)
		var height = lerp(0.42, 3.4, t)
		var pos = Vector3(cos(angle) * radius, height, sin(angle) * radius)
		path_positions.append(pos)

		var is_trap = i in TRAP_INDICES

		# Trittstein-Sockel
		var tile = MeshInstance3D.new()
		var tm = CylinderMesh.new()
		tm.top_radius = 0.42
		tm.bottom_radius = 0.45
		tm.height = 0.14
		tile.mesh = tm

		if is_trap:
			# Fallenloch-Optik
			tile.material_override = TextureHelper.get_stone_material(Color(0.2, 0.2, 0.22))
		elif i == 0:
			tile.material_override = TextureHelper.get_stone_material(Color(0.3, 0.85, 0.4))
		elif i == num_steps - 1:
			tile.material_override = TextureHelper.get_stone_material(Color(0.98, 0.82, 0.15))
		else:
			tile.material_override = TextureHelper.get_stone_material(Color(0.82, 0.78, 0.7))

		tile.position = pos
		add_child(tile)
		path_tiles.append(tile)

		# Bei Fallenfeldern: Bewegliche Falltür
		if is_trap:
			var door = MeshInstance3D.new()
			var dm = CylinderMesh.new()
			dm.top_radius = 0.38
			dm.bottom_radius = 0.38
			dm.height = 0.05
			door.mesh = dm
			door.material_override = TextureHelper.get_wood_material(Color(0.4, 0.25, 0.15))
			door.position = pos + Vector3(0, 0.06, 0)
			add_child(door)
			trap_doors[i] = door

		# StaticBody für Klick/Touch auf Trittstein
		var sb = StaticBody3D.new()
		var col = CollisionShape3D.new()
		var cs = CylinderShape3D.new()
		cs.radius = 0.45
		cs.height = 0.4
		col.shape = cs
		sb.add_child(col)
		sb.set_meta("grid_pos", Vector2i(i, 0))
		tile.add_child(sb)

		# Feldnummerierung als 3D-Zahl
		var lbl = Label3D.new()
		lbl.text = str(i + 1)
		lbl.pixel_size = 0.012
		lbl.rotation_degrees = Vector3(-90, 0, 0)
		lbl.position = Vector3(0, 0.1, 0)
		lbl.modulate = Color(0.1, 0.1, 0.1) if not is_trap else Color(0.9, 0.9, 0.9)
		tile.add_child(lbl)

	# 5. Physischer 3D-Kartenstapel am Spielfeldrand
	deck_node = Node3D.new()
	deck_node.position = Vector3(-5.5, 0.35, -4.5)
	
	for c in range(12):
		var cm = MeshInstance3D.new()
		var box = BoxMesh.new()
		box.size = Vector3(1.0, 0.03, 1.4)
		cm.mesh = box
		cm.material_override = TextureHelper.get_parchment_material(Color(0.92, 0.88, 0.8))
		cm.position = Vector3(0, c * 0.03, 0)
		deck_node.add_child(cm)

	var deck_sb = StaticBody3D.new()
	var d_col = CollisionShape3D.new()
	var d_box = BoxShape3D.new()
	d_box.size = Vector3(1.2, 0.8, 1.6)
	d_col.shape = d_box
	deck_sb.add_child(d_col)
	deck_sb.set_meta("grid_pos", Vector2i(777, 0)) # Spezial-Code für Kartenstapel
	deck_node.add_child(deck_sb)

	var deck_lbl = Label3D.new()
	deck_lbl.text = "🎴 ZIEHSTAPEL\n(Tippen zum Ziehen)"
	deck_lbl.pixel_size = 0.01
	deck_lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	deck_lbl.position = Vector3(0, 0.7, 0)
	deck_lbl.outline_size = 4
	deck_node.add_child(deck_lbl)
	add_child(deck_node)

	# 6. Hasen-Figuren (je 4 Hasen pro Spieler in Startmulden)
	spawn_all_bunnies()

func spawn_all_bunnies():
	# Alte Figuren entfernen
	for team in player_bunnies:
		for b in team:
			if is_instance_valid(b): b.queue_free()
	player_bunnies = [[], []]

	# Team 0: Rosa Hasen
	var start_p0 = Vector3(-4.8, 0.35, 4.2)
	for i in range(4):
		var pos = start_p0 + Vector3((i % 2) * 0.8, 0, (i / 2) * 0.8)
		var bunny = create_bunny_figure(pos, Color(0.98, 0.45, 0.75), 0, i)
		player_bunnies[0].append(bunny)

	# Team 1: Blaue Hasen
	var start_p1 = Vector3(4.0, 0.35, 4.2)
	for i in range(4):
		var pos = start_p1 + Vector3((i % 2) * 0.8, 0, (i / 2) * 0.8)
		var bunny = create_bunny_figure(pos, Color(0.25, 0.65, 0.95), 1, i)
		player_bunnies[1].append(bunny)

func create_bunny_figure(pos: Vector3, col: Color, team: int, b_idx: int) -> Node3D:
	var bunny = Node3D.new()
	bunny.position = pos
	bunny.set_meta("team", team)
	bunny.set_meta("b_idx", b_idx)

	var mat = TextureHelper.get_wood_material(col)

	# Körper
	var body = MeshInstance3D.new()
	var bm = SphereMesh.new()
	bm.radius = 0.24
	bm.height = 0.45
	body.mesh = bm
	body.material_override = mat
	body.position = Vector3(0, 0.25, 0)
	bunny.add_child(body)

	# Hasenohren
	for side in [-0.09, 0.09]:
		var ear = MeshInstance3D.new()
		var em = CylinderMesh.new()
		em.top_radius = 0.03
		em.bottom_radius = 0.06
		em.height = 0.32
		ear.mesh = em
		ear.material_override = mat
		ear.position = Vector3(side, 0.58, 0)
		bunny.add_child(ear)

	# Klickbarer StaticBody
	var sb = StaticBody3D.new()
	var col_shape = CollisionShape3D.new()
	var cs = CylinderShape3D.new()
	cs.radius = 0.35
	cs.height = 0.8
	col_shape.shape = cs
	sb.add_child(col_shape)
	sb.set_meta("grid_pos", Vector2i(500 + team * 10 + b_idx, 0))
	bunny.add_child(sb)

	add_child(bunny)
	return bunny

func setup_game_ui():
	ui_layer = CanvasLayer.new()
	add_child(ui_layer)

	# Steuerungs-Panel unten rechts
	var panel = PanelContainer.new()
	panel.anchors_preset = Control.PRESET_BOTTOM_RIGHT
	panel.offset_left = -340
	panel.offset_top = -200
	panel.offset_right = -20
	panel.offset_bottom = -20
	ui_layer.add_child(panel)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	panel.add_child(vbox)

	var info = Label.new()
	info.name = "LottiInfo"
	info.text = "Du bist am Zug (Rosa)! Ziehe eine Aktionskarte."
	vbox.add_child(info)

	var draw_btn = Button.new()
	draw_btn.name = "DrawBtn"
	draw_btn.text = "🎴 Karte ziehen (1-3 Schritte oder Karotte)"
	draw_btn.custom_minimum_size = Vector2(0, 48)
	draw_btn.pressed.connect(draw_action_card)
	vbox.add_child(draw_btn)

	var twist_btn = Button.new()
	twist_btn.text = "🥕 Karotte drehen (Klick-Klack!)"
	twist_btn.custom_minimum_size = Vector2(0, 40)
	twist_btn.pressed.connect(twist_carrot)
	vbox.add_child(twist_btn)

	var b_select_hbox = HBoxContainer.new()
	b_select_hbox.add_theme_constant_override("separation", 6)
	vbox.add_child(b_select_hbox)

	for i in range(4):
		var btn = Button.new()
		btn.text = "Hase " + str(i + 1)
		btn.custom_minimum_size = Vector2(65, 36)
		var b_i = i
		btn.pressed.connect(func():
			selected_bunny_idx = b_i
			emit_signal("status_changed", "Hase " + str(b_i + 1) + " gewählt! Ziehe nun eine Karte.")
		)
		b_select_hbox.add_child(btn)

	# 2D Anzeige der gezogenen Aktionskarte in der Bildschirmmitte
	card_display_rect = PanelContainer.new()
	card_display_rect.anchors_preset = Control.PRESET_CENTER
	card_display_rect.offset_left = -160
	card_display_rect.offset_top = -100
	card_display_rect.offset_right = 160
	card_display_rect.offset_bottom = 100
	card_display_rect.visible = false
	ui_layer.add_child(card_display_rect)

	var c_vbox = VBoxContainer.new()
	c_vbox.add_theme_constant_override("separation", 8)
	card_display_rect.add_child(c_vbox)

	var c_title = Label.new()
	c_title.name = "CardTitle"
	c_title.text = "🎴 GEZOGENE KARTE"
	c_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	c_vbox.add_child(c_title)

	var c_art = Label.new()
	c_art.name = "CardArt"
	c_art.text = "🥕🥕\n2 Schritte vor!"
	c_art.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	c_vbox.add_child(c_art)

	# Sieges-Modal
	victory_modal = PanelContainer.new()
	victory_modal.anchors_preset = Control.PRESET_CENTER
	victory_modal.offset_left = -220
	victory_modal.offset_top = -120
	victory_modal.offset_right = 220
	victory_modal.offset_bottom = 120
	victory_modal.visible = false
	ui_layer.add_child(victory_modal)

	var v_box = VBoxContainer.new()
	v_box.add_theme_constant_override("separation", 10)
	victory_modal.add_child(v_box)

	var v_title = Label.new()
	v_title.name = "VictoryTitle"
	v_title.text = "🏆 GEWONNEN!"
	v_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v_box.add_child(v_title)

	var v_desc = Label.new()
	v_desc.name = "VictoryDesc"
	v_desc.text = "Dein Hase hat die Riesenkarotte auf dem Gipfel erreicht!"
	v_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v_box.add_child(v_desc)

	var v_btn = Button.new()
	v_btn.text = "🔄 Neues Spiel starten"
	v_btn.custom_minimum_size = Vector2(0, 48)
	v_btn.pressed.connect(reset_game)
	v_box.add_child(v_btn)

func reset_game():
	bunny_positions = [[-1, -1, -1, -1], [-1, -1, -1, -1]]
	active_player = 0
	selected_bunny_idx = 0
	is_animating = false
	if victory_modal: victory_modal.visible = false
	if card_display_rect: card_display_rect.visible = false

	# Hasen auf Startpositionen zurücksetzen
	spawn_all_bunnies()

	# Alle Falltüren schließen
	for idx in trap_doors.keys():
		var door = trap_doors[idx]
		door.rotation_degrees = Vector3.ZERO

	emit_signal("status_changed", "Lotti Karotti 3D: Alle 4 Hasen bereit! Klicke auf den Kartenstapel oder wähle deinen Hasen.")

func handle_tile_clicked(grid_pos: Vector2i):
	if is_animating: return
	var code = grid_pos.x

	# Klick auf Kartenstapel
	if code == 777:
		draw_action_card()
		return

	# Klick auf Karotte
	if code == 999:
		twist_carrot()
		return

	# Klick auf Hase (500 + team * 10 + b_idx)
	if code >= 500 and code < 520:
		var team = int((code - 500) / 10)
		var b_i = (code - 500) % 10
		if team == active_player:
			selected_bunny_idx = b_i
			emit_signal("sound_triggered", "click")
			emit_signal("status_changed", "Hase " + str(b_i + 1) + " gewählt! Ziehe nun eine Karte.")
		return

	# Klick auf Wegfeld
	if code >= 0 and code < path_positions.size():
		emit_signal("status_changed", "Feld " + str(code + 1) + " gewählt. Ziehe eine Karte zum Vorrücken!")

func draw_action_card():
	if is_animating: return
	is_animating = true

	var cards = [
		{"type": "step", "amount": 1, "art": "🥕\n1 Schritt hüpfen!"},
		{"type": "step", "amount": 2, "art": "🥕🥕\n2 Schritte hüpfen!"},
		{"type": "step", "amount": 3, "art": "🥕🥕🥕\n3 Schritte hüpfen!"},
		{"type": "twist", "amount": 0, "art": "🔄 KLICK-KLACK!\nKarotte drehen!"}
	]
	var drawn = cards.pick_random()
	last_drawn_card = drawn.type

	emit_signal("sound_triggered", "card")

	# 2D Anzeige anzeigen
	if card_display_rect:
		card_display_rect.visible = true
		var art_lbl = card_display_rect.find_child("CardArt", true, false) as Label
		if art_lbl: art_lbl.text = drawn.art

	get_tree().create_timer(1.2).timeout.connect(func():
		if card_display_rect: card_display_rect.visible = false
		if drawn.type == "twist":
			twist_carrot()
		else:
			move_selected_bunny(drawn.amount)
	)

func move_selected_bunny(steps: int):
	var team = active_player
	var b_idx = selected_bunny_idx
	var cur_pos = bunny_positions[team][b_idx]
	var next_pos = cur_pos + steps

	# Wenn noch in der Startwiese, starte auf Feld 0
	if cur_pos == -1:
		next_pos = steps - 1

	var bunny_node = player_bunnies[team][b_idx]
	emit_signal("sound_triggered", "move")

	if next_pos >= path_positions.size() - 1:
		# Sieg! Auf den Gipfel zur Karotte springen
		bunny_positions[team][b_idx] = path_positions.size() - 1
		animate_bunny_jump(bunny_node, Vector3(0, 3.8, 0), func():
			show_victory(team)
		)
		return
	else:
		bunny_positions[team][b_idx] = next_pos
		var target = path_positions[next_pos] + Vector3(0, 0.15, 0)
		animate_bunny_jump(bunny_node, target, func():
			is_animating = false
			var p_name = "Spieler 1 (Rosa)" if team == 0 else "Bot (Blau)"
			emit_signal("status_changed", p_name + " Hase " + str(b_idx + 1) + " hüpft auf Feld " + str(next_pos + 1) + "!")
			switch_turn()
		)

func animate_bunny_jump(bunny: Node3D, target: Vector3, callback: Callable):
	var start = bunny.position
	var mid = (start + target) * 0.5 + Vector3(0, 1.2, 0)
	var tween = create_tween()
	tween.tween_property(bunny, "position", mid, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(bunny, "position", target, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_callback(callback)

func twist_carrot():
	is_animating = true
	emit_signal("sound_triggered", "twist")

	# Karotte dreht sich um 60 Grad
	var tween = create_tween()
	tween.tween_property(carrot_node, "rotation_degrees:y", carrot_node.rotation_degrees.y + 60.0, 0.45)

	# Eine zufällige Falltür öffnet sich
	var trap_to_open = TRAP_INDICES.pick_random()
	for idx in trap_doors.keys():
		var door = trap_doors[idx]
		var open = (idx == trap_to_open)
		var d_tween = create_tween()
		var target_rot = Vector3(65, 0, 0) if open else Vector3.ZERO
		d_tween.tween_property(door, "rotation_degrees", target_rot, 0.35)

	get_tree().create_timer(0.5).timeout.connect(func():
		check_trap_falls(trap_to_open)
	)

func check_trap_falls(trap_idx: int):
	var any_fallen = false
	for team in range(2):
		for b in range(4):
			if bunny_positions[team][b] == trap_idx:
				any_fallen = true
				var bunny_node = player_bunnies[team][b]
				bunny_positions[team][b] = -1 # Zurück in Startmulde
				emit_signal("sound_triggered", "move")
				
				# Hase fällt ins Loch
				var f_tween = create_tween()
				f_tween.tween_property(bunny_node, "position:y", bunny_node.position.y - 1.2, 0.3)
				var team_copy = team
				var b_copy = b
				f_tween.tween_callback(func():
					var start_pos = Vector3(-4.8 if team_copy == 0 else 4.0, 0.35, 4.2) + Vector3((b_copy % 2) * 0.8, 0, (b_copy / 2) * 0.8)
					bunny_node.position = start_pos
				)

	if any_fallen:
		emit_signal("status_changed", "🕳️ PLUMPS! Ein Loch hat sich auf Feld " + str(trap_idx + 1) + " geöffnet! Hase fällt hinein!")
	else:
		emit_signal("status_changed", "Klick-Klack! Feld " + str(trap_idx + 1) + " öffnet sich, aber alle Hasen stehen sicher!")

	is_animating = false
	switch_turn()

func switch_turn():
	active_player = 1 if active_player == 0 else 0
	if active_player == 1 and is_bot_opponent:
		emit_signal("status_changed", "Bot überlegt und zieht als nächstes...")
		get_tree().create_timer(1.0).timeout.connect(bot_take_turn)
	else:
		emit_signal("status_changed", "Du bist am Zug (Rosa)! Wähle deinen Hasen oder ziehe eine Karte.")

func bot_take_turn():
	if active_player != 1: return
	selected_bunny_idx = randi_range(0, 3)
	draw_action_card()

func show_victory(team: int):
	is_animating = false
	if team == 0:
		emit_signal("sound_triggered", "win")
	else:
		emit_signal("sound_triggered", "loss")
	if victory_modal:
		victory_modal.visible = true
		var t_lbl = victory_modal.find_child("VictoryTitle", true, false) as Label
		var d_lbl = victory_modal.find_child("VictoryDesc", true, false) as Label
		if team == 0:
			if t_lbl: t_lbl.text = "🏆 GLORREICHER SIEG!"
			if d_lbl: d_lbl.text = "Dein Hase hat die Riesenkarotte auf dem Gipfel als Erster erreicht!"
			emit_signal("status_changed", "🏆 GEWONNEN! Du hast die Riesenkarotte erreicht!")
		else:
			if t_lbl: t_lbl.text = "💀 BOT HAT GEWONNEN!"
			if d_lbl: d_lbl.text = "Der blaue Hase war schneller auf dem Gipfel!"
			emit_signal("status_changed", "Bot hat die Riesenkarotte erreicht!")
