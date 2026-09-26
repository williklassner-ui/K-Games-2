extends Node3D

class_name Civilization3D

const TextureHelper = preload("res://scripts/TextureHelper.gd")

signal status_changed(msg: String)
signal sound_triggered(sound_name: String)

# Große 24x16 Weltkarte (384 Felder)
const MAP_WIDTH = 24
const MAP_HEIGHT = 16

var gold: int = 150
var science: int = 40
var turn: int = 1
var selected_tile: Vector2i = Vector2i(10, 8)
var is_bot_opponent: bool = true

var tiles_data: Dictionary = {}
var tile_nodes: Dictionary = {}
var cities: Array = []
var units: Array = []
var ui_layer: CanvasLayer = null

func _ready():
	setup_stage()
	setup_game_ui()
	emit_signal("status_changed", "Civilization CtP2 3D: Große Weltkarte bereit! Gründe Städte, bilde Einheiten aus und forsche!")

func setup_stage():
	# Großer Kontinental-Ozean-Sockel
	var ocean_base = BoxMesh.new()
	ocean_base.size = Vector3(MAP_WIDTH * 1.15 + 1.0, 0.4, MAP_HEIGHT * 1.15 + 1.0)
	var ob_inst = MeshInstance3D.new()
	ob_inst.mesh = ocean_base
	ob_inst.material_override = TextureHelper.get_wood_material(Color(0.12, 0.08, 0.05))
	ob_inst.position = Vector3(0, -0.05, 0)
	add_child(ob_inst)

	# Prozedurale Kontinente & Gelände-Topographie generieren
	var noise = FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.frequency = 0.09
	noise.fractal_octaves = 4

	for x in range(MAP_WIDTH):
		for z in range(MAP_HEIGHT):
			var tile = Node3D.new()
			var world_x = (x - (MAP_WIDTH * 0.5 - 0.5)) * 1.15
			var world_z = (z - (MAP_HEIGHT * 0.5 - 0.5)) * 1.15

			var elev = noise.get_noise_2d(float(x) * 12.0, float(z) * 12.0)
			# Randbereiche eher Ozean
			if x <= 1 or x >= MAP_WIDTH - 2 or z <= 1 or z >= MAP_HEIGHT - 2:
				elev -= 0.35

			var type = "plains"
			var tile_mesh: Mesh
			var mat: StandardMaterial3D

			if elev < -0.15:
				type = "water"
				var b = BoxMesh.new()
				b.size = Vector3(1.1, 0.12, 1.1)
				tile_mesh = b
				mat = TextureHelper.get_water_material(Color(0.06, 0.28, 0.58, 0.85))
				tile.position = Vector3(world_x, 0.06, world_z)
			elif elev > 0.38:
				type = "mountain"
				var p = PrismMesh.new()
				p.size = Vector3(1.05, 1.4, 1.05)
				tile_mesh = p
				mat = TextureHelper.get_stone_material(Color(0.82, 0.85, 0.90))
				tile.position = Vector3(world_x, 0.7, world_z)
			elif elev > 0.18:
				type = "hill"
				var s = SphereMesh.new()
				s.radius = 0.55
				s.height = 0.65
				tile_mesh = s
				mat = TextureHelper.get_stone_material(Color(0.48, 0.52, 0.35))
				tile.position = Vector3(world_x, 0.35, world_z)
			elif elev > 0.02:
				type = "forest"
				var b = BoxMesh.new()
				b.size = Vector3(1.1, 0.25, 1.1)
				tile_mesh = b
				mat = TextureHelper.get_grass_material(Color(0.12, 0.45, 0.18))
				tile.position = Vector3(world_x, 0.12, world_z)
			else:
				type = "plains"
				var b = BoxMesh.new()
				b.size = Vector3(1.1, 0.22, 1.1)
				tile_mesh = b
				mat = TextureHelper.get_grass_material(Color(0.28, 0.62, 0.26))
				tile.position = Vector3(world_x, 0.11, world_z)

			var inst = MeshInstance3D.new()
			inst.mesh = tile_mesh
			inst.material_override = mat
			tile.add_child(inst)

			# StaticBody3D für Klicks & Touch
			var sb = StaticBody3D.new()
			var col = CollisionShape3D.new()
			var shape = BoxShape3D.new()
			shape.size = Vector3(1.15, 0.8, 1.15)
			col.shape = shape
			sb.add_child(col)
			sb.set_meta("grid_pos", Vector2i(x, z))
			tile.add_child(sb)

			tiles_data[Vector2i(x, z)] = {
				"type": type,
				"has_city": false,
				"city_name": "",
				"owner": "none",
				"improved": false
			}
			tile_nodes[Vector2i(x, z)] = tile
			add_child(tile)

	# Gründungsstädte
	spawn_city_at(Vector2i(8, 8), "Athen (Hauptstadt)", "player")
	spawn_city_at(Vector2i(16, 7), "Sparta (Sowjet/Bot)", "enemy")

	# Start-Einheiten
	spawn_unit_at(Vector2i(9, 8), "Siedler", "player")
	spawn_unit_at(Vector2i(8, 7), "Phalanx", "player")
	spawn_unit_at(Vector2i(15, 7), "Krieger", "enemy")

func spawn_city_at(pos: Vector2i, c_name: String, owner: String):
	if not tiles_data.has(pos): return
	var tile = tile_nodes[pos]
	tiles_data[pos].has_city = true
	tiles_data[pos].city_name = c_name
	tiles_data[pos].owner = owner

	var city = Node3D.new()
	city.name = "CityNode"
	var col = Color(0.95, 0.90, 0.78) if owner == "player" else Color(0.85, 0.35, 0.35)
	var mat = TextureHelper.get_stone_material(col)

	# Akropolis & Stadtmauern
	var wall = BoxMesh.new()
	wall.size = Vector3(0.65, 0.45, 0.65)
	var wall_inst = MeshInstance3D.new()
	wall_inst.mesh = wall
	wall_inst.material_override = mat
	wall_inst.position = Vector3(0, 0.35, 0)
	city.add_child(wall_inst)

	# Tempelsäulen / Turm
	var tower = CylinderMesh.new()
	tower.top_radius = 0.15
	tower.bottom_radius = 0.18
	tower.height = 0.45
	var tower_inst = MeshInstance3D.new()
	tower_inst.mesh = tower
	tower_inst.material_override = mat
	tower_inst.position = Vector3(0, 0.7, 0)
	city.add_child(tower_inst)

	var lbl = Label3D.new()
	lbl.text = "🏛️ " + c_name + " [Pop: 4]"
	lbl.pixel_size = 0.012
	lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lbl.position = Vector3(0, 1.15, 0)
	lbl.outline_size = 4
	city.add_child(lbl)

	tile.add_child(city)
	cities.append({"pos": pos, "name": c_name, "owner": owner})

func spawn_unit_at(pos: Vector2i, u_type: String, owner: String):
	if not tile_nodes.has(pos): return
	var tile = tile_nodes[pos]

	var unit_node = Node3D.new()
	unit_node.name = "Unit_" + u_type
	var col = Color(0.2, 0.55, 0.95) if owner == "player" else Color(0.9, 0.25, 0.25)
	var mat = TextureHelper.get_metal_material(col, 0.8)

	var body = MeshInstance3D.new()
	var b_mesh = CylinderMesh.new()
	b_mesh.top_radius = 0.12
	b_mesh.bottom_radius = 0.22
	b_mesh.height = 0.5
	body.mesh = b_mesh
	body.material_override = mat
	body.position = Vector3(0, 0.4, 0)
	unit_node.add_child(body)

	var icon_lbl = Label3D.new()
	var icon = "⚔️" if u_type == "Phalanx" or u_type == "Krieger" else "👥"
	icon_lbl.text = icon + " " + u_type
	icon_lbl.pixel_size = 0.011
	icon_lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	icon_lbl.position = Vector3(0, 0.85, 0)
	unit_node.add_child(icon_lbl)

	tile.add_child(unit_node)
	units.append({"pos": pos, "type": u_type, "owner": owner, "node": unit_node})

func setup_game_ui():
	ui_layer = CanvasLayer.new()
	add_child(ui_layer)

	var panel = PanelContainer.new()
	panel.anchors_preset = Control.PRESET_BOTTOM_RIGHT
	panel.offset_left = -380
	panel.offset_top = -220
	panel.offset_right = -20
	panel.offset_bottom = -20
	ui_layer.add_child(panel)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	panel.add_child(vbox)

	var info = Label.new()
	info.name = "CivInfo"
	info.text = "Runde: 1 | Gold: 150 (+25) | Forschung: 40 (+15)\nGewählt: Feld (10, 8) [Ebene]"
	vbox.add_child(info)

	var city_btn = Button.new()
	city_btn.text = "🏛️ Neue Stadt gründen (Kostet 60 Gold)"
	city_btn.custom_minimum_size = Vector2(0, 42)
	city_btn.pressed.connect(build_city)
	vbox.add_child(city_btn)

	var recruit_btn = Button.new()
	recruit_btn.text = "⚔️ Einheit ausheben: Phalanx (Kostet 40 Gold)"
	recruit_btn.custom_minimum_size = Vector2(0, 38)
	recruit_btn.pressed.connect(recruit_unit)
	vbox.add_child(recruit_btn)

	var turn_btn = Button.new()
	turn_btn.text = "⏩ Runde beenden (Next Turn)"
	turn_btn.custom_minimum_size = Vector2(0, 40)
	turn_btn.pressed.connect(next_turn)
	vbox.add_child(turn_btn)

func handle_tile_clicked(grid_pos: Vector2i):
	if not tiles_data.has(grid_pos): return
	selected_tile = grid_pos
	var data = tiles_data[grid_pos]
	emit_signal("sound_triggered", "select")

	var details = "[" + data.type.capitalize() + "]"
	if data.has_city:
		details += " | Stadt: " + data.city_name + " (" + data.owner + ")"
	
	emit_signal("status_changed", "Feld (" + str(grid_pos.x) + "," + str(grid_pos.y) + ") " + details)
	update_ui()

func build_city():
	if not tiles_data.has(selected_tile): return
	var data = tiles_data[selected_tile]
	if data.type == "water" or data.type == "mountain":
		emit_signal("status_changed", "Städte können nicht auf Wasser oder Hochgebirge gegründet werden!")
		return
	if data.has_city:
		emit_signal("status_changed", "Hier steht bereits eine Stadt!")
		return
	if gold < 60:
		emit_signal("status_changed", "Nicht genug Gold (60 benötigt)!")
		return

	gold -= 60
	var c_name = "Korinth" if cities.size() == 2 else ("Theben" if cities.size() == 3 else "Argos")
	spawn_city_at(selected_tile, c_name, "player")
	emit_signal("sound_triggered", "win")
	emit_signal("status_changed", "🏛️ STADTPOLITISCHER TRIUMPH! Neue Stadt " + c_name + " gegründet!")
	update_ui()

func recruit_unit():
	if gold < 40:
		emit_signal("status_changed", "Nicht genug Gold für Einheiten-Rekrutierung!")
		return
	gold -= 40
	spawn_unit_at(selected_tile, "Phalanx", "player")
	emit_signal("sound_triggered", "move")
	emit_signal("status_changed", "⚔️ Phalanx-Division aufgestellt!")
	update_ui()

func next_turn():
	turn += 1
	gold += 30 + cities.size() * 15
	science += 20 + cities.size() * 10
	emit_signal("sound_triggered", "click")
	emit_signal("status_changed", "Runde " + str(turn) + " beginnt! +Gold und Forschung gutgeschrieben.")

	if is_bot_opponent:
		bot_expand()
	update_ui()

func bot_expand():
	# Bot expandiert occasional
	if randf() > 0.5:
		var free_tiles = []
		for x in range(12, MAP_WIDTH - 2):
			for z in range(2, MAP_HEIGHT - 2):
				var p = Vector2i(x, z)
				if tiles_data.has(p) and not tiles_data[p].has_city and tiles_data[p].type != "water":
					free_tiles.append(p)
		if not free_tiles.is_empty():
			var p = free_tiles.pick_random()
			spawn_city_at(p, "Persien / Bot-Vorposten", "enemy")

func update_ui():
	var info = ui_layer.get_node_or_null("PanelContainer/VBoxContainer/CivInfo") as Label
	if info:
		var t_type = tiles_data[selected_tile].type if tiles_data.has(selected_tile) else "Ebene"
		info.text = "Runde: " + str(turn) + " | Gold: " + str(gold) + " | Forschung: " + str(science) + "\nGewählt: Feld (" + str(selected_tile.x) + "," + str(selected_tile.y) + ") [" + t_type + "]"
