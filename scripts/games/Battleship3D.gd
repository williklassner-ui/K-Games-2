extends Node3D

class_name Battleship3D

const TextureHelper = preload("res://scripts/TextureHelper.gd")

signal status_changed(msg: String)
signal sound_triggered(sound_name: String)

var ocean_root: Node3D
var grid_root: Node3D
var water_mat: StandardMaterial3D
var water_mesh_inst: MeshInstance3D

# Schiffe und Wellen-Animation
var background_warships: Array = []
var wave_time: float = 0.0

# 10x10 Spielfelddaten
# 0 = Wasser, 1 = Schiff, 2 = Fehlschuss, 3 = Treffer
var enemy_grid: Array = []
var enemy_fleet: Array = [] # Detaillierte Schiffsdaten
var player_ships_left = 5
var enemy_ships_left = 5
var total_enemy_ship_cells = 0
var enemy_hits = 0
var turn = "player" # "player" oder "ai"
var shots_fired = 0
var is_bot_opponent = true

var tile_nodes: Dictionary = {}
var sunk_ship_nodes: Array = []
var ui_layer: CanvasLayer = null
var game_over_panel: PanelContainer = null

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

	# Dynamisches sanftes Schwanken der Hintergrund-Schiffe
	for i in range(background_warships.size()):
		var ship = background_warships[i]
		if is_instance_valid(ship):
			var phase = wave_time + float(i) * 1.3
			ship.position.y = ship.get_meta("base_y", 0.45) + sin(phase) * 0.04
			ship.rotation_degrees.z = sin(phase * 1.2) * 2.5
			ship.rotation_degrees.x = cos(phase * 0.9) * 1.5

	# Leichtes Schwanken der versenkten Schiffe im Wasser
	for ship in sunk_ship_nodes:
		if is_instance_valid(ship):
			var base_y = ship.get_meta("base_y", 0.12)
			ship.position.y = base_y + sin(wave_time + float(ship.get_instance_id() % 7)) * 0.015

func setup_stage():
	ocean_root = Node3D.new()
	ocean_root.name = "OceanRoot"
	add_child(ocean_root)

	# 3D Wasserbecken mit animierten Wasser-Wellen
	var water_mesh = PlaneMesh.new()
	water_mesh.size = Vector2(22.0, 22.0)
	water_mesh.subdivide_width = 32
	water_mesh.subdivide_depth = 32
	
	water_mesh_inst = MeshInstance3D.new()
	water_mesh_inst.mesh = water_mesh
	
	water_mat = TextureHelper.get_water_material(Color(0.04, 0.32, 0.58, 0.9))
	water_mesh_inst.material_override = water_mat
	water_mesh_inst.position = Vector3(0, 0.15, 0)
	ocean_root.add_child(water_mesh_inst)

	# Becken-Rahmen (Metallische Tiefsee-Station)
	var border_mesh = BoxMesh.new()
	border_mesh.size = Vector3(22.4, 0.35, 22.4)
	var border_inst = MeshInstance3D.new()
	border_inst.mesh = border_mesh
	border_inst.material_override = TextureHelper.get_metal_material(Color(0.08, 0.1, 0.14), 0.85)
	border_inst.position = Vector3(0, -0.05, 0)
	ocean_root.add_child(border_inst)

	# 10x10 Taktisches 3D-Gitter mit leuchtenden Hologramm-Kanten
	grid_root = Node3D.new()
	grid_root.name = "GridRoot"
	add_child(grid_root)

	for x in range(10):
		for z in range(10):
			var tile_mesh = BoxMesh.new()
			tile_mesh.size = Vector3(0.92, 0.06, 0.92)
			var tile = MeshInstance3D.new()
			tile.mesh = tile_mesh
			var mat = StandardMaterial3D.new()
			mat.albedo_color = Color(0.05, 0.38, 0.58, 0.6)
			mat.roughness = 0.15
			mat.metallic = 0.5
			mat.emission_enabled = true
			mat.emission = Color(0.02, 0.18, 0.35)
			mat.emission_energy_multiplier = 0.4
			tile.material_override = mat

			# Zentriert auf dem 10x10 Spielfeld (Abstand 1.0)
			tile.position = Vector3((x - 4.5) * 1.0, 0.18, (z - 4.5) * 1.0)

			# Klickbarer StaticBody mit CollisionShape
			var sb = StaticBody3D.new()
			var col_shape = CollisionShape3D.new()
			var b_shape = BoxShape3D.new()
			b_shape.size = Vector3(0.96, 0.3, 0.96)
			col_shape.shape = b_shape
			sb.add_child(col_shape)
			sb.set_meta("grid_pos", Vector2i(x, z))
			tile.add_child(sb)

			grid_root.add_child(tile)
			tile_nodes[Vector2i(x, z)] = tile

	# Taktische Flottenkoordinaten (A-J und 1-10)
	for x in range(10):
		var lbl = Label3D.new()
		lbl.text = char(65 + x) # A, B, C...
		lbl.font_size = 28
		lbl.pixel_size = 0.012
		lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		lbl.position = Vector3((x - 4.5) * 1.0, 0.35, -5.3)
		grid_root.add_child(lbl)

	for z in range(10):
		var lbl = Label3D.new()
		lbl.text = str(z + 1) # 1, 2, 3...
		lbl.font_size = 28
		lbl.pixel_size = 0.012
		lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		lbl.position = Vector3(-5.3, 0.35, (z - 4.5) * 1.0)
		grid_root.add_child(lbl)

	# Eigene Kriegsschiffe patrouillieren im Hintergrundgewässer
	spawn_background_fleet()

func spawn_background_fleet():
	for s in background_warships:
		if is_instance_valid(s): s.queue_free()
	background_warships.clear()

	var bg_ships = [
		{"type": "carrier", "len": 5, "pos": Vector3(-8.5, 0.35, -7.5), "rot": 35.0},
		{"type": "battleship", "len": 4, "pos": Vector3(8.5, 0.35, -7.0), "rot": -40.0},
		{"type": "cruiser", "len": 3, "pos": Vector3(-8.8, 0.35, 7.0), "rot": 125.0},
		{"type": "submarine", "len": 3, "pos": Vector3(8.8, 0.28, 7.5), "rot": -135.0},
		{"type": "patrol", "len": 2, "pos": Vector3(0.0, 0.35, 8.8), "rot": 180.0}
	]
	for cfg in bg_ships:
		var ship = create_detailed_warship(cfg["type"], cfg["len"], false)
		ship.position = cfg["pos"]
		ship.rotation_degrees = Vector3(0, cfg["rot"], 0)
		ship.set_meta("base_y", cfg["pos"].y)
		ocean_root.add_child(ship)
		background_warships.append(ship)

func setup_touch_ui():
	ui_layer = CanvasLayer.new()
	add_child(ui_layer)

	var panel = PanelContainer.new()
	panel.anchors_preset = Control.PRESET_BOTTOM_RIGHT
	panel.offset_left = -300
	panel.offset_top = -150
	panel.offset_right = -15
	panel.offset_bottom = -15
	ui_layer.add_child(panel)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	panel.add_child(vbox)

	var fleet_status = Label.new()
	fleet_status.name = "FleetStatus"
	fleet_status.text = "Feindflotte: 5 Schiffe geortet"
	fleet_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(fleet_status)

	var fire_rnd_btn = Button.new()
	fire_rnd_btn.text = "🎯 Späher-Angriff (Zufallsziel)"
	fire_rnd_btn.custom_minimum_size = Vector2(0, 44)
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

	var reset_btn = Button.new()
	reset_btn.text = "🔄 Neues Spiel"
	reset_btn.custom_minimum_size = Vector2(0, 36)
	reset_btn.pressed.connect(reset_game)
	vbox.add_child(reset_btn)

	# Game Over Modal
	game_over_panel = PanelContainer.new()
	game_over_panel.anchors_preset = Control.PRESET_CENTER
	game_over_panel.offset_left = -220
	game_over_panel.offset_top = -130
	game_over_panel.offset_right = 220
	game_over_panel.offset_bottom = 130
	game_over_panel.visible = false
	ui_layer.add_child(game_over_panel)

	var go_vbox = VBoxContainer.new()
	go_vbox.add_theme_constant_override("separation", 10)
	game_over_panel.add_child(go_vbox)

	var go_title = Label.new()
	go_title.name = "GameOverTitle"
	go_title.text = "🏆 SIEG!"
	go_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	go_vbox.add_child(go_title)

	var go_stats = Label.new()
	go_stats.name = "GameOverStats"
	go_stats.text = ""
	go_stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	go_vbox.add_child(go_stats)

	var go_btn = Button.new()
	go_btn.text = "🔄 Nochmal spielen"
	go_btn.custom_minimum_size = Vector2(0, 48)
	go_btn.pressed.connect(reset_game)
	go_vbox.add_child(go_btn)

func reset_game():
	enemy_grid.clear()
	for x in range(10):
		var col = []
		for z in range(10):
			col.append(0)
		enemy_grid.append(col)

	# Versenkte Schiffe auf dem Spielfeld aufräumen
	for node in sunk_ship_nodes:
		if is_instance_valid(node): node.queue_free()
	sunk_ship_nodes.clear()

	# 5 offizielle Schiffe mit genauen Typen und Längen
	var fleet_types = [
		{"type": "carrier", "name": "Flugzeugträger", "length": 5},
		{"type": "battleship", "name": "Schlachtschiff", "length": 4},
		{"type": "cruiser", "name": "Schwerer Kreuzer", "length": 3},
		{"type": "submarine", "name": "U-Boot", "length": 3},
		{"type": "patrol", "name": "Schnellboot", "length": 2}
	]

	enemy_fleet.clear()
	for s_def in fleet_types:
		var placed = false
		var safety = 0
		while not placed and safety < 500:
			safety += 1
			placed = place_fleet_ship(s_def)

	# Zähle die exakt platzierten Schiffsfelder auf dem Gitter
	total_enemy_ship_cells = 0
	for x in range(10):
		for z in range(10):
			if enemy_grid[x][z] == 1:
				total_enemy_ship_cells += 1

	enemy_hits = 0
	shots_fired = 0
	player_ships_left = 5
	enemy_ships_left = 5
	turn = "player"
	if game_over_panel:
		game_over_panel.visible = false

	# Vorherige Treffermarkierungen auf den Kacheln entfernen
	for tile in tile_nodes.values():
		for child in tile.get_children():
			if child is MeshInstance3D and child.name.begins_with("Marker"):
				child.queue_free()

	update_fleet_status_label()
	emit_signal("status_changed", "Schiffe versenken 3D: Bereit! 5 feindliche Kriegsschiffe (" + str(total_enemy_ship_cells) + " Segmente) geortet. Tippe zum Feuern!")

func update_fleet_status_label():
	if ui_layer:
		var lbl = ui_layer.find_child("FleetStatus", true, false) as Label
		if lbl:
			lbl.text = "Feindliche Flotte: " + str(enemy_ships_left) + "/5 Schiffe übrig"

func place_fleet_ship(s_def: Dictionary) -> bool:
	var length = s_def["length"]
	var horizontal = randf() > 0.5
	var sx = randi_range(0, 9 - (length if horizontal else 0))
	var sz = randi_range(0, 9 - (0 if horizontal else length))
	
	for i in range(length):
		var cx = sx + (i if horizontal else 0)
		var cz = sz + (0 if horizontal else i)
		if enemy_grid[cx][cz] != 0:
			return false

	var cells = []
	for i in range(length):
		var cx = sx + (i if horizontal else 0)
		var cz = sz + (0 if horizontal else i)
		enemy_grid[cx][cz] = 1
		cells.append(Vector2i(cx, cz))

	enemy_fleet.append({
		"type": s_def["type"],
		"name": s_def["name"],
		"length": length,
		"cells": cells,
		"hits": 0,
		"sunk": false,
		"horizontal": horizontal
	})
	return true

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

		# Prüfen, welches Schiff getroffen wurde und ob es versenkt ist
		var hit_ship = null
		for ship in enemy_fleet:
			if grid_pos in ship["cells"]:
				hit_ship = ship
				ship["hits"] += 1
				if ship["hits"] >= ship["length"] and not ship["sunk"]:
					ship["sunk"] = true
					enemy_ships_left -= 1
					update_fleet_status_label()
					# DAS VERSENKTE KRIEGSSCHIFF DIREKT AUF DEM FELD ANZEIGEN!
					reveal_sunk_ship_on_grid(ship)
				break

		if enemy_hits >= total_enemy_ship_cells:
			show_game_over(true)
			return
		else:
			if hit_ship and hit_ship["sunk"]:
				emit_signal("status_changed", "🔥💥 VERSENKT! Du hast das " + hit_ship["name"] + " (" + str(hit_ship["length"]) + " Felder) versenkt! Noch " + str(enemy_ships_left) + " Schiffe.")
			else:
				emit_signal("status_changed", "💥 TREFFER! Schiff getroffen! (" + str(enemy_hits) + "/" + str(total_enemy_ship_cells) + ")")
	else:
		enemy_grid[gx][gz] = 2
		emit_signal("sound_triggered", "splash")
		spawn_splash(tile.position + Vector3(0, 0.2, 0))
		spawn_hit_marker(tile, false)
		emit_signal("status_changed", "🌊 PLUMPS! Nur Wasser bei (" + str(gx) + "," + str(gz) + "). " + ("Gegner zielt..." if is_bot_opponent else "Spieler 2 ist am Zug!"))
		if is_bot_opponent:
			turn = "ai"
			get_tree().create_timer(0.6).timeout.connect(ai_take_shot)
		else:
			turn = "player"

func reveal_sunk_ship_on_grid(ship: Dictionary):
	# Berechne den Mittelpunkt aller Felder dieses Schiffs auf dem 3D-Gitter
	var cells = ship["cells"]
	var p_sum = Vector3.ZERO
	for cell in cells:
		var tile = tile_nodes[cell]
		p_sum += tile.position
	var center_pos = p_sum / float(cells.size())
	center_pos.y = 0.28 # Direkt über den Kacheln im Wasser liegend

	var rot_y = 0.0 if ship["horizontal"] else 90.0
	var warship_model = create_detailed_warship(ship["type"], ship["length"], true)
	warship_model.position = center_pos
	warship_model.rotation_degrees = Vector3(3.0, rot_y, 6.0) # Leicht schlagseitig gekrängt im Wasser
	warship_model.set_meta("base_y", center_pos.y)
	grid_root.add_child(warship_model)
	sunk_ship_nodes.append(warship_model)

	# Aufsteigende Feuer- & Rauchwolke über dem Wrack
	spawn_sunk_smoke(center_pos + Vector3(0, 0.35, 0))

	# 3D-Schriftzug über dem versenkten Schiff
	var label = Label3D.new()
	label.text = "🔥 " + ship["name"] + " (Versenkt!)"
	label.font_size = 24
	label.pixel_size = 0.012
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.position = center_pos + Vector3(0, 1.1, 0)
	label.outline_size = 4
	label.modulate = Color(1.0, 0.35, 0.1)
	grid_root.add_child(label)
	sunk_ship_nodes.append(label)

func spawn_sunk_smoke(pos: Vector3):
	var smoke_node = Node3D.new()
	smoke_node.position = pos
	grid_root.add_child(smoke_node)
	sunk_ship_nodes.append(smoke_node)

	# Dauerhafte Rauchsäule mit kleinen Partikel-Sphären
	for i in range(12):
		var p = MeshInstance3D.new()
		var sm = SphereMesh.new()
		sm.radius = randf_range(0.12, 0.25)
		sm.height = sm.radius * 2.0
		p.mesh = sm
		var smat = StandardMaterial3D.new()
		smat.albedo_color = Color(0.15, 0.15, 0.15, 0.8)
		smat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		p.material_override = smat
		p.position = Vector3(randf_range(-0.25, 0.25), float(i) * 0.12, randf_range(-0.25, 0.25))
		smoke_node.add_child(p)

		var tw = create_tween().set_loops()
		tw.tween_property(p, "position:y", p.position.y + 0.6, randf_range(1.0, 1.8))
		tw.parallel().tween_property(smat, "albedo_color:a", 0.1, randf_range(1.0, 1.8))

func show_game_over(won: bool):
	turn = "game_over"
	if game_over_panel:
		game_over_panel.visible = true
		var t_lbl = game_over_panel.find_child("GameOverTitle", true, false) as Label
		var s_lbl = game_over_panel.find_child("GameOverStats", true, false) as Label
		if won:
			emit_signal("sound_triggered", "win")
			var acc = int((float(enemy_hits) / float(max(1, shots_fired))) * 100.0)
			if t_lbl: t_lbl.text = "🏆 GLORREICHER SIEG!"
			if s_lbl: s_lbl.text = "Alle 5 feindlichen Kriegsschiffe versenkt!\n• Abgefeuerte Schüsse: " + str(shots_fired) + "\n• Trefferquote: " + str(acc) + "%\n• Eigene Schiffe intakt: " + str(player_ships_left) + "/5"
			emit_signal("status_changed", "SIEG! Alle Schiffe versenkt in " + str(shots_fired) + " Schüssen!")
		else:
			emit_signal("sound_triggered", "loss")
			if t_lbl: t_lbl.text = "💀 FLOTTE VERSENKT - NIEDERLAGE!"
			if s_lbl: s_lbl.text = "Deine Kriegsschiffe wurden vernichtet!\n• Feindliche Schiffe getroffen: " + str(enemy_hits) + "/" + str(total_enemy_ship_cells)
			emit_signal("status_changed", "NIEDERLAGE! Deine Flotte wurde versenkt!")

func ai_take_shot():
	if turn != "ai": return
	var hit_player = (randf() > 0.6)
	if hit_player:
		emit_signal("sound_triggered", "shoot")
		player_ships_left -= 1
		if not background_warships.is_empty():
			var hit_ship = background_warships.pick_random()
			spawn_explosion(hit_ship.position + Vector3(0, 0.4, 0))
		if player_ships_left <= 0:
			show_game_over(false)
			return
		emit_signal("status_changed", "⚠️ Feindfeuer! Ein eigenes Schiff versenkt (" + str(player_ships_left) + " übrig)! Du bist am Zug.")
	else:
		emit_signal("sound_triggered", "splash")
		emit_signal("status_changed", "Gegner feuert ins Wasser vorbei! Du bist am Zug.")
	turn = "player"

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
		mat.emission = Color(1.0, randf_range(0.3, 0.7), 0.1)
		mat.emission_energy_multiplier = 2.0
		p.material_override = mat
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

# -------------------------------------------------------------
# Detaillierte Kriegsschiff-Modelle mit echten Marine-Texturen
# -------------------------------------------------------------
func create_detailed_warship(type: String, length_cells: int, is_damaged: bool = false) -> Node3D:
	var ship = Node3D.new()
	var total_len = length_cells * 0.95

	# Militärische PBR-Materialien
	var hull_color = Color(0.18, 0.2, 0.24) if is_damaged else Color(0.28, 0.32, 0.38) # Marine-Grau
	var hull_mat = TextureHelper.get_metal_material(hull_color, 0.82)
	var deck_color = Color(0.15, 0.16, 0.18) if is_damaged else Color(0.22, 0.24, 0.28) # Teak-/Stahldeck
	var deck_mat = TextureHelper.get_metal_material(deck_color, 0.88)
	var water_line_mat = TextureHelper.get_metal_material(Color(0.52, 0.12, 0.12), 0.75) # Antifouling-Rot
	var turret_mat = TextureHelper.get_metal_material(Color(0.16, 0.18, 0.22), 0.9)
	var barrel_mat = TextureHelper.get_metal_material(Color(0.1, 0.12, 0.14), 0.95)

	# 1. Wasserlinien-Rumpf (Rot)
	var keel = MeshInstance3D.new()
	var km = BoxMesh.new()
	km.size = Vector3(total_len * 0.92, 0.08, 0.44)
	keel.mesh = km
	keel.material_override = water_line_mat
	keel.position = Vector3(0, -0.04, 0)
	ship.add_child(keel)

	# 2. Haupt-Rumpf (Panzerstahl grau mit abgeschrägter Panzerung)
	var hull = MeshInstance3D.new()
	var hm = BoxMesh.new()
	hm.size = Vector3(total_len * 0.88, 0.24, 0.48)
	hull.mesh = hm
	hull.material_override = hull_mat
	hull.position = Vector3(-total_len * 0.04, 0.12, 0)
	ship.add_child(hull)

	# 3. Schnittiger Bug (Spitz zulaufend wie echtes Kriegsschiff)
	var bow = MeshInstance3D.new()
	var bm = PrismMesh.new()
	bm.size = Vector3(0.48, 0.24, total_len * 0.22)
	bow.mesh = bm
	bow.material_override = hull_mat
	bow.rotation_degrees = Vector3(0, -90, 0)
	bow.position = Vector3(total_len * 0.44, 0.12, 0)
	ship.add_child(bow)

	# 4. Schiffs-Spezifische Aufbauten und Details
	match type:
		"carrier": # Flugzeugträger (5 Zellen): Großes Flugdeck, Träger-Insel, Flugzeuge
			var deck = MeshInstance3D.new()
			var dm = BoxMesh.new()
			dm.size = Vector3(total_len * 0.98, 0.06, 0.78)
			deck.mesh = dm
			deck.material_override = deck_mat
			deck.position = Vector3(0, 0.26, 0)
			ship.add_child(deck)

			# Startbahn-Markierung (weiße Centerline)
			var runway = MeshInstance3D.new()
			var rm = BoxMesh.new()
			rm.size = Vector3(total_len * 0.85, 0.01, 0.05)
			runway.mesh = rm
			var rmat = StandardMaterial3D.new()
			rmat.albedo_color = Color(0.95, 0.95, 0.95)
			runway.material_override = rmat
			runway.position = Vector3(0, 0.30, -0.08)
			ship.add_child(runway)

			# Starboard Kommandobrücke / Insel
			var island = MeshInstance3D.new()
			var im = BoxMesh.new()
			im.size = Vector3(0.65, 0.38, 0.16)
			island.mesh = im
			island.material_override = hull_mat
			island.position = Vector3(0.2, 0.46, 0.28)
			ship.add_child(island)

			# Radarmast
			var mast = MeshInstance3D.new()
			var mm = CylinderMesh.new()
			mm.top_radius = 0.02
			mm.bottom_radius = 0.03
			mm.height = 0.4
			mast.mesh = mm
			mast.material_override = barrel_mat
			mast.position = Vector3(0.2, 0.75, 0.28)
			ship.add_child(mast)

			# 2 geparkte Kampfflugzeuge auf Deck
			for f_i in range(2):
				var plane = Node3D.new()
				plane.position = Vector3(-total_len * 0.25 + float(f_i) * 0.55, 0.32, 0.18)
				var p_body = MeshInstance3D.new()
				var pbm = BoxMesh.new()
				pbm.size = Vector3(0.3, 0.04, 0.08)
				p_body.mesh = pbm
				p_body.material_override = barrel_mat
				plane.add_child(p_body)

				var p_wings = MeshInstance3D.new()
				var pwm = BoxMesh.new()
				pwm.size = Vector3(0.12, 0.01, 0.26)
				p_wings.mesh = pwm
				p_wings.material_override = barrel_mat
				plane.add_child(p_wings)
				ship.add_child(plane)

		"battleship": # Schlachtschiff (4 Zellen): 3 schwere Dreifachtürme, Kommandoturm, Zwillingstürme
			# Panzeraufbau
			var superstr = MeshInstance3D.new()
			var ssm = BoxMesh.new()
			ssm.size = Vector3(total_len * 0.45, 0.26, 0.32)
			superstr.mesh = ssm
			superstr.material_override = hull_mat
			superstr.position = Vector3(0, 0.32, 0)
			ship.add_child(superstr)

			# Pagoden-Brückenturm
			var tower = MeshInstance3D.new()
			var tm = BoxMesh.new()
			tm.size = Vector3(0.35, 0.42, 0.24)
			tower.mesh = tm
			tower.material_override = deck_mat
			tower.position = Vector3(0.25, 0.55, 0)
			ship.add_child(tower)

			# 2 Schornsteine mit Rußkappen
			for fn in [-0.15, -0.4]:
				var funnel = MeshInstance3D.new()
				var fm = CylinderMesh.new()
				fm.top_radius = 0.06
				fm.bottom_radius = 0.08
				fm.height = 0.32
				funnel.mesh = fm
				funnel.material_override = barrel_mat
				funnel.rotation_degrees = Vector3(0, 0, -10)
				funnel.position = Vector3(fn, 0.52, 0)
				ship.add_child(funnel)

			# 3 schwere Hauptgeschütztürme (2 vorn superfiring, 1 achtern)
			add_battleship_turret(ship, Vector3(total_len * 0.28, 0.28, 0), turret_mat, barrel_mat, 0.0, 3)
			add_battleship_turret(ship, Vector3(total_len * 0.12, 0.36, 0), turret_mat, barrel_mat, 0.0, 3) # Überhöhter Turm Bruno
			add_battleship_turret(ship, Vector3(-total_len * 0.32, 0.28, 0), turret_mat, barrel_mat, 180.0, 3) # Achterturm Cäsar

		"cruiser": # Schwerer Kreuzer (3 Zellen): 2 Doppeltürme, schlanke Silhouette, Torpedos
			var bridge = MeshInstance3D.new()
			var brm = BoxMesh.new()
			brm.size = Vector3(0.55, 0.3, 0.26)
			bridge.mesh = brm
			bridge.material_override = hull_mat
			bridge.position = Vector3(0.05, 0.34, 0)
			ship.add_child(bridge)

			var funnel = MeshInstance3D.new()
			var fm = CylinderMesh.new()
			fm.top_radius = 0.05
			fm.bottom_radius = 0.07
			fm.height = 0.28
			funnel.mesh = fm
			funnel.material_override = barrel_mat
			funnel.position = Vector3(-0.25, 0.42, 0)
			ship.add_child(funnel)

			add_battleship_turret(ship, Vector3(total_len * 0.3, 0.28, 0), turret_mat, barrel_mat, 0.0, 2)
			add_battleship_turret(ship, Vector3(-total_len * 0.32, 0.28, 0), turret_mat, barrel_mat, 180.0, 2)

		"submarine": # U-Boot (3 Zellen): Zylindrischer Druckkörper, Turm mit Periskop, Deckgeschütz
			var sub_cyl = MeshInstance3D.new()
			var scm = CylinderMesh.new()
			scm.top_radius = 0.18
			scm.bottom_radius = 0.18
			scm.height = total_len * 0.85
			sub_cyl.mesh = scm
			sub_cyl.material_override = hull_mat
			sub_cyl.rotation_degrees = Vector3(0, 0, 90)
			sub_cyl.position = Vector3(0, 0.12, 0)
			ship.add_child(sub_cyl)

			# Turm (Conning Tower)
			var conning = MeshInstance3D.new()
			var cm = BoxMesh.new()
			cm.size = Vector3(0.42, 0.28, 0.14)
			conning.mesh = cm
			conning.material_override = deck_mat
			conning.position = Vector3(0.1, 0.34, 0)
			ship.add_child(conning)

			# Periskop
			var peri = MeshInstance3D.new()
			var pm = CylinderMesh.new()
			pm.top_radius = 0.015
			pm.bottom_radius = 0.015
			pm.height = 0.22
			peri.mesh = pm
			peri.material_override = barrel_mat
			peri.position = Vector3(0.15, 0.54, 0)
			ship.add_child(peri)

			# Deckgeschütz
			var d_gun = MeshInstance3D.new()
			var dgm = CylinderMesh.new()
			dgm.top_radius = 0.02
			dgm.bottom_radius = 0.02
			dgm.height = 0.2
			d_gun.mesh = dgm
			d_gun.material_override = barrel_mat
			d_gun.rotation_degrees = Vector3(0, 0, 75)
			d_gun.position = Vector3(0.5, 0.28, 0)
			ship.add_child(d_gun)

		"patrol": # Schnellboot (2 Zellen): Wendiger Keilrumpf, Schnellfeuerkanone, Radom
			var wheelhouse = MeshInstance3D.new()
			var whm = BoxMesh.new()
			whm.size = Vector3(0.45, 0.22, 0.24)
			wheelhouse.mesh = whm
			wheelhouse.material_override = hull_mat
			wheelhouse.position = Vector3(-0.05, 0.3, 0)
			ship.add_child(wheelhouse)

			var radome = MeshInstance3D.new()
			var rdm = SphereMesh.new()
			rdm.radius = 0.08
			rdm.height = 0.16
			radome.mesh = rdm
			var w_mat = StandardMaterial3D.new()
			w_mat.albedo_color = Color(0.9, 0.9, 0.9)
			radome.material_override = w_mat
			radome.position = Vector3(-0.1, 0.46, 0)
			ship.add_child(radome)

			add_battleship_turret(ship, Vector3(total_len * 0.25, 0.25, 0), turret_mat, barrel_mat, 0.0, 1)

	return ship

func add_battleship_turret(parent: Node3D, pos: Vector3, t_mat: Material, b_mat: Material, rot_deg: float, barrels_count: int):
	var turret = Node3D.new()
	turret.position = pos
	turret.rotation_degrees = Vector3(0, rot_deg, 0)

	var house = MeshInstance3D.new()
	var hm = BoxMesh.new()
	hm.size = Vector3(0.28, 0.14, 0.24)
	house.mesh = hm
	house.material_override = t_mat
	turret.add_child(house)

	# Rohre
	var spacing = 0.07
	var start_z = -float(barrels_count - 1) * 0.5 * spacing
	for b in range(barrels_count):
		var barrel = MeshInstance3D.new()
		var bm = CylinderMesh.new()
		bm.top_radius = 0.016
		bm.bottom_radius = 0.022
		bm.height = 0.36
		barrel.mesh = bm
		barrel.material_override = b_mat
		barrel.rotation_degrees = Vector3(0, 0, 90)
		barrel.position = Vector3(0.24, 0.02, start_z + float(b) * spacing)
		turret.add_child(barrel)

	parent.add_child(turret)
