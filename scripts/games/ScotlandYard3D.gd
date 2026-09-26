extends Node3D

class_name ScotlandYard3D

const TextureHelper = preload("res://scripts/TextureHelper.gd")

signal status_changed(msg: String)
signal sound_triggered(sound_name: String)

# Londoner Stationen (Underground, Bus, Taxi, Ferry)
var stations: Array = []
var station_nodes: Array = []
var mr_x_pos: int = 18
var detective_pos: int = 0
var mr_x_revealed: bool = false
var round_num: int = 1
var is_bot_opponent: bool = true

# Tickets
var detective_tickets = {"Taxi": 10, "Bus": 8, "U-Bahn": 4}
var mr_x_last_ticket = "Taxi"

var detective_node: Node3D = null
var mr_x_node: Node3D = null
var water_mesh_inst: MeshInstance3D = null
var ui_layer: CanvasLayer = null
var victory_modal: PanelContainer = null

func _ready():
	setup_stage()
	setup_game_ui()
	reset_game()

func setup_stage():
	# 1. Großflächiger London-Stadtplan Sockel (32x22 Einheiten für Originalgröße)
	var map_mesh = BoxMesh.new()
	map_mesh.size = Vector3(32.0, 0.45, 22.0)
	var map_inst = MeshInstance3D.new()
	map_inst.mesh = map_mesh
	map_inst.material_override = TextureHelper.get_parchment_material(Color(0.88, 0.85, 0.76))
	map_inst.position = Vector3(0, 0.2, 0)
	add_child(map_inst)

	# 2. Londoner Parks (Hyde Park, Regent's Park, St. James's Park)
	spawn_park(Vector3(-10.5, 0.44, 1.5), Vector2(5.5, 4.2), "Hyde Park")
	spawn_park(Vector3(-5.0, 0.44, -7.5), Vector2(6.0, 3.5), "Regent's Park")
	spawn_park(Vector3(-3.5, 0.44, 3.2), Vector2(4.0, 2.2), "St. James's Park")

	# 3. Straßennetz (Cobblestone / Asphalt-Blöcke)
	spawn_city_street_grid()

	# 4. Die Themse: Als durchgehender, fließend verbundener Fluss (SurfaceTool Ribbon)
	build_smooth_river_thames()

	# 5. Berühmte Themse-Brücken (Tower Bridge, London Bridge, Waterloo Bridge, Westminster Bridge)
	spawn_bridge(Vector3(-4.0, 0.52, 1.0), 3.0, 15.0, "Westminster Bridge")
	spawn_bridge(Vector3(1.2, 0.52, 0.5), 2.8, -10.0, "Waterloo Bridge")
	spawn_bridge(Vector3(6.5, 0.52, 1.8), 2.8, 25.0, "London Bridge")
	spawn_tower_bridge(Vector3(10.5, 0.52, 1.0))

	# 6. 32 authentische Londoner Stationen
	setup_london_stations()

	# 7. Verbindungsrouten zeichnen (U-Bahn Rot, Bus Grün, Taxi Gelb)
	draw_route_network()

	# 8. Spielfiguren
	detective_node = spawn_detective_figure(stations[detective_pos].pos)
	mr_x_node = spawn_mrx_figure(stations[mr_x_pos].pos)
	mr_x_node.visible = false

func spawn_park(pos: Vector3, size: Vector2, p_name: String):
	var park = MeshInstance3D.new()
	var p_box = BoxMesh.new()
	p_box.size = Vector3(size.x, 0.04, size.y)
	park.mesh = p_box
	park.material_override = TextureHelper.get_grass_material(Color(0.25, 0.58, 0.28))
	park.position = pos
	add_child(park)

	var lbl = Label3D.new()
	lbl.text = "🌳 " + p_name
	lbl.pixel_size = 0.012
	lbl.rotation_degrees = Vector3(-90, 0, 0)
	lbl.position = Vector3(0, 0.05, 0)
	lbl.modulate = Color(0.12, 0.35, 0.15)
	park.add_child(lbl)

func spawn_city_street_grid():
	var road_mat = TextureHelper.get_stone_material(Color(0.35, 0.35, 0.38))
	# Längs- und Querstraßen
	var road_defs = [
		{"pos": Vector3(-2.0, 0.435, -4.5), "size": Vector3(26.0, 0.02, 0.7)}, # Oxford St / Holborn
		{"pos": Vector3(-2.0, 0.435, -1.8), "size": Vector3(24.0, 0.02, 0.7)}, # Piccadilly / Fleet St
		{"pos": Vector3(0.0, 0.435, 4.5), "size": Vector3(22.0, 0.02, 0.7)},   # Southwark / Lambeth
		{"pos": Vector3(-8.0, 0.435, 0.0), "size": Vector3(0.7, 0.02, 16.0)},  # Park Lane
		{"pos": Vector3(-4.0, 0.435, 0.0), "size": Vector3(0.7, 0.02, 18.0)},  # Regent St / Whitehall
		{"pos": Vector3(3.0, 0.435, 0.0), "size": Vector3(0.7, 0.02, 18.0)},   # Kingsway / Waterloo Rd
		{"pos": Vector3(8.5, 0.435, 0.0), "size": Vector3(0.7, 0.02, 16.0)}    # City / London Bridge Rd
	]
	for rd in road_defs:
		var r_inst = MeshInstance3D.new()
		var bm = BoxMesh.new()
		bm.size = rd.size
		r_inst.mesh = bm
		r_inst.material_override = road_mat
		r_inst.position = rd.pos
		add_child(r_inst)

func build_smooth_river_thames():
	# Glatte Spline-Punkte entlang des echten Themse-Verlaufs
	var spline_points = [
		Vector3(-15.0, 0.44, 2.5),
		Vector3(-12.0, 0.44, 1.8),
		Vector3(-8.5, 0.44, 0.5),
		Vector3(-5.5, 0.44, 0.2),
		Vector3(-2.0, 0.44, -0.2),
		Vector3(1.5, 0.44, 0.2),
		Vector3(4.5, 0.44, 1.2),
		Vector3(8.0, 0.44, 2.0),
		Vector3(11.0, 0.44, 1.2),
		Vector3(13.5, 0.44, -0.5),
		Vector3(15.5, 0.44, -1.8)
	]

	# Feines Interpolieren zu 40 gleichmäßigen Punkten
	var detailed_points: Array[Vector3] = []
	for i in range(spline_points.size() - 1):
		var p0 = spline_points[max(0, i - 1)]
		var p1 = spline_points[i]
		var p2 = spline_points[i + 1]
		var p3 = spline_points[min(spline_points.size() - 1, i + 2)]
		for step in range(5):
			var t = float(step) / 5.0
			var pt = p1.cubic_interpolate(p2, p0, p3, t)
			detailed_points.append(pt)
	detailed_points.append(spline_points.back())

	# Nahtloses Band-Mesh (Ribbon) mit SurfaceTool erzeugen
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var half_width = 1.35
	var count = detailed_points.size()

	for i in range(count):
		var pt = detailed_points[i]
		var dir = Vector3.RIGHT
		if i < count - 1:
			dir = (detailed_points[i + 1] - pt).normalized()
		elif i > 0:
			dir = (pt - detailed_points[i - 1]).normalized()

		var normal_2d = Vector3(-dir.z, 0, dir.x).normalized()
		var left_v = pt + normal_2d * half_width
		var right_v = pt - normal_2d * half_width

		var v_u = float(i) / float(count - 1) * 6.0
		st.set_uv(Vector2(v_u, 0.0))
		st.set_normal(Vector3.UP)
		st.add_vertex(left_v)

		st.set_uv(Vector2(v_u, 1.0))
		st.set_normal(Vector3.UP)
		st.add_vertex(right_v)

	for i in range(count - 1):
		var idx = i * 2
		# Dreieck 1
		st.add_index(idx)
		st.add_index(idx + 1)
		st.add_index(idx + 2)
		# Dreieck 2
		st.add_index(idx + 1)
		st.add_index(idx + 3)
		st.add_index(idx + 2)

	var river_mesh = st.commit()
	water_mesh_inst = MeshInstance3D.new()
	water_mesh_inst.mesh = river_mesh
	var water_mat = TextureHelper.get_water_material(Color(0.06, 0.28, 0.55, 0.92))
	water_mesh_inst.material_override = water_mat
	add_child(water_mesh_inst)

func spawn_bridge(pos: Vector3, length: float, rot_deg: float, b_name: String):
	var bridge = Node3D.new()
	bridge.position = pos
	bridge.rotation_degrees = Vector3(0, rot_deg, 0)

	var b_mat = TextureHelper.get_stone_material(Color(0.65, 0.62, 0.58))
	var deck = MeshInstance3D.new()
	var dm = BoxMesh.new()
	dm.size = Vector3(0.8, 0.12, length)
	deck.mesh = dm
	deck.material_override = b_mat
	bridge.add_child(deck)

	for z_o in [-length * 0.35, length * 0.35]:
		var pillar = MeshInstance3D.new()
		var pm = CylinderMesh.new()
		pm.top_radius = 0.25
		pm.bottom_radius = 0.3
		pm.height = 0.3
		pillar.mesh = pm
		pillar.material_override = b_mat
		pillar.position = Vector3(0, -0.15, z_o)
		bridge.add_child(pillar)

	add_child(bridge)

func spawn_tower_bridge(pos: Vector3):
	var tb = Node3D.new()
	tb.position = pos
	var mat = TextureHelper.get_stone_material(Color(0.72, 0.68, 0.62))

	# Zwei Zwillings-Türme
	for x_o in [-0.5, 0.5]:
		var tower = MeshInstance3D.new()
		var tm = BoxMesh.new()
		tm.size = Vector3(0.55, 1.4, 0.55)
		tower.mesh = tm
		tower.material_override = mat
		tower.position = Vector3(x_o, 0.6, 0)
		tb.add_child(tower)

		# Spitzdach
		var roof = MeshInstance3D.new()
		var rm = PrismMesh.new()
		rm.size = Vector3(0.55, 0.5, 0.55)
		roof.mesh = rm
		roof.material_override = TextureHelper.get_metal_material(Color(0.2, 0.45, 0.7), 0.8)
		roof.position = Vector3(x_o, 1.55, 0)
		tb.add_child(roof)

	# Brückendeck
	var deck = MeshInstance3D.new()
	var dm = BoxMesh.new()
	dm.size = Vector3(1.8, 0.1, 2.6)
	deck.mesh = dm
	deck.material_override = mat
	deck.position = Vector3(0, 0.25, 0)
	tb.add_child(deck)

	add_child(tb)

func setup_london_stations():
	stations = [
		{"name": "Baker Street", "pos": Vector3(-7.5, 0.46, -6.5), "type": "metro", "col": Color(0.9, 0.2, 0.2)},
		{"name": "Regent's Park", "pos": Vector3(-4.5, 0.46, -6.8), "type": "bus", "col": Color(0.2, 0.5, 0.9)},
		{"name": "Euston Station", "pos": Vector3(-1.0, 0.46, -7.2), "type": "metro", "col": Color(0.9, 0.2, 0.2)},
		{"name": "King's Cross", "pos": Vector3(3.0, 0.46, -7.0), "type": "metro", "col": Color(0.9, 0.2, 0.2)},
		{"name": "Angel Islington", "pos": Vector3(7.0, 0.46, -6.5), "type": "bus", "col": Color(0.2, 0.5, 0.9)},
		{"name": "Liverpool Street", "pos": Vector3(11.0, 0.46, -5.5), "type": "metro", "col": Color(0.9, 0.2, 0.2)},

		{"name": "Paddington", "pos": Vector3(-11.5, 0.46, -4.0), "type": "metro", "col": Color(0.9, 0.2, 0.2)},
		{"name": "Marble Arch", "pos": Vector3(-8.0, 0.46, -3.8), "type": "taxi", "col": Color(0.95, 0.85, 0.15)},
		{"name": "Oxford Circus", "pos": Vector3(-4.0, 0.46, -4.0), "type": "metro", "col": Color(0.9, 0.2, 0.2)},
		{"name": "Tottenham Court Rd", "pos": Vector3(-0.5, 0.46, -4.0), "type": "bus", "col": Color(0.2, 0.5, 0.9)},
		{"name": "Holborn", "pos": Vector3(3.5, 0.46, -3.8), "type": "metro", "col": Color(0.9, 0.2, 0.2)},
		{"name": "St. Paul's", "pos": Vector3(7.5, 0.46, -3.2), "type": "taxi", "col": Color(0.95, 0.85, 0.15)},
		{"name": "Bank / Monument", "pos": Vector3(11.0, 0.46, -2.8), "type": "metro", "col": Color(0.9, 0.2, 0.2)},

		{"name": "Hyde Park Corner", "pos": Vector3(-8.5, 0.46, 0.5), "type": "bus", "col": Color(0.2, 0.5, 0.9)},
		{"name": "Green Park", "pos": Vector3(-5.5, 0.46, -1.2), "type": "metro", "col": Color(0.9, 0.2, 0.2)},
		{"name": "Piccadilly Circus", "pos": Vector3(-2.5, 0.46, -1.5), "type": "metro", "col": Color(0.9, 0.2, 0.2)},
		{"name": "Leicester Square", "pos": Vector3(0.5, 0.46, -1.4), "type": "bus", "col": Color(0.2, 0.5, 0.9)},
		{"name": "Covent Garden", "pos": Vector3(3.0, 0.46, -1.2), "type": "taxi", "col": Color(0.95, 0.85, 0.15)},
		{"name": "Blackfriars Pier", "pos": Vector3(6.5, 0.46, -0.2), "type": "ferry", "col": Color(0.12, 0.12, 0.15)},
		{"name": "Tower of London", "pos": Vector3(10.5, 0.46, 0.2), "type": "ferry", "col": Color(0.12, 0.12, 0.15)},

		{"name": "Victoria Station", "pos": Vector3(-7.5, 0.46, 3.5), "type": "metro", "col": Color(0.9, 0.2, 0.2)},
		{"name": "Westminster Abbey", "pos": Vector3(-4.0, 0.46, 2.2), "type": "metro", "col": Color(0.9, 0.2, 0.2)},
		{"name": "Waterloo Station", "pos": Vector3(0.5, 0.46, 2.0), "type": "metro", "col": Color(0.9, 0.2, 0.2)},
		{"name": "Southwark", "pos": Vector3(4.5, 0.46, 2.8), "type": "bus", "col": Color(0.2, 0.5, 0.9)},
		{"name": "London Bridge Station", "pos": Vector3(7.5, 0.46, 3.0), "type": "metro", "col": Color(0.9, 0.2, 0.2)},
		{"name": "Borough Market", "pos": Vector3(9.5, 0.46, 3.8), "type": "taxi", "col": Color(0.95, 0.85, 0.15)},

		{"name": "Pimlico", "pos": Vector3(-6.5, 0.46, 6.5), "type": "bus", "col": Color(0.2, 0.5, 0.9)},
		{"name": "Vauxhall", "pos": Vector3(-3.0, 0.46, 6.0), "type": "metro", "col": Color(0.9, 0.2, 0.2)},
		{"name": "Kennington", "pos": Vector3(1.0, 0.46, 6.2), "type": "taxi", "col": Color(0.95, 0.85, 0.15)},
		{"name": "Elephant & Castle", "pos": Vector3(5.0, 0.46, 6.5), "type": "metro", "col": Color(0.9, 0.2, 0.2)},
		{"name": "Bermondsey", "pos": Vector3(9.0, 0.46, 6.8), "type": "bus", "col": Color(0.2, 0.5, 0.9)},
		{"name": "Canary Wharf", "pos": Vector3(13.5, 0.46, 2.5), "type": "metro", "col": Color(0.9, 0.2, 0.2)}
	]

	station_nodes.clear()
	for i in range(stations.size()):
		var s = stations[i]
		var s_node = Node3D.new()
		s_node.name = "Station_" + str(i)
		s_node.position = s.pos

		# Runder Stations-Sockel mit Leuchtring
		var st_mesh = CylinderMesh.new()
		st_mesh.top_radius = 0.55
		st_mesh.bottom_radius = 0.58
		st_mesh.height = 0.12
		var st_inst = MeshInstance3D.new()
		st_inst.mesh = st_mesh
		st_inst.material_override = TextureHelper.get_metal_material(s.col, 0.8)
		s_node.add_child(st_inst)

		# Klickbarer StaticBody
		var sb = StaticBody3D.new()
		var col = CollisionShape3D.new()
		var cs = CylinderShape3D.new()
		cs.radius = 0.65
		cs.height = 0.6
		col.shape = cs
		sb.add_child(col)
		sb.set_meta("grid_pos", Vector2i(i, 0))
		s_node.add_child(sb)

		# 3D Label mit Stationsnummer & Name
		var lbl = Label3D.new()
		lbl.text = str(i + 1) + ". " + s.name + "\n[" + s.type.to_upper() + "]"
		lbl.pixel_size = 0.011
		lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		lbl.position = Vector3(0, 0.65, 0)
		lbl.outline_size = 4
		s_node.add_child(lbl)

		add_child(s_node)
		station_nodes.append(s_node)

func draw_route_network():
	# Erzeuge farbige Verbindungslinien zwischen benachbarten Stationen
	for i in range(stations.size() - 1):
		var p1 = stations[i].pos
		var p2 = stations[i + 1].pos
		if p1.distance_to(p2) < 5.5:
			draw_connection_line(p1, p2, stations[i].col)

func draw_connection_line(p1: Vector3, p2: Vector3, col: Color):
	var line_node = MeshInstance3D.new()
	var cyl = CylinderMesh.new()
	cyl.top_radius = 0.04
	cyl.bottom_radius = 0.04
	var dist = p1.distance_to(p2)
	cyl.height = dist
	line_node.mesh = cyl

	var mat = StandardMaterial3D.new()
	mat.albedo_color = col
	mat.roughness = 0.3
	line_node.material_override = mat

	line_node.position = (p1 + p2) * 0.5 + Vector3(0, 0.05, 0)
	line_node.look_at(p2 + Vector3(0.001, 0, 0), Vector3.UP)
	line_node.rotation_degrees.x += 90.0
	add_child(line_node)

func spawn_detective_figure(pos: Vector3) -> Node3D:
	var fig = Node3D.new()
	fig.position = pos + Vector3(0, 0.12, 0)
	var mat = TextureHelper.get_wood_material(Color(0.18, 0.48, 0.95))

	var body = MeshInstance3D.new()
	var bm = CylinderMesh.new()
	bm.top_radius = 0.18
	bm.bottom_radius = 0.28
	bm.height = 0.7
	body.mesh = bm
	body.material_override = mat
	body.position = Vector3(0, 0.35, 0)
	fig.add_child(body)

	var head = MeshInstance3D.new()
	var hm = SphereMesh.new()
	hm.radius = 0.22
	hm.height = 0.4
	head.mesh = hm
	head.material_override = mat
	head.position = Vector3(0, 0.85, 0)
	fig.add_child(head)

	add_child(fig)
	return fig

func spawn_mrx_figure(pos: Vector3) -> Node3D:
	var fig = Node3D.new()
	fig.position = pos + Vector3(0, 0.12, 0)
	var mat = TextureHelper.get_metal_material(Color(0.08, 0.08, 0.1), 0.9)

	var body = MeshInstance3D.new()
	var bm = CylinderMesh.new()
	bm.top_radius = 0.18
	bm.bottom_radius = 0.28
	bm.height = 0.7
	body.mesh = bm
	body.material_override = mat
	body.position = Vector3(0, 0.35, 0)
	fig.add_child(body)

	var head = MeshInstance3D.new()
	var hm = SphereMesh.new()
	hm.radius = 0.22
	hm.height = 0.4
	head.mesh = hm
	head.material_override = mat
	head.position = Vector3(0, 0.85, 0)
	fig.add_child(head)

	add_child(fig)
	return fig

func setup_game_ui():
	ui_layer = CanvasLayer.new()
	add_child(ui_layer)

	var panel = PanelContainer.new()
	panel.anchors_preset = Control.PRESET_BOTTOM_RIGHT
	panel.offset_left = -420
	panel.offset_top = -240
	panel.offset_right = -20
	panel.offset_bottom = -20
	ui_layer.add_child(panel)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	panel.add_child(vbox)

	var info = Label.new()
	info.name = "SyInfo"
	info.text = "Runde: 1 / 24 | Detektiv bei: Baker Street\nMister X: Unbekannt (Ticket: Taxi)\nTickets: 🚕10 | 🚌8 | 🚇4"
	vbox.add_child(info)

	var taxi_btn = Button.new()
	taxi_btn.text = "🚕 Taxi nehmen (1 Station weit)"
	taxi_btn.custom_minimum_size = Vector2(0, 42)
	taxi_btn.pressed.connect(func(): use_transport(1, "Taxi"))
	vbox.add_child(taxi_btn)

	var bus_btn = Button.new()
	bus_btn.text = "🚌 Bus-Linie (2 Stationen weit)"
	bus_btn.custom_minimum_size = Vector2(0, 38)
	bus_btn.pressed.connect(func(): use_transport(2, "Bus"))
	vbox.add_child(bus_btn)

	var metro_btn = Button.new()
	metro_btn.text = "🚇 U-Bahn Express (3 Stationen)"
	metro_btn.custom_minimum_size = Vector2(0, 38)
	metro_btn.pressed.connect(func(): use_transport(3, "U-Bahn"))
	vbox.add_child(metro_btn)

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
	vm_title.text = "🏆 MISTER X GEFASST!"
	vm_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vm_vbox.add_child(vm_title)

	var vm_desc = Label.new()
	vm_desc.name = "VictoryDesc"
	vm_desc.text = ""
	vm_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vm_vbox.add_child(vm_desc)

	var vm_btn = Button.new()
	vm_btn.text = "🔄 Neues Spiel"
	vm_btn.custom_minimum_size = Vector2(0, 46)
	vm_btn.pressed.connect(reset_game)
	vm_vbox.add_child(vm_btn)

func reset_game():
	round_num = 1
	detective_pos = 0
	mr_x_pos = 18
	mr_x_revealed = false
	detective_tickets = {"Taxi": 10, "Bus": 8, "U-Bahn": 4}
	mr_x_last_ticket = "Taxi"

	if detective_node:
		detective_node.position = stations[detective_pos].pos + Vector3(0, 0.12, 0)
	if mr_x_node:
		mr_x_node.position = stations[mr_x_pos].pos + Vector3(0, 0.12, 0)
		mr_x_node.visible = false

	if victory_modal:
		victory_modal.visible = false

	update_ui()
	emit_signal("status_changed", "Scotland Yard 3D: London 32x22 Map bereit! Jage Mister X mit Taxi, Bus & U-Bahn!")

func handle_tile_clicked(grid_pos: Vector2i):
	var s_idx = grid_pos.x
	if s_idx >= 0 and s_idx < stations.size():
		var dist = abs(s_idx - detective_pos)
		if dist == 1:
			use_transport(1, "Taxi")
		elif dist == 2:
			use_transport(2, "Bus")
		elif dist == 3:
			use_transport(3, "U-Bahn")
		else:
			travel_to(s_idx, "Direktwahl")

func use_transport(steps: int, ticket_type: String):
	if detective_tickets.get(ticket_type, 0) <= 0:
		emit_signal("status_changed", "Keine " + ticket_type + "-Tickets mehr übrig!")
		return

	detective_tickets[ticket_type] -= 1
	var target = (detective_pos + steps) % stations.size()
	travel_to(target, ticket_type)

func travel_to(target_idx: int, method_name: String):
	detective_pos = target_idx
	var target_pos = stations[detective_pos].pos + Vector3(0, 0.12, 0)
	emit_signal("sound_triggered", "move")

	var tween = create_tween()
	var mid = (detective_node.position + target_pos) * 0.5 + Vector3(0, 1.2, 0)
	tween.tween_property(detective_node, "position", mid, 0.22)
	tween.tween_property(detective_node, "position", target_pos, 0.22)
	tween.tween_callback(check_turn_outcome)

func check_turn_outcome():
	# Detektiv fängt Mister X?
	if detective_pos == mr_x_pos:
		mr_x_node.visible = true
		show_end_screen(true)
		return

	round_num += 1
	if round_num > 24:
		show_end_screen(false)
		return

	# Mister X zieht
	var mx_moves = [1, 2, 3]
	var mx_tickets = ["Taxi", "Bus", "U-Bahn"]
	var move_choice = randi_range(0, 2)
	mr_x_pos = (mr_x_pos + mx_moves[move_choice]) % stations.size()
	mr_x_last_ticket = mx_tickets[move_choice]
	mr_x_node.position = stations[mr_x_pos].pos + Vector3(0, 0.12, 0)

	# Mister X zeigt sich in Runde 3, 8, 13, 18, 24
	if round_num in [3, 8, 13, 18, 24]:
		mr_x_revealed = true
		mr_x_node.visible = true
		emit_signal("sound_triggered", "win")
		emit_signal("status_changed", "🚨 MISTER X GESICHTET! Er taucht bei " + stations[mr_x_pos].name + " auf!")
	else:
		mr_x_revealed = false
		mr_x_node.visible = false

	# Erneute Prüfung nach Mr. X Zug
	if detective_pos == mr_x_pos:
		mr_x_node.visible = true
		show_end_screen(true)
		return

	update_ui()
	emit_signal("status_changed", "Detektiv erreicht " + stations[detective_pos].name + ". Mister X fuhr mit " + mr_x_last_ticket + " weiter!")

func show_end_screen(won: bool):
	if victory_modal:
		victory_modal.visible = true
		var t_lbl = victory_modal.find_child("VictoryTitle", true, false) as Label
		var d_lbl = victory_modal.find_child("VictoryDesc", true, false) as Label
		if won:
			emit_signal("sound_triggered", "win")
			if t_lbl: t_lbl.text = "🏆 MISTER X GEFASST!"
			if d_lbl: d_lbl.text = "Du hast Mister X in Runde " + str(round_num) + " bei " + stations[detective_pos].name + " gestellt!"
			emit_signal("status_changed", "SIEG! Mister X erfolgreich gestellt!")
		else:
			emit_signal("sound_triggered", "shoot")
			if t_lbl: t_lbl.text = "💀 MISTER X IST ENTKOMMEN!"
			if d_lbl: d_lbl.text = "24 Runden sind vorbei und Mister X konnte unerkannt entfliehen!"
			emit_signal("status_changed", "NIEDERLAGE! Mister X ist entkommen!")

func update_ui():
	var lbl = ui_layer.get_node_or_null("PanelContainer/VBoxContainer/SyInfo") as Label
	if lbl:
		var mx_str = stations[mr_x_pos].name if mr_x_revealed else "Unbekannt"
		lbl.text = "Runde: " + str(round_num) + " / 24 | Detektiv bei: " + stations[detective_pos].name + "\nMister X: " + mx_str + " (Letztes Ticket: " + mr_x_last_ticket + ")\nTickets: 🚕" + str(detective_tickets["Taxi"]) + " | 🚌" + str(detective_tickets["Bus"]) + " | 🚇" + str(detective_tickets["U-Bahn"])
