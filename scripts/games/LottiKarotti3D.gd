extends Node3D

class_name LottiKarotti3D

const TextureHelper = preload("res://scripts/TextureHelper.gd")

signal status_changed(msg: String)
signal sound_triggered(sound_name: String)

# Spielfeld-Daten: 24 Stufen im Spiralweg auf den Karottenhügel
var path_positions: Array = []
var path_tiles: Array = []
var trap_doors: Dictionary = {} # tile_idx -> MeshInstance3D
var trap_holes: Dictionary = {} # tile_idx -> Node3D

# Hasen-Teams: 4 Hasen pro Spieler
# Spieler 0 (Rosa/Rot), Spieler 1 / Bot (Blau)
var player_bunnies: Array = [[], []]
var bunny_positions: Array = [[-1, -1, -1, -1], [-1, -1, -1, -1]] # -1 = Startwiese, 0-23 = Feld
var active_player: int = 0
var is_bot_opponent: bool = true
var selected_bunny_idx: int = 0

# 4 Fallenfelder auf dem Weg
const TRAP_INDICES = [4, 9, 14, 19]

# 3D Komponenten
var carrot_node: Node3D = null
var deck_node: Node3D = null
var discard_pile_node: Node3D = null
var active_flying_card: Node3D = null
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
	# 1. Großer grüner Spielbrett-Sockel mit Grasteppich (18x18)
	var base_mesh = BoxMesh.new()
	base_mesh.size = Vector3(18.0, 0.45, 18.0)
	var base_inst = MeshInstance3D.new()
	base_inst.mesh = base_mesh
	base_inst.material_override = TextureHelper.get_grass_material(Color(0.24, 0.68, 0.28))
	base_inst.position = Vector3(0, 0.1, 0)
	add_child(base_inst)

	# 2. Runder grüner Hügel (Mehrstufige sanfte Böschung)
	for t in range(5):
		var terr = MeshInstance3D.new()
		var tm = CylinderMesh.new()
		var r_top = lerp(6.4, 1.8, float(t) / 4.0)
		var r_bot = lerp(7.6, 3.0, float(t) / 4.0)
		tm.top_radius = r_top
		tm.bottom_radius = r_bot
		tm.height = 0.85
		terr.mesh = tm
		terr.material_override = TextureHelper.get_grass_material(Color(0.2 + t * 0.025, 0.6 + t * 0.025, 0.24))
		terr.position = Vector3(0, 0.45 + t * 0.75, 0)
		add_child(terr)

	# 3. RUNDE, organische Riesenkarotte auf dem Gipfel
	build_rounded_carrot()

	# 4. Der 24-Felder-Laufweg auf den Hügel (Spirale, 100% sichtbar, KEINE Überlagerung)
	build_mountain_path()

	# 5. 3D Interaktiver Ziehstapel & Ablagestapel auf Holztisch
	build_3d_card_deck()

	# 6. Hasen-Figuren (je 4 Hasen pro Spieler in Startmulden)
	spawn_all_bunnies()

func build_rounded_carrot():
	carrot_node = Node3D.new()
	carrot_node.name = "GiantCarrot"
	carrot_node.position = Vector3(0, 3.8, 0)

	var c_mat = StandardMaterial3D.new()
	c_mat.albedo_color = Color(1.0, 0.46, 0.04) # Sattes Karotten-Orange
	c_mat.roughness = 0.25
	c_mat.metallic = 0.08
	c_mat.clearcoat_enabled = true
	c_mat.clearcoat = 0.6

	# Rundes oberes Karotten-Segment (Kuppel)
	var top_dome = MeshInstance3D.new()
	var sm = SphereMesh.new()
	sm.radius = 0.62
	sm.height = 0.75
	top_dome.mesh = sm
	top_dome.material_override = c_mat
	top_dome.position = Vector3(0, 1.15, 0)
	carrot_node.add_child(top_dome)

	# Verjüngender, abgerundeter Karottenkörper mit Querringen
	var body_segments = [
		{"r_top": 0.62, "r_bot": 0.58, "h": 0.4, "y": 0.85},
		{"r_top": 0.58, "r_bot": 0.50, "h": 0.45, "y": 0.45},
		{"r_top": 0.50, "r_bot": 0.40, "h": 0.45, "y": 0.05},
		{"r_top": 0.40, "r_bot": 0.28, "h": 0.45, "y": -0.38},
		{"r_top": 0.28, "r_bot": 0.12, "h": 0.45, "y": -0.80}
	]
	for seg in body_segments:
		var c_part = MeshInstance3D.new()
		var cm = CylinderMesh.new()
		cm.top_radius = seg["r_top"]
		cm.bottom_radius = seg["r_bot"]
		cm.height = seg["h"]
		c_part.mesh = cm
		c_part.material_override = c_mat
		c_part.position = Vector3(0, seg["y"], 0)
		carrot_node.add_child(c_part)

	# Spitze unten abgerundet
	var tip = MeshInstance3D.new()
	var t_sm = SphereMesh.new()
	t_sm.radius = 0.12
	t_sm.height = 0.22
	tip.mesh = t_sm
	tip.material_override = c_mat
	tip.position = Vector3(0, -1.02, 0)
	carrot_node.add_child(tip)

	# 6 geschwungene grüne Karottenblätter an der Krone
	var leaf_mat = StandardMaterial3D.new()
	leaf_mat.albedo_color = Color(0.12, 0.78, 0.22)
	leaf_mat.roughness = 0.35

	for i in range(6):
		var leaf = MeshInstance3D.new()
		var lm = SphereMesh.new()
		lm.radius = 0.22
		lm.height = 0.75
		leaf.mesh = lm
		leaf.material_override = leaf_mat
		var a = float(i) * (TAU / 6.0)
		leaf.position = Vector3(cos(a) * 0.32, 1.6, sin(a) * 0.32)
		leaf.rotation_degrees = Vector3(sin(a) * 25.0, rad_to_deg(a), cos(a) * 25.0)
		carrot_node.add_child(leaf)

	# StaticBody für Karottendrehung per Klick
	var c_sb = StaticBody3D.new()
	var c_col = CollisionShape3D.new()
	var c_cyl = CylinderShape3D.new()
	c_cyl.radius = 0.8
	c_cyl.height = 2.8
	c_col.shape = c_cyl
	c_sb.add_child(c_col)
	c_sb.position = Vector3(0, 0.4, 0)
	c_sb.set_meta("grid_pos", Vector2i(999, 0)) # Spezial-Code für Karotte
	carrot_node.add_child(c_sb)

	# Hinweisschild "Hier drehen!"
	var c_hint = Label3D.new()
	c_hint.text = "🥕 DREHEN!\n(Klick-Klack)"
	c_hint.font_size = 26
	c_hint.pixel_size = 0.012
	c_hint.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	c_hint.position = Vector3(0, 2.35, 0)
	c_hint.outline_size = 4
	c_hint.modulate = Color(1.0, 0.9, 0.2)
	carrot_node.add_child(c_hint)

	add_child(carrot_node)

func build_mountain_path():
	path_positions.clear()
	path_tiles.clear()
	trap_doors.clear()
	trap_holes.clear()

	var num_steps = 24
	# 1.25 Umdrehungen: Weite spiralförmige Streckung verhindert Überlagerungen vollständig!
	for i in range(num_steps):
		var t = float(i) / float(num_steps - 1)
		var angle = t * TAU * 1.25 - PI * 0.75
		var radius = lerp(6.2, 1.75, t)
		var height = lerp(0.38, 3.65, t)
		var pos = Vector3(cos(angle) * radius, height, sin(angle) * radius)
		path_positions.append(pos)

	# Sichtbare, geschwungene Pfad-Verbindung zwischen allen Steinen (Wanderweg auf dem Berg)
	for i in range(num_steps - 1):
		var p_start = path_positions[i]
		var p_end = path_positions[i + 1]
		var p_mid = (p_start + p_end) * 0.5

		var road_seg = MeshInstance3D.new()
		var rm = BoxMesh.new()
		var dist = p_start.distance_to(p_end)
		rm.size = Vector3(0.55, 0.06, dist * 1.05)
		road_seg.mesh = rm
		road_seg.material_override = TextureHelper.get_stone_material(Color(0.55, 0.48, 0.38))
		road_seg.position = p_mid - Vector3(0, 0.02, 0)
		road_seg.look_at(p_end, Vector3.UP)
		add_child(road_seg)

	# 24 Einzelfelder
	for i in range(num_steps):
		var pos = path_positions[i]
		var is_trap = i in TRAP_INDICES

		if is_trap:
			# ECHTE TIEFE FALLEN-LÖCHER: Erhabener Steinring + hohler, dunkler Schacht nach unten
			var hole_node = Node3D.new()
			hole_node.position = pos

			# 1. Erhabener Steinring-Kragen
			var rim = MeshInstance3D.new()
			var rim_m = TorusMesh.new()
			rim_m.inner_radius = 0.28
			rim_m.outer_radius = 0.44
			rim.mesh = rim_m
			rim.material_override = TextureHelper.get_stone_material(Color(0.35, 0.34, 0.32))
			rim.position = Vector3(0, 0.04, 0)
			hole_node.add_child(rim)

			# 2. Tiefer, dunkler Abgrund-Schacht (echtes Loch im Hügel)
			var pit = MeshInstance3D.new()
			var pit_m = CylinderMesh.new()
			pit_m.top_radius = 0.28
			pit_m.bottom_radius = 0.26
			pit_m.height = 0.95
			pit.mesh = pit_m
			var pit_mat = StandardMaterial3D.new()
			pit_mat.albedo_color = Color(0.04, 0.04, 0.05) # Tiefschwarz
			pit_mat.roughness = 1.0
			pit.material_override = pit_mat
			pit.position = Vector3(0, -0.42, 0)
			hole_node.add_child(pit)

			# 3. Mechanische Falltür-Klappe im Schacht
			var door = MeshInstance3D.new()
			var dm = CylinderMesh.new()
			dm.top_radius = 0.27
			dm.bottom_radius = 0.27
			dm.height = 0.05
			door.mesh = dm
			door.material_override = TextureHelper.get_wood_material(Color(0.38, 0.24, 0.14))
			door.position = Vector3(0, 0.04, 0)
			hole_node.add_child(door)
			trap_doors[i] = door
			trap_holes[i] = hole_node

			# StaticBody
			var sb = StaticBody3D.new()
			var cs = CollisionShape3D.new()
			var c_shape = CylinderShape3D.new()
			c_shape.radius = 0.45
			c_shape.height = 0.3
			cs.shape = c_shape
			sb.add_child(cs)
			sb.set_meta("grid_pos", Vector2i(i, 0))
			hole_node.add_child(sb)

			add_child(hole_node)
			path_tiles.append(hole_node)
		else:
			# Normaler Trittstein-Sockel
			var tile = MeshInstance3D.new()
			var tm = CylinderMesh.new()
			tm.top_radius = 0.36
			tm.bottom_radius = 0.40
			tm.height = 0.12
			tile.mesh = tm

			if i == 0:
				tile.material_override = TextureHelper.get_stone_material(Color(0.28, 0.85, 0.4)) # Start grün
			elif i == num_steps - 1:
				tile.material_override = TextureHelper.get_stone_material(Color(1.0, 0.82, 0.15)) # Ziel gold
			else:
				tile.material_override = TextureHelper.get_stone_material(Color(0.86, 0.82, 0.74))

			tile.position = pos

			var sb = StaticBody3D.new()
			var cs = CollisionShape3D.new()
			var c_shape = CylinderShape3D.new()
			c_shape.radius = 0.42
			c_shape.height = 0.25
			cs.shape = c_shape
			sb.add_child(cs)
			sb.set_meta("grid_pos", Vector2i(i, 0))
			tile.add_child(sb)

			add_child(tile)
			path_tiles.append(tile)

		# Schrittnummern über den Feldern
		var num_lbl = Label3D.new()
		num_lbl.text = str(i + 1)
		num_lbl.font_size = 20
		num_lbl.pixel_size = 0.01
		num_lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		num_lbl.position = pos + Vector3(0, 0.32, 0)
		num_lbl.outline_size = 3
		add_child(num_lbl)

func build_3d_card_deck():
	# Holz-Kartentisch neben der Startwiese
	var table = Node3D.new()
	table.position = Vector3(-6.2, 0.32, 1.2)
	var t_mesh = BoxMesh.new()
	t_mesh.size = Vector3(2.6, 0.3, 1.8)
	var t_inst = MeshInstance3D.new()
	t_inst.mesh = t_mesh
	t_inst.material_override = TextureHelper.get_wood_material(Color(0.4, 0.25, 0.12))
	table.add_child(t_inst)
	add_child(table)

	# 1. Der 3D Ziehstapel (Stapel aus vielen Karten)
	deck_node = Node3D.new()
	deck_node.name = "CardDeck3D"
	deck_node.position = Vector3(-6.6, 0.52, 1.2)

	var deck_body = MeshInstance3D.new()
	var dm = BoxMesh.new()
	dm.size = Vector3(0.9, 0.35, 1.25)
	deck_body.mesh = dm
	var d_mat = StandardMaterial3D.new()
	d_mat.albedo_color = Color(0.95, 0.95, 0.95)
	deck_body.material_override = d_mat
	deck_node.add_child(deck_body)

	# Karotten-Rückenmuster der obersten Karte
	var top_card = MeshInstance3D.new()
	var tcm = BoxMesh.new()
	tcm.size = Vector3(0.88, 0.02, 1.22)
	top_card.mesh = tcm
	var tc_mat = StandardMaterial3D.new()
	tc_mat.albedo_color = Color(0.18, 0.45, 0.88) # Blaues Lotti-Karotti Kartenmuster
	top_card.material_override = tc_mat
	top_card.position = Vector3(0, 0.18, 0)
	deck_node.add_child(top_card)

	var deck_lbl = Label3D.new()
	deck_lbl.text = "🎴 ZIEHSTAPEL\n(Tippen zum Ziehen)"
	deck_lbl.font_size = 24
	deck_lbl.pixel_size = 0.012
	deck_lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	deck_lbl.position = Vector3(0, 0.65, 0)
	deck_lbl.outline_size = 4
	deck_lbl.modulate = Color(1.0, 0.95, 0.2)
	deck_node.add_child(deck_lbl)

	# Klickbarer StaticBody
	var sb = StaticBody3D.new()
	var cs = CollisionShape3D.new()
	var b_shape = BoxShape3D.new()
	b_shape.size = Vector3(1.1, 0.7, 1.4)
	cs.shape = b_shape
	sb.add_child(cs)
	sb.set_meta("grid_pos", Vector2i(777, 0)) # Spezial-Code für Ziehstapel
	deck_node.add_child(sb)
	add_child(deck_node)

	# 2. Ablagestapel für bereits gezogene Karten
	discard_pile_node = Node3D.new()
	discard_pile_node.position = Vector3(-5.4, 0.48, 1.2)
	var disc_mesh = BoxMesh.new()
	disc_mesh.size = Vector3(0.9, 0.08, 1.25)
	var disc_inst = MeshInstance3D.new()
	disc_inst.mesh = disc_mesh
	disc_inst.material_override = TextureHelper.get_wood_material(Color(0.28, 0.18, 0.1))
	discard_pile_node.add_child(disc_inst)

	var disc_lbl = Label3D.new()
	disc_lbl.text = "Ablage"
	disc_lbl.font_size = 18
	disc_lbl.pixel_size = 0.01
	disc_lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	disc_lbl.position = Vector3(0, 0.2, 0)
	discard_pile_node.add_child(disc_lbl)
	add_child(discard_pile_node)

func spawn_all_bunnies():
	for team in player_bunnies:
		for b in team:
			if is_instance_valid(b): b.queue_free()
	player_bunnies = [[], []]

	# Team 0: Rosa Hasen auf Startwiese
	var start_p0 = Vector3(-5.2, 0.35, 4.6)
	for i in range(4):
		var pos = start_p0 + Vector3((i % 2) * 0.85, 0, (i / 2) * 0.85)
		var bunny = create_bunny_figure(pos, Color(0.98, 0.45, 0.75), 0, i)
		player_bunnies[0].append(bunny)

	# Team 1: Blaue Hasen auf Startwiese
	var start_p1 = Vector3(4.2, 0.35, 4.6)
	for i in range(4):
		var pos = start_p1 + Vector3((i % 2) * 0.85, 0, (i / 2) * 0.85)
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
	draw_btn.text = "🎴 Karte vom 3D-Stapel ziehen"
	draw_btn.custom_minimum_size = Vector2(0, 48)
	draw_btn.pressed.connect(draw_action_card)
	vbox.add_child(draw_btn)

	var twist_btn = Button.new()
	twist_btn.text = "🥕 Riesenkarotte drehen"
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
			emit_signal("sound_triggered", "click")
			emit_signal("status_changed", "Hase " + str(b_i + 1) + " gewählt! Ziehe nun eine Karte.")
		)
		b_select_hbox.add_child(btn)

	# 2D Anzeige der gezogenen Aktionskarte in der Bildschirmmitte
	card_display_rect = PanelContainer.new()
	card_display_rect.anchors_preset = Control.PRESET_CENTER
	card_display_rect.offset_left = -170
	card_display_rect.offset_top = -110
	card_display_rect.offset_right = 170
	card_display_rect.offset_bottom = 110
	card_display_rect.visible = false
	ui_layer.add_child(card_display_rect)

	var c_vbox = VBoxContainer.new()
	c_vbox.add_theme_constant_override("separation", 8)
	card_display_rect.add_child(c_vbox)

	var c_title = Label.new()
	c_title.name = "CardTitle"
	c_title.text = "🎴 GEZOGENE AKTIONSKARTE"
	c_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	c_vbox.add_child(c_title)

	var c_art = Label.new()
	c_art.name = "CardArt"
	c_art.text = "🥕🥕\n2 Schritte vorwärts!"
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

	emit_signal("status_changed", "Lotti Karotti 3D: Alle 4 Hasen bereit! Klicke auf den 3D-Kartenstapel oder wähle deinen Hasen.")

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
		{"type": "step", "amount": 1, "art": "🥕\n1 Schritt hüpfen!", "title": "1 SCHRITT"},
		{"type": "step", "amount": 2, "art": "🥕🥕\n2 Schritte hüpfen!", "title": "2 SCHRITTE"},
		{"type": "step", "amount": 3, "art": "🥕🥕🥕\n3 Schritte hüpfen!", "title": "3 SCHRITTE"},
		{"type": "twist", "amount": 0, "art": "🔄 KLICK-KLACK!\nKarotte drehen!", "title": "KAROTTE DREHEN"}
	]
	var drawn = cards.pick_random()
	last_drawn_card = drawn.type

	emit_signal("sound_triggered", "card")

	# 3D Animiertes Kartenziehen vom Stapel zur Kamera
	animate_3d_card_draw(drawn, func():
		# 2D HUD Anzeige
		if card_display_rect:
			card_display_rect.visible = true
			var t_lbl = card_display_rect.find_child("CardTitle", true, false) as Label
			var a_lbl = card_display_rect.find_child("CardArt", true, false) as Label
			if t_lbl: t_lbl.text = "🎴 " + drawn["title"]
			if a_lbl: a_lbl.text = drawn["art"]

		get_tree().create_timer(1.2).timeout.connect(func():
			if card_display_rect: card_display_rect.visible = false
			if drawn.type == "twist":
				twist_carrot()
			else:
				move_selected_bunny(drawn.amount)
		)
	)

func animate_3d_card_draw(drawn_card: Dictionary, on_finished: Callable):
	if is_instance_valid(active_flying_card): active_flying_card.queue_free()

	active_flying_card = Node3D.new()
	active_flying_card.position = deck_node.position + Vector3(0, 0.25, 0)
	add_child(active_flying_card)

	var card_body = MeshInstance3D.new()
	var cm = BoxMesh.new()
	cm.size = Vector3(0.85, 0.02, 1.2)
	card_body.mesh = cm
	var c_mat = StandardMaterial3D.new()
	c_mat.albedo_color = Color(0.98, 0.98, 0.96)
	card_body.material_override = c_mat
	active_flying_card.add_child(card_body)

	# Symbol-Grafik auf der Vorderseite
	var sym_lbl = Label3D.new()
	sym_lbl.text = drawn_card["art"]
	sym_lbl.font_size = 28
	sym_lbl.pixel_size = 0.012
	sym_lbl.position = Vector3(0, 0.02, 0)
	sym_lbl.rotation_degrees = Vector3(-90, 0, 0)
	active_flying_card.add_child(sym_lbl)

	# Tween-Animation: Heben, Drehen (180 Grad Flip) und zur Kamera schweben
	var tw = create_tween()
	var cam_target = Vector3(-3.0, 2.5, 2.5)
	tw.tween_property(active_flying_card, "position", cam_target, 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(active_flying_card, "rotation_degrees:y", 180.0, 0.45)
	tw.parallel().tween_property(active_flying_card, "rotation_degrees:x", 35.0, 0.45)
	
	tw.tween_interval(0.35)
	tw.tween_callback(func():
		# Anschließend zur Ablage fliegen
		var disc_target = discard_pile_node.position + Vector3(0, 0.1, 0)
		var tw_disc = create_tween()
		tw_disc.tween_property(active_flying_card, "position", disc_target, 0.35)
		tw_disc.parallel().tween_property(active_flying_card, "rotation_degrees", Vector3.ZERO, 0.35)
		on_finished.call()
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
		# Sieg! Auf den Gipfel zur Riesenkarotte springen
		bunny_positions[team][b_idx] = path_positions.size() - 1
		animate_bunny_jump(bunny_node, Vector3(0, 4.2, 0), func():
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

	# Karotte dreht sich um 60 Grad (sanft und rund)
	var tween = create_tween()
	tween.tween_property(carrot_node, "rotation_degrees:y", carrot_node.rotation_degrees.y + 60.0, 0.45)

	# Eine zufällige Falltür öffnet sich (Klappe fällt nach unten weg)
	var trap_to_open = TRAP_INDICES.pick_random()
	for idx in trap_doors.keys():
		var door = trap_doors[idx]
		var open = (idx == trap_to_open)
		var d_tween = create_tween()
		var target_rot = Vector3(85, 0, 0) if open else Vector3.ZERO
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
				
				# Hase fällt sichtbar in den tiefen Schacht des Hügels hinein
				var f_tween = create_tween()
				f_tween.tween_property(bunny_node, "position:y", bunny_node.position.y - 1.4, 0.35)
				var team_copy = team
				var b_copy = b
				f_tween.tween_callback(func():
					var start_pos = Vector3(-5.2 if team_copy == 0 else 4.2, 0.35, 4.6) + Vector3((b_copy % 2) * 0.85, 0, (b_copy / 2) * 0.85)
					bunny_node.position = start_pos
				)

	if any_fallen:
		emit_signal("status_changed", "🕳️ PLUMPS! Das Loch auf Feld " + str(trap_idx + 1) + " hat sich geöffnet! Hase ist hineingefallen!")
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
