extends Node3D

class_name Tetris3D

const TextureHelper = preload("res://scripts/TextureHelper.gd")

signal status_changed(msg: String)
signal sound_triggered(sound_name: String)

var active_block_node: Node3D = null
var current_shape_index: int = 0
var current_pos: Vector2i = Vector2i(0, 5) # Startet oben
var current_rotation: int = 0
var placed_blocks_root: Node3D = null
var score: int = 0
var lines_cleared: int = 0
var fall_timer: float = 0.0
var fall_interval: float = 0.8
var is_game_over: bool = false

var grid_cells: Dictionary = {} # Vector2i -> MeshInstance3D

var ui_layer: CanvasLayer = null
var game_over_modal: PanelContainer = null

const SHAPES = [
	# T
	[Vector2i(0,0), Vector2i(-1,0), Vector2i(1,0), Vector2i(0,1)],
	# O
	[Vector2i(0,0), Vector2i(1,0), Vector2i(0,1), Vector2i(1,1)],
	# I
	[Vector2i(-1,0), Vector2i(0,0), Vector2i(1,0), Vector2i(2,0)],
	# L
	[Vector2i(0,0), Vector2i(0,1), Vector2i(0,2), Vector2i(1,0)],
	# S
	[Vector2i(0,0), Vector2i(1,0), Vector2i(0,1), Vector2i(-1,1)]
]

const SHAPE_COLORS = [
	Color(0.75, 0.25, 0.95), # Violett (T)
	Color(0.95, 0.85, 0.15), # Gelb (O)
	Color(0.15, 0.85, 0.95), # Cyan (I)
	Color(0.95, 0.55, 0.1),  # Orange (L)
	Color(0.2, 0.85, 0.3)    # Grün (S)
]

func _ready():
	setup_stage()
	setup_game_ui()
	reset_game()

func _process(delta: float):
	if is_game_over: return
	fall_timer += delta
	if fall_timer >= fall_interval:
		fall_timer = 0.0
		tick_fall()

func setup_stage():
	# 3D Tetris Glasboden & Arena (10x12 Spielfeld)
	var floor_m = BoxMesh.new()
	floor_m.size = Vector3(10.0, 0.4, 12.0)
	var fl = MeshInstance3D.new()
	fl.mesh = floor_m
	fl.material_override = TextureHelper.get_metal_material(Color(0.06, 0.08, 0.12), 0.9)
	fl.position = Vector3(0, 0.15, 0)
	add_child(fl)

	# Gitter-Boden
	for x in range(-4, 5):
		for z in range(-5, 6):
			var tile = MeshInstance3D.new()
			var tm = BoxMesh.new()
			tm.size = Vector3(0.75, 0.02, 0.75)
			tile.mesh = tm
			var mat = StandardMaterial3D.new()
			mat.albedo_color = Color(0.12, 0.16, 0.22)
			tile.material_override = mat
			tile.position = Vector3(x * 0.82, 0.36, z * 0.82)
			add_child(tile)

	placed_blocks_root = Node3D.new()
	placed_blocks_root.name = "PlacedBlocks"
	add_child(placed_blocks_root)

func setup_game_ui():
	ui_layer = CanvasLayer.new()
	add_child(ui_layer)

	var panel = PanelContainer.new()
	panel.anchors_preset = Control.PRESET_BOTTOM_RIGHT
	panel.offset_left = -340
	panel.offset_top = -200
	panel.offset_right = -20
	panel.offset_bottom = -20
	ui_layer.add_child(panel)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	panel.add_child(vbox)

	var score_lbl = Label.new()
	score_lbl.name = "ScoreLabel"
	score_lbl.text = "Punkte: 0 | Reihen: 0"
	vbox.add_child(score_lbl)

	var hbox_moves = HBoxContainer.new()
	hbox_moves.add_theme_constant_override("separation", 6)
	vbox.add_child(hbox_moves)

	var btn_left = Button.new()
	btn_left.text = "⬅️ Links"
	btn_left.custom_minimum_size = Vector2(95, 44)
	btn_left.pressed.connect(func(): move_block(-1, 0))
	hbox_moves.add_child(btn_left)

	var btn_rot = Button.new()
	btn_rot.text = "🔄 Drehen"
	btn_rot.custom_minimum_size = Vector2(95, 44)
	btn_rot.pressed.connect(rotate_block)
	hbox_moves.add_child(btn_rot)

	var btn_right = Button.new()
	btn_right.text = "➡️ Rechts"
	btn_right.custom_minimum_size = Vector2(95, 44)
	btn_right.pressed.connect(func(): move_block(1, 0))
	hbox_moves.add_child(btn_right)

	var btn_drop = Button.new()
	btn_drop.text = "⬇️ Hard Drop (Sofort fallen lassen)"
	btn_drop.custom_minimum_size = Vector2(0, 44)
	btn_drop.pressed.connect(hard_drop)
	vbox.add_child(btn_drop)

	# Game Over Modal
	game_over_modal = PanelContainer.new()
	game_over_modal.anchors_preset = Control.PRESET_CENTER
	game_over_modal.offset_left = -180
	game_over_modal.offset_top = -100
	game_over_modal.offset_right = 180
	game_over_modal.offset_bottom = 100
	game_over_modal.visible = false
	ui_layer.add_child(game_over_modal)

	var go_vbox = VBoxContainer.new()
	go_vbox.add_theme_constant_override("separation", 10)
	game_over_modal.add_child(go_vbox)

	var go_title = Label.new()
	go_title.name = "GameOverTitle"
	go_title.text = "🧱 GAME OVER!"
	go_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	go_vbox.add_child(go_title)

	var go_btn = Button.new()
	go_btn.text = "🔄 Nochmal spielen"
	go_btn.custom_minimum_size = Vector2(0, 46)
	go_btn.pressed.connect(reset_game)
	go_vbox.add_child(go_btn)

func reset_game():
	score = 0
	lines_cleared = 0
	is_game_over = false
	fall_timer = 0.0
	grid_cells.clear()

	for child in placed_blocks_root.get_children():
		child.queue_free()

	if game_over_modal: game_over_modal.visible = false
	update_ui()
	spawn_new_piece()
	emit_signal("status_changed", "Tetris 3D: Automatischer Fall aktiv! Steuere mit Pfeiltasten/Buttons.")

func _unhandled_key_input(event: InputEvent):
	if is_game_over: return
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_LEFT, KEY_A: move_block(-1, 0)
			KEY_RIGHT, KEY_D: move_block(1, 0)
			KEY_UP, KEY_W: rotate_block()
			KEY_DOWN, KEY_S: tick_fall()
			KEY_SPACE: hard_drop()

func spawn_new_piece():
	current_shape_index = randi() % SHAPES.size()
	current_pos = Vector2i(0, 5) # Oben
	current_rotation = 0

	# Kollision beim Spawnen -> Game Over
	if check_collision(current_pos, current_rotation):
		is_game_over = true
		emit_signal("sound_triggered", "shoot")
		emit_signal("status_changed", "GAME OVER! Das Spielfeld ist voll! Endpunktzahl: " + str(score))
		if game_over_modal: game_over_modal.visible = true
		return

	render_active_piece()
	emit_signal("sound_triggered", "select")

func tick_fall():
	var next_pos = Vector2i(current_pos.x, current_pos.y - 1)
	if check_collision(next_pos, current_rotation):
		lock_piece()
	else:
		current_pos = next_pos
		render_active_piece()

func hard_drop():
	while not check_collision(Vector2i(current_pos.x, current_pos.y - 1), current_rotation):
		current_pos.y -= 1
	lock_piece()

func move_block(dx: int, _dy: int):
	var next_pos = Vector2i(current_pos.x + dx, current_pos.y)
	if not check_collision(next_pos, current_rotation):
		current_pos = next_pos
		emit_signal("sound_triggered", "click")
		render_active_piece()

func rotate_block():
	var next_rot = (current_rotation + 1) % 4
	if not check_collision(current_pos, next_rot):
		current_rotation = next_rot
		emit_signal("sound_triggered", "select")
		render_active_piece()

func check_collision(pos: Vector2i, rot: int) -> bool:
	var coords = get_coords(current_shape_index, rot)
	for c in coords:
		var gx = pos.x + c.x
		var gy = pos.y + c.y
		if gx < -4 or gx > 4: return true # Seitliche Wand
		if gy < -5: return true # Boden
		if grid_cells.has(Vector2i(gx, gy)): return true # Belegtes Feld
	return false

func get_coords(shape_idx: int, rot: int) -> Array:
	var base = SHAPES[shape_idx]
	var res = []
	for p in base:
		var x = p.x
		var y = p.y
		for r in range(rot % 4):
			var nx = -y
			var ny = x
			x = nx
			y = ny
		res.append(Vector2i(x, y))
	return res

func render_active_piece():
	if active_block_node: active_block_node.queue_free()
	active_block_node = Node3D.new()

	var coords = get_coords(current_shape_index, current_rotation)
	var col = SHAPE_COLORS[current_shape_index]

	var mat = StandardMaterial3D.new()
	mat.albedo_color = col
	mat.metallic = 0.5
	mat.roughness = 0.2
	mat.emission_enabled = true
	mat.emission = col
	mat.emission_energy_multiplier = 0.5

	for c in coords:
		var cube = MeshInstance3D.new()
		var cm = BoxMesh.new()
		cm.size = Vector3(0.75, 0.75, 0.75)
		cube.mesh = cm
		cube.material_override = mat
		var gx = current_pos.x + c.x
		var gy = current_pos.y + c.y
		cube.position = Vector3(gx * 0.82, 0.75, -gy * 0.82)
		active_block_node.add_child(cube)

	add_child(active_block_node)

func lock_piece():
	emit_signal("sound_triggered", "move")
	var coords = get_coords(current_shape_index, current_rotation)
	var col = SHAPE_COLORS[current_shape_index]

	for c in coords:
		var gx = current_pos.x + c.x
		var gy = current_pos.y + c.y
		var cube = MeshInstance3D.new()
		var cm = BoxMesh.new()
		cm.size = Vector3(0.75, 0.75, 0.75)
		cube.mesh = cm
		var mat = StandardMaterial3D.new()
		mat.albedo_color = col
		cube.material_override = mat
		cube.position = Vector3(gx * 0.82, 0.75, -gy * 0.82)
		placed_blocks_root.add_child(cube)
		grid_cells[Vector2i(gx, gy)] = cube

	if active_block_node:
		active_block_node.queue_free()
		active_block_node = null

	score += 40
	check_line_clears()
	spawn_new_piece()

func check_line_clears():
	var cleared = 0
	for y in range(-5, 6):
		var full_line = true
		for x in range(-4, 5):
			if not grid_cells.has(Vector2i(x, y)):
				full_line = false
				break

		if full_line:
			cleared += 1
			for x in range(-4, 5):
				var node = grid_cells[Vector2i(x, y)]
				grid_cells.erase(Vector2i(x, y))
				node.queue_free()

			# Alle Steine darüber nach unten rücken
			for above_y in range(y + 1, 6):
				for x in range(-4, 5):
					if grid_cells.has(Vector2i(x, above_y)):
						var n = grid_cells[Vector2i(x, above_y)]
						grid_cells.erase(Vector2i(x, above_y))
						grid_cells[Vector2i(x, above_y - 1)] = n
						n.position.z += 0.82

	if cleared > 0:
		lines_cleared += cleared
		score += cleared * 250
		emit_signal("sound_triggered", "win")
		emit_signal("status_changed", "🎉 " + str(cleared) + " REIHE(N) GELÖSCHT! +" + str(cleared * 250) + " Punkte!")
		update_ui()

func update_ui():
	var lbl = ui_layer.get_node_or_null("PanelContainer/VBoxContainer/ScoreLabel") as Label
	if lbl:
		lbl.text = "Punkte: " + str(score) + " | Gelöschte Reihen: " + str(lines_cleared)
