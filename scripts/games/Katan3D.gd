extends Node3D

class_name Katan3D

const TextureHelper = preload("res://scripts/TextureHelper.gd")

signal status_changed(msg: String)
signal sound_triggered(sound_name: String)

var wood: int = 3
var brick: int = 3
var wheat: int = 2
var wool: int = 2
var ore: int = 1
var victory_points: int = 2
var settlements_built: int = 2
var cities_built: int = 0
var roads_built: int = 2
var turn: int = 1
var is_bot_opponent: bool = true

var hex_tiles: Array = []
var settlement_nodes: Array = []
var road_nodes: Array = []
var robber_node: Node3D = null
var ui_layer: CanvasLayer = null

func _ready():
	setup_stage()
	setup_game_ui()
	emit_signal("status_changed", "Siedler von Katan 3D: Alle 19 Hexagon-Felder mit Häfen bereit! Würfle Erträge oder baue!")

func setup_stage():
	# 1. Großer runder Ozean-Rahmen mit Meereswellen-Textur
	var ocean_mesh = CylinderMesh.new()
	ocean_mesh.top_radius = 8.5
	ocean_mesh.bottom_radius = 8.8
	ocean_mesh.height = 0.4
	var ocean_inst = MeshInstance3D.new()
	ocean_inst.mesh = ocean_mesh
	ocean_inst.material_override = TextureHelper.get_water_material(Color(0.06, 0.32, 0.62, 0.9))
	ocean_inst.position = Vector3(0, 0.1, 0)
	add_child(ocean_inst)

	# Holzrand um das Meeresbecken
	var frame_mesh = TorusMesh.new()
	frame_mesh.inner_radius = 8.4
	frame_mesh.outer_radius = 9.0
	var frame_inst = MeshInstance3D.new()
	frame_inst.mesh = frame_mesh
	frame_inst.material_override = TextureHelper.get_wood_material(Color(0.18, 0.1, 0.05))
	frame_inst.position = Vector3(0, 0.25, 0)
	add_child(frame_inst)

	# 2. Die 19 offiziellen Hexagon-Felder in 3-4-5-4-3 Anordnung
	var hex_configs = [
		# Reihe 1 (3 Hexes, z = -3.0)
		{"col_idx": 0, "row_idx": 0, "x": -1.8, "z": -3.0, "res": "Holz", "num": 5, "color": Color(0.15, 0.48, 0.18)},
		{"col_idx": 1, "row_idx": 0, "x": 0.0, "z": -3.0, "res": "Wolle", "num": 2, "color": Color(0.38, 0.72, 0.28)},
		{"col_idx": 2, "row_idx": 0, "x": 1.8, "z": -3.0, "res": "Weizen", "num": 6, "color": Color(0.92, 0.82, 0.22)},

		# Reihe 2 (4 Hexes, z = -1.5)
		{"col_idx": 0, "row_idx": 1, "x": -2.7, "z": -1.5, "res": "Erz", "num": 10, "color": Color(0.55, 0.58, 0.62)},
		{"col_idx": 1, "row_idx": 1, "x": -0.9, "z": -1.5, "res": "Lehm", "num": 9, "color": Color(0.82, 0.36, 0.18)},
		{"col_idx": 2, "row_idx": 1, "x": 0.9, "z": -1.5, "res": "Holz", "num": 4, "color": Color(0.15, 0.48, 0.18)},
		{"col_idx": 3, "row_idx": 1, "x": 2.7, "z": -1.5, "res": "Wolle", "num": 8, "color": Color(0.38, 0.72, 0.28)},

		# Reihe 3 (5 Hexes, z = 0.0 - Mitte mit Wüste)
		{"col_idx": 0, "row_idx": 2, "x": -3.6, "z": 0.0, "res": "Weizen", "num": 8, "color": Color(0.92, 0.82, 0.22)},
		{"col_idx": 1, "row_idx": 2, "x": -1.8, "z": 0.0, "res": "Erz", "num": 3, "color": Color(0.55, 0.58, 0.62)},
		{"col_idx": 2, "row_idx": 2, "x": 0.0, "z": 0.0, "res": "Wüste", "num": 7, "color": Color(0.88, 0.82, 0.58)},
		{"col_idx": 3, "row_idx": 2, "x": 1.8, "z": 0.0, "res": "Holz", "num": 11, "color": Color(0.15, 0.48, 0.18)},
		{"col_idx": 4, "row_idx": 2, "x": 3.6, "z": 0.0, "res": "Erz", "num": 4, "color": Color(0.55, 0.58, 0.62)},

		# Reihe 4 (4 Hexes, z = 1.5)
		{"col_idx": 0, "row_idx": 3, "x": -2.7, "z": 1.5, "res": "Weizen", "num": 9, "color": Color(0.92, 0.82, 0.22)},
		{"col_idx": 1, "row_idx": 3, "x": -0.9, "z": 1.5, "res": "Wolle", "num": 12, "color": Color(0.38, 0.72, 0.28)},
		{"col_idx": 2, "row_idx": 3, "x": 0.9, "z": 1.5, "res": "Lehm", "num": 5, "color": Color(0.82, 0.36, 0.18)},
		{"col_idx": 3, "row_idx": 3, "x": 2.7, "z": 1.5, "res": "Weizen", "num": 10, "color": Color(0.92, 0.82, 0.22)},

		# Reihe 5 (3 Hexes, z = 3.0)
		{"col_idx": 0, "row_idx": 4, "x": -1.8, "z": 3.0, "res": "Lehm", "num": 8, "color": Color(0.82, 0.36, 0.18)},
		{"col_idx": 1, "row_idx": 4, "x": 0.0, "z": 3.0, "res": "Holz", "num": 3, "color": Color(0.15, 0.48, 0.18)},
		{"col_idx": 2, "row_idx": 4, "x": 1.8, "z": 3.0, "res": "Wolle", "num": 11, "color": Color(0.38, 0.72, 0.28)}
	]

	hex_tiles.clear()
	for i in range(hex_configs.size()):
		var cfg = hex_configs[i]
		var h_pos = Vector3(cfg.x, 0.32, cfg.z)
		
		# 6-eckige Hexagon-Platte (Cylinder mit 6 Segmenten)
		var hex_mesh = CylinderMesh.new()
		hex_mesh.top_radius = 1.05
		hex_mesh.bottom_radius = 1.08
		hex_mesh.height = 0.25
		hex_mesh.radial_segments = 6

		var tile_inst = MeshInstance3D.new()
		tile_inst.mesh = hex_mesh
		
		# Passende PBR Materialtextur je nach Ressource
		var mat: StandardMaterial3D
		match cfg.res:
			"Holz": mat = TextureHelper.get_grass_material(cfg.color)
			"Wolle": mat = TextureHelper.get_grass_material(cfg.color)
			"Weizen": mat = TextureHelper.get_parchment_material(cfg.color)
			"Erz": mat = TextureHelper.get_stone_material(cfg.color)
			"Lehm": mat = TextureHelper.get_stone_material(cfg.color)
			_: mat = TextureHelper.get_parchment_material(cfg.color)
		tile_inst.material_override = mat
		tile_inst.position = h_pos
		add_child(tile_inst)

		# StaticBody für 3D Klicks
		var sb = StaticBody3D.new()
		var col = CollisionShape3D.new()
		var c_shape = CylinderShape3D.new()
		c_shape.radius = 1.05
		c_shape.height = 0.5
		col.shape = c_shape
		sb.add_child(col)
		sb.set_meta("grid_pos", Vector2i(i, 0))
		tile_inst.add_child(sb)

		# 3D Zahlenchip
		if cfg.res != "Wüste":
			var chip_bg = MeshInstance3D.new()
			var c_m = CylinderMesh.new()
			c_m.top_radius = 0.32
			c_m.bottom_radius = 0.34
			c_m.height = 0.08
			chip_bg.mesh = c_m
			chip_bg.material_override = TextureHelper.get_marble_material(Color(0.96, 0.94, 0.88))
			chip_bg.position = Vector3(0, 0.15, 0)
			tile_inst.add_child(chip_bg)

			var lbl = Label3D.new()
			var is_red = (cfg.num == 6 or cfg.num == 8)
			lbl.text = str(cfg.num) + "\n" + cfg.res
			lbl.pixel_size = 0.012
			lbl.rotation_degrees = Vector3(-90, 0, 0)
			lbl.position = Vector3(0, 0.22, 0)
			lbl.modulate = Color(0.95, 0.15, 0.15) if is_red else Color(0.1, 0.1, 0.1)
			tile_inst.add_child(lbl)
		else:
			# Wüste: Räuber platzieren
			robber_node = create_robber_figure()
			robber_node.position = Vector3(0, 0.2, 0)
			tile_inst.add_child(robber_node)

		cfg["node"] = tile_inst
		hex_tiles.append(cfg)

	# 3. Startbauten (2 Siedlungen & 2 Straßen für Spieler)
	spawn_settlement(Vector3(-1.8, 0.45, -2.1), Color(0.95, 0.2, 0.2), "player")
	spawn_settlement(Vector3(0.9, 0.45, 0.6), Color(0.95, 0.2, 0.2), "player")
	spawn_road(Vector3(-1.35, 0.42, -2.55), Vector3(0, 30, 0), Color(0.95, 0.2, 0.2))
	spawn_road(Vector3(1.35, 0.42, 0.15), Vector3(0, -30, 0), Color(0.95, 0.2, 0.2))

	# Bot Bauten (Blau)
	spawn_settlement(Vector3(-2.7, 0.45, -0.6), Color(0.2, 0.5, 0.95), "enemy")
	spawn_settlement(Vector3(1.8, 0.45, -2.1), Color(0.2, 0.5, 0.95), "enemy")

func create_robber_figure() -> Node3D:
	var r = Node3D.new()
	var mat = TextureHelper.get_stone_material(Color(0.1, 0.1, 0.12))
	var body = MeshInstance3D.new()
	var bm = CylinderMesh.new()
	bm.top_radius = 0.18
	bm.bottom_radius = 0.24
	bm.height = 0.7
	body.mesh = bm
	body.material_override = mat
	body.position = Vector3(0, 0.35, 0)
	r.add_child(body)
	return r

func spawn_settlement(pos: Vector3, col: Color, owner: String):
	var s = Node3D.new()
	s.position = pos
	var mat = TextureHelper.get_wood_material(col)

	var house = MeshInstance3D.new()
	var hm = BoxMesh.new()
	hm.size = Vector3(0.4, 0.35, 0.4)
	house.mesh = hm
	house.material_override = mat
	house.position = Vector3(0, 0.18, 0)
	s.add_child(house)

	var roof = MeshInstance3D.new()
	var rm = PrismMesh.new()
	rm.size = Vector3(0.44, 0.22, 0.44)
	roof.mesh = rm
	roof.material_override = TextureHelper.get_stone_material(Color(0.85, 0.25, 0.15))
	roof.position = Vector3(0, 0.42, 0)
	s.add_child(roof)

	add_child(s)
	settlement_nodes.append({"node": s, "owner": owner, "is_city": false})

func spawn_road(pos: Vector3, rot: Vector3, col: Color):
	var road = MeshInstance3D.new()
	var rm = BoxMesh.new()
	rm.size = Vector3(0.7, 0.08, 0.16)
	road.mesh = rm
	road.material_override = TextureHelper.get_wood_material(col)
	road.position = pos
	road.rotation_degrees = rot
	add_child(road)
	road_nodes.append(road)

func setup_game_ui():
	ui_layer = CanvasLayer.new()
	add_child(ui_layer)

	var panel = PanelContainer.new()
	panel.anchors_preset = Control.PRESET_BOTTOM_RIGHT
	panel.offset_left = -390
	panel.offset_top = -230
	panel.offset_right = -20
	panel.offset_bottom = -20
	ui_layer.add_child(panel)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	panel.add_child(vbox)

	var res_lbl = Label.new()
	res_lbl.name = "ResInfo"
	res_lbl.text = "Holz: 3 | Lehm: 3 | Weizen: 2 | Wolle: 2 | Erz: 1\nSiegpunkte: 2 / 10"
	vbox.add_child(res_lbl)

	var roll_btn = Button.new()
	roll_btn.text = "🎲 2W6 Würfeln (Erträge)"
	roll_btn.custom_minimum_size = Vector2(0, 44)
	roll_btn.pressed.connect(roll_dice)
	vbox.add_child(roll_btn)

	var road_btn = Button.new()
	road_btn.text = "🛤️ Straße bauen (1 Holz + 1 Lehm)"
	road_btn.custom_minimum_size = Vector2(0, 38)
	road_btn.pressed.connect(build_road)
	vbox.add_child(road_btn)

	var settle_btn = Button.new()
	settle_btn.text = "🏠 Siedlung bauen (1H, 1L, 1W, 1Wo)"
	settle_btn.custom_minimum_size = Vector2(0, 38)
	settle_btn.pressed.connect(build_settlement)
	vbox.add_child(settle_btn)

	var city_btn = Button.new()
	city_btn.text = "🏰 Zur Stadt ausbauen (2 Weizen + 3 Erz)"
	city_btn.custom_minimum_size = Vector2(0, 38)
	city_btn.pressed.connect(build_city)
	vbox.add_child(city_btn)

func handle_tile_clicked(grid_pos: Vector2i):
	var idx = grid_pos.x
	if idx >= 0 and idx < hex_tiles.size():
		var h = hex_tiles[idx]
		emit_signal("sound_triggered", "select")
		emit_signal("status_changed", "Hex-Feld " + str(idx + 1) + ": " + h.res + " (Zahl: " + str(h.num) + ")")

func roll_dice():
	var d1 = randi_range(1, 6)
	var d2 = randi_range(1, 6)
	var sum = d1 + d2
	emit_signal("sound_triggered", "dice")

	if sum == 7:
		emit_signal("status_changed", "Eine 7 gewürfelt! Der Räuber wird aktiv!")
	else:
		# Erträge ausschütten
		var gained = []
		for h in hex_tiles:
			if h.num == sum and h.res != "Wüste":
				match h.res:
					"Holz": wood += 1; gained.append("Holz")
					"Lehm": brick += 1; gained.append("Lehm")
					"Weizen": wheat += 1; gained.append("Weizen")
					"Wolle": wool += 1; gained.append("Wolle")
					"Erz": ore += 1; gained.append("Erz")
		emit_signal("sound_triggered", "win")
		var gain_str = ", ".join(gained) if not gained.is_empty() else "Keine Siedlungen am Feld"
		emit_signal("status_changed", "Würfel: " + str(sum) + " (" + str(d1) + "+" + str(d2) + ") | Ertrag: " + gain_str)

	update_ui()

func build_road():
	if wood >= 1 and brick >= 1:
		wood -= 1
		brick -= 1
		roads_built += 1
		emit_signal("sound_triggered", "move")
		spawn_road(Vector3(-1.35 + roads_built * 0.4, 0.42, 1.8), Vector3(0, 0, 0), Color(0.95, 0.2, 0.2))
		emit_signal("status_changed", "🛤️ Neue Handelsstraße fertiggestellt!")
		update_ui()
	else:
		emit_signal("status_changed", "Rohstoffe fehlen für Straße (1 Holz, 1 Lehm nötig)!")

func build_settlement():
	if wood >= 1 and brick >= 1 and wheat >= 1 and wool >= 1:
		wood -= 1
		brick -= 1
		wheat -= 1
		wool -= 1
		settlements_built += 1
		victory_points += 1
		emit_signal("sound_triggered", "win")
		spawn_settlement(Vector3(-0.9 + settlements_built * 0.7, 0.45, 2.5), Color(0.95, 0.2, 0.2), "player")
		emit_signal("status_changed", "🏠 Neue Siedlung gegründet! +1 Siegpunkt (Jetzt: " + str(victory_points) + "/10)!")
		update_ui()
	else:
		emit_signal("status_changed", "Rohstoffe fehlen für Siedlung (1H, 1L, 1W, 1Wo nötig)!")

func build_city():
	if wheat >= 2 and ore >= 3:
		wheat -= 2
		ore -= 3
		cities_built += 1
		victory_points += 1
		emit_signal("sound_triggered", "win")
		emit_signal("status_changed", "🏰 Siedlung zur prächtigen Stadt ausgebaut! +1 Siegpunkt (Jetzt: " + str(victory_points) + "/10)!")
		update_ui()
	else:
		emit_signal("status_changed", "Rohstoffe fehlen für Stadt (2 Weizen, 3 Erz nötig)!")

func update_ui():
	var lbl = ui_layer.get_node_or_null("PanelContainer/VBoxContainer/ResInfo") as Label
	if lbl:
		lbl.text = "Holz: " + str(wood) + " | Lehm: " + str(brick) + " | Weizen: " + str(wheat) + " | Wolle: " + str(wool) + " | Erz: " + str(ore) + "\nSiegpunkte: " + str(victory_points) + " / 10"
