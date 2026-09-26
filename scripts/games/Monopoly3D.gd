extends Node3D

class_name Monopoly3D

const TextureHelper = preload("res://scripts/TextureHelper.gd")

signal status_changed(msg: String)
signal sound_triggered(sound_name: String)

var money: int = 1500
var player_pos: int = 0
var tile_positions: Array = []
var board_spaces: Array = []
var player_token: Node3D = null
var owned_properties: Dictionary = {} # space_idx -> {"level": 0, "name": ...}
var is_bot_opponent: bool = true
var ui_layer: CanvasLayer = null

func _ready():
	setup_stage()
	setup_game_ui()
	emit_signal("status_changed", "Monopoly 3D: Alle 40 Original-Spielfelder bereit! Würfle um über LOS zu ziehen und Straßen zu kaufen!")

func setup_stage():
	# 1. Großer edler Spielbrett-Sockel mit Holzrahmen & Samtmitte (14x14)
	var board_mesh = BoxMesh.new()
	board_mesh.size = Vector3(14.0, 0.45, 14.0)
	var board_inst = MeshInstance3D.new()
	board_inst.mesh = board_mesh
	board_inst.material_override = TextureHelper.get_wood_material(Color(0.18, 0.1, 0.05))
	board_inst.position = Vector3(0, 0.2, 0)
	add_child(board_inst)

	# Spielfeldmitte mit grünem Samtfilz
	var center_mesh = BoxMesh.new()
	center_mesh.size = Vector3(10.2, 0.47, 10.2)
	var center_inst = MeshInstance3D.new()
	center_inst.mesh = center_mesh
	center_inst.material_override = TextureHelper.get_grass_material(Color(0.12, 0.38, 0.22))
	center_inst.position = Vector3(0, 0.21, 0)
	add_child(center_inst)

	# 2. Die 40 offiziellen Monopoly-Felder
	var space_names = [
		{"name": "LOS (+$200)", "type": "corner", "cost": 0, "color": Color(0.9, 0.2, 0.2)},
		{"name": "Badstraße", "type": "street", "cost": 60, "color": Color(0.55, 0.28, 0.12)},
		{"name": "Gemeinschaftsfeld", "type": "special", "cost": 0, "color": Color(0.9, 0.9, 0.85)},
		{"name": "Turmstraße", "type": "street", "cost": 60, "color": Color(0.55, 0.28, 0.12)},
		{"name": "Einkommensteuer", "type": "tax", "cost": 200, "color": Color(0.8, 0.8, 0.8)},
		{"name": "Südbahnhof", "type": "station", "cost": 200, "color": Color(0.2, 0.2, 0.25)},
		{"name": "Chausseestraße", "type": "street", "cost": 100, "color": Color(0.65, 0.85, 0.95)},
		{"name": "Ereignisfeld", "type": "special", "cost": 0, "color": Color(0.95, 0.65, 0.2)},
		{"name": "Elisenstraße", "type": "street", "cost": 100, "color": Color(0.65, 0.85, 0.95)},
		{"name": "Poststraße", "type": "street", "cost": 120, "color": Color(0.65, 0.85, 0.95)},

		{"name": "Gefängnis / Besuch", "type": "corner", "cost": 0, "color": Color(0.85, 0.5, 0.15)},
		{"name": "Seestraße", "type": "street", "cost": 140, "color": Color(0.85, 0.35, 0.65)},
		{"name": "Elektrizitätswerk", "type": "utility", "cost": 150, "color": Color(0.95, 0.95, 0.9)},
		{"name": "Hafenstraße", "type": "street", "cost": 140, "color": Color(0.85, 0.35, 0.65)},
		{"name": "Neue Straße", "type": "street", "cost": 160, "color": Color(0.85, 0.35, 0.65)},
		{"name": "Westbahnhof", "type": "station", "cost": 200, "color": Color(0.2, 0.2, 0.25)},
		{"name": "Münchner Straße", "type": "street", "cost": 180, "color": Color(0.95, 0.58, 0.15)},
		{"name": "Gemeinschaftsfeld", "type": "special", "cost": 0, "color": Color(0.9, 0.9, 0.85)},
		{"name": "Wiener Straße", "type": "street", "cost": 180, "color": Color(0.95, 0.58, 0.15)},
		{"name": "Berliner Straße", "type": "street", "cost": 200, "color": Color(0.95, 0.58, 0.15)},

		{"name": "Frei Parken", "type": "corner", "cost": 0, "color": Color(0.95, 0.2, 0.2)},
		{"name": "Theaterstraße", "type": "street", "cost": 220, "color": Color(0.9, 0.15, 0.15)},
		{"name": "Ereignisfeld", "type": "special", "cost": 0, "color": Color(0.95, 0.65, 0.2)},
		{"name": "Museumstraße", "type": "street", "cost": 220, "color": Color(0.9, 0.15, 0.15)},
		{"name": "Opernplatz", "type": "street", "cost": 240, "color": Color(0.9, 0.15, 0.15)},
		{"name": "Nordbahnhof", "type": "station", "cost": 200, "color": Color(0.2, 0.2, 0.25)},
		{"name": "Lessingstraße", "type": "street", "cost": 260, "color": Color(0.95, 0.9, 0.15)},
		{"name": "Schillerstraße", "type": "street", "cost": 260, "color": Color(0.95, 0.9, 0.15)},
		{"name": "Wasserwerk", "type": "utility", "cost": 150, "color": Color(0.95, 0.95, 0.9)},
		{"name": "Goethestraße", "type": "street", "cost": 280, "color": Color(0.95, 0.9, 0.15)},

		{"name": "In das Gefängnis!", "type": "corner", "cost": 0, "color": Color(0.2, 0.45, 0.85)},
		{"name": "Rathausplatz", "type": "street", "cost": 300, "color": Color(0.18, 0.72, 0.28)},
		{"name": "Hauptstraße", "type": "street", "cost": 300, "color": Color(0.18, 0.72, 0.28)},
		{"name": "Gemeinschaftsfeld", "type": "special", "cost": 0, "color": Color(0.9, 0.9, 0.85)},
		{"name": "Bahnhofstraße", "type": "street", "cost": 320, "color": Color(0.18, 0.72, 0.28)},
		{"name": "Hauptbahnhof", "type": "station", "cost": 200, "color": Color(0.2, 0.2, 0.25)},
		{"name": "Ereignisfeld", "type": "special", "cost": 0, "color": Color(0.95, 0.65, 0.2)},
		{"name": "Parkstraße", "type": "street", "cost": 350, "color": Color(0.1, 0.25, 0.85)},
		{"name": "Zusatzsteuer", "type": "tax", "cost": 100, "color": Color(0.8, 0.8, 0.8)},
		{"name": "Schlossallee", "type": "street", "cost": 400, "color": Color(0.1, 0.25, 0.85)}
	]

	tile_positions.clear()
	board_spaces.clear()

	for i in range(40):
		var s_data = space_names[i]
		var side = int(i / 10)
		var edge_idx = i % 10
		var c_offset = (float(edge_idx) - 4.5) * 1.15
		var pos = Vector3.ZERO

		if side == 0:
			pos = Vector3(c_offset, 0.46, 5.75)
		elif side == 1:
			pos = Vector3(-5.75, 0.46, -c_offset)
		elif side == 2:
			pos = Vector3(-c_offset, 0.46, -5.75)
		else:
			pos = Vector3(5.75, 0.46, c_offset)

		tile_positions.append(pos)

		var tile_mesh = BoxMesh.new()
		tile_mesh.size = Vector3(1.1, 0.08, 1.1)
		var tile_inst = MeshInstance3D.new()
		tile_inst.mesh = tile_mesh
		
		# Textur mit Farbband für Straßen
		var mat = TextureHelper.get_parchment_material(s_data.color)
		tile_inst.material_override = mat
		tile_inst.position = pos
		add_child(tile_inst)

		# StaticBody für Klicks
		var sb = StaticBody3D.new()
		var col = CollisionShape3D.new()
		var b_shape = BoxShape3D.new()
		b_shape.size = Vector3(1.15, 0.5, 1.15)
		col.shape = b_shape
		sb.add_child(col)
		sb.set_meta("grid_pos", Vector2i(i, 0))
		tile_inst.add_child(sb)

		# Label
		var lbl = Label3D.new()
		lbl.text = s_data.name + ("\n$" + str(s_data.cost) if s_data.cost > 0 else "")
		lbl.pixel_size = 0.009
		lbl.rotation_degrees = Vector3(-90, 0, 0)
		lbl.position = Vector3(0, 0.06, 0)
		lbl.modulate = Color(0.1, 0.1, 0.1)
		tile_inst.add_child(lbl)

		s_data["node"] = tile_inst
		board_spaces.append(s_data)

	# 3D Spielfigur (Edler goldener Zylinder-Hut)
	player_token = create_top_hat()
	player_token.position = tile_positions[0] + Vector3(0, 0.1, 0)
	add_child(player_token)

func create_top_hat() -> Node3D:
	var hat = Node3D.new()
	var mat = TextureHelper.get_metal_material(Color(0.95, 0.82, 0.15), 0.9)

	var brim = MeshInstance3D.new()
	var b_m = CylinderMesh.new()
	b_m.top_radius = 0.32
	b_m.bottom_radius = 0.35
	b_m.height = 0.06
	brim.mesh = b_m
	brim.material_override = mat
	brim.position = Vector3(0, 0.04, 0)
	hat.add_child(brim)

	var crown = MeshInstance3D.new()
	var c_m = CylinderMesh.new()
	c_m.top_radius = 0.22
	c_m.bottom_radius = 0.24
	c_m.height = 0.45
	crown.mesh = c_m
	crown.material_override = mat
	crown.position = Vector3(0, 0.26, 0)
	hat.add_child(crown)

	return hat

func setup_game_ui():
	ui_layer = CanvasLayer.new()
	add_child(ui_layer)

	var panel = PanelContainer.new()
	panel.anchors_preset = Control.PRESET_BOTTOM_RIGHT
	panel.offset_left = -390
	panel.offset_top = -220
	panel.offset_right = -20
	panel.offset_bottom = -20
	ui_layer.add_child(panel)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	panel.add_child(vbox)

	var info = Label.new()
	info.name = "MonopolyInfo"
	info.text = "Guthaben: $1500 | Feld: 0 (LOS)\nBesitz: 0 Grundstücke"
	vbox.add_child(info)

	var roll_btn = Button.new()
	roll_btn.text = "🎲 2W6 Würfeln & Ziehen"
	roll_btn.custom_minimum_size = Vector2(0, 44)
	roll_btn.pressed.connect(roll_and_move)
	vbox.add_child(roll_btn)

	var buy_btn = Button.new()
	buy_btn.text = "🏠 Aktuelles Grundstück kaufen"
	buy_btn.custom_minimum_size = Vector2(0, 40)
	buy_btn.pressed.connect(buy_current_property)
	vbox.add_child(buy_btn)

	var house_btn = Button.new()
	house_btn.text = "🔨 Haus / Hotel bauen ($100)"
	house_btn.custom_minimum_size = Vector2(0, 38)
	house_btn.pressed.connect(build_house)
	vbox.add_child(house_btn)

func handle_tile_clicked(grid_pos: Vector2i):
	var idx = grid_pos.x
	if idx >= 0 and idx < board_spaces.size():
		var s = board_spaces[idx]
		emit_signal("sound_triggered", "select")
		var owned_str = " (Besitzer: Du)" if owned_properties.has(idx) else (" (Kaufbar)" if s.cost > 0 else "")
		emit_signal("status_changed", "Feld " + str(idx) + ": " + s.name + " [Kaufpreis: $" + str(s.cost) + "]" + owned_str)

func roll_and_move():
	var d1 = randi_range(1, 6)
	var d2 = randi_range(1, 6)
	var total = d1 + d2
	emit_signal("sound_triggered", "dice")

	var old_pos = player_pos
	player_pos = (player_pos + total) % 40
	if player_pos < old_pos:
		money += 200 # Über Los gezogen
		emit_signal("sound_triggered", "win")
		emit_signal("status_changed", "Über LOS gezogen! +$200 Gehalt erhalten!")

	var target = tile_positions[player_pos] + Vector3(0, 0.1, 0)
	var tween = create_tween()
	var mid = (player_token.position + target) * 0.5 + Vector3(0, 1.2, 0)
	tween.tween_property(player_token, "position", mid, 0.22)
	tween.tween_property(player_token, "position", target, 0.22)
	tween.tween_callback(func():
		emit_signal("sound_triggered", "move")
		var cur_space = board_spaces[player_pos]
		var status = "Feld: " + cur_space.name + (" ($" + str(cur_space.cost) + ")" if cur_space.cost > 0 else "")
		emit_signal("status_changed", "Gewürfelt: " + str(total) + " (" + str(d1) + "+" + str(d2) + ") | " + status)
		update_ui()
	)

func buy_current_property():
	var cur = board_spaces[player_pos]
	if cur.cost == 0 or cur.type == "corner" or cur.type == "special" or cur.type == "tax":
		emit_signal("status_changed", cur.name + " kann nicht gekauft werden!")
		return
	if owned_properties.has(player_pos):
		emit_signal("status_changed", "Dieses Grundstück besitzt du bereits!")
		return
	if money < cur.cost:
		emit_signal("status_changed", "Nicht genug Guthaben ($" + str(cur.cost) + " benötigt)!")
		return

	money -= cur.cost
	owned_properties[player_pos] = {"level": 0, "name": cur.name}
	emit_signal("sound_triggered", "win")
	emit_signal("status_changed", "🏠 " + cur.name + " für $" + str(cur.cost) + " erfolgreich erworben!")

	# Haus-Markierung platzieren
	var h_mesh = BoxMesh.new()
	h_mesh.size = Vector3(0.3, 0.3, 0.3)
	var h_inst = MeshInstance3D.new()
	h_inst.mesh = h_mesh
	h_inst.material_override = TextureHelper.get_wood_material(Color(0.2, 0.8, 0.25))
	h_inst.position = tile_positions[player_pos] + Vector3(0, 0.25, 0)
	add_child(h_inst)

	update_ui()

func build_house():
	if not owned_properties.has(player_pos):
		emit_signal("status_changed", "Du musst auf einem eigenen Grundstück stehen, um Häuser zu bauen!")
		return
	if money < 100:
		emit_signal("status_changed", "Nicht genug Geld für Hausbau ($100 benötigt)!")
		return

	money -= 100
	owned_properties[player_pos].level += 1
	var lvl = owned_properties[player_pos].level
	emit_signal("sound_triggered", "win")
	emit_signal("status_changed", "🔨 Haus gebaut auf " + board_spaces[player_pos].name + "! (Stufe " + str(lvl) + ")")
	update_ui()

func update_ui():
	var lbl = ui_layer.get_node_or_null("PanelContainer/VBoxContainer/MonopolyInfo") as Label
	if lbl:
		var cur_name = board_spaces[player_pos].name
		lbl.text = "Guthaben: $" + str(money) + " | Feld: " + str(player_pos) + " (" + cur_name + ")\nBesitz: " + str(owned_properties.size()) + " Grundstücke"
