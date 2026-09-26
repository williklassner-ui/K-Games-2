extends Node3D

class_name Chess3D

const TextureHelper = preload("res://scripts/TextureHelper.gd")

var board_root: Node3D
var pieces_root: Node3D
var highlights_root: Node3D

# Spielfeld Status 8x8
# "" leer, oder Format: "w_p", "w_r", "w_n", "w_b", "w_q", "w_k" bzw "b_..."
var grid: Array = []
var piece_nodes: Dictionary = {}
var selected_pos = null
var current_turn = "w"
var move_count = 0
var is_bot_opponent = true

# Material-Caches
var white_mat: StandardMaterial3D
var black_mat: StandardMaterial3D
var highlight_mat: StandardMaterial3D
var selected_mat: StandardMaterial3D

signal status_changed(msg: String)
signal sound_triggered(sound_name: String)

func _ready():
	init_materials()
	setup_stage()
	reset_game()

func init_materials():
	white_mat = TextureHelper.get_marble_material(Color(0.96, 0.94, 0.88))
	black_mat = TextureHelper.get_stone_material(Color(0.12, 0.14, 0.18))

	highlight_mat = StandardMaterial3D.new()
	highlight_mat.albedo_color = Color(0.15, 0.85, 0.35, 0.8)
	highlight_mat.emission_enabled = true
	highlight_mat.emission = Color(0.15, 0.85, 0.35)
	highlight_mat.emission_energy_multiplier = 0.5

	selected_mat = StandardMaterial3D.new()
	selected_mat.albedo_color = Color(0.95, 0.85, 0.15, 0.9)
	selected_mat.emission_enabled = true
	selected_mat.emission = Color(0.95, 0.85, 0.15)
	selected_mat.emission_energy_multiplier = 0.8

func setup_stage():
	board_root = Node3D.new()
	board_root.name = "BoardRoot"
	add_child(board_root)
	
	pieces_root = Node3D.new()
	pieces_root.name = "PiecesRoot"
	add_child(pieces_root)

	highlights_root = Node3D.new()
	highlights_root.name = "HighlightsRoot"
	add_child(highlights_root)

	# Edler Holz- und Marmorrahmen
	var frame_mesh = BoxMesh.new()
	frame_mesh.size = Vector3(9.4, 0.4, 9.4)
	var frame_inst = MeshInstance3D.new()
	frame_inst.mesh = frame_mesh
	frame_inst.material_override = TextureHelper.get_wood_material(Color(0.18, 0.10, 0.05))
	frame_inst.position = Vector3(0, 0.15, 0)
	board_root.add_child(frame_inst)

	# 64 3D Felder mit Marmor-/Stein-Texturen und statischen Kollisionsboxen für Touch/Klick
	for x in range(8):
		for z in range(8):
			var tile_mesh = BoxMesh.new()
			tile_mesh.size = Vector3(0.98, 0.1, 0.98)
			var tile = MeshInstance3D.new()
			tile.mesh = tile_mesh
			var is_white = (x + z) % 2 == 0
			tile.material_override = white_mat if is_white else black_mat
			tile.position = Vector3((x - 3.5), 0.4, (z - 3.5))

			# StaticBody für 3D-Picking / Raycast Klicks
			var sb = StaticBody3D.new()
			var col = CollisionShape3D.new()
			var shape = BoxShape3D.new()
			shape.size = Vector3(1.0, 0.25, 1.0)
			col.shape = shape
			sb.add_child(col)
			sb.set_meta("grid_pos", Vector2i(x, z))
			tile.add_child(sb)

			board_root.add_child(tile)

func reset_game():
	for child in pieces_root.get_children():
		child.queue_free()
	piece_nodes.clear()
	clear_highlights()
	selected_pos = null
	current_turn = "w"
	move_count = 0

	grid = []
	for x in range(8):
		var row = []
		for z in range(8):
			row.append("")
		grid.append(row)

	# Standard Schach-Aufstellung
	for x in range(8):
		set_piece(x, 6, "w_p")
		set_piece(x, 1, "b_p")

	var major = ["r", "n", "b", "q", "k", "b", "n", "r"]
	for x in range(8):
		set_piece(x, 7, "w_" + major[x])
		set_piece(x, 0, "b_" + major[x])

	emit_signal("status_changed", "Schach 3D: Weiß ist am Zug (Tippe eine Figur an)")

func set_piece(x: int, z: int, piece_code: String):
	grid[x][z] = piece_code
	if piece_code != "":
		var is_white = piece_code.begins_with("w_")
		var type = piece_code.substr(2)
		var p_node = create_piece_mesh(type, is_white)
		p_node.position = Vector3(x - 3.5, 0.5, z - 3.5)

		var sb = StaticBody3D.new()
		var col = CollisionShape3D.new()
		var shape = CylinderShape3D.new()
		shape.radius = 0.4
		shape.height = 1.3
		col.shape = shape
		sb.add_child(col)
		sb.set_meta("grid_pos", Vector2i(x, z))
		p_node.add_child(sb)

		pieces_root.add_child(p_node)
		piece_nodes[Vector2i(x, z)] = p_node

func create_piece_mesh(type: String, is_white: bool) -> Node3D:
	var piece = Node3D.new()
	var mat = white_mat if is_white else black_mat

	# Sockel
	var base_mesh = CylinderMesh.new()
	base_mesh.top_radius = 0.32
	base_mesh.bottom_radius = 0.38
	base_mesh.height = 0.15
	var base_inst = MeshInstance3D.new()
	base_inst.mesh = base_mesh
	base_inst.material_override = mat
	base_inst.position = Vector3(0, 0.08, 0)
	piece.add_child(base_inst)

	# Schaft
	var body_mesh = CylinderMesh.new()
	body_mesh.bottom_radius = 0.28
	body_mesh.top_radius = 0.18
	body_mesh.height = 0.6
	var body_inst = MeshInstance3D.new()
	body_inst.mesh = body_mesh
	body_inst.material_override = mat
	body_inst.position = Vector3(0, 0.45, 0)
	piece.add_child(body_inst)

	# Kopf
	var head_mesh: Mesh
	if type == "k":
		var k = BoxMesh.new()
		k.size = Vector3(0.25, 0.4, 0.25)
		head_mesh = k
	elif type == "q":
		var q = SphereMesh.new()
		q.radius = 0.26
		q.height = 0.45
		head_mesh = q
	elif type == "n":
		var kn = PrismMesh.new()
		kn.size = Vector3(0.35, 0.5, 0.35)
		head_mesh = kn
	elif type == "r":
		var r = CylinderMesh.new()
		r.top_radius = 0.25
		r.bottom_radius = 0.25
		r.height = 0.3
		head_mesh = r
	elif type == "b":
		var b = CylinderMesh.new()
		b.top_radius = 0.12
		b.bottom_radius = 0.24
		b.height = 0.45
		head_mesh = b
	else:
		var p = SphereMesh.new()
		p.radius = 0.2
		p.height = 0.35
		head_mesh = p

	var head_inst = MeshInstance3D.new()
	head_inst.mesh = head_mesh
	head_inst.material_override = mat
	head_inst.position = Vector3(0, 0.85, 0)
	piece.add_child(head_inst)

	return piece

func handle_tile_clicked(grid_pos: Vector2i):
	var gx = grid_pos.x
	var gz = grid_pos.y
	if gx < 0 or gx > 7 or gz < 0 or gz > 7:
		return

	var clicked_piece = grid[gx][gz]

	# Fall 1: Bereits eine Figur ausgewählt und Klick auf Ziel
	if selected_pos != null:
		if gx == selected_pos.x and gz == selected_pos.y:
			# Deselektieren
			clear_highlights()
			selected_pos = null
			emit_signal("status_changed", "Auswahl aufgehoben.")
			return

		var valid_moves = get_valid_moves(selected_pos.x, selected_pos.y)
		if grid_pos in valid_moves:
			execute_move(selected_pos, grid_pos)
			return
		elif clicked_piece.begins_with(current_turn + "_"):
			# Zu anderer eigener Figur wechseln
			select_piece(grid_pos)
			return
		else:
			emit_signal("status_changed", "Ungültiger Zug!")
			return

	# Fall 2: Noch keine Figur ausgewählt
	if clicked_piece.begins_with(current_turn + "_"):
		select_piece(grid_pos)
	elif clicked_piece != "":
		emit_signal("status_changed", "Nicht deine Farbe am Zug!")

func select_piece(pos: Vector2i):
	clear_highlights()
	selected_pos = pos
	emit_signal("sound_triggered", "select")

	# Markierung für ausgewählte Figur
	spawn_highlight(pos, selected_mat, 0.5)

	# Markierungen für mögliche Züge
	var moves = get_valid_moves(pos.x, pos.y)
	for m in moves:
		spawn_highlight(m, highlight_mat, 0.45)

	var p_name = get_piece_display_name(grid[pos.x][pos.y])
	emit_signal("status_changed", p_name + " ausgewählt (" + str(moves.size()) + " Züge möglich)")

func execute_move(from: Vector2i, to: Vector2i):
	var moving_code = grid[from.x][from.y]
	var target_code = grid[to.x][to.y]
	emit_signal("sound_triggered", "move")

	# Ziel schlagen falls vorhanden
	if target_code != "" and piece_nodes.has(to):
		var target_node = piece_nodes[to]
		target_node.queue_free()
		piece_nodes.erase(to)

	# Figur bewegen
	grid[to.x][to.y] = moving_code
	grid[from.x][from.y] = ""

	if piece_nodes.has(from):
		var node = piece_nodes[from]
		piece_nodes.erase(from)
		piece_nodes[to] = node
		var sb = node.get_node_or_null("StaticBody3D")
		if sb:
			sb.set_meta("grid_pos", to)

		# Sanfte 3D-Zug-Animation
		var tween = create_tween()
		var target_pos = Vector3(to.x - 3.5, 0.5, to.y - 3.5)
		var mid_pos = (node.position + target_pos) * 0.5 + Vector3(0, 0.6, 0)
		tween.tween_property(node, "position", mid_pos, 0.12)
		tween.tween_property(node, "position", target_pos, 0.12)

	clear_highlights()
	selected_pos = null
	move_count += 1

	# Bauern-Umwandlung (Pawn Promotion)
	if moving_code == "w_p" and to.y == 0:
		grid[to.x][to.y] = "w_q"
		if piece_nodes.has(to):
			piece_nodes[to].queue_free()
			set_piece(to.x, to.y, "w_q")
	elif moving_code == "b_p" and to.y == 7:
		grid[to.x][to.y] = "b_q"
		if piece_nodes.has(to):
			piece_nodes[to].queue_free()
			set_piece(to.x, to.y, "b_q")

	# Spielerwechsel
	current_turn = "b" if current_turn == "w" else "w"
	var turn_str = "Weiß" if current_turn == "w" else "Schwarz"
	emit_signal("status_changed", "Zug ausgeführt! " + turn_str + " ist am Zug.")

	# Wenn Schwarz am Zug ist: automatische KI-Antwort nach kurzer Bedenkzeit falls Bot aktiviert
	if current_turn == "b" and is_bot_opponent:
		get_tree().create_timer(0.6).timeout.connect(ai_make_move)

func ai_make_move():
	if current_turn != "b": return
	var all_moves = []
	for x in range(8):
		for z in range(8):
			if grid[x][z].begins_with("b_"):
				var moves = get_valid_moves(x, z)
				for m in moves:
					all_moves.append({"from": Vector2i(x, z), "to": m})

	if all_moves.is_empty():
		emit_signal("status_changed", "Schachmatt oder Patt! Weiß gewinnt!")
		return

	# Bevorzuge Schlagzüge
	var captures = []
	for move in all_moves:
		if grid[move.to.x][move.to.y].begins_with("w_"):
			captures.append(move)

	var chosen = captures.pick_random() if not captures.is_empty() else all_moves.pick_random()
	execute_move(chosen.from, chosen.to)

func get_valid_moves(x: int, z: int) -> Array:
	var moves = []
	var code = grid[x][z]
	if code == "": return moves
	var color = code.substr(0, 1)
	var type = code.substr(2)

	match type:
		"p": # Bauer
			var dir = -1 if color == "w" else 1
			var start_row = 6 if color == "w" else 1
			# 1 Schritt vor
			if is_in_bounds(x, z + dir) and grid[x][z + dir] == "":
				moves.append(Vector2i(x, z + dir))
				# 2 Schritte vom Start
				if z == start_row and grid[x][z + 2 * dir] == "":
					moves.append(Vector2i(x, z + 2 * dir))
			# Diagonal schlagen
			for dx in [-1, 1]:
				if is_in_bounds(x + dx, z + dir):
					var target = grid[x + dx][z + dir]
					if target != "" and not target.begins_with(color + "_"):
						moves.append(Vector2i(x + dx, z + dir))

		"r": # Turm
			moves.append_array(get_ray_moves(x, z, [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)], color))
		"b": # Läufer
			moves.append_array(get_ray_moves(x, z, [Vector2i(1,1), Vector2i(-1,1), Vector2i(1,-1), Vector2i(-1,-1)], color))
		"q": # Dame
			moves.append_array(get_ray_moves(x, z, [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1), Vector2i(1,1), Vector2i(-1,1), Vector2i(1,-1), Vector2i(-1,-1)], color))
		"k": # König
			for dx in [-1, 0, 1]:
				for dz in [-1, 0, 1]:
					if dx == 0 and dz == 0: continue
					if is_in_bounds(x + dx, z + dz):
						var target = grid[x + dx][z + dz]
						if target == "" or not target.begins_with(color + "_"):
							moves.append(Vector2i(x + dx, z + dz))
		"n": # Springer
			var knight_dirs = [Vector2i(1,2), Vector2i(2,1), Vector2i(-1,2), Vector2i(-2,1), Vector2i(1,-2), Vector2i(2,-1), Vector2i(-1,-2), Vector2i(-2,-1)]
			for kd in knight_dirs:
				if is_in_bounds(x + kd.x, z + kd.y):
					var target = grid[x + kd.x][z + kd.y]
					if target == "" or not target.begins_with(color + "_"):
						moves.append(Vector2i(x + kd.x, z + kd.y))

	return moves

func get_ray_moves(start_x: int, start_z: int, dirs: Array, color: String) -> Array:
	var list = []
	for d in dirs:
		var cx = start_x + d.x
		var cz = start_z + d.y
		while is_in_bounds(cx, cz):
			var target = grid[cx][cz]
			if target == "":
				list.append(Vector2i(cx, cz))
			else:
				if not target.begins_with(color + "_"):
					list.append(Vector2i(cx, cz))
				break
			cx += d.x
			cz += d.y
	return list

func is_in_bounds(x: int, z: int) -> bool:
	return x >= 0 and x < 8 and z >= 0 and z < 8

func spawn_highlight(pos: Vector2i, mat: Material, y_level: float):
	var m = BoxMesh.new()
	m.size = Vector3(0.9, 0.04, 0.9)
	var inst = MeshInstance3D.new()
	inst.mesh = m
	inst.material_override = mat
	inst.position = Vector3(pos.x - 3.5, y_level, pos.y - 3.5)
	highlights_root.add_child(inst)

func clear_highlights():
	for c in highlights_root.get_children():
		c.queue_free()

func get_piece_display_name(code: String) -> String:
	var names = {"p": "Bauer", "r": "Turm", "n": "Springer", "b": "Läufer", "q": "Dame", "k": "König"}
	var col = "Weißer " if code.begins_with("w_") else "Schwarzer "
	return col + names.get(code.substr(2), "Figur")
