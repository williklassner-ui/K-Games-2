extends Node3D

class_name MenschAergereDichNicht3D

const TextureHelper = preload("res://scripts/TextureHelper.gd")

signal status_changed(msg: String)
signal sound_triggered(sound_name: String)

var track_positions: Array = []
var player_pawns: Array = [] # 4 Spieler-Figuren (Rot)
var pawn_track_indices: Array = [-1, -1, -1, -1] # -1 = Startbasis, 0-39 = Feld
var current_dice = 6
var ui_layer: CanvasLayer

func _ready():
	setup_stage()
	setup_game_ui()
	emit_signal("status_changed", "Mensch ärgere dich nicht: Würfle um eine Figur herauszusetzen (bei 6) oder zu bewegen!")

func setup_stage():
	# Hölzernes Spielbrett mit feiner Holzmaserung
	var board_mesh = CylinderMesh.new()
	board_mesh.top_radius = 5.2
	board_mesh.bottom_radius = 5.4
	board_mesh.height = 0.35
	var board_inst = MeshInstance3D.new()
	board_inst.mesh = board_mesh
	board_inst.material_override = TextureHelper.get_wood_material(Color(0.85, 0.76, 0.58))
	board_inst.position = Vector3(0, 0.15, 0)
	add_child(board_inst)

	# 40 Lauffelder im Kreis angeordnet
	var radius = 3.6
	track_positions.clear()
	for i in range(40):
		var angle = (float(i) / 40.0) * TAU
		var x = cos(angle) * radius
		var z = sin(angle) * radius
		var pos = Vector3(x, 0.35, z)
		track_positions.append(pos)
		
		var tile_mesh = CylinderMesh.new()
		tile_mesh.top_radius = 0.22
		tile_mesh.bottom_radius = 0.22
		tile_mesh.height = 0.05
		var tile = MeshInstance3D.new()
		tile.mesh = tile_mesh
		
		var tile_mat = StandardMaterial3D.new()
		if i % 10 == 0:
			var colors = [Color(0.85, 0.15, 0.15), Color(0.15, 0.75, 0.25), Color(0.95, 0.75, 0.1), Color(0.15, 0.45, 0.95)]
			tile_mat.albedo_color = colors[int(i / 10)]
		else:
			tile_mat.albedo_color = Color(0.98, 0.98, 0.95)
			
		tile_mat.roughness = 0.25
		tile.material_override = tile_mat
		tile.position = pos

		# StaticBody für 3D Klicks auf Felder
		var sb = StaticBody3D.new()
		var col = CollisionShape3D.new()
		var shape = BoxShape3D.new()
		shape.size = Vector3(0.5, 0.2, 0.5)
		col.shape = shape
		sb.add_child(col)
		sb.set_meta("grid_pos", Vector2i(i, 0))
		tile.add_child(sb)

		add_child(tile)

	# 4 Spielfarben-Figuren
	var colors = [
		{"col": Color(0.9, 0.12, 0.12), "base": Vector3(-3.2, 0.4, -3.2)},
		{"col": Color(0.12, 0.8, 0.25), "base": Vector3(3.2, 0.4, -3.2)},
		{"col": Color(0.95, 0.8, 0.1), "base": Vector3(3.2, 0.4, 3.2)},
		{"col": Color(0.15, 0.4, 0.95), "base": Vector3(-3.2, 0.4, 3.2)}
	]

	player_pawns.clear()
	for c_idx in range(colors.size()):
		var c = colors[c_idx]
		for f in range(4):
			var ox = (f % 2) * 0.6 - 0.3
			var oz = (int(f / 2)) * 0.6 - 0.3
			var pawn = spawn_pawn(c.base + Vector3(ox, 0, oz), c.col, c_idx == 0, f)
			if c_idx == 0:
				player_pawns.append(pawn)

func spawn_pawn(pos: Vector3, col: Color, is_player: bool = false, pawn_id: int = 0) -> Node3D:
	var pawn = Node3D.new()
	pawn.position = pos
	
	var mat = TextureHelper.get_wood_material(col)

	# Kegelkörper
	var body_mesh = CylinderMesh.new()
	body_mesh.top_radius = 0.12
	body_mesh.bottom_radius = 0.25
	body_mesh.height = 0.65
	var body = MeshInstance3D.new()
	body.mesh = body_mesh
	body.material_override = mat
	body.position = Vector3(0, 0.35, 0)
	pawn.add_child(body)

	# Kopfkugel
	var head_mesh = SphereMesh.new()
	head_mesh.radius = 0.18
	head_mesh.height = 0.36
	var head = MeshInstance3D.new()
	head.mesh = head_mesh
	head.material_override = mat
	head.position = Vector3(0, 0.78, 0)
	pawn.add_child(head)

	if is_player:
		var sb = StaticBody3D.new()
		var col_shape = CollisionShape3D.new()
		var shape = BoxShape3D.new()
		shape.size = Vector3(0.6, 1.0, 0.6)
		col_shape.shape = shape
		sb.add_child(col_shape)
		sb.set_meta("grid_pos", Vector2i(100 + pawn_id, 0))
		pawn.add_child(sb)

	add_child(pawn)
	return pawn

func setup_game_ui():
	ui_layer = CanvasLayer.new()
	add_child(ui_layer)

	var panel = PanelContainer.new()
	panel.anchors_preset = Control.PRESET_BOTTOM_RIGHT
	panel.offset_left = -300
	panel.offset_top = -140
	panel.offset_right = -20
	panel.offset_bottom = -20
	ui_layer.add_child(panel)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	panel.add_child(vbox)

	var dice_btn = Button.new()
	dice_btn.name = "DiceBtn"
	dice_btn.text = "🎲 Würfeln (Aktuell: 6)"
	dice_btn.custom_minimum_size = Vector2(0, 44)
	dice_btn.pressed.connect(roll_dice)
	vbox.add_child(dice_btn)

	var move_btn = Button.new()
	move_btn.name = "MoveBtn"
	move_btn.text = "▶️ Nächste rote Figur vorrücken"
	move_btn.custom_minimum_size = Vector2(0, 38)
	move_btn.pressed.connect(move_first_available_pawn)
	vbox.add_child(move_btn)

func roll_dice():
	current_dice = randi_range(1, 6)
	emit_signal("sound_triggered", "dice")
	var btn = ui_layer.get_node_or_null("PanelContainer/VBoxContainer/DiceBtn") as Button
	if btn:
		btn.text = "🎲 Würfeln (Aktuell: " + str(current_dice) + ")"
	emit_signal("status_changed", "Gewürfelt: " + str(current_dice) + "! Klicke auf deine Figur oder den Vorrücken-Button.")

func handle_tile_clicked(grid_pos: Vector2i):
	if grid_pos.x >= 100:
		var p_idx = grid_pos.x - 100
		move_pawn(p_idx)
	else:
		move_first_available_pawn()

func move_first_available_pawn():
	for i in range(4):
		if pawn_track_indices[i] >= 0:
			move_pawn(i)
			return
	if current_dice == 6:
		for i in range(4):
			if pawn_track_indices[i] == -1:
				move_pawn(i)
				return
	emit_signal("status_changed", "Du benötigst eine 6 zum Heraussetzen aus dem Startfeld!")

func move_pawn(pawn_idx: int):
	if pawn_idx < 0 or pawn_idx >= player_pawns.size(): return
	var pawn = player_pawns[pawn_idx]
	var cur_idx = pawn_track_indices[pawn_idx]

	if cur_idx == -1:
		if current_dice == 6:
			pawn_track_indices[pawn_idx] = 0
			var target_pos = track_positions[0] + Vector3(0, 0.4, 0)
			animate_pawn(pawn, target_pos)
			emit_signal("sound_triggered", "win")
			emit_signal("status_changed", "Figur " + str(pawn_idx + 1) + " startet auf Feld 1! Nochmal würfeln.")
		else:
			emit_signal("status_changed", "Du brauchst eine 6 um Figur " + str(pawn_idx + 1) + " herauszusetzen.")
	else:
		var next_idx = (cur_idx + current_dice) % 40
		pawn_track_indices[pawn_idx] = next_idx
		var target_pos = track_positions[next_idx] + Vector3(0, 0.4, 0)
		animate_pawn(pawn, target_pos)
		emit_signal("sound_triggered", "move")
		emit_signal("status_changed", "Figur " + str(pawn_idx + 1) + " zieht " + str(current_dice) + " Felder vor auf Position " + str(next_idx + 1) + "!")

func animate_pawn(pawn: Node3D, target_pos: Vector3):
	var tween = create_tween()
	var mid = (pawn.position + target_pos) * 0.5 + Vector3(0, 0.8, 0)
	tween.tween_property(pawn, "position", mid, 0.15)
	tween.tween_property(pawn, "position", target_pos, 0.15)
