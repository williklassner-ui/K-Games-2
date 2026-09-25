extends Node3D

class_name ScotlandYard3D

signal status_changed(msg: String)
signal sound_triggered(sound_name: String)

var stations = [
	{"pos": Vector3(-3.5, 0.38, -2.5), "type": "metro", "col": Color(0.9, 0.15, 0.15), "name": "Baker Street"},
	{"pos": Vector3(-1.0, 0.38, -2.0), "type": "bus", "col": Color(0.15, 0.4, 0.9), "name": "Piccadilly Circus"},
	{"pos": Vector3(2.5, 0.38, -2.5), "type": "taxi", "col": Color(0.95, 0.8, 0.1), "name": "Holborn"},
	{"pos": Vector3(-2.5, 0.38, 2.0), "type": "metro", "col": Color(0.9, 0.15, 0.15), "name": "Westminster"},
	{"pos": Vector3(0.5, 0.38, 2.5), "type": "bus", "col": Color(0.15, 0.4, 0.9), "name": "London Bridge"},
	{"pos": Vector3(3.5, 0.38, 2.0), "type": "taxi", "col": Color(0.95, 0.8, 0.1), "name": "Tower Hill"}
]

var mr_x_pos = 2
var detective_pos = 0
var mr_x_revealed = false
var detective_node: Node3D = null
var mr_x_node: Node3D = null
var round_num = 1
var ui_layer: CanvasLayer

func _ready():
	setup_stage()
	setup_game_ui()
	emit_signal("status_changed", "Scotland Yard 3D: Fahre mit Taxi, Bus oder U-Bahn um Mister X in London zu schnappen!")

func setup_stage():
	var map_mesh = BoxMesh.new()
	map_mesh.size = Vector3(12.0, 0.35, 9.0)
	var map_inst = MeshInstance3D.new()
	map_inst.mesh = map_mesh
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.14, 0.15, 0.18)
	mat.roughness = 0.5
	map_inst.material_override = mat
	map_inst.position = Vector3(0, 0.15, 0)
	add_child(map_inst)

	# Themse
	var river_points = [Vector3(-5.5, 0.36, -1.0), Vector3(-2.0, 0.36, -0.2), Vector3(1.5, 0.36, 1.2), Vector3(5.5, 0.36, 0.8)]
	for p in river_points:
		var r_mesh = BoxMesh.new()
		r_mesh.size = Vector3(3.2, 0.05, 1.2)
		var r_inst = MeshInstance3D.new()
		r_inst.mesh = r_mesh
		var r_mat = StandardMaterial3D.new()
		r_mat.albedo_color = Color(0.05, 0.28, 0.55, 0.85)
		r_inst.material_override = r_mat
		r_inst.position = p
		add_child(r_inst)

	for i in range(stations.size()):
		var s = stations[i]
		var st_mesh = CylinderMesh.new()
		st_mesh.top_radius = 0.35
		st_mesh.bottom_radius = 0.35
		st_mesh.height = 0.06
		var st = MeshInstance3D.new()
		st.mesh = st_mesh
		var st_mat = StandardMaterial3D.new()
		st_mat.albedo_color = s.col
		st.material_override = st_mat
		st.position = s.pos

		var lbl = Label3D.new()
		lbl.text = s.name + "\n[" + s.type.capitalize() + "]"
		lbl.pixel_size = 0.012
		lbl.position = Vector3(0, 0.35, 0)
		lbl.rotation_degrees = Vector3(-45, 0, 0)
		st.add_child(lbl)

		# StaticBody
		var sb = StaticBody3D.new()
		var col = CollisionShape3D.new()
		var shape = BoxShape3D.new()
		shape.size = Vector3(0.8, 0.5, 0.8)
		col.shape = shape
		sb.add_child(col)
		sb.set_meta("grid_pos", Vector2i(i, 0))
		st.add_child(sb)

		add_child(st)

	detective_node = spawn_figure(stations[detective_pos].pos, Color(0.15, 0.45, 0.95), "Detektiv")
	mr_x_node = spawn_figure(stations[mr_x_pos].pos, Color(0.08, 0.08, 0.08), "Mister X")
	mr_x_node.visible = false

func spawn_figure(pos: Vector3, col: Color, _fig_name: String) -> Node3D:
	var fig = Node3D.new()
	fig.position = pos + Vector3(0, 0.2, 0)

	var mat = StandardMaterial3D.new()
	mat.albedo_color = col

	var body = MeshInstance3D.new()
	var bm = CylinderMesh.new()
	bm.top_radius = 0.12
	bm.bottom_radius = 0.22
	bm.height = 0.6
	body.mesh = bm
	body.material_override = mat
	body.position = Vector3(0, 0.3, 0)
	fig.add_child(body)

	var head = MeshInstance3D.new()
	var hm = SphereMesh.new()
	hm.radius = 0.16
	hm.height = 0.32
	head.mesh = hm
	head.material_override = mat
	head.position = Vector3(0, 0.68, 0)
	fig.add_child(head)

	add_child(fig)
	return fig

func setup_game_ui():
	ui_layer = CanvasLayer.new()
	add_child(ui_layer)

	var panel = PanelContainer.new()
	panel.anchors_preset = Control.PRESET_BOTTOM_RIGHT
	panel.offset_left = -320
	panel.offset_top = -140
	panel.offset_right = -20
	panel.offset_bottom = -20
	ui_layer.add_child(panel)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	panel.add_child(vbox)

	var info = Label.new()
	info.name = "SyInfo"
	info.text = "Runde: 1 | Mister X: Versteckt"
	vbox.add_child(info)

	var taxi_btn = Button.new()
	taxi_btn.text = "🚕 Mit Taxi zur nächsten Station"
	taxi_btn.custom_minimum_size = Vector2(0, 42)
	taxi_btn.pressed.connect(func(): travel_to((detective_pos + 1) % stations.size(), "Taxi"))
	vbox.add_child(taxi_btn)

	var metro_btn = Button.new()
	metro_btn.text = "🚇 U-Bahn Express (2 Stationen)"
	metro_btn.custom_minimum_size = Vector2(0, 38)
	metro_btn.pressed.connect(func(): travel_to((detective_pos + 2) % stations.size(), "Metro"))
	vbox.add_child(metro_btn)

func handle_tile_clicked(grid_pos: Vector2i):
	var s_idx = grid_pos.x
	if s_idx >= 0 and s_idx < stations.size():
		travel_to(s_idx, "Direkt")

func travel_to(target_idx: int, method_name: String):
	detective_pos = target_idx
	var target = stations[detective_pos].pos + Vector3(0, 0.2, 0)
	emit_signal("sound_triggered", "move")

	var tween = create_tween()
	var mid = (detective_node.position + target) * 0.5 + Vector3(0, 0.6, 0)
	tween.tween_property(detective_node, "position", mid, 0.15)
	tween.tween_property(detective_node, "position", target, 0.15)

	round_num += 1

	# Mister X Bewegung
	mr_x_pos = (mr_x_pos + randi_range(1, 2)) % stations.size()
	mr_x_revealed = (round_num % 3 == 0)
	mr_x_node.visible = mr_x_revealed
	mr_x_node.position = stations[mr_x_pos].pos + Vector3(0, 0.2, 0)

	var info_lbl = ui_layer.get_node_or_null("PanelContainer/VBoxContainer/SyInfo") as Label

	if detective_pos == mr_x_pos:
		mr_x_node.visible = true
		emit_signal("sound_triggered", "win")
		emit_signal("status_changed", "GEFASST! Detektiv hat Mister X bei " + stations[detective_pos].name + " gestellt!")
		if info_lbl: info_lbl.text = "MISTER X GESCHNAPPT!"
	else:
		if mr_x_revealed:
			emit_signal("sound_triggered", "select")
			emit_signal("status_changed", method_name + " nach " + stations[detective_pos].name + "! Mister X wurde gesichtet bei " + stations[mr_x_pos].name + "!")
			if info_lbl: info_lbl.text = "Runde: " + str(round_num) + " | Mister X gesichtet: " + stations[mr_x_pos].name
		else:
			emit_signal("status_changed", method_name + " nach " + stations[detective_pos].name + "! Mister X nutzt Black Ticket...")
			if info_lbl: info_lbl.text = "Runde: " + str(round_num) + " | Mister X: Versteckt"
