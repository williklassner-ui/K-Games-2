extends Node3D

class_name ScotlandYard3D

const TextureHelper = preload("res://scripts/TextureHelper.gd")

signal status_changed(msg: String)
signal sound_triggered(sound_name: String)

# 24 Londoner Stationen (Underground, Bus, Taxi, Ferry)
var stations: Array = []
var mr_x_pos: int = 12
var detective_pos: int = 0
var mr_x_revealed: bool = false
var round_num: int = 1
var is_bot_opponent: bool = true

var detective_node: Node3D = null
var mr_x_node: Node3D = null
var ui_layer: CanvasLayer = null

func _ready():
	setup_stage()
	setup_game_ui()
	emit_signal("status_changed", "Scotland Yard 3D: 24 Stationen in London bereit! Jage Mister X mit Taxi, Bus und U-Bahn!")

func setup_stage():
	# 1. London-Stadtplan Sockel mit antiker Pergament-Textur
	var map_mesh = BoxMesh.new()
	map_mesh.size = Vector3(18.0, 0.4, 12.0)
	var map_inst = MeshInstance3D.new()
	map_inst.mesh = map_mesh
	map_inst.material_override = TextureHelper.get_parchment_material(Color(0.85, 0.82, 0.72))
	map_inst.position = Vector3(0, 0.18, 0)
	add_child(map_inst)

	# 2. Die Themse (River Thames) mit Wasserwellen
	var thames_points = [
		Vector3(-8.0, 0.4, -1.5), Vector3(-4.5, 0.4, -0.5), Vector3(-1.0, 0.4, 0.8),
		Vector3(2.5, 0.4, 1.5), Vector3(6.0, 0.4, 0.5), Vector3(8.0, 0.4, -0.8)
	]
	var water_mat = TextureHelper.get_water_material(Color(0.08, 0.28, 0.55, 0.88))
	for i in range(thames_points.size() - 1):
		var p1 = thames_points[i]
		var p2 = thames_points[i + 1]
		var r_mesh = BoxMesh.new()
		var dist = p1.distance_to(p2)
		r_mesh.size = Vector3(dist, 0.06, 1.6)
		var r_inst = MeshInstance3D.new()
		r_inst.mesh = r_mesh
		r_inst.material_override = water_mat
		r_inst.position = (p1 + p2) * 0.5
		r_inst.look_at(p2 + Vector3(0.001, 0, 0), Vector3.UP)
		add_child(r_inst)

	# 3. Die 24 Londoner Stationen
	stations = [
		{"name": "Baker Street", "pos": Vector3(-6.5, 0.45, -4.0), "type": "metro", "col": Color(0.92, 0.2, 0.2)},
		{"name": "Regent's Park", "pos": Vector3(-4.0, 0.45, -4.5), "type": "bus", "col": Color(0.2, 0.45, 0.9)},
		{"name": "Euston Station", "pos": Vector3(-1.5, 0.45, -4.8), "type": "metro", "col": Color(0.92, 0.2, 0.2)},
		{"name": "King's Cross", "pos": Vector3(1.5, 0.45, -4.6), "type": "metro", "col": Color(0.92, 0.2, 0.2)},
		{"name": "Angel Islington", "pos": Vector3(4.5, 0.45, -4.2), "type": "bus", "col": Color(0.2, 0.45, 0.9)},
		{"name": "Liverpool Street", "pos": Vector3(7.0, 0.45, -3.5), "type": "metro", "col": Color(0.92, 0.2, 0.2)},

		{"name": "Marble Arch", "pos": Vector3(-6.8, 0.45, -2.2), "type": "taxi", "col": Color(0.95, 0.8, 0.15)},
		{"name": "Oxford Circus", "pos": Vector3(-4.2, 0.45, -2.5), "type": "metro", "col": Color(0.92, 0.2, 0.2)},
		{"name": "Tottenham Court Rd", "pos": Vector3(-1.8, 0.45, -2.6), "type": "bus", "col": Color(0.2, 0.45, 0.9)},
		{"name": "Holborn", "pos": Vector3(1.2, 0.45, -2.4), "type": "metro", "col": Color(0.92, 0.2, 0.2)},
		{"name": "St. Paul's Cathedral", "pos": Vector3(4.2, 0.45, -2.0), "type": "taxi", "col": Color(0.95, 0.8, 0.15)},
		{"name": "Bank / Monument", "pos": Vector3(6.8, 0.45, -1.8), "type": "metro", "col": Color(0.92, 0.2, 0.2)},

		{"name": "Hyde Park Corner", "pos": Vector3(-6.5, 0.45, 0.2), "type": "bus", "col": Color(0.2, 0.45, 0.9)},
		{"name": "Piccadilly Circus", "pos": Vector3(-3.8, 0.45, -0.6), "type": "metro", "col": Color(0.92, 0.2, 0.2)},
		{"name": "Trafalgar Square", "pos": Vector3(-1.5, 0.45, -0.4), "type": "bus", "col": Color(0.2, 0.45, 0.9)},
		{"name": "Blackfriars (Ferry)", "pos": Vector3(1.5, 0.45, 0.6), "type": "ferry", "col": Color(0.1, 0.1, 0.15)},
		{"name": "London Bridge", "pos": Vector3(4.5, 0.45, 1.8), "type": "metro", "col": Color(0.92, 0.2, 0.2)},
		{"name": "Tower of London", "pos": Vector3(7.2, 0.45, 1.2), "type": "ferry", "col": Color(0.1, 0.1, 0.15)},

		{"name": "Victoria Station", "pos": Vector3(-5.5, 0.45, 2.5), "type": "metro", "col": Color(0.92, 0.2, 0.2)},
		{"name": "Westminster Abbey", "pos": Vector3(-2.8, 0.45, 1.8), "type": "taxi", "col": Color(0.95, 0.8, 0.15)},
		{"name": "Waterloo Station", "pos": Vector3(0.2, 0.45, 2.8), "type": "metro", "col": Color(0.92, 0.2, 0.2)},
		{"name": "Southwark Cathedral", "pos": Vector3(3.2, 0.45, 3.6), "type": "bus", "col": Color(0.2, 0.45, 0.9)},
		{"name": "Borough Market", "pos": Vector3(5.6, 0.45, 3.8), "type": "taxi", "col": Color(0.95, 0.8, 0.15)},
		{"name": "Elephant & Castle", "pos": Vector3(2.5, 0.45, 5.0), "type": "metro", "col": Color(0.92, 0.2, 0.2)}
	]

	for i in range(stations.size()):
		var s = stations[i]
		var s_node = Node3D.new()
		s_node.name = "Station_" + str(i)
		s_node.position = s.pos

		# Stations-Sockel mit leuchtendem Transportring
		var st_mesh = CylinderMesh.new()
		st_mesh.top_radius = 0.42
		st_mesh.bottom_radius = 0.45
		st_mesh.height = 0.1
		var st_inst = MeshInstance3D.new()
		st_inst.mesh = st_mesh
		st_inst.material_override = TextureHelper.get_metal_material(s.col, 0.75)
		s_node.add_child(st_inst)

		# StaticBody für 3D Klick- und Touch-Erfassung
		var sb = StaticBody3D.new()
		var col = CollisionShape3D.new()
		var c_shape = CylinderShape3D.new()
		c_shape.radius = 0.5
		c_shape.height = 0.6
		col.shape = c_shape
		sb.add_child(col)
		sb.set_meta("grid_pos", Vector2i(i, 0))
		s_node.add_child(sb)

		# Label mit Stationsname & Verkehrsmittel
		var lbl = Label3D.new()
		lbl.text = str(i + 1) + ". " + s.name + "\n[" + s.type.to_upper() + "]"
		lbl.pixel_size = 0.011
		lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		lbl.position = Vector3(0, 0.5, 0)
		lbl.outline_size = 4
		s_node.add_child(lbl)

		add_child(s_node)

	# Spielfiguren: Detektiv (Blau) und Mister X (Schwarz/Geheim)
	detective_node = spawn_detective_figure(stations[detective_pos].pos)
	mr_x_node = spawn_mrx_figure(stations[mr_x_pos].pos)
	mr_x_node.visible = false # Mister X ist zunächst unsichtbar!

func spawn_detective_figure(pos: Vector3) -> Node3D:
	var fig = Node3D.new()
	fig.position = pos + Vector3(0, 0.1, 0)
	var mat = TextureHelper.get_wood_material(Color(0.15, 0.45, 0.95))

	var body = MeshInstance3D.new()
	var bm = CylinderMesh.new()
	bm.top_radius = 0.15
	bm.bottom_radius = 0.25
	bm.height = 0.65
	body.mesh = bm
	body.material_override = mat
	body.position = Vector3(0, 0.32, 0)
	fig.add_child(body)

	var head = MeshInstance3D.new()
	var hm = SphereMesh.new()
	hm.radius = 0.18
	hm.height = 0.35
	head.mesh = hm
	head.material_override = mat
	head.position = Vector3(0, 0.75, 0)
	fig.add_child(head)

	add_child(fig)
	return fig

func spawn_mrx_figure(pos: Vector3) -> Node3D:
	var fig = Node3D.new()
	fig.position = pos + Vector3(0, 0.1, 0)
	var mat = TextureHelper.get_metal_material(Color(0.08, 0.08, 0.1), 0.9)

	var body = MeshInstance3D.new()
	var bm = CylinderMesh.new()
	bm.top_radius = 0.15
	bm.bottom_radius = 0.25
	bm.height = 0.65
	body.mesh = bm
	body.material_override = mat
	body.position = Vector3(0, 0.32, 0)
	fig.add_child(body)

	add_child(fig)
	return fig

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
	info.name = "SyInfo"
	info.text = "Runde: 1 | Detektiv bei: Baker Street\nMister X: Unbekannt (Letztes Ticket: Taxi)"
	vbox.add_child(info)

	var taxi_btn = Button.new()
	taxi_btn.text = "🚕 Mit Taxi zur nächsten Station"
	taxi_btn.custom_minimum_size = Vector2(0, 42)
	taxi_btn.pressed.connect(func(): travel_step(1, "Taxi"))
	vbox.add_child(taxi_btn)

	var bus_btn = Button.new()
	bus_btn.text = "🚌 Mit Bus 2 Stationen weit"
	bus_btn.custom_minimum_size = Vector2(0, 38)
	bus_btn.pressed.connect(func(): travel_step(2, "Bus"))
	vbox.add_child(bus_btn)

	var metro_btn = Button.new()
	metro_btn.text = "🚇 U-Bahn Express (3 Stationen)"
	metro_btn.custom_minimum_size = Vector2(0, 38)
	metro_btn.pressed.connect(func(): travel_step(3, "U-Bahn"))
	vbox.add_child(metro_btn)

func handle_tile_clicked(grid_pos: Vector2i):
	var s_idx = grid_pos.x
	if s_idx >= 0 and s_idx < stations.size():
		travel_to(s_idx, "Direktwahl")

func travel_step(steps: int, method_name: String):
	var target = (detective_pos + steps) % stations.size()
	travel_to(target, method_name)

func travel_to(target_idx: int, method_name: String):
	detective_pos = target_idx
	var target_pos = stations[detective_pos].pos + Vector3(0, 0.1, 0)
	emit_signal("sound_triggered", "move")

	var tween = create_tween()
	var mid = (detective_node.position + target_pos) * 0.5 + Vector3(0, 1.0, 0)
	tween.tween_property(detective_node, "position", mid, 0.2)
	tween.tween_property(detective_node, "position", target_pos, 0.2)
	tween.tween_callback(check_turn_outcome)

func check_turn_outcome():
	round_num += 1
	# Mister X bewegt sich
	mr_x_pos = (mr_x_pos + randi_range(1, 3)) % stations.size()
	mr_x_node.position = stations[mr_x_pos].pos + Vector3(0, 0.1, 0)

	# In Runde 3, 8, 13 zeigt sich Mister X kurz!
	if round_num in [3, 8, 13]:
		mr_x_revealed = true
		mr_x_node.visible = true
		emit_signal("sound_triggered", "win")
		emit_signal("status_changed", "🚨 MISTER X ZEIGT SICH! Er wurde bei " + stations[mr_x_pos].name + " gesichtet!")
	else:
		mr_x_revealed = false
		mr_x_node.visible = false

	# Detektiv fängt Mister X?
	if detective_pos == mr_x_pos:
		mr_x_node.visible = true
		emit_signal("sound_triggered", "win")
		emit_signal("status_changed", "🏆 GEFASST! Detektiv hat Mister X bei " + stations[detective_pos].name + " geschnappt!")
	else:
		var st_name = stations[detective_pos].name
		emit_signal("status_changed", "Detektiv erreicht " + st_name + ". Mister X zieht weiter...")

	update_ui()

func update_ui():
	var lbl = ui_layer.get_node_or_null("PanelContainer/VBoxContainer/SyInfo") as Label
	if lbl:
		var mx_str = stations[mr_x_pos].name if mr_x_revealed else "Unbekannt"
		lbl.text = "Runde: " + str(round_num) + " | Detektiv bei: " + stations[detective_pos].name + "\nMister X: " + mx_str
