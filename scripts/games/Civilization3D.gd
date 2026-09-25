extends Node3D

class_name Civilization3D

signal status_changed(msg: String)
signal sound_triggered(sound_name: String)

var gold = 100
var science = 20
var turn = 1
var selected_tile: Vector2i = Vector2i(-1, -1)
var tiles_data: Dictionary = {}
var tile_nodes: Dictionary = {}
var ui_layer: CanvasLayer

func _ready():
	setup_stage()
	setup_game_ui()
	emit_signal("status_changed", "Civilization CtP2: Wähle ein Feld um Städte zu gründen oder Siedler zu bewegen!")

func setup_stage():
	for x in range(12):
		for z in range(8):
			var tile = Node3D.new()
			var world_x = (x - 5.5) * 1.05
			var world_z = (z - 3.5) * 1.05
			
			var is_mountain = (x == 3 and z == 4) or (x == 4 and z == 4) or (x == 8 and z == 2)
			var is_hill = (x == 2 and z == 3) or (x == 5 and z == 5) or (x == 7 and z == 3)
			var is_water = (z == 0 or (x <= 1 and z <= 2))

			var tile_mesh: Mesh
			var mat = StandardMaterial3D.new()
			var type = "plains"

			if is_mountain:
				type = "mountain"
				var p = PrismMesh.new()
				p.size = Vector3(0.95, 1.2, 0.95)
				tile_mesh = p
				mat.albedo_color = Color(0.88, 0.90, 0.95)
				mat.roughness = 0.4
				tile.position = Vector3(world_x, 0.6, world_z)
			elif is_hill:
				type = "hill"
				var s = SphereMesh.new()
				s.radius = 0.5
				s.height = 0.6
				tile_mesh = s
				mat.albedo_color = Color(0.35, 0.55, 0.25)
				mat.roughness = 0.5
				tile.position = Vector3(world_x, 0.3, world_z)
			elif is_water:
				type = "water"
				var b = BoxMesh.new()
				b.size = Vector3(1.0, 0.1, 1.0)
				tile_mesh = b
				mat.albedo_color = Color(0.08, 0.35, 0.65, 0.8)
				mat.roughness = 0.1
				mat.metallic = 0.5
				tile.position = Vector3(world_x, 0.05, world_z)
			else:
				var b = BoxMesh.new()
				b.size = Vector3(1.0, 0.2, 1.0)
				tile_mesh = b
				mat.albedo_color = Color(0.28, 0.50, 0.22)
				mat.roughness = 0.6
				tile.position = Vector3(world_x, 0.1, world_z)

			var inst = MeshInstance3D.new()
			inst.mesh = tile_mesh
			inst.material_override = mat
			tile.add_child(inst)

			# 3D StaticBody für Klicks
			var sb = StaticBody3D.new()
			var col = CollisionShape3D.new()
			var shape = BoxShape3D.new()
			shape.size = Vector3(1.0, 0.5, 1.0)
			col.shape = shape
			sb.add_child(col)
			sb.set_meta("grid_pos", Vector2i(x, z))
			tile.add_child(sb)

			# Initial-Städte
			var has_city = false
			if (x == 5 and z == 2) or (x == 9 and z == 5):
				has_city = true
				spawn_city(tile, "Athen" if x == 5 else "Sparta")

			tiles_data[Vector2i(x, z)] = {"type": type, "has_city": has_city}
			tile_nodes[Vector2i(x, z)] = tile
			add_child(tile)

func spawn_city(parent: Node3D, city_name: String):
	var city = Node3D.new()
	city.name = "CityNode"
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.95, 0.92, 0.85)
	mat.roughness = 0.3

	var b = BoxMesh.new()
	b.size = Vector3(0.5, 0.4, 0.5)
	var inst = MeshInstance3D.new()
	inst.mesh = b
	inst.material_override = mat
	inst.position = Vector3(0, 0.3, 0)
	city.add_child(inst)

	var lbl = Label3D.new()
	lbl.text = city_name
	lbl.pixel_size = 0.012
	lbl.position = Vector3(0, 0.65, 0)
	lbl.rotation_degrees = Vector3(-45, 0, 0)
	city.add_child(lbl)

	parent.add_child(city)

func setup_game_ui():
	ui_layer = CanvasLayer.new()
	add_child(ui_layer)

	var panel = PanelContainer.new()
	panel.anchors_preset = Control.PRESET_BOTTOM_RIGHT
	panel.offset_left = -320
	panel.offset_top = -160
	panel.offset_right = -20
	panel.offset_bottom = -20
	ui_layer.add_child(panel)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	panel.add_child(vbox)

	var info_lbl = Label.new()
	info_lbl.name = "CivInfo"
	info_lbl.text = "Runde: 1 | Gold: 100 | Forschung: 20"
	vbox.add_child(info_lbl)

	var build_btn = Button.new()
	build_btn.text = "🏛️ Stadt gründen (Kostet 50 Gold)"
	build_btn.custom_minimum_size = Vector2(0, 40)
	build_btn.pressed.connect(build_city_on_selected)
	vbox.add_child(build_btn)

	var next_turn_btn = Button.new()
	next_turn_btn.text = "⏩ Runde beenden (Next Turn)"
	next_turn_btn.custom_minimum_size = Vector2(0, 40)
	next_turn_btn.pressed.connect(next_turn)
	vbox.add_child(next_turn_btn)

func handle_tile_clicked(grid_pos: Vector2i):
	selected_tile = grid_pos
	var data = tiles_data.get(grid_pos, null)
	if data:
		emit_signal("sound_triggered", "select")
		var city_str = " (Stadt vorhanden)" if data.has_city else " (Unbesiedelt)"
		emit_signal("status_changed", "Feld (" + str(grid_pos.x) + "," + str(grid_pos.y) + ") ausgewählt [" + data.type + "]" + city_str)

func build_city_on_selected():
	if selected_tile.x < 0:
		emit_signal("status_changed", "Wähle zuerst ein Feld auf der Karte aus!")
		return
	var data = tiles_data.get(selected_tile)
	if not data or data.type == "water" or data.type == "mountain":
		emit_signal("status_changed", "Auf Wasser oder Hochgebirge kann keine Stadt gegründet werden!")
		return
	if data.has_city:
		emit_signal("status_changed", "Hier existiert bereits eine Stadt!")
		return
	if gold < 50:
		emit_signal("status_changed", "Nicht genug Gold (50 benötigt)!")
		return

	gold -= 50
	data.has_city = true
	var tile_node = tile_nodes[selected_tile]
	spawn_city(tile_node, "Polis " + str(selected_tile.x))
	emit_signal("sound_triggered", "win")
	update_ui()
	emit_signal("status_changed", "Neue Stadt 'Polis' gegründet! Gold: " + str(gold))

func next_turn():
	turn += 1
	gold += 30
	science += 15
	emit_signal("sound_triggered", "move")
	update_ui()
	emit_signal("status_changed", "Runde " + str(turn) + " hat begonnen! Erträge erhalten: +30 Gold, +15 Forschung.")

func update_ui():
	var lbl = ui_layer.get_node_or_null("PanelContainer/VBoxContainer/CivInfo") as Label
	if lbl:
		lbl.text = "Runde: " + str(turn) + " | Gold: " + str(gold) + " | Forschung: " + str(science)
