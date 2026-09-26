extends Node3D

class_name Monopoly3D

const TextureHelper = preload("res://scripts/TextureHelper.gd")
const DiceHelper = preload("res://scripts/DiceHelper.gd")

signal status_changed(msg: String)
signal sound_triggered(sound_name: String)

var money: Array = [1500, 1500] # [0] = Spieler, [1] = Bot
var player_positions: Array = [0, 0]
var owned_properties: Dictionary = {} # space_idx -> {"owner": 0/1, "level": 0, "name": ...}

var tile_positions: Array = []
var board_spaces: Array = []
var tokens: Array = []

var die1_node: Node3D = null
var die2_node: Node3D = null
var is_rolling: bool = false
var active_player: int = 0
var is_bot_opponent: bool = true

var ui_layer: CanvasLayer = null
var victory_modal: PanelContainer = null

func _ready():
	setup_stage()
	setup_game_ui()
	reset_game()

func setup_stage():
	# 1. Großes authentisches Spielbrett (26x26)
	var board_mesh = BoxMesh.new()
	board_mesh.size = Vector3(26.0, 0.5, 26.0)
	var board_inst = MeshInstance3D.new()
	board_inst.mesh = board_mesh
	board_inst.material_override = TextureHelper.get_wood_material(Color(0.18, 0.1, 0.05))
	board_inst.position = Vector3(0, 0.2, 0)
	add_child(board_inst)

	# Spielfeldmitte mit grünem Samtfilz
	var center_mesh = BoxMesh.new()
	center_mesh.size = Vector3(19.2, 0.52, 19.2)
	var center_inst = MeshInstance3D.new()
	center_inst.mesh = center_mesh
	center_inst.material_override = TextureHelper.get_grass_material(Color(0.12, 0.38, 0.22))
	center_inst.position = Vector3(0, 0.22, 0)
	add_child(center_inst)

	# 2. Die 40 offiziellen Monopoly-Felder
	var space_defs = [
		{"name": "LOS (+$200)", "type": "corner", "cost": 0, "color": Color(0.9, 0.2, 0.2)},
		{"name": "Badstraße", "type": "street", "cost": 60, "color": Color(0.55, 0.28, 0.12)},
		{"name": "Gemeinschaftsfeld", "type": "special", "cost": 0, "color": Color(0.9, 0.9, 0.85)},
		{"name": "Turmstraße", "type": "street", "cost": 60, "color": Color(0.55, 0.28, 0.12)},
		{"name": "Einkommensteuer", "type": "tax", "cost": 200, "color": Color(0.8, 0.8, 0.8)},
		{"name": "Südbahnhof", "type": "station", "cost": 200, "color": Color(0.2, 0.2, 0.25)},
		{"name": "Chausseestraße", "type": "street", "cost": 100, "color": Color(0.65, 0.85, 0.95)},
		{"name": "Ereignisfeld", "type": "special", "cost": 0, "color": Color(0.95, 0.65, 0.2)},
		{"name": "Elisenstraße", "type": "street", "cost": 100, "color": Color(0.65, 0.85, 0.95)},
		{"name": "Poststraße", "type": "street", "cost": 120, "color": Color(0.65, 0.85, 0.95)},

		{"name": "Gefängnis / Besuch", "type": "corner", "cost": 0, "color": Color(0.85, 0.5, 0.15)},
		{"name": "Seestraße", "type": "street", "cost": 140, "color": Color(0.85, 0.35, 0.65)},
		{"name": "Elektrizitätswerk", "type": "utility", "cost": 150, "color": Color(0.95, 0.95, 0.9)},
		{"name": "Hafenstraße", "type": "street", "cost": 140, "color": Color(0.85, 0.35, 0.65)},
		{"name": "Neue Straße", "type": "street", "cost": 160, "color": Color(0.85, 0.35, 0.65)},
		{"name": "Westbahnhof", "type": "station", "cost": 200, "color": Color(0.2, 0.2, 0.25)},
		{"name": "Münchner Straße", "type": "street", "cost": 180, "color": Color(0.95, 0.58, 0.15)},
		{"name": "Gemeinschaftsfeld", "type": "special", "cost": 0, "color": Color(0.9, 0.9, 0.85)},
		{"name": "Wiener Straße", "type": "street", "cost": 180, "color": Color(0.95, 0.58, 0.15)},
		{"name": "Berliner Straße", "type": "street", "cost": 200, "color": Color(0.95, 0.58, 0.15)},

		{"name": "Frei Parken", "type": "corner", "cost": 0, "color": Color(0.95, 0.2, 0.2)},
		{"name": "Theaterstraße", "type": "street", "cost": 220, "color": Color(0.9, 0.15, 0.15)},
		{"name": "Ereignisfeld", "type": "special", "cost": 0, "color": Color(0.95, 0.65, 0.2)},
		{"name": "Museumstraße", "type": "street", "cost": 220, "color": Color(0.9, 0.15, 0.15)},
		{"name": "Opernplatz", "type": "street", "cost": 240, "color": Color(0.9, 0.15, 0.15)},
		{"name": "Nordbahnhof", "type": "station", "cost": 200, "color": Color(0.2, 0.2, 0.25)},
		{"name": "Lessingstraße", "type": "street", "cost": 260, "color": Color(0.95, 0.9, 0.15)},
		{"name": "Schillerstraße", "type": "street", "cost": 260, "color": Color(0.95, 0.9, 0.15)},
		{"name": "Wasserwerk", "type": "utility", "cost": 150, "color": Color(0.95, 0.95, 0.9)},
		{"name": "Goethestraße", "type": "street", "cost": 280, "color": Color(0.95, 0.9, 0.15)},

		{"name": "In das Gefängnis!", "type": "corner", "cost": 0, "color": Color(0.2, 0.45, 0.85)},
		{"name": "Rathausplatz", "type": "street", "cost": 300, "color": Color(0.18, 0.72, 0.28)},
		{"name": "Hauptstraße", "type": "street", "cost": 300, "color": Color(0.18, 0.72, 0.28)},
		{"name": "Gemeinschaftsfeld", "type": "special", "cost": 0, "color": Color(0.9, 0.9, 0.85)},
		{"name": "Bahnhofstraße", "type": "street", "cost": 320, "color": Color(0.18, 0.72, 0.28)},
		{"name": "Hauptbahnhof", "type": "station", "cost": 200, "color": Color(0.2, 0.2, 0.25)},
		{"name": "Ereignisfeld", "type": "special", "cost": 0, "color": Color(0.95, 0.65, 0.2)},
		{"name": "Parkstraße", "type": "street", "cost": 350, "color": Color(0.1, 0.25, 0.85)},
		{"name": "Zusatzsteuer", "type": "tax", "cost": 100, "color": Color(0.8, 0.8, 0.8)},
		{"name": "Schlossallee", "type": "street", "cost": 400, "color": Color(0.1, 0.25, 0.85)}
	]

	tile_positions.clear()
	board_spaces.clear()

	for i in range(40):
		var s_data = space_defs[i]
		var side = int(i / 10)
		var edge_idx = i % 10
		var c_offset = (float(edge_idx) - 4.5) * 2.2
		var pos = Vector3.ZERO

		if side == 0:
			pos = Vector3(c_offset, 0.48, 11.0)
		elif side == 1:
			pos = Vector3(-11.0, 0.48, -c_offset)
		elif side == 2:
			pos = Vector3(-c_offset, 0.48, -11.0)
		else:
			pos = Vector3(11.0, 0.48, c_offset)

		tile_positions.append(pos)

		var tile_mesh = BoxMesh.new()
		tile_mesh.size = Vector3(2.05, 0.08, 2.05)
		var tile_inst = MeshInstance3D.new()
		tile_inst.mesh = tile_mesh
		tile_inst.material_override = TextureHelper.get_parchment_material(s_data.color)
		tile_inst.position = pos
		add_child(tile_inst)

		# Klickbarer StaticBody
		var sb = StaticBody3D.new()
		var col = CollisionShape3D.new()
		var b_shape = BoxShape3D.new()
		b_shape.size = Vector3(2.1, 0.6, 2.1)
		col.shape = b_shape
		sb.add_child(col)
		sb.set_meta("grid_pos", Vector2i(i, 0))
		tile_inst.add_child(sb)

		# Label mit Feldname und Preis
		var lbl = Label3D.new()
		lbl.text = s_data.name + ("\n$" + str(s_data.cost) if s_data.cost > 0 else "")
		lbl.pixel_size = 0.012
		lbl.rotation_degrees = Vector3(-90, 0, 0)
		lbl.position = Vector3(0, 0.08, 0)
		lbl.modulate = Color(0.1, 0.1, 0.1)
		lbl.outline_size = 3
		tile_inst.add_child(lbl)

		s_data["node"] = tile_inst
		board_spaces.append(s_data)

	# 3. Zwei physische 3D-Würfel in der Mitte des Bretts
	die1_node = DiceHelper.create_3d_die(1.1, Color(0.98, 0.98, 0.95))
	die1_node.position = Vector3(-1.2, 0.8, 0)
	add_child(die1_node)

	die2_node = DiceHelper.create_3d_die(1.1, Color(0.98, 0.98, 0.95))
	die2_node.position = Vector3(1.2, 0.8, 0)
	add_child(die2_node)

	# 4. Spielfiguren: Spieler (Zylinder-Hut) & Bot (Rennwagen)
	tokens.clear()
	var t1 = create_top_hat()
	t1.position = tile_positions[0] + Vector3(-0.4, 0.1, 0)
	add_child(t1)
	tokens.append(t1)

	var t2 = create_car_token()
	t2.position = tile_positions[0] + Vector3(0.4, 0.1, 0)
	add_child(t2)
	tokens.append(t2)

func create_top_hat() -> Node3D:
	var hat = Node3D.new()
	var mat = TextureHelper.get_metal_material(Color(0.95, 0.82, 0.15), 0.9)

	var brim = MeshInstance3D.new()
	var b_m = CylinderMesh.new()
	b_m.top_radius = 0.4
	b_m.bottom_radius = 0.45
	b_m.height = 0.08
	brim.mesh = b_m
	brim.material_override = mat
	brim.position = Vector3(0, 0.05, 0)
	hat.add_child(brim)

	var crown = MeshInstance3D.new()
	var c_m = CylinderMesh.new()
	c_m.top_radius = 0.28
	c_m.bottom_radius = 0.3
	c_m.height = 0.6
	crown.mesh = c_m
	crown.material_override = mat
	crown.position = Vector3(0, 0.35, 0)
	hat.add_child(crown)
	return hat

func create_car_token() -> Node3D:
	var car = Node3D.new()
	var mat = TextureHelper.get_metal_material(Color(0.2, 0.5, 0.95), 0.85)

	var body = MeshInstance3D.new()
	var bm = BoxMesh.new()
	bm.size = Vector3(0.6, 0.3, 0.9)
	body.mesh = bm
	body.material_override = mat
	body.position = Vector3(0, 0.2, 0)
	car.add_child(body)
	return car

func setup_game_ui():
	ui_layer = CanvasLayer.new()
	add_child(ui_layer)

	var panel = PanelContainer.new()
	panel.anchors_preset = Control.PRESET_BOTTOM_RIGHT
	panel.offset_left = -400
	panel.offset_top = -240
	panel.offset_right = -20
	panel.offset_bottom = -20
	ui_layer.add_child(panel)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	panel.add_child(vbox)

	var info = Label.new()
	info.name = "MonopolyInfo"
	info.text = "Guthaben: Du $1500 | Bot $1500\nFeld: 0 (LOS)"
	vbox.add_child(info)

	var roll_btn = Button.new()
	roll_btn.name = "RollBtn"
	roll_btn.text = "🎲 2W6 3D-Würfel rollen"
	roll_btn.custom_minimum_size = Vector2(0, 46)
	roll_btn.pressed.connect(roll_dice_action)
	vbox.add_child(roll_btn)

	var buy_btn = Button.new()
	buy_btn.text = "🏠 Aktuelles Grundstück kaufen"
	buy_btn.custom_minimum_size = Vector2(0, 40)
	buy_btn.pressed.connect(buy_current_property)
	vbox.add_child(buy_btn)

	var house_btn = Button.new()
	house_btn.text = "🔨 Haus / Hotel bauen ($100)"
	house_btn.custom_minimum_size = Vector2(0, 38)
	house_btn.pressed.connect(build_house)
	vbox.add_child(house_btn)

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
	money = [1500, 1500]
	player_positions = [0, 0]
	owned_properties.clear()
	active_player = 0
	is_rolling = false

	if victory_modal: victory_modal.visible = false
	tokens[0].position = tile_positions[0] + Vector3(-0.4, 0.1, 0)
	tokens[1].position = tile_positions[0] + Vector3(0.4, 0.1, 0)

	DiceHelper.apply_value_rotation(die1_node, 1)
	DiceHelper.apply_value_rotation(die2_node, 2)
	update_ui()
	emit_signal("status_changed", "Monopoly 3D: Original 26x26 Brett mit 40 Feldern bereit! Würfle um Straßen zu kaufen.")

func handle_tile_clicked(grid_pos: Vector2i):
	var idx = grid_pos.x
	if idx >= 0 and idx < board_spaces.size():
		var s = board_spaces[idx]
		emit_signal("sound_triggered", "select")
		var owner_str = ""
		if owned_properties.has(idx):
			var o = owned_properties[idx].owner
			owner_str = " (Besitzer: " + ("Du" if o == 0 else "Bot") + ")"
		emit_signal("status_changed", "Feld " + str(idx) + ": " + s.name + " [$" + str(s.cost) + "]" + owner_str)
	else:
		roll_dice_action()

func roll_dice_action():
	if is_rolling: return
	is_rolling = true

	var d1 = randi_range(1, 6)
	var d2 = randi_range(1, 6)
	var sum = d1 + d2
	emit_signal("sound_triggered", "dice")

	DiceHelper.roll_die(die1_node, d1, Vector3(-1.2, 0.8, 0), 0.5)
	DiceHelper.roll_die(die2_node, d2, Vector3(1.2, 0.8, 0), 0.5, func():
		is_rolling = false
		execute_move(active_player, sum, d1, d2)
	)

func execute_move(p_idx: int, steps: int, d1: int, d2: int):
	var old_pos = player_positions[p_idx]
	player_positions[p_idx] = (player_positions[p_idx] + steps) % 40
	var new_pos = player_positions[p_idx]

	if new_pos < old_pos:
		money[p_idx] += 200
		emit_signal("sound_triggered", "win")
		emit_signal("status_changed", ("Du ziehst" if p_idx == 0 else "Bot zieht") + " über LOS! +$200 erhalten!")

	var target = tile_positions[new_pos] + Vector3(-0.4 if p_idx == 0 else 0.4, 0.1, 0)
	var token = tokens[p_idx]
	var mid = (token.position + target) * 0.5 + Vector3(0, 1.4, 0)

	var tween = create_tween()
	tween.tween_property(token, "position", mid, 0.22)
	tween.tween_property(token, "position", target, 0.22)
	tween.tween_callback(func():
		emit_signal("sound_triggered", "move")
		handle_space_landing(p_idx, new_pos, d1, d2)
	)

func handle_space_landing(p_idx: int, space_idx: int, d1: int, d2: int):
	var s = board_spaces[space_idx]
	var p_name = "Du" if p_idx == 0 else "Bot"

	# Mietzahlung prüfen
	if owned_properties.has(space_idx):
		var prop = owned_properties[space_idx]
		if prop.owner != p_idx:
			var rent = int(s.cost * 0.2) + prop.level * 50
			money[p_idx] -= rent
			money[prop.owner] += rent
			emit_signal("sound_triggered", "shoot")
			emit_signal("status_changed", p_name + " landet auf " + s.name + " und zahlt $" + str(rent) + " Miete!")
			check_bankruptcy(p_idx)
	elif s.type == "tax":
		money[p_idx] -= s.cost
		emit_signal("sound_triggered", "shoot")
		emit_signal("status_changed", p_name + " zahlt $" + str(s.cost) + " Steuern!")
		check_bankruptcy(p_idx)
	elif s.name == "In das Gefängnis!":
		player_positions[p_idx] = 10
		tokens[p_idx].position = tile_positions[10] + Vector3(-0.4 if p_idx == 0 else 0.4, 0.1, 0)
		emit_signal("sound_triggered", "shoot")
		emit_signal("status_changed", p_name + " geht direkt ins Gefängnis!")
	else:
		emit_signal("status_changed", p_name + " würfelt " + str(d1 + d2) + " (" + str(d1) + "+" + str(d2) + ") -> landet auf " + s.name)
		# Bot kauft automatisch kaufbare Straßen
		if p_idx == 1 and s.cost > 0 and s.cost <= money[1] and not owned_properties.has(space_idx):
			buy_property_for(1, space_idx)

	update_ui()

	# Pasch gibt nochmaligen Wurf, sonst nächster Spieler
	if d1 == d2:
		emit_signal("status_changed", "PASCH! (" + str(d1) + "+" + str(d2) + ") - Nochmal würfeln!")
		if p_idx == 1:
			get_tree().create_timer(0.8).timeout.connect(roll_dice_action)
	else:
		switch_turn()

func buy_current_property():
	var cur_pos = player_positions[active_player]
	if active_player != 0: return
	buy_property_for(0, cur_pos)

func buy_property_for(p_idx: int, space_idx: int):
	var s = board_spaces[space_idx]
	if s.cost == 0 or s.type == "corner" or s.type == "special" or s.type == "tax":
		if p_idx == 0: emit_signal("status_changed", s.name + " kann nicht gekauft werden!")
		return
	if owned_properties.has(space_idx):
		if p_idx == 0: emit_signal("status_changed", "Bereits in Besitz!")
		return
	if money[p_idx] < s.cost:
		if p_idx == 0: emit_signal("status_changed", "Nicht genug Geld!")
		return

	money[p_idx] -= s.cost
	owned_properties[space_idx] = {"owner": p_idx, "level": 0, "name": s.name}
	emit_signal("sound_triggered", "win")

	# Haus-Markierung
	var hm = BoxMesh.new()
	hm.size = Vector3(0.5, 0.4, 0.5)
	var h_inst = MeshInstance3D.new()
	h_inst.mesh = hm
	h_inst.material_override = TextureHelper.get_wood_material(Color(0.2, 0.8, 0.3) if p_idx == 0 else Color(0.2, 0.5, 0.9))
	h_inst.position = tile_positions[space_idx] + Vector3(0, 0.28, 0)
	add_child(h_inst)

	emit_signal("status_changed", ("Du kaufst " if p_idx == 0 else "Bot kauft ") + s.name + " für $" + str(s.cost) + "!")
	update_ui()

func build_house():
	var cur = player_positions[0]
	if not owned_properties.has(cur) or owned_properties[cur].owner != 0:
		emit_signal("status_changed", "Du musst auf deinem eigenen Grundstück stehen!")
		return
	if money[0] < 100:
		emit_signal("status_changed", "Nicht genug Geld für Hausbau ($100 nötig)!")
		return

	money[0] -= 100
	owned_properties[cur].level += 1
	emit_signal("sound_triggered", "win")
	emit_signal("status_changed", "🔨 Haus gebaut auf " + board_spaces[cur].name + "! (Stufe " + str(owned_properties[cur].level) + ")")
	update_ui()

func check_bankruptcy(p_idx: int):
	if money[p_idx] < 0:
		if victory_modal:
			victory_modal.visible = true
			var t_lbl = victory_modal.find_child("VictoryTitle", true, false) as Label
			var d_lbl = victory_modal.find_child("VictoryDesc", true, false) as Label
			if p_idx == 1:
				emit_signal("sound_triggered", "win")
				if t_lbl: t_lbl.text = "🏆 GEWONNEN!"
				if d_lbl: d_lbl.text = "Der Bot ist bankrott! Du beherrschst das Monopoly-Imperium!"
			else:
				emit_signal("sound_triggered", "shoot")
				if t_lbl: t_lbl.text = "💀 BANKROTT - NIEDERLAGE!"
				if d_lbl: d_lbl.text = "Dein Guthaben ist aufgebraucht! Der Bot hat gewonnen!"

func switch_turn():
	active_player = 1 if active_player == 0 else 0
	var p_name = "Du bist" if active_player == 0 else "Bot ist"
	emit_signal("status_changed", p_name + " am Zug!")
	if active_player == 1 and is_bot_opponent:
		get_tree().create_timer(0.9).timeout.connect(roll_dice_action)

func update_ui():
	var lbl = ui_layer.get_node_or_null("PanelContainer/VBoxContainer/MonopolyInfo") as Label
	if lbl:
		var cur_name = board_spaces[player_positions[0]].name
		lbl.text = "Guthaben: Du $" + str(money[0]) + " | Bot $" + str(money[1]) + "\nFeld: " + str(player_positions[0]) + " (" + cur_name + ")\nBesitz: " + str(owned_properties.size()) + " Grundstücke"
