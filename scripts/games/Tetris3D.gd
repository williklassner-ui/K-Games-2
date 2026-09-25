extends Node3D

class_name Tetris3D

signal status_changed(msg: String)
signal sound_triggered(sound_name: String)

var active_block_node: Node3D = null
var current_shape_index = 0
var current_pos: Vector2i = Vector2i(0, 0)
var current_rotation = 0
var placed_blocks_root: Node3D = null
var score = 0
var ui_layer: CanvasLayer

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
	Color(0.7, 0.2, 0.9),   # Violett (T)
	Color(0.95, 0.85, 0.15),# Gelb (O)
	Color(0.15, 0.85, 0.95),# Cyan (I)
	Color(0.95, 0.55, 0.1), # Orange (L)
	Color(0.2, 0.85, 0.3)   # Grün (S)
]

func _ready():
	setup_stage()
	setup_game_ui()
	spawn_new_piece()

func setup_stage():
	# 3D Tetris Glasboden
	var floor_m = BoxMesh.new()
	floor_m.size = Vector3(8.0, 0.4, 8.0)
	var fl = MeshInstance3D.new()
	fl.mesh = floor_m
	var f_mat = StandardMaterial3D.new()
	f_mat.albedo_color = Color(0.08, 0.1, 0.15)
	fl.material_override = f_mat
	fl.position = Vector3(0, 0.15, 0)
	add_child(fl)

	# Gitter-Boden
	for x in range(-4, 5):
		for z in range(-4, 5):
			var tile = MeshInstance3D.new()
			var tm = BoxMesh.new()
			tm.size = Vector3(0.55, 0.02, 0.55)
			tile.mesh = tm
			var mat = StandardMaterial3D.new()
			mat.albedo_color = Color(0.12, 0.16, 0.22)
			tile.material_override = mat
			tile.position = Vector3(x * 0.6, 0.36, z * 0.6)
			add_child(tile)

	placed_blocks_root = Node3D.new()
	placed_blocks_root.name = "PlacedBlocks"
	add_child(placed_blocks_root)

func setup_game_ui():
	ui_layer = CanvasLayer.new()
	add_child(ui_layer)

	var panel = PanelContainer.new()
	panel.anchors_preset = Control.PRESET_BOTTOM_RIGHT
	panel.offset_left = -320
	panel.offset_top = -180
	panel.offset_right = -20
	panel.offset_bottom = -20
	ui_layer.add_child(panel)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	panel.add_child(vbox)

	var hbox_moves = HBoxContainer.new()
	hbox_moves.add_theme_constant_override("separation", 6)
	vbox.add_child(hbox_moves)

	var btn_left = Button.new()
	btn_left.text = "⬅️ Links"
	btn_left.custom_minimum_size = Vector2(90, 42)
	btn_left.pressed.connect(func(): move_block(-1, 0))
	hbox_moves.add_child(btn_left)

	var btn_rot = Button.new()
	btn_rot.text = "🔄 Drehen"
	btn_rot.custom_minimum_size = Vector2(90, 42)
	btn_rot.pressed.connect(rotate_block)
	hbox_moves.add_child(btn_rot)

	var btn_right = Button.new()
	btn_right.text = "➡️ Rechts"
	btn_right.custom_minimum_size = Vector2(90, 42)
	btn_right.pressed.connect(func(): move_block(1, 0))
	hbox_moves.add_child(btn_right)

	var btn_drop = Button.new()
	btn_drop.text = "⬇️ Festsetzen (Drop)"
	btn_drop.custom_minimum_size = Vector2(0, 44)
	btn_drop.pressed.connect(drop_block)
	vbox.add_child(btn_drop)

func spawn_new_piece():
	current_shape_index = randi() % SHAPES.size()
	current_pos = Vector2i(0, 0)
	current_rotation = 0
	render_active_piece()
	emit_signal("sound_triggered", "select")
	emit_signal("status_changed", "Tetris 3D: Bewege den Block (Links/Rechts), drehe ihn oder lasse ihn fallen! Score: " + str(score))

func render_active_piece():
	if active_block_node:
		active_block_node.queue_free()

	active_block_node = Node3D.new()
	var coords = get_current_coords()
	var col = SHAPE_COLORS[current_shape_index]

	var mat = StandardMaterial3D.new()
	mat.albedo_color = col
	mat.metallic = 0.4
	mat.roughness = 0.2
	mat.emission_enabled = true
	mat.emission = col
	mat.emission_energy_multiplier = 0.4

	for c in coords:
		var cube = MeshInstance3D.new()
		var cm = BoxMesh.new()
		cm.size = Vector3(0.55, 0.55, 0.55)
		cube.mesh = cm
		cube.material_override = mat
		cube.position = Vector3((current_pos.x + c.x) * 0.6, 0.65, (current_pos.y + c.y) * 0.6)
		active_block_node.add_child(cube)

	add_child(active_block_node)

func get_current_coords() -> Array:
	var base = SHAPES[current_shape_index]
	var res = []
	for p in base:
		var x = p.x
		var y = p.y
		for r in range(current_rotation % 4):
			var nx = -y
			var ny = x
			x = nx
			y = ny
		res.append(Vector2i(x, y))
	return res

func move_block(dx: int, dy: int):
	current_pos.x = clamp(current_pos.x + dx, -3, 3)
	current_pos.y = clamp(current_pos.y + dy, -3, 3)
	emit_signal("sound_triggered", "click")
	render_active_piece()

func rotate_block():
	current_rotation = (current_rotation + 1) % 4
	emit_signal("sound_triggered", "select")
	render_active_piece()

func drop_block():
	if not active_block_node: return
	# Festsetzen
	emit_signal("sound_triggered", "move")
	for child in active_block_node.get_children():
		child.reparent(placed_blocks_root)
		var m = child as MeshInstance3D
		if m:
			m.position.y = 0.38 # Auf Grundplatte absetzen

	active_block_node.queue_free()
	active_block_node = null
	score += 100
	emit_signal("sound_triggered", "win")
	emit_signal("status_changed", "Block platziert! +100 Punkte! Neuer Block erscheint...")
	get_tree().create_timer(0.4).timeout.connect(spawn_new_piece)
