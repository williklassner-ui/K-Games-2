extends Node3D

class_name Battleship3D

signal status_changed(msg: String)
signal sound_triggered(sound_name: String)

var ocean_root: Node3D
var grid_root: Node3D
var water_mat: StandardMaterial3D
var water_mesh_inst: MeshInstance3D

# Schiffe und Wellen-Animation
var warships: Array = []
var wave_time: float = 0.0

# 10x10 Spielfelddaten
# 0 = Wasser, 1 = Schiff, 2 = Fehlschuss, 3 = Treffer
var enemy_grid: Array = []
var player_ships_left = 5
var enemy_ships_left = 5
var total_enemy_ship_cells = 0
var enemy_hits = 0
var turn = "player" # "player" oder "ai"
var shots_fired = 0
var is_bot_opponent = true

var tile_nodes: Dictionary = {}
var ui_layer: CanvasLayer = null

func _ready():
	setup_stage()
	reset_game()
	setup_touch_ui()

func _process(delta: float):
	wave_time += delta * 2.0
	# Sanfte Wellen- und Wasserbewegung (Schimmern & Reflektion)
	if water_mat:
		var wave_offset = sin(wave_time * 0.8) * 0.02
		water_mat.uv1_offset = Vector3(wave_time * 0.02, wave_time * 0.015, 0.0)
		if water_mesh_inst:
			water_mesh_inst.position.y = 0.15 + wave_offset

	# Dynamisches sanftes Schwanken der Schiffe auf den Wellen
	for i in range(warships.size()):
		var ship = warships[i]
		if is_instance_valid(ship):
			var phase = wave_time + float(i) * 1.3
			ship.position.y = ship.get_meta("base_y", 0.45) + sin(phase) * 0.04
			ship.rotation_degrees.z = sin(phase * 1.2) * 2.5
			ship.rotation_degrees.x = cos(phase * 0.9) * 1.5

func setup_stage():
	ocean_root = Node3D.new()
	ocean_root.name = "OceanRoot"
	add_child(ocean_root)

	# 3D Wasserbecken mit animierten Wasser-Wellen
	var water_mesh = PlaneMesh.new()
	water_mesh.size = Vector2(16.0, 16.0)
	water_mesh.subdivide_width = 32
	water_mesh.subdivide_depth = 32
	
	water_mesh_inst = MeshInstance3D.new()
	water_mesh_inst.mesh = water_mesh
	
	water_mat = StandardMaterial3D.new()
	water_mat.albedo_color = Color(0.04, 0.32, 0.58, 0.9)
	water_mat.roughness = 0.06
	water_mat.metallic = 0.8
	water_mat.rim_enabled = true
	water_mat.rim = 0.5
	water_mat.clearcoat_enabled = true
	water_mat.clearcoat = 1.0
	water_mesh_inst.material_override = water_mat
	water_mesh_inst.position = Vector3(0, 0.15, 0)
	ocean_root.add_child(water_mesh_inst)

	# Becken-Rahmen (Metallische Tiefsee-Station)
	var border_mesh = BoxMesh.new()
	border_mesh.size = Vector3(16.4, 0.3, 16.4)
	var border_inst = MeshInstance3D.new()
	border_inst.mesh = border_mesh
	var border_mat = StandardMaterial3D.new()
	border_mat.albedo_color = Color(0.08, 0.1, 0.14)
	border_mat.metallic = 0.7
	border_mat.roughness = 0.3
	border_inst.material_override = border_mat
	border_inst.position = Vector3(0, -0.05, 0)
	ocean_root.add_child(border_inst)

	# 10x10 Taktisches 3D-Gitter mit leuchtenden Hologramm-Kanten
	grid_root = Node3D.new()
	grid_root.name = "GridRoot"
	add_child(grid_root)

	for x in range(10):
		for z in range(10):
			var tile_mesh = BoxMesh.new()
			tile_mesh.size = Vector3(0.85, 0.06, 0.85)
			var tile = MeshInstance3D.new()
			tile.mesh = tile_mesh
			var mat = StandardMaterial3D.new()
			mat.albedo_color = Color(0.05, 0.38, 0.58, 0.6)
			mat.roughness = 0.15
			mat.metallic = 0.5
			mat.emission_enabled = true
			mat.emission = Color(0.02, 0.18, 0.35)
			mat.emission_energy_multiplier = 0.3
			tile.material_override = mat
			tile.position = Vector3((x - 4.5) * 0.95, 0.38, (z - 4.5) * 0.95)

			# StaticBody für touch & mouse 3D picking
			var sb = StaticBody3D.new()
			var col = CollisionShape3D.new()
			var shape = BoxShape3D.new()
			shape.size = Vector3(0.9, 0.4, 0.9)
			col.shape = shape
			sb.add_child(col)
			sb.set_meta("grid_pos", Vector2i(x, z))
			tile.add_child(sb)

			grid_root.add_child(tile)
			tile_nodes[Vector2i(x, z)] = tile

	# 5 detaillierte Kriegsschiffe mit Wellen-Bobbing
	warships.clear()
	spawn_warship(Vector3(-5.2, 0.42, 0.0), 5, "Träger / Carrier", 90)
	spawn_warship(Vector3(-6.2, 0.42, -1.8), 4, "Schlachtschiff", 90)
	spawn_warship(Vector3(-6.2, 0.42, 1.8), 3, "Kreuzer", 90)
	spawn_warship(Vector3(6.2, 0.42, -1.8), 3, "U-Boot", 90)
	spawn_warship(Vector3(6.2, 0.42, 1.8), 2, "Zerstörer", 90)

func setup_touch_ui():
	ui_layer = CanvasLayer.new()
	add_child(ui_layer)

	var panel = PanelContainer.new()
	panel.anchors_preset = Control.PRESET_BOTTOM_RIGHT
	panel.offset_left = -260
	panel.offset_top = -140
	panel.offset_right = -15
	panel.offset_bottom = -75
	ui_layer.add_child(panel)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	panel.add_child(vbox)

	var fire_rnd_btn = Button.new()
	fire_rnd_btn.text = "🎯 Späher-Angriff (Zufallsziel)"
	fire_rnd_btn.custom_minimum_size = Vector2(0, 48)
	fire_rnd_btn.pressed.connect(func():
		var open_tiles = []
		for x in range(10):
			for z in range(10):
				if enemy_grid[x][z] < 2:
					open_tiles.append(Vector2i(x, z))
		if not open_tiles.is_empty():
			handle_tile_clicked(open_tiles.pick_random())
	)
	vbox.add_child(fire_rnd_btn)

func reset_game():
	enemy_grid.clear()
	for x in range(10):
		var col = []
		for z in range(10):
			col.append(0)
		enemy_grid.append(col)

	total_enemy_ship_cells = 0
	var ship_lengths = [5, 4, 3, 3, 2]
	for slen in ship_lengths:
		place_enemy_ship_random(slen)
		total_enemy_ship_cells += slen

	enemy_hits = 0
	shots_fired = 0
	turn = "player"
	emit_signal("status_changed", "Schiffe versenken 3D: Tippe/klicke auf ein Gitterfeld (10x10) zum Feuern!")

func place_enemy_ship_random(length: int):
	var placed = false
	var attempts = 0
	while not placed and attempts < 100:
		attempts += 1
		var horizontal = randf() > 0.5
		var sx = randi_range(0, 9 - (length if horizontal else 0))
		var sz = randi_range(0, 9 - (0 if horizontal else length))
		var fits = true
		for i in range(length):
			var cx = sx + (i if horizontal else 0)
			var cz = sz + (0 if horizontal else i)
			if enemy_grid[cx][cz] != 0:
				fits = false
				break
		if fits:
			for i in range(length):
				var cx = sx + (i if horizontal else 0)
				var cz = sz + (0 if horizontal else i)
				enemy_grid[cx][cz] = 1
			placed = true

func handle_tile_clicked(grid_pos: Vector2i):
	if turn != "player": return
	var gx = grid_pos.x
	var gz = grid_pos.y
	if gx < 0 or gx >= 10 or gz < 0 or gz >= 10: return

	var cell_state = enemy_grid[gx][gz]
	if cell_state >= 2:
		emit_signal("status_changed", "Dieses Feld hast du bereits beschossen!")
		return

	shots_fired += 1
	var tile = tile_nodes.get(grid_pos)
	if cell_state == 1:
		enemy_grid[gx][gz] = 3
		enemy_hits += 1
		emit_signal("sound_triggered", "shoot")
		spawn_explosion(tile.position + Vector3(0, 0.4, 0))
		spawn_hit_marker(tile, true)
		if enemy_hits >= total_enemy_ship_cells:
			emit_signal("sound_triggered", "win")
			emit_signal("status_changed", "SIEG! Alle feindlichen Kriegsschiffe versenkt in " + str(shots_fired) + " Schüssen!")
			return
		else:
			emit_signal("status_changed", "💥 TREFFER & EXPLOSION! Schiff getroffen! (" + str(enemy_hits) + "/" + str(total_enemy_ship_cells) + ")")
	else:
		enemy_grid[gx][gz] = 2
		emit_signal("sound_triggered", "move")
		spawn_splash(tile.position + Vector3(0, 0.2, 0))
		spawn_hit_marker(tile, false)
		emit_signal("status_changed", "🌊 PLUMPS! Nur Wasser bei (" + str(gx) + "," + str(gz) + "). " + ("Gegner zielt..." if is_bot_opponent else "Spieler 2 ist am Zug!"))
		if is_bot_opponent:
			turn = "ai"
			get_tree().create_timer(0.6).timeout.connect(ai_take_shot)
		else:
			turn = "player"

func ai_take_shot():
	emit_signal("sound_triggered", "shoot")
	var hit_player = (randf() > 0.6)
	turn = "player"
	if hit_player:
		if not warships.is_empty():
			var hit_ship = warships.pick_random()
			spawn_explosion(hit_ship.position + Vector3(0, 0.4, 0))
		emit_signal("status_changed", "⚠️ Feindfeuer! Ein eigenes Schiff wurde getroffen! Du bist am Zug.")
	else:
		emit_signal("status_changed", "Gegner feuert ins Wasser vorbei! Du bist am Zug.")

func spawn_explosion(pos: Vector3):
	var exp_node = Node3D.new()
	exp_node.position = pos
	add_child(exp_node)

	# Explosions-Lichtblitz
	var light = OmniLight3D.new()
	light.light_color = Color(1.0, 0.6, 0.1)
	light.light_energy = 4.0
	light.omni_range = 3.5
	exp_node.add_child(light)

	# Feurige Explosions-Kugeln
	for i in range(8):
		var p_mesh = SphereMesh.new()
		p_mesh.radius = randf_range(0.12, 0.28)
		p_mesh.height = p_mesh.radius * 2.0
		var p = MeshInstance3D.new()
		p.mesh = p_mesh
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(1.0, randf_range(0.2, 0.6), 0.05)
		mat.emission_enabled = true
		mat.emission = Color(1.0, 0.4, 0.0)
		mat.emission_energy_multiplier = 2.0
		p.material_override = mat
		p.position = Vector3(randf_range(-0.2, 0.2), randf_range(0.0, 0.3), randf_range(-0.2, 0.2))
		exp_node.add_child(p)

		var tween = create_tween()
		var target = p.position + Vector3(randf_range(-0.6, 0.6), randf_range(0.4, 1.2), randf_range(-0.6, 0.6))
		tween.tween_property(p, "position", target, 0.45)
		tween.parallel().tween_property(p, "scale", Vector3.ZERO, 0.45)

	var lt_tween = create_tween()
	lt_tween.tween_property(light, "light_energy", 0.0, 0.45)
	lt_tween.tween_callback(exp_node.queue_free)

func spawn_splash(pos: Vector3):
	var splash = Node3D.new()
	splash.position = pos
	add_child(splash)

	var ring_mesh = TorusMesh.new()
	ring_mesh.inner_radius = 0.1
	ring_mesh.outer_radius = 0.35
	var r_inst = MeshInstance3D.new()
	r_inst.mesh = ring_mesh
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.8, 0.95, 1.0, 0.8)
	mat.roughness = 0.1
	r_inst.material_override = mat
	splash.add_child(r_inst)

	var tween = create_tween()
	tween.tween_property(r_inst, "scale", Vector3(2.0, 1.0, 2.0), 0.4)
	tween.parallel().tween_property(mat, "albedo_color:a", 0.0, 0.4)
	tween.tween_callback(splash.queue_free)

func spawn_hit_marker(tile: MeshInstance3D, is_hit: bool):
	if not tile: return
	var marker = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = 0.22
	sphere.height = 0.44
	marker.mesh = sphere
	var mat = StandardMaterial3D.new()
	if is_hit:
		mat.albedo_color = Color(0.95, 0.15, 0.15)
		mat.emission_enabled = true
		mat.emission = Color(0.95, 0.15, 0.15)
		mat.emission_energy_multiplier = 1.2
	else:
		mat.albedo_color = Color(0.95, 0.95, 0.95)
		mat.roughness = 0.2
	marker.material_override = mat
	marker.position = Vector3(0, 0.25, 0)
	tile.add_child(marker)

func spawn_warship(pos: Vector3, length_cells: int, _ship_name: String, rot_deg: float = 0.0):
	var ship = Node3D.new()
	ship.position = pos
	ship.rotation_degrees = Vector3(0, rot_deg, 0)
	ship.set_meta("base_y", pos.y)
	
	# Hochwertige PBR Tarnfarben-Materialien
	var hull_mat = StandardMaterial3D.new()
	hull_mat.albedo_color = Color(0.24, 0.28, 0.35)
	hull_mat.roughness = 0.35
	hull_mat.metallic = 0.75

	var l = length_cells * 0.75
	var hull_mesh = BoxMesh.new()
	hull_mesh.size = Vector3(l, 0.32, 0.48)
	var hull_inst = MeshInstance3D.new()
	hull_inst.mesh = hull_mesh
	hull_inst.material_override = hull_mat
	hull_inst.position = Vector3(0, 0.16, 0)
	ship.add_child(hull_inst)

	# Bugspitze
	var bow_mesh = PrismMesh.new()
	bow_mesh.size = Vector3(0.48, 0.32, 0.45)
	var bow_inst = MeshInstance3D.new()
	bow_inst.mesh = bow_mesh
	bow_inst.material_override = hull_mat
	bow_inst.rotation_degrees = Vector3(0, -90, 0)
	bow_inst.position = Vector3(l * 0.5 + 0.2, 0.16, 0)
	ship.add_child(bow_inst)

	# Brücke & Aufbauten
	var deck_mesh = BoxMesh.new()
	deck_mesh.size = Vector3(l * 0.45, 0.24, 0.28)
	var deck_inst = MeshInstance3D.new()
	deck_inst.mesh = deck_mesh
	var deck_mat = StandardMaterial3D.new()
	deck_mat.albedo_color = Color(0.16, 0.2, 0.25)
	deck_mat.metallic = 0.8
	deck_inst.material_override = deck_mat
	deck_inst.position = Vector3(-0.1, 0.38, 0)
	ship.add_child(deck_inst)

	# Geschützturm
	var turret_mesh = CylinderMesh.new()
	turret_mesh.top_radius = 0.12
	turret_mesh.bottom_radius = 0.14
	turret_mesh.height = 0.15
	var turret_inst = MeshInstance3D.new()
	turret_inst.mesh = turret_mesh
	turret_inst.material_override = deck_mat
	turret_inst.position = Vector3(l * 0.25, 0.38, 0)
	ship.add_child(turret_inst)

	add_child(ship)
	warships.append(ship)
