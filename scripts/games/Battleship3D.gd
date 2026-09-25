extends Node3D

class_name Battleship3D

signal status_changed(msg: String)
signal sound_triggered(sound_name: String)

var ocean_root: Node3D
var grid_root: Node3D

# 10x10 Spielfelddaten
# 0 = Wasser, 1 = Schiff, 2 = Fehlschuss, 3 = Treffer
var enemy_grid: Array = []
var player_ships_left = 5
var enemy_ships_left = 5
var total_enemy_ship_cells = 0
var enemy_hits = 0
var turn = "player" # "player" oder "ai"
var shots_fired = 0

var tile_nodes: Dictionary = {}

func _ready():
	setup_stage()
	reset_game()

func setup_stage():
	ocean_root = Node3D.new()
	ocean_root.name = "OceanRoot"
	add_child(ocean_root)

	# 3D Wasserbecken mit Wasser-Shader PBR
	var water_mesh = BoxMesh.new()
	water_mesh.size = Vector3(14.0, 0.4, 14.0)
	var water_inst = MeshInstance3D.new()
	water_inst.mesh = water_mesh
	
	var water_mat = StandardMaterial3D.new()
	water_mat.albedo_color = Color(0.02, 0.25, 0.45, 0.85)
	water_mat.roughness = 0.08
	water_mat.metallic = 0.6
	water_inst.material_override = water_mat
	water_inst.position = Vector3(0, 0.15, 0)
	ocean_root.add_child(water_inst)

	# 10x10 Taktisches 3D-Gitter
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
			mat.albedo_color = Color(0.05, 0.35, 0.55, 0.5)
			mat.roughness = 0.2
			tile.material_override = mat
			tile.position = Vector3((x - 4.5) * 0.95, 0.38, (z - 4.5) * 0.95)

			# StaticBody für 3D-Interaktion & Picking
			var sb = StaticBody3D.new()
			var col = CollisionShape3D.new()
			var shape = BoxShape3D.new()
			shape.size = Vector3(0.9, 0.2, 0.9)
			col.shape = shape
			sb.add_child(col)
			sb.set_meta("grid_pos", Vector2i(x, z))
			tile.add_child(sb)

			grid_root.add_child(tile)
			tile_nodes[Vector2i(x, z)] = tile

	# Schiffe des Spielers in der Basis platziert
	spawn_warship(Vector3(-4.8, 0.45, 0.0), 5, "Carrier", 90)
	spawn_warship(Vector3(-5.6, 0.45, -1.0), 4, "Battleship", 90)
	spawn_warship(Vector3(-5.6, 0.45, 2.0), 3, "Cruiser", 90)
	spawn_warship(Vector3(5.6, 0.45, -1.0), 3, "Submarine", 90)
	spawn_warship(Vector3(5.6, 0.45, 2.0), 2, "Destroyer", 90)

func reset_game():
	enemy_grid.clear()
	for x in range(10):
		var col = []
		for z in range(10):
			col.append(0)
		enemy_grid.append(col)

	# Schiffe des Gegners zufällig verstecken (5 Schiffe: Längen 5, 4, 3, 3, 2)
	total_enemy_ship_cells = 0
	var ship_lengths = [5, 4, 3, 3, 2]
	for slen in ship_lengths:
		place_enemy_ship_random(slen)
		total_enemy_ship_cells += slen

	enemy_hits = 0
	shots_fired = 0
	turn = "player"
	emit_signal("status_changed", "Schiffe versenken: Wähle ein Zielkoordinaten-Feld (10x10) zum Feuern!")

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
		# Treffer!
		enemy_grid[gx][gz] = 3
		enemy_hits += 1
		emit_signal("sound_triggered", "shoot")
		spawn_hit_marker(tile, true)
		if enemy_hits >= total_enemy_ship_cells:
			emit_signal("sound_triggered", "win")
			emit_signal("status_changed", "SIEG! Alle feindlichen Kriegsschiffe versenkt in " + str(shots_fired) + " Schüssen!")
			return
		else:
			emit_signal("status_changed", "TREFFER! Feindliches Schiff getroffen! (" + str(enemy_hits) + "/" + str(total_enemy_ship_cells) + ")")
	else:
		# Wasser / Fehlschuss
		enemy_grid[gx][gz] = 2
		emit_signal("sound_triggered", "move")
		spawn_hit_marker(tile, false)
		emit_signal("status_changed", "PLUMPS! Nur Wasser getroffen bei (" + str(gx) + "," + str(gz) + "). Gegner zielt...")
		turn = "ai"
		get_tree().create_timer(0.6).timeout.connect(ai_take_shot)

func ai_take_shot():
	emit_signal("sound_triggered", "shoot")
	var hit_player = (randf() > 0.6)
	turn = "player"
	if hit_player:
		emit_signal("status_changed", "Gegner feuert: Ein eigenes Schiff wurde beschädigt! Du bist am Zug.")
	else:
		emit_signal("status_changed", "Gegner feuert ins Wasser! Du bist am Zug.")

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
		mat.emission_energy_multiplier = 0.8
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
	
	var hull_mat = StandardMaterial3D.new()
	hull_mat.albedo_color = Color(0.22, 0.26, 0.32)
	hull_mat.roughness = 0.4
	hull_mat.metallic = 0.65

	var l = length_cells * 0.75
	var hull_mesh = BoxMesh.new()
	hull_mesh.size = Vector3(l, 0.3, 0.45)
	var hull_inst = MeshInstance3D.new()
	hull_inst.mesh = hull_mesh
	hull_inst.material_override = hull_mat
	hull_inst.position = Vector3(0, 0.15, 0)
	ship.add_child(hull_inst)

	var bow_mesh = PrismMesh.new()
	bow_mesh.size = Vector3(0.45, 0.3, 0.4)
	var bow_inst = MeshInstance3D.new()
	bow_inst.mesh = bow_mesh
	bow_inst.material_override = hull_mat
	bow_inst.rotation_degrees = Vector3(0, -90, 0)
	bow_inst.position = Vector3(l * 0.5 + 0.18, 0.15, 0)
	ship.add_child(bow_inst)

	var deck_mesh = BoxMesh.new()
	deck_mesh.size = Vector3(l * 0.5, 0.22, 0.25)
	var deck_inst = MeshInstance3D.new()
	deck_inst.mesh = deck_mesh
	var deck_mat = StandardMaterial3D.new()
	deck_mat.albedo_color = Color(0.15, 0.18, 0.22)
	deck_mat.metallic = 0.7
	deck_inst.material_override = deck_mat
	deck_inst.position = Vector3(-0.1, 0.35, 0)
	ship.add_child(deck_inst)

	add_child(ship)
