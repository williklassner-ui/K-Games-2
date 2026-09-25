extends Node3D

class_name Katan3D

signal status_changed(msg: String)
signal sound_triggered(sound_name: String)

var wood = 2
var brick = 2
var wheat = 2
var ore = 0
var settlements = 1
var roads = 1
var victory_points = 2
var ui_layer: CanvasLayer

func _ready():
	setup_stage()
	setup_game_ui()
	emit_signal("status_changed", "Siedler von Katan 3D: Würfle Erträge oder baue Siedlungen & Straßen!")

func setup_stage():
	var hex_coords = [
		{"pos": Vector3(0, 0, 0), "type": "Wüste", "col": Color(0.85, 0.78, 0.55), "number": 7},
		{"pos": Vector3(-1.8, 0, 0), "type": "Weizen", "col": Color(0.9, 0.8, 0.2), "number": 6},
		{"pos": Vector3(1.8, 0, 0), "type": "Holz", "col": Color(0.18, 0.5, 0.15), "number": 8},
		{"pos": Vector3(-0.9, 0, -1.6), "type": "Erz", "col": Color(0.45, 0.48, 0.52), "number": 5},
		{"pos": Vector3(0.9, 0, -1.6), "type": "Lehm", "col": Color(0.78, 0.32, 0.18), "number": 9},
		{"pos": Vector3(-0.9, 0, 1.6), "type": "Wolle", "col": Color(0.45, 0.75, 0.3), "number": 4},
		{"pos": Vector3(0.9, 0, 1.6), "type": "Weizen", "col": Color(0.9, 0.8, 0.2), "number": 10}
	]

	for h in hex_coords:
		var tile_mesh = CylinderMesh.new()
		tile_mesh.top_radius = 1.0
		tile_mesh.bottom_radius = 1.0
		tile_mesh.height = 0.3
		var tile = MeshInstance3D.new()
		tile.mesh = tile_mesh

		var mat = StandardMaterial3D.new()
		mat.albedo_color = h.col
		mat.roughness = 0.4
		tile.material_override = mat
		tile.position = h.pos + Vector3(0, 0.15, 0)

		# 3D Zahlenchip
		var chip = Label3D.new()
		chip.text = str(h.number) + "\n" + h.type
		chip.pixel_size = 0.012
		chip.position = Vector3(0, 0.32, 0)
		chip.rotation_degrees = Vector3(-90, 0, 0)
		chip.modulate = Color(0.1, 0.1, 0.1)
		tile.add_child(chip)

		add_child(tile)

	# Start-Bauten
	spawn_settlement(Vector3(-0.9, 0.32, 0.5), Color(0.9, 0.15, 0.15))
	spawn_road(Vector3(-0.45, 0.31, 0.25), Vector3(0, 45, 0), Color(0.9, 0.15, 0.15))

func spawn_settlement(pos: Vector3, col: Color):
	var s = Node3D.new()
	s.position = pos
	var mat = StandardMaterial3D.new()
	mat.albedo_color = col

	var body = MeshInstance3D.new()
	var b_m = BoxMesh.new()
	b_m.size = Vector3(0.35, 0.3, 0.35)
	body.mesh = b_m
	body.material_override = mat
	body.position = Vector3(0, 0.15, 0)
	s.add_child(body)

	var roof = MeshInstance3D.new()
	var r_m = PrismMesh.new()
	r_m.size = Vector3(0.4, 0.2, 0.4)
	roof.mesh = r_m
	roof.material_override = mat
	roof.position = Vector3(0, 0.35, 0)
	s.add_child(roof)

	add_child(s)

func spawn_road(pos: Vector3, rot: Vector3, col: Color):
	var road = MeshInstance3D.new()
	var r_m = BoxMesh.new()
	r_m.size = Vector3(0.8, 0.08, 0.15)
	road.mesh = r_m
	var mat = StandardMaterial3D.new()
	mat.albedo_color = col
	road.material_override = mat
	road.position = pos
	road.rotation_degrees = rot
	add_child(road)

func setup_game_ui():
	ui_layer = CanvasLayer.new()
	add_child(ui_layer)

	var panel = PanelContainer.new()
	panel.anchors_preset = Control.PRESET_BOTTOM_RIGHT
	panel.offset_left = -340
	panel.offset_top = -180
	panel.offset_right = -20
	panel.offset_bottom = -20
	ui_layer.add_child(panel)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	panel.add_child(vbox)

	var res_lbl = Label.new()
	res_lbl.name = "ResLabel"
	res_lbl.text = "Holz: 2 | Lehm: 2 | Weizen: 2 | Erz: 0 | Punkte: 2"
	vbox.add_child(res_lbl)

	var roll_btn = Button.new()
	roll_btn.text = "🎲 Erträge würfeln (2W6)"
	roll_btn.custom_minimum_size = Vector2(0, 42)
	roll_btn.pressed.connect(roll_resources)
	vbox.add_child(roll_btn)

	var build_road_btn = Button.new()
	build_road_btn.text = "🛤️ Straße bauen (1 Holz + 1 Lehm)"
	build_road_btn.custom_minimum_size = Vector2(0, 38)
	build_road_btn.pressed.connect(build_road)
	vbox.add_child(build_road_btn)

	var build_settle_btn = Button.new()
	build_settle_btn.text = "🏠 Siedlung bauen (1H, 1L, 1W)"
	build_settle_btn.custom_minimum_size = Vector2(0, 38)
	build_settle_btn.pressed.connect(build_settlement)
	vbox.add_child(build_settle_btn)

func roll_resources():
	var d1 = randi_range(1, 6)
	var d2 = randi_range(1, 6)
	var sum = d1 + d2
	emit_signal("sound_triggered", "dice")

	if sum == 7:
		emit_signal("status_changed", "Eine 7 gewürfelt! Der Räuber zieht um!")
	else:
		wood += 1
		brick += 1
		wheat += 1
		emit_signal("sound_triggered", "win")
		emit_signal("status_changed", "Würfel: " + str(sum) + "! Rohstoffe erhalten (+1 Holz, +1 Lehm, +1 Weizen)!")
	update_ui()

func build_road():
	if wood >= 1 and brick >= 1:
		wood -= 1
		brick -= 1
		roads += 1
		emit_signal("sound_triggered", "move")
		spawn_road(Vector3(-0.45 + (roads * 0.4), 0.31, 0.25), Vector3(0, 0, 0), Color(0.9, 0.15, 0.15))
		update_ui()
		emit_signal("status_changed", "Neue Handelsstraße errichtet!")
	else:
		emit_signal("status_changed", "Nicht genug Rohstoffe für eine Straße (1 Holz, 1 Lehm)!")

func build_settlement():
	if wood >= 1 and brick >= 1 and wheat >= 1:
		wood -= 1
		brick -= 1
		wheat -= 1
		settlements += 1
		victory_points += 1
		emit_signal("sound_triggered", "win")
		spawn_settlement(Vector3(-0.9 + (settlements * 0.8), 0.32, 0.5), Color(0.9, 0.15, 0.15))
		update_ui()
		emit_signal("status_changed", "Neue Siedlung gebaut! +1 Siegpunkt! Gesamt: " + str(victory_points) + " VP!")
	else:
		emit_signal("status_changed", "Nicht genug Rohstoffe für eine Siedlung (1 Holz, 1 Lehm, 1 Weizen)!")

func update_ui():
	var lbl = ui_layer.get_node_or_null("PanelContainer/VBoxContainer/ResLabel") as Label
	if lbl:
		lbl.text = "Holz: " + str(wood) + " | Lehm: " + str(brick) + " | Weizen: " + str(wheat) + " | VP: " + str(victory_points)
