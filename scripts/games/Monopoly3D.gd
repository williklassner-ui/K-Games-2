extends Node3D

class_name Monopoly3D

signal status_changed(msg: String)
signal sound_triggered(sound_name: String)

var money = 1500
var player_pos = 0
var tile_positions: Array = []
var player_token: Node3D = null
var owned_properties: Dictionary = {}
var ui_layer: CanvasLayer

func _ready():
	setup_stage()
	setup_game_ui()
	emit_signal("status_changed", "Monopoly 3D: Würfle um über das Spielbrett zu ziehen und Straßen zu kaufen!")

func setup_stage():
	var board_mesh = BoxMesh.new()
	board_mesh.size = Vector3(10.0, 0.4, 10.0)
	var board_inst = MeshInstance3D.new()
	board_inst.mesh = board_mesh
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.12, 0.14, 0.18)
	mat.roughness = 0.35
	board_inst.material_override = mat
	board_inst.position = Vector3(0, 0.15, 0)
	add_child(board_inst)

	# 40 Spielfelder im Quadrat
	tile_positions.clear()
	for i in range(40):
		var pos = Vector3.ZERO
		var edge_idx = i % 10
		var side = int(i / 10)
		var coord = (edge_idx - 4.5) * 0.95
		
		if side == 0:
			pos = Vector3(coord, 0.38, 4.4)
		elif side == 1:
			pos = Vector3(-4.4, 0.38, -coord)
		elif side == 2:
			pos = Vector3(-coord, 0.38, -4.4)
		else:
			pos = Vector3(4.4, 0.38, coord)

		tile_positions.append(pos)

		var tile_mesh = BoxMesh.new()
		tile_mesh.size = Vector3(0.9, 0.08, 0.9)
		var tile = MeshInstance3D.new()
		tile.mesh = tile_mesh
		
		var t_mat = StandardMaterial3D.new()
		if edge_idx == 0:
			t_mat.albedo_color = Color(0.95, 0.2, 0.2)
		else:
			var str_colors = [Color(0.55, 0.27, 0.07), Color(0.68, 0.85, 0.9), Color(0.85, 0.3, 0.7), Color(0.95, 0.55, 0.1), Color(0.9, 0.1, 0.1), Color(0.95, 0.9, 0.15), Color(0.15, 0.7, 0.25), Color(0.1, 0.2, 0.8)]
			t_mat.albedo_color = str_colors[int(i / 5) % 8]
		
		t_mat.roughness = 0.2
		tile.material_override = t_mat
		tile.position = pos
		add_child(tile)

	# Spielfigur (Zylinder-Hut)
	player_token = Node3D.new()
	var hat_m = CylinderMesh.new()
	hat_m.top_radius = 0.15
	hat_m.bottom_radius = 0.2
	hat_m.height = 0.4
	var hat_inst = MeshInstance3D.new()
	hat_inst.mesh = hat_m
	var hat_mat = StandardMaterial3D.new()
	hat_mat.albedo_color = Color(0.95, 0.85, 0.1)
	hat_mat.metallic = 0.8
	hat_inst.material_override = hat_mat
	hat_inst.position = Vector3(0, 0.2, 0)
	player_token.add_child(hat_inst)
	player_token.position = tile_positions[0] + Vector3(0, 0.1, 0)
	add_child(player_token)

func setup_game_ui():
	ui_layer = CanvasLayer.new()
	add_child(ui_layer)

	var panel = PanelContainer.new()
	panel.anchors_preset = Control.PRESET_BOTTOM_RIGHT
	panel.offset_left = -320
	panel.offset_top = -170
	panel.offset_right = -20
	panel.offset_bottom = -20
	ui_layer.add_child(panel)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	panel.add_child(vbox)

	var lbl = Label.new()
	lbl.name = "MonopolyInfo"
	lbl.text = "Guthaben: $1500 | Position: LOS (0)"
	vbox.add_child(lbl)

	var roll_btn = Button.new()
	roll_btn.text = "🎲 Würfeln & Ziehen"
	roll_btn.custom_minimum_size = Vector2(0, 44)
	roll_btn.pressed.connect(roll_and_move)
	vbox.add_child(roll_btn)

	var buy_btn = Button.new()
	buy_btn.text = "🏠 Straße kaufen ($200)"
	buy_btn.custom_minimum_size = Vector2(0, 40)
	buy_btn.pressed.connect(buy_property)
	vbox.add_child(buy_btn)

func roll_and_move():
	var d1 = randi_range(1, 6)
	var d2 = randi_range(1, 6)
	var total = d1 + d2
	emit_signal("sound_triggered", "dice")

	var old_pos = player_pos
	player_pos = (player_pos + total) % 40
	if player_pos < old_pos:
		money += 200 # Über Los gezogen
		emit_signal("sound_triggered", "win")
		emit_signal("status_changed", "Über LOS gezogen! +$200 erhalten!")

	var target = tile_positions[player_pos] + Vector3(0, 0.1, 0)
	var tween = create_tween()
	var mid = (player_token.position + target) * 0.5 + Vector3(0, 0.8, 0)
	tween.tween_property(player_token, "position", mid, 0.2)
	tween.tween_property(player_token, "position", target, 0.2)
	tween.tween_callback(func():
		emit_signal("sound_triggered", "move")
		update_ui()
		var owned = " (Bereits gekauft)" if owned_properties.has(player_pos) else " (Kaufbar)"
		emit_signal("status_changed", "Gewürfelt: " + str(total) + " (" + str(d1) + "+" + str(d2) + ") | Feld: " + str(player_pos) + owned)
	)

func buy_property():
	if player_pos % 10 == 0:
		emit_signal("status_changed", "Eckfelder können nicht gekauft werden!")
		return
	if owned_properties.has(player_pos):
		emit_signal("status_changed", "Dieses Grundstück besitzt du bereits!")
		return
	if money < 200:
		emit_signal("status_changed", "Nicht genug Geld!")
		return

	money -= 200
	owned_properties[player_pos] = true
	emit_signal("sound_triggered", "win")

	# Haus platzieren
	var h_pos = tile_positions[player_pos] + Vector3(0, 0.15, 0)
	var house = MeshInstance3D.new()
	var hm = BoxMesh.new()
	hm.size = Vector3(0.3, 0.3, 0.3)
	house.mesh = hm
	var hmat = StandardMaterial3D.new()
	hmat.albedo_color = Color(0.1, 0.8, 0.2)
	house.material_override = hmat
	house.position = h_pos
	add_child(house)

	update_ui()
	emit_signal("status_changed", "Straße " + str(player_pos) + " gekauft! Neues Haus gebaut!")

func update_ui():
	var lbl = ui_layer.get_node_or_null("PanelContainer/VBoxContainer/MonopolyInfo") as Label
	if lbl:
		lbl.text = "Guthaben: $" + str(money) + " | Feld: " + str(player_pos) + " | Straßen: " + str(owned_properties.size())
