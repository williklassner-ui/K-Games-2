extends Node3D

const DiceHelper = preload("res://scripts/DiceHelper.gd")
const TextureHelper = preload("res://scripts/TextureHelper.gd")

signal status_changed(msg: String)
signal sound_triggered(sound_name: String)

var tile_coords: Array = []
var player_pos = 0
var ai_pos = 0
var player_node: Node3D = null
var ai_node: Node3D = null
var die_node: Node3D = null
var is_rolling: bool = false
var ui_layer: CanvasLayer = null
var victory_modal: PanelContainer = null

const LADDERS = {
	4: 14,
	9: 31,
	20: 38,
	28: 84,
	40: 59,
	51: 67,
	63: 81,
	71: 91
}

const SNAKES = {
	17: 7,
	54: 34,
	62: 19,
	64: 60,
	87: 24,
	93: 73,
	95: 75,
	99: 78
}

func _ready():
	setup_stage()
	setup_game_ui()
	reset_game()

func setup_stage():
	var board_mesh = BoxMesh.new()
	board_mesh.size = Vector3(14.0, 0.45, 11.5)
	var board = MeshInstance3D.new()
	board.mesh = board_mesh
	board.material_override = TextureHelper.get_wood_material(Color(0.18, 0.1, 0.05))
	board.position = Vector3(0, 0.15, 0)
	add_child(board)

	tile_coords.clear()
	for i in range(100):
		var row = int(i / 10)
		var col = i % 10
		if row % 2 == 1:
			col = 9 - col
		var pos = Vector3((col - 4.5) * 0.95 - 1.0, 0.42, (4.5 - row) * 0.95)
		tile_coords.append(pos)

		var tile = MeshInstance3D.new()
		var tm = BoxMesh.new()
		tm.size = Vector3(0.9, 0.06, 0.9)
		tile.mesh = tm
		var t_mat = StandardMaterial3D.new()
		var colors = [Color(0.85, 0.25, 0.25), Color(0.25, 0.65, 0.85), Color(0.95, 0.8, 0.2), Color(0.25, 0.8, 0.4)]
		t_mat.albedo_color = colors[(row + col) % 4]
		tile.material_override = t_mat
		tile.position = pos
		add_child(tile)

	player_node = spawn_pawn(tile_coords[0] + Vector3(-0.15, 0.1, 0), Color(0.9, 0.1, 0.1))
	ai_node = spawn_pawn(tile_coords[0] + Vector3(0.15, 0.1, 0), Color(0.1, 0.4, 0.9))

	# 3D-Würfel rechts auf dem Spielbrett
	die_node = DiceHelper.create_3d_die(1.1, Color(0.98, 0.98, 0.94))
	die_node.position = Vector3(5.2, 0.75, 0)
	add_child(die_node)

func spawn_pawn(pos: Vector3, col: Color) -> Node3D:
	var p = Node3D.new()
	p.position = pos
	var mat = StandardMaterial3D.new()
	mat.albedo_color = col
	mat.metallic = 0.3

	var body = MeshInstance3D.new()
	var bm = CylinderMesh.new()
	bm.top_radius = 0.1
	bm.bottom_radius = 0.2
	bm.height = 0.5
	body.mesh = bm
	body.material_override = mat
	body.position = Vector3(0, 0.25, 0)
	p.add_child(body)

	var head = MeshInstance3D.new()
	var hm = SphereMesh.new()
	hm.radius = 0.16
	hm.height = 0.32
	head.mesh = hm
	head.material_override = mat
	head.position = Vector3(0, 0.58, 0)
	p.add_child(head)

	add_child(p)
	return p

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

	var lbl = Label.new()
	lbl.name = "SnakesInfo"
	lbl.text = "Du: Feld 1 | Gegner: Feld 1"
	vbox.add_child(lbl)

	var roll_btn = Button.new()
	roll_btn.text = "🎲 3D-Würfel werfen"
	roll_btn.custom_minimum_size = Vector2(0, 44)
	roll_btn.pressed.connect(play_turn)
	vbox.add_child(roll_btn)

	# Victory Modal
	victory_modal = PanelContainer.new()
	victory_modal.anchors_preset = Control.PRESET_CENTER
	victory_modal.offset_left = -200
	victory_modal.offset_top = -110
	victory_modal.offset_right = 200
	victory_modal.offset_bottom = 110
	victory_modal.visible = false
	ui_layer.add_child(victory_modal)

	var vm_vbox = VBoxContainer.new()
	vm_vbox.add_theme_constant_override("separation", 10)
	victory_modal.add_child(vm_vbox)

	var vm_title = Label.new()
	vm_title.name = "VictoryTitle"
	vm_title.text = "🏆 FELD 100 ERREICHT!"
	vm_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vm_vbox.add_child(vm_title)

	var vm_desc = Label.new()
	vm_desc.name = "VictoryDesc"
	vm_desc.text = ""
	vm_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vm_vbox.add_child(vm_desc)

	var vm_btn = Button.new()
	vm_btn.text = "🔄 Nochmal spielen"
	vm_btn.custom_minimum_size = Vector2(0, 46)
	vm_btn.pressed.connect(reset_game)
	vm_vbox.add_child(vm_btn)

func reset_game():
	player_pos = 0
	ai_pos = 0
	is_rolling = false
	if victory_modal: victory_modal.visible = false
	player_node.position = tile_coords[0] + Vector3(-0.15, 0.1, 0)
	ai_node.position = tile_coords[0] + Vector3(0.15, 0.1, 0)
	DiceHelper.apply_value_rotation(die_node, 1)
	update_ui()
	emit_signal("status_changed", "Snakes & Ladders 3D: Bereit! Würfle um Feld 100 zu erreichen.")

func play_turn():
	if is_rolling: return
	is_rolling = true
	var roll = randi_range(1, 6)
	emit_signal("sound_triggered", "dice")

	DiceHelper.roll_die(die_node, roll, Vector3(5.2, 0.75, 0), 0.5, func():
		is_rolling = false
		execute_player_step(roll)
	)

func execute_player_step(roll: int):
	player_pos = min(99, player_pos + roll)
	var final_target = tile_coords[player_pos] + Vector3(-0.15, 0.1, 0)
	animate_pawn(player_node, final_target)

	if LADDERS.has(player_pos):
		var new_pos = LADDERS[player_pos]
		player_pos = new_pos
		emit_signal("sound_triggered", "win")
		emit_signal("status_changed", "🪜 LEITER HOCHGEKLETTERT auf Feld " + str(player_pos + 1) + "!")
	elif SNAKES.has(player_pos):
		var new_pos = SNAKES[player_pos]
		player_pos = new_pos
		emit_signal("sound_triggered", "shoot")
		emit_signal("status_changed", "🐍 SCHLANGE GEBISSEN! Zurück auf Feld " + str(player_pos + 1) + "!")
	else:
		emit_signal("sound_triggered", "move")
		emit_signal("status_changed", "Du würfelst " + str(roll) + " und ziehst auf Feld " + str(player_pos + 1) + "!")

	if player_pos >= 99:
		show_end_screen(true)
		return

	# KI zieht
	get_tree().create_timer(0.7).timeout.connect(func():
		var ai_roll = randi_range(1, 6)
		ai_pos = min(99, ai_pos + ai_roll)
		if LADDERS.has(ai_pos): ai_pos = LADDERS[ai_pos]
		elif SNAKES.has(ai_pos): ai_pos = SNAKES[ai_pos]
		var ai_target = tile_coords[ai_pos] + Vector3(0.15, 0.1, 0)
		animate_pawn(ai_node, ai_target)
		emit_signal("sound_triggered", "move")
		if ai_pos >= 99:
			show_end_screen(false)
		else:
			update_ui()
	)

func show_end_screen(won: bool):
	if victory_modal:
		victory_modal.visible = true
		var t_lbl = victory_modal.find_child("VictoryTitle", true, false) as Label
		var d_lbl = victory_modal.find_child("VictoryDesc", true, false) as Label
		if won:
			emit_signal("sound_triggered", "win")
			if t_lbl: t_lbl.text = "🏆 SIEG!"
			if d_lbl: d_lbl.text = "Du hast als Erster das Zielfeld 100 erklommen!"
		else:
			emit_signal("sound_triggered", "shoot")
			if t_lbl: t_lbl.text = "💀 BOT HAT GEWONNEN!"
			if d_lbl: d_lbl.text = "Der blaue Gegner hat Feld 100 zuerst erreicht!"


func animate_pawn(pawn: Node3D, target: Vector3):
	var tween = create_tween()
	var mid = (pawn.position + target) * 0.5 + Vector3(0, 0.7, 0)
	tween.tween_property(pawn, "position", mid, 0.15)
	tween.tween_property(pawn, "position", target, 0.15)

func update_ui():
	var lbl = ui_layer.get_node_or_null("PanelContainer/VBoxContainer/SnakesInfo") as Label
	if lbl:
		lbl.text = "Du: Feld " + str(player_pos + 1) + " | Gegner: Feld " + str(ai_pos + 1)
