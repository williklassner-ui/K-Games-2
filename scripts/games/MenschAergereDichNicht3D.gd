extends Node3D

class_name MenschAergereDichNicht3D

const TextureHelper = preload("res://scripts/TextureHelper.gd")
const DiceHelper = preload("res://scripts/DiceHelper.gd")

signal status_changed(msg: String)
signal sound_triggered(sound_name: String)

# Original Kreuz-Spielfeld: 40 Lauffelder im Kreuz
# 4 Spielerfarben: 0 = Rot (Spieler), 1 = Blau (Bot), 2 = Grün (Bot), 3 = Gelb (Bot)
var track_coords: Array = []
var home_coords: Array = [[], [], [], []]
var base_coords: Array = [[], [], [], []]

# Pawns: 4 Figuren pro Farbe
var pawn_nodes: Array = [[], [], [], []]
# -1 = In Basis, 0-39 = Auf Laufstrecke, 100-103 = Im Zielfeld (Haus)
var pawn_positions: Array = [
	[-1, -1, -1, -1],
	[-1, -1, -1, -1],
	[-1, -1, -1, -1],
	[-1, -1, -1, -1]
]

var active_player: int = 0 # 0=Rot, 1=Blau, 2=Grün, 3=Gelb
var is_bot_opponent: bool = true
var current_dice_val: int = 6
var dice_3d_node: Node3D = null
var is_rolling: bool = false
var attempts_left: int = 3

var ui_layer: CanvasLayer = null
var victory_modal: PanelContainer = null

const COLOR_DEFS = [
	{"name": "Rot", "col": Color(0.92, 0.15, 0.15), "start_idx": 0},
	{"name": "Blau", "col": Color(0.18, 0.45, 0.95), "start_idx": 10},
	{"name": "Grün", "col": Color(0.15, 0.78, 0.25), "start_idx": 20},
	{"name": "Gelb", "col": Color(0.95, 0.85, 0.15), "start_idx": 30}
]

func _ready():
	setup_stage()
	setup_game_ui()
	reset_game()

func setup_stage():
	# 1. Großes Holzbrett (22x22 Einheiten im Original-Design)
	var board_mesh = BoxMesh.new()
	board_mesh.size = Vector3(22.0, 0.5, 22.0)
	var board_inst = MeshInstance3D.new()
	board_inst.mesh = board_mesh
	board_inst.material_override = TextureHelper.get_wood_material(Color(0.88, 0.78, 0.62))
	board_inst.position = Vector3(0, 0.2, 0)
	add_child(board_inst)

	# 2. Die 40 Kreuz-Felder (11x11 Rasterpunkte)
	# Koordinaten im Kreuz-Uhrzeigersinn:
	# Start Rot bei (-1, 5) -> geht nach oben bis (-1, 1), dann nach links (-5, 1) usw.
	var raw_track_grid = [
		Vector2i(-1, 5), Vector2i(-1, 4), Vector2i(-1, 3), Vector2i(-1, 2), Vector2i(-1, 1),
		Vector2i(-2, 1), Vector2i(-3, 1), Vector2i(-4, 1), Vector2i(-5, 1), Vector2i(-5, 0),
		Vector2i(-5, -1), Vector2i(-4, -1), Vector2i(-3, -1), Vector2i(-2, -1), Vector2i(-1, -1),
		Vector2i(-1, -2), Vector2i(-1, -3), Vector2i(-1, -4), Vector2i(-1, -5), Vector2i(0, -5),
		Vector2i(1, -5), Vector2i(1, -4), Vector2i(1, -3), Vector2i(1, -2), Vector2i(1, -1),
		Vector2i(2, -1), Vector2i(3, -1), Vector2i(4, -1), Vector2i(5, -1), Vector2i(5, 0),
		Vector2i(5, 1), Vector2i(4, 1), Vector2i(3, 1), Vector2i(2, 1), Vector2i(1, 1),
		Vector2i(1, 2), Vector2i(1, 3), Vector2i(1, 4), Vector2i(1, 5), Vector2i(0, 5)
	]

	track_coords.clear()
	for i in range(40):
		var gp = raw_track_grid[i]
		var pos = Vector3(gp.x * 1.6, 0.46, gp.y * 1.6)
		track_coords.append(pos)

		var tile = MeshInstance3D.new()
		var tm = CylinderMesh.new()
		tm.top_radius = 0.52
		tm.bottom_radius = 0.55
		tm.height = 0.08
		tile.mesh = tm

		# Startfelder in Spielerfarbe, sonst weißes Spielfeld
		var t_col = Color(0.96, 0.96, 0.92)
		if i == 0: t_col = COLOR_DEFS[0].col
		elif i == 10: t_col = COLOR_DEFS[1].col
		elif i == 20: t_col = COLOR_DEFS[2].col
		elif i == 30: t_col = COLOR_DEFS[3].col

		tile.material_override = TextureHelper.get_marble_material(t_col)
		tile.position = pos
		add_child(tile)

		# Klickbarer StaticBody
		var sb = StaticBody3D.new()
		var col = CollisionShape3D.new()
		var cs = CylinderShape3D.new()
		cs.radius = 0.58
		cs.height = 0.5
		col.shape = cs
		sb.add_child(col)
		sb.set_meta("grid_pos", Vector2i(i, 0))
		tile.add_child(sb)

	# 3. Vier Zielstrecken (je 4 Zielfelder pro Farbe im Zentrum)
	home_coords = [[], [], [], []]
	for step in range(4):
		home_coords[0].append(Vector3(0, 0.46, (4 - step) * 1.6))    # Rot (Süden nach Nord)
		home_coords[1].append(Vector3((-4 + step) * 1.6, 0.46, 0))   # Blau (Westen nach Ost)
		home_coords[2].append(Vector3(0, 0.46, (-4 + step) * 1.6))   # Grün (Norden nach Süd)
		home_coords[3].append(Vector3((4 - step) * 1.6, 0.46, 0))    # Gelb (Osten nach West)

	for p in range(4):
		for h in range(4):
			var tile = MeshInstance3D.new()
			var tm = CylinderMesh.new()
			tm.top_radius = 0.45
			tm.bottom_radius = 0.48
			tm.height = 0.08
			tile.mesh = tm
			tile.material_override = TextureHelper.get_marble_material(COLOR_DEFS[p].col)
			tile.position = home_coords[p][h]
			add_child(tile)

	# 4. Vier Basen / Start-Häuschen in den 4 Ecken
	base_coords = [[], [], [], []]
	var corner_offsets = [
		Vector2i(-4, 4),  # Rot (Süd-West)
		Vector2i(-4, -4), # Blau (Nord-West)
		Vector2i(4, -4),  # Grün (Nord-Ost)
		Vector2i(4, 4)    # Gelb (Süd-Ost)
	]
	for p in range(4):
		var co = corner_offsets[p]
		for f in range(4):
			var ox = (f % 2) - 0.5
			var oz = (f / 2) - 0.5
			var b_pos = Vector3((co.x + ox) * 1.6, 0.46, (co.y + oz) * 1.6)
			base_coords[p].append(b_pos)

			var tile = MeshInstance3D.new()
			var tm = CylinderMesh.new()
			tm.top_radius = 0.48
			tm.bottom_radius = 0.5
			tm.height = 0.08
			tile.mesh = tm
			tile.material_override = TextureHelper.get_marble_material(COLOR_DEFS[p].col * 0.75)
			tile.position = b_pos
			add_child(tile)

	# 5. Interaktiver 3D-Würfel in der Mitte
	dice_3d_node = DiceHelper.create_3d_die(1.2, Color(0.98, 0.98, 0.95))
	dice_3d_node.position = Vector3(0, 0.8, 0)
	add_child(dice_3d_node)

	# 6. Figuren erzeugen
	spawn_all_pawns()

func spawn_all_pawns():
	for p in range(4):
		for f in range(4):
			if is_instance_valid(pawn_nodes[p][f]):
				pawn_nodes[p][f].queue_free()
	pawn_nodes = [[], [], [], []]

	for p in range(4):
		for f in range(4):
			var pawn = create_pawn_figure(base_coords[p][f], COLOR_DEFS[p].col, p, f)
			pawn_nodes[p].append(pawn)

func create_pawn_figure(pos: Vector3, col: Color, p_idx: int, f_idx: int) -> Node3D:
	var pawn = Node3D.new()
	pawn.position = pos
	pawn.set_meta("player_idx", p_idx)
	pawn.set_meta("pawn_idx", f_idx)

	var mat = TextureHelper.get_wood_material(col)

	var body = MeshInstance3D.new()
	var bm = CylinderMesh.new()
	bm.top_radius = 0.16
	bm.bottom_radius = 0.32
	bm.height = 0.8
	body.mesh = bm
	body.material_override = mat
	body.position = Vector3(0, 0.4, 0)
	pawn.add_child(body)

	var head = MeshInstance3D.new()
	var hm = SphereMesh.new()
	hm.radius = 0.22
	hm.height = 0.44
	head.mesh = hm
	head.material_override = mat
	head.position = Vector3(0, 0.9, 0)
	pawn.add_child(head)

	# StaticBody für Klicks
	var sb = StaticBody3D.new()
	var col_shape = CollisionShape3D.new()
	var cs = CylinderShape3D.new()
	cs.radius = 0.4
	cs.height = 1.1
	col_shape.shape = cs
	sb.add_child(col_shape)
	sb.set_meta("grid_pos", Vector2i(200 + p_idx * 10 + f_idx, 0))
	pawn.add_child(sb)

	add_child(pawn)
	return pawn

func setup_game_ui():
	ui_layer = CanvasLayer.new()
	add_child(ui_layer)

	var panel = PanelContainer.new()
	panel.anchors_preset = Control.PRESET_BOTTOM_RIGHT
	panel.offset_left = -340
	panel.offset_top = -180
	panel.offset_right = -20
	panel.offset_bottom = -20
	ui_layer.add_child(panel)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	panel.add_child(vbox)

	var info = Label.new()
	info.name = "MenschInfo"
	info.text = "Rot ist am Zug! Würfle um eine Figur herauszusetzen (bei 6)."
	vbox.add_child(info)

	var roll_btn = Button.new()
	roll_btn.name = "RollBtn"
	roll_btn.text = "🎲 3D-Würfel werfen"
	roll_btn.custom_minimum_size = Vector2(0, 48)
	roll_btn.pressed.connect(roll_dice_action)
	vbox.add_child(roll_btn)

	var auto_move_btn = Button.new()
	auto_move_btn.name = "AutoMoveBtn"
	auto_move_btn.text = "▶️ Beste Figur ziehen"
	auto_move_btn.custom_minimum_size = Vector2(0, 40)
	auto_move_btn.pressed.connect(auto_move_active_player)
	vbox.add_child(auto_move_btn)

	# Victory Modal
	victory_modal = PanelContainer.new()
	victory_modal.anchors_preset = Control.PRESET_CENTER
	victory_modal.offset_left = -220
	victory_modal.offset_top = -120
	victory_modal.offset_right = 220
	victory_modal.offset_bottom = 120
	victory_modal.visible = false
	ui_layer.add_child(victory_modal)

	var vm_vbox = VBoxContainer.new()
	vm_vbox.add_theme_constant_override("separation", 10)
	victory_modal.add_child(vm_vbox)

	var vm_title = Label.new()
	vm_title.name = "VictoryTitle"
	vm_title.text = "🏆 GEWONNEN!"
	vm_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vm_vbox.add_child(vm_title)

	var vm_desc = Label.new()
	vm_desc.name = "VictoryDesc"
	vm_desc.text = ""
	vm_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vm_vbox.add_child(vm_desc)

	var vm_btn = Button.new()
	vm_btn.text = "🔄 Neues Spiel"
	vm_btn.custom_minimum_size = Vector2(0, 48)
	vm_btn.pressed.connect(reset_game)
	vm_vbox.add_child(vm_btn)

func reset_game():
	pawn_positions = [
		[-1, -1, -1, -1],
		[-1, -1, -1, -1],
		[-1, -1, -1, -1],
		[-1, -1, -1, -1]
	]
	active_player = 0
	current_dice_val = 6
	is_rolling = false
	attempts_left = 3

	if victory_modal: victory_modal.visible = false
	spawn_all_pawns()
	DiceHelper.apply_value_rotation(dice_3d_node, 6)
	emit_signal("status_changed", "Mensch ärgere dich nicht: Original 22x22 Kreuz-Spielfeld bereit! Du spielst Rot.")

func handle_tile_clicked(grid_pos: Vector2i):
	if is_rolling: return
	var code = grid_pos.x

	# Klick auf 3D-Würfel
	if code == -1 or grid_pos == Vector2i.ZERO:
		roll_dice_action()
		return

	# Klick auf eine Figur
	if code >= 200 and code < 240:
		var p_idx = int((code - 200) / 10)
		var f_idx = (code - 200) % 10
		if p_idx == active_player:
			try_move_pawn(p_idx, f_idx)
		return

	# Klick auf den Würfel selbst
	roll_dice_action()

func roll_dice_action():
	if is_rolling: return
	is_rolling = true
	current_dice_val = randi_range(1, 6)
	emit_signal("sound_triggered", "dice")

	DiceHelper.roll_die(dice_3d_node, current_dice_val, Vector3(0, 0.8, 0), 0.5, func():
		is_rolling = false
		emit_signal("sound_triggered", "click")
		on_dice_rolled()
	)

func on_dice_rolled():
	var p_name = COLOR_DEFS[active_player].name
	emit_signal("status_changed", p_name + " hat eine " + str(current_dice_val) + " gewürfelt!")

	# Prüfe ob Spieler ziehen kann
	var valid_moves = get_valid_pawn_moves(active_player)
	if valid_moves.is_empty():
		# Wenn alle Figuren in der Basis sind, hat man 3 Versuche für eine 6
		var all_in_base = true
		for pos in pawn_positions[active_player]:
			if pos != -1: all_in_base = false
		if all_in_base and attempts_left > 1 and current_dice_val != 6:
			attempts_left -= 1
			emit_signal("status_changed", "Keine 6 zum Rauskommen! Noch " + str(attempts_left) + " Versuche.")
			if active_player != 0:
				get_tree().create_timer(0.6).timeout.connect(roll_dice_action)
			return

		attempts_left = 3
		emit_signal("status_changed", p_name + " kann keinen Zug machen. Weiter zum nächsten Spieler.")
		switch_turn()
	else:
		attempts_left = 3
		if active_player != 0 and is_bot_opponent:
			get_tree().create_timer(0.6).timeout.connect(auto_move_active_player)

func get_valid_pawn_moves(player_idx: int) -> Array:
	var moves = []
	for f in range(4):
		var pos = pawn_positions[player_idx][f]
		if pos == -1 and current_dice_val == 6:
			moves.append(f)
		elif pos >= 0 and pos < 40:
			moves.append(f)
		elif pos >= 100 and pos < 103 and (pos - 100 + current_dice_val) <= 3:
			moves.append(f)
	return moves

func auto_move_active_player():
	var valid = get_valid_pawn_moves(active_player)
	if not valid.is_empty():
		# Bevorzuge Raussetzen bei einer 6
		var chosen = valid[0]
		for f in valid:
			if pawn_positions[active_player][f] == -1 and current_dice_val == 6:
				chosen = f
				break
		try_move_pawn(active_player, chosen)
	else:
		switch_turn()

func try_move_pawn(player_idx: int, pawn_idx: int):
	var cur_pos = pawn_positions[player_idx][pawn_idx]
	var start_field = COLOR_DEFS[player_idx].start_idx

	if cur_pos == -1:
		if current_dice_val == 6:
			# Raussetzen auf Startfeld
			pawn_positions[player_idx][pawn_idx] = start_field
			var target_pos = track_coords[start_field] + Vector3(0, 0.4, 0)
			animate_pawn(pawn_nodes[player_idx][pawn_idx], target_pos)
			check_capture(player_idx, start_field)
			emit_signal("sound_triggered", "win")
			emit_signal("status_changed", COLOR_DEFS[player_idx].name + " setzt Figur heraus! (Bei 6 darf man nochmal würfeln)")
			# Bei 6 nochmal würfeln!
			if active_player != 0 and is_bot_opponent:
				get_tree().create_timer(0.8).timeout.connect(roll_dice_action)
			return
		else:
			emit_signal("status_changed", "Du brauchst eine 6 um aus der Basis herauszuziehen!")
			return

	# Vorrücken auf der Strecke
	if cur_pos >= 0 and cur_pos < 40:
		var steps_from_start = (cur_pos - start_field + 40) % 40
		if steps_from_start + current_dice_val >= 40:
			# Einbiegen ins Zielhaus
			var home_idx = (steps_from_start + current_dice_val) - 40
			if home_idx < 4:
				pawn_positions[player_idx][pawn_idx] = 100 + home_idx
				var target_pos = home_coords[player_idx][home_idx] + Vector3(0, 0.4, 0)
				animate_pawn(pawn_nodes[player_idx][pawn_idx], target_pos)
				emit_signal("sound_triggered", "win")
				check_win(player_idx)
				finish_turn()
				return
		else:
			var new_field = (cur_pos + current_dice_val) % 40
			pawn_positions[player_idx][pawn_idx] = new_field
			var target_pos = track_coords[new_field] + Vector3(0, 0.4, 0)
			animate_pawn(pawn_nodes[player_idx][pawn_idx], target_pos)
			check_capture(player_idx, new_field)
			finish_turn()
			return

	finish_turn()

func check_capture(player_idx: int, field_idx: int):
	for p in range(4):
		if p == player_idx: continue
		for f in range(4):
			if pawn_positions[p][f] == field_idx:
				# Geschlagen! Zurück in Basis
				pawn_positions[p][f] = -1
				var base_pos = base_coords[p][f] + Vector3(0, 0.4, 0)
				animate_pawn(pawn_nodes[p][f], base_pos)
				emit_signal("sound_triggered", "shoot")
				emit_signal("status_changed", "💥 GESCHLAGEN! " + COLOR_DEFS[player_idx].name + " wirft " + COLOR_DEFS[p].name + " zurück in die Basis!")

func animate_pawn(pawn: Node3D, target: Vector3):
	var start = pawn.position
	var mid = (start + target) * 0.5 + Vector3(0, 1.2, 0)
	var tween = create_tween()
	tween.tween_property(pawn, "position", mid, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(pawn, "position", target, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	emit_signal("sound_triggered", "move")

func check_win(player_idx: int):
	var all_in_house = true
	for pos in pawn_positions[player_idx]:
		if pos < 100: all_in_house = false

	if all_in_house:
		emit_signal("sound_triggered", "win")
		if victory_modal:
			victory_modal.visible = true
			var t_lbl = victory_modal.find_child("VictoryTitle", true, false) as Label
			var d_lbl = victory_modal.find_child("VictoryDesc", true, false) as Label
			if player_idx == 0:
				if t_lbl: t_lbl.text = "🏆 GLORREICHER SIEG!"
				if d_lbl: d_lbl.text = "Alle 4 roten Figuren stehen sicher im Haus! Du hast gewonnen!"
				emit_signal("status_changed", "SIEG! Alle 4 roten Figuren im Zielhaus!")
			else:
				if t_lbl: t_lbl.text = "💀 " + COLOR_DEFS[player_idx].name + " HAT GEWONNEN!"
				if d_lbl: d_lbl.text = "Der Bot hat alle Figuren im Haus!"

func finish_turn():
	if current_dice_val == 6:
		emit_signal("status_changed", COLOR_DEFS[active_player].name + " darf bei einer 6 noch einmal würfeln!")
		if active_player != 0 and is_bot_opponent:
			get_tree().create_timer(0.8).timeout.connect(roll_dice_action)
	else:
		switch_turn()

func switch_turn():
	active_player = (active_player + 1) % 4
	attempts_left = 3
	var p_name = COLOR_DEFS[active_player].name
	emit_signal("status_changed", p_name + " ist am Zug! Würfel rollen...")
	if active_player != 0 and is_bot_opponent:
		get_tree().create_timer(0.8).timeout.connect(roll_dice_action)
