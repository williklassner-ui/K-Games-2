extends Node3D

class_name Katan3D

const TextureHelper = preload("res://scripts/TextureHelper.gd")
const DiceHelper = preload("res://scripts/DiceHelper.gd")

signal status_changed(msg: String)
signal sound_triggered(sound_name: String)

var wood: int = 4
var brick: int = 4
var wheat: int = 3
var wool: int = 3
var ore: int = 2
var victory_points: int = 2
var settlements_built: int = 2
var cities_built: int = 0
var roads_built: int = 2
var turn_count: int = 1
var is_bot_opponent: bool = true

var hex_tiles: Array = []
var settlement_nodes: Array = []
var road_nodes: Array = []
var robber_node: Node3D = null

var die1_node: Node3D = null
var die2_node: Node3D = null
var is_rolling: bool = false

var ui_layer: CanvasLayer = null
var victory_modal: PanelContainer = null

func _ready():
	setup_stage()
	setup_game_ui()
	reset_game()

func setup_stage():
	# 1. Runder Ozean-Rahmen mit Meereswellen (Durchmesser 24.0)
	var ocean_mesh = CylinderMesh.new()
	ocean_mesh.top_radius = 12.0
	ocean_mesh.bottom_radius = 12.4
	ocean_mesh.height = 0.45
	var ocean_inst = MeshInstance3D.new()
	ocean_inst.mesh = ocean_mesh
	ocean_inst.material_override = TextureHelper.get_water_material(Color(0.06, 0.32, 0.65, 0.92))
	ocean_inst.position = Vector3(0, 0.12, 0)
	add_child(ocean_inst)

	# Holzrand um die Insel
	var frame_mesh = TorusMesh.new()
	frame_mesh.inner_radius = 11.8
	frame_mesh.outer_radius = 12.6
	var frame_inst = MeshInstance3D.new()
	frame_inst.mesh = frame_mesh
	frame_inst.material_override = TextureHelper.get_wood_material(Color(0.18, 0.1, 0.05))
	frame_inst.position = Vector3(0, 0.28, 0)
	add_child(frame_inst)

	# 2. Die 19 offiziellen Hexagon-Felder in 3-4-5-4-3 Anordnung (Skalierung x1.8)
	var hex_configs = [
		# Reihe 1 (3 Hexes, z = -5.4)
		{"res": "Holz", "num": 5, "color": Color(0.15, 0.48, 0.18), "x": -3.2, "z": -5.4},
		{"res": "Wolle", "num": 2, "color": Color(0.38, 0.72, 0.28), "x": 0.0, "z": -5.4},
		{"res": "Weizen", "num": 6, "color": Color(0.92, 0.82, 0.22), "x": 3.2, "z": -5.4},

		# Reihe 2 (4 Hexes, z = -2.7)
		{"res": "Erz", "num": 10, "color": Color(0.55, 0.58, 0.62), "x": -4.8, "z": -2.7},
		{"res": "Lehm", "num": 9, "color": Color(0.82, 0.36, 0.18), "x": -1.6, "z": -2.7},
		{"res": "Holz", "num": 4, "color": Color(0.15, 0.48, 0.18), "x": 1.6, "z": -2.7},
		{"res": "Wolle", "num": 8, "color": Color(0.38, 0.72, 0.28), "x": 4.8, "z": -2.7},

		# Reihe 3 (5 Hexes, z = 0.0 - Mitte mit Wüste)
		{"res": "Weizen", "num": 8, "color": Color(0.92, 0.82, 0.22), "x": -6.4, "z": 0.0},
		{"res": "Erz", "num": 3, "color": Color(0.55, 0.58, 0.62), "x": -3.2, "z": 0.0},
		{"res": "Wüste", "num": 7, "color": Color(0.88, 0.82, 0.58), "x": 0.0, "z": 0.0},
		{"res": "Holz", "num": 11, "color": Color(0.15, 0.48, 0.18), "x": 3.2, "z": 0.0},
		{"res": "Erz", "num": 4, "color": Color(0.55, 0.58, 0.62), "x": 6.4, "z": 0.0},

		# Reihe 4 (4 Hexes, z = 2.7)
		{"res": "Weizen", "num": 9, "color": Color(0.92, 0.82, 0.22), "x": -4.8, "z": 2.7},
		{"res": "Wolle", "num": 12, "color": Color(0.38, 0.72, 0.28), "x": -1.6, "z": 2.7},
		{"res": "Lehm", "num": 5, "color": Color(0.82, 0.36, 0.18), "x": 1.6, "z": 2.7},
		{"res": "Weizen", "num": 10, "color": Color(0.92, 0.82, 0.22), "x": 4.8, "z": 2.7},

		# Reihe 5 (3 Hexes, z = 5.4)
		{"res": "Lehm", "num": 8, "color": Color(0.82, 0.36, 0.18), "x": -3.2, "z": 5.4},
		{"res": "Holz", "num": 3, "color": Color(0.15, 0.48, 0.18), "x": 0.0, "z": 5.4},
		{"res": "Wolle", "num": 11, "color": Color(0.38, 0.72, 0.28), "x": 3.2, "z": 5.4}
	]

	hex_tiles.clear()
	for i in range(hex_configs.size()):
		var cfg = hex_configs[i]
		var h_pos = Vector3(cfg.x, 0.38, cfg.z)

		var hex_mesh = CylinderMesh.new()
		hex_mesh.top_radius = 1.75
		hex_mesh.bottom_radius = 1.82
		hex_mesh.height = 0.3
		hex_mesh.radial_segments = 6

		var tile_inst = MeshInstance3D.new()
		tile_inst.mesh = hex_mesh

		var mat: StandardMaterial3D
		match cfg.res:
			"Holz", "Wolle": mat = TextureHelper.get_grass_material(cfg.color)
			"Weizen", "Wüste": mat = TextureHelper.get_parchment_material(cfg.color)
			"Erz", "Lehm": mat = TextureHelper.get_stone_material(cfg.color)
			_: mat = TextureHelper.get_parchment_material(cfg.color)

		tile_inst.material_override = mat
		tile_inst.position = h_pos
		add_child(tile_inst)

		# Klickbarer StaticBody
		var sb = StaticBody3D.new()
		var col = CollisionShape3D.new()
		var cs = CylinderShape3D.new()
		cs.radius = 1.8
		cs.height = 0.5
		col.shape = cs
		sb.add_child(col)
		sb.set_meta("grid_pos", Vector2i(i, 0))
		tile_inst.add_child(sb)

		# 3D Zahlenchip
		if cfg.res != "Wüste":
			var chip = MeshInstance3D.new()
			var cm = CylinderMesh.new()
			cm.top_radius = 0.52
			cm.bottom_radius = 0.55
			cm.height = 0.1
			chip.mesh = cm
			chip.material_override = TextureHelper.get_marble_material(Color(0.96, 0.94, 0.88))
			chip.position = Vector3(0, 0.2, 0)
			tile_inst.add_child(chip)

			var lbl = Label3D.new()
			var is_red = (cfg.num == 6 or cfg.num == 8)
			lbl.text = str(cfg.num) + "\n" + cfg.res
			lbl.pixel_size = 0.014
			lbl.rotation_degrees = Vector3(-90, 0, 0)
			lbl.position = Vector3(0, 0.28, 0)
			lbl.modulate = Color(0.95, 0.15, 0.15) if is_red else Color(0.1, 0.1, 0.1)
			lbl.outline_size = 3
			tile_inst.add_child(lbl)
		else:
			robber_node = create_robber()
			robber_node.position = Vector3(0, 0.25, 0)
			tile_inst.add_child(robber_node)

		cfg["node"] = tile_inst
		hex_tiles.append(cfg)

	# 3. Zwei 3D-Würfel auf dem Meeresbereich
	die1_node = DiceHelper.create_3d_die(1.1, Color(0.98, 0.98, 0.94))
	die1_node.position = Vector3(-8.5, 0.8, -7.5)
	add_child(die1_node)

	die2_node = DiceHelper.create_3d_die(1.1, Color(0.98, 0.98, 0.94))
	die2_node.position = Vector3(-6.2, 0.8, -7.5)
	add_child(die2_node)

	# 4. Startbauten (2 Siedlungen & 2 Straßen)
	spawn_settlement(Vector3(-3.2, 0.55, -3.8), Color(0.95, 0.2, 0.2), "player")
	spawn_settlement(Vector3(1.6, 0.55, 1.2), Color(0.95, 0.2, 0.2), "player")
	spawn_road(Vector3(-2.4, 0.5, -4.6), Vector3(0, 30, 0), Color(0.95, 0.2, 0.2))
	spawn_road(Vector3(2.4, 0.5, 0.4), Vector3(0, -30, 0), Color(0.95, 0.2, 0.2))

func create_robber() -> Node3D:
	var r = Node3D.new()
	var mat = TextureHelper.get_stone_material(Color(0.12, 0.12, 0.14))
	var body = MeshInstance3D.new()
	var bm = CylinderMesh.new()
	bm.top_radius = 0.25
	bm.bottom_radius = 0.35
	bm.height = 0.9
	body.mesh = bm
	body.material_override = mat
	body.position = Vector3(0, 0.45, 0)
	r.add_child(body)
	return r

func spawn_settlement(pos: Vector3, col: Color, owner: String):
	var s = Node3D.new()
	s.position = pos
	var mat = TextureHelper.get_wood_material(col)

	var house = MeshInstance3D.new()
	var hm = BoxMesh.new()
	hm.size = Vector3(0.65, 0.55, 0.65)
	house.mesh = hm
	house.material_override = mat
	house.position = Vector3(0, 0.28, 0)
	s.add_child(house)

	var roof = MeshInstance3D.new()
	var rm = PrismMesh.new()
	rm.size = Vector3(0.7, 0.35, 0.7)
	roof.mesh = rm
	roof.material_override = TextureHelper.get_stone_material(Color(0.85, 0.25, 0.15))
	roof.position = Vector3(0, 0.65, 0)
	s.add_child(roof)

	add_child(s)
	settlement_nodes.append({"node": s, "owner": owner, "pos": pos, "is_city": false})

func spawn_road(pos: Vector3, rot: Vector3, col: Color):
	var road = MeshInstance3D.new()
	var rm = BoxMesh.new()
	rm.size = Vector3(1.1, 0.12, 0.25)
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
	panel.offset_left = -400
	panel.offset_top = -240
	panel.offset_right = -20
	panel.offset_bottom = -20
	ui_layer.add_child(panel)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	panel.add_child(vbox)

	var res_lbl = Label.new()
	res_lbl.name = "ResInfo"
	res_lbl.text = "Holz: 4 | Lehm: 4 | Weizen: 3 | Wolle: 3 | Erz: 2\nSiegpunkte: 2 / 10"
	vbox.add_child(res_lbl)

	var roll_btn = Button.new()
	roll_btn.name = "RollBtn"
	roll_btn.text = "🎲 2W6 3D-Würfel rollen (Erträge)"
	roll_btn.custom_minimum_size = Vector2(0, 46)
	roll_btn.pressed.connect(roll_dice_action)
	vbox.add_child(roll_btn)

	var road_btn = Button.new()
	road_btn.text = "🛤️ Straße bauen (1 Holz + 1 Lehm)"
	road_btn.custom_minimum_size = Vector2(0, 38)
	road_btn.pressed.connect(build_road)
	vbox.add_child(road_btn)

	var settle_btn = Button.new()
	settle_btn.text = "🏠 Siedlung gründen (1H, 1L, 1W, 1Wo)"
	settle_btn.custom_minimum_size = Vector2(0, 38)
	settle_btn.pressed.connect(build_settlement)
	vbox.add_child(settle_btn)

	var city_btn = Button.new()
	city_btn.text = "🏰 Zur Stadt ausbauen (2 Weizen + 3 Erz)"
	city_btn.custom_minimum_size = Vector2(0, 38)
	city_btn.pressed.connect(build_city)
	vbox.add_child(city_btn)

	# Victory Modal
	victory_modal = PanelContainer.new()
	victory_modal.anchors_preset = Control.PRESET_CENTER
	victory_modal.offset_left = -220
	victory_modal.offset_top = -120
	victory_modal.offset_right = 220
	victory_modal.offset_bottom = 120
	victory_modal.visible = false
	ui_layer.add_child(victory_modal)

	var vm_vbox = VBoxContainer.new()
	vm_vbox.add_theme_constant_override("separation", 10)
	victory_modal.add_child(vm_vbox)

	var vm_title = Label.new()
	vm_title.name = "VictoryTitle"
	vm_title.text = "🏆 HERRSCHER VON KATAN!"
	vm_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vm_vbox.add_child(vm_title)

	var vm_desc = Label.new()
	vm_desc.name = "VictoryDesc"
	vm_desc.text = "Du hast 10 Siegpunkte erreicht und die Insel Katan meisterhaft besiedelt!"
	vm_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vm_vbox.add_child(vm_desc)

	var vm_btn = Button.new()
	vm_btn.text = "🔄 Neues Katan-Spiel"
	vm_btn.custom_minimum_size = Vector2(0, 48)
	vm_btn.pressed.connect(reset_game)
	vm_vbox.add_child(vm_btn)

func reset_game():
	wood = 4
	brick = 4
	wheat = 3
	wool = 3
	ore = 2
	victory_points = 2
	settlements_built = 2
	cities_built = 0
	roads_built = 2
	turn_count = 1
	is_rolling = false

	if victory_modal: victory_modal.visible = false
	DiceHelper.apply_value_rotation(die1_node, 3)
	DiceHelper.apply_value_rotation(die2_node, 4)
	update_ui()
	emit_signal("status_changed", "Siedler von Katan 3D: Alle 19 Hex-Felder mit Zahlenchips bereit! Würfle Erträge.")

func handle_tile_clicked(grid_pos: Vector2i):
	var idx = grid_pos.x
	if idx >= 0 and idx < hex_tiles.size():
		var h = hex_tiles[idx]
		emit_signal("sound_triggered", "select")
		emit_signal("status_changed", "Landschaft " + str(idx + 1) + ": " + h.res + " (Zahlenchip: " + str(h.num) + ")")
	else:
		roll_dice_action()

func roll_dice_action():
	if is_rolling: return
	is_rolling = true

	var d1 = randi_range(1, 6)
	var d2 = randi_range(1, 6)
	var sum = d1 + d2
	emit_signal("sound_triggered", "dice")

	DiceHelper.roll_die(die1_node, d1, Vector3(-8.5, 0.8, -7.5), 0.5)
	DiceHelper.roll_die(die2_node, d2, Vector3(-6.2, 0.8, -7.5), 0.5, func():
		is_rolling = false
		process_dice_result(sum, d1, d2)
	)

func process_dice_result(sum: int, d1: int, d2: int):
	if sum == 7:
		emit_signal("sound_triggered", "shoot")
		emit_signal("status_changed", "Eine 7 gewürfelt! (" + str(d1) + "+" + str(d2) + ") - Der Räuber wird aktiv!")
	else:
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
		var gain_str = ", ".join(gained) if not gained.is_empty() else "Kein Ertrag"
		emit_signal("status_changed", "Würfel: " + str(sum) + " (" + str(d1) + "+" + str(d2) + ") | Ertrag: " + gain_str)

	turn_count += 1
	update_ui()

func build_road():
	if wood >= 1 and brick >= 1:
		wood -= 1
		brick -= 1
		roads_built += 1
		emit_signal("sound_triggered", "move")
		spawn_road(Vector3(-2.4 + roads_built * 0.8, 0.5, 3.2), Vector3(0, 0, 0), Color(0.95, 0.2, 0.2))
		emit_signal("status_changed", "🛤️ Neue Handelsstraße fertiggestellt!")
		update_ui()
	else:
		emit_signal("status_changed", "Rohstoffe fehlen (1 Holz, 1 Lehm nötig)!")

func build_settlement():
	if wood >= 1 and brick >= 1 and wheat >= 1 and wool >= 1:
		wood -= 1
		brick -= 1
		wheat -= 1
		wool -= 1
		settlements_built += 1
		victory_points += 1
		emit_signal("sound_triggered", "win")
		spawn_settlement(Vector3(-1.6 + settlements_built * 1.4, 0.55, 4.2), Color(0.95, 0.2, 0.2), "player")
		emit_signal("status_changed", "🏠 Neue Siedlung gegründet! +1 Siegpunkt (Jetzt: " + str(victory_points) + "/10)!")
		check_victory()
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
		emit_signal("status_changed", "🏰 Siedlung zur Stadt ausgebaut! +1 Siegpunkt (Jetzt: " + str(victory_points) + "/10)!")
		check_victory()
		update_ui()
	else:
		emit_signal("status_changed", "Rohstoffe fehlen für Stadt (2 Weizen, 3 Erz nötig)!")

func check_victory():
	if victory_points >= 10:
		emit_signal("sound_triggered", "win")
		if victory_modal:
			victory_modal.visible = true

func update_ui():
	var lbl = ui_layer.get_node_or_null("PanelContainer/VBoxContainer/ResInfo") as Label
	if lbl:
		lbl.text = "Holz: " + str(wood) + " | Lehm: " + str(brick) + " | Weizen: " + str(wheat) + " | Wolle: " + str(wool) + " | Erz: " + str(ore) + "\nSiegpunkte: " + str(victory_points) + " / 10"
