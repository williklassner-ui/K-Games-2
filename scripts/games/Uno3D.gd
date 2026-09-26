extends Node3D

class_name Uno3D

const TextureHelper = preload("res://scripts/TextureHelper.gd")

signal status_changed(msg: String)
signal sound_triggered(sound_name: String)

var player_hand: Array = []
var top_card: Dictionary = {"color": Color(0.9, 0.15, 0.15), "value": "7", "name": "Rot 7"}
var card_nodes: Array = []
var center_card_node: Node3D = null
var ui_layer: CanvasLayer

func _ready():
	setup_stage()
	setup_game_ui()
	reset_game()

func setup_stage():
	# Runder Holztisch mit feiner Holzmaserung
	var table_m = CylinderMesh.new()
	table_m.top_radius = 4.5
	table_m.bottom_radius = 4.8
	table_m.height = 0.4
	var t_inst = MeshInstance3D.new()
	t_inst.mesh = table_m
	t_inst.material_override = TextureHelper.get_wood_material(Color(0.18, 0.1, 0.05))
	t_inst.position = Vector3(0, 0.15, 0)
	add_child(t_inst)

	# Nachziehstapel links in der Mitte
	spawn_card_deck(Vector3(-1.0, 0.36, 0), 15, Color(0.1, 0.1, 0.1))

func reset_game():
	player_hand = [
		{"color": Color(0.85, 0.15, 0.15), "value": "3", "name": "Rot 3"},
		{"color": Color(0.15, 0.45, 0.9), "value": "7", "name": "Blau 7"},
		{"color": Color(0.15, 0.8, 0.25), "value": "5", "name": "Grün 5"},
		{"color": Color(0.95, 0.8, 0.1), "value": "2", "name": "Gelb 2"},
		{"color": Color(0.85, 0.15, 0.15), "value": "+2", "name": "Rot +2"}
	]
	top_card = {"color": Color(0.85, 0.15, 0.15), "value": "7", "name": "Rot 7"}
	render_center_card()
	render_player_hand()
	emit_signal("status_changed", "UNO 3D: Wähle eine passende Karte auf deiner Hand oder ziehe eine neue Karte!")

func render_center_card():
	if center_card_node:
		center_card_node.queue_free()
	center_card_node = create_card_node(Vector3(0.5, 0.36, 0), top_card.color, top_card.value, -1)
	add_child(center_card_node)

func render_player_hand():
	for c in card_nodes:
		c.queue_free()
	card_nodes.clear()

	var total = player_hand.size()
	for i in range(total):
		var offset_x = (i - float(total - 1) * 0.5) * 0.85
		var card_data = player_hand[i]
		var card_n = create_card_node(Vector3(offset_x, 0.42, 2.3), card_data.color, card_data.value, i)
		add_child(card_n)
		card_nodes.append(card_n)

func create_card_node(pos: Vector3, col: Color, label_str: String, card_idx: int) -> Node3D:
	var card = Node3D.new()
	card.position = pos

	var cm = BoxMesh.new()
	cm.size = Vector3(0.7, 0.02, 1.05)
	var inst = MeshInstance3D.new()
	inst.mesh = cm
	var mat = StandardMaterial3D.new()
	mat.albedo_color = col
	mat.roughness = 0.2
	inst.material_override = mat
	card.add_child(inst)

	# Weißes Schild in der Mitte
	var sym = MeshInstance3D.new()
	var sm = BoxMesh.new()
	sm.size = Vector3(0.48, 0.03, 0.7)
	sym.mesh = sm
	var s_mat = StandardMaterial3D.new()
	s_mat.albedo_color = Color(0.96, 0.96, 0.96)
	sym.material_override = s_mat
	sym.position = Vector3(0, 0.01, 0)
	card.add_child(sym)

	# 3D Label für Kartenwert
	var lbl = Label3D.new()
	lbl.text = label_str
	lbl.pixel_size = 0.015
	lbl.position = Vector3(0, 0.04, 0)
	lbl.rotation_degrees = Vector3(-90, 0, 0)
	lbl.modulate = Color(0.1, 0.1, 0.1)
	card.add_child(lbl)

	if card_idx >= 0:
		var sb = StaticBody3D.new()
		var col_shape = CollisionShape3D.new()
		var shape = BoxShape3D.new()
		shape.size = Vector3(0.7, 0.3, 1.0)
		col_shape.shape = shape
		sb.add_child(col_shape)
		sb.set_meta("grid_pos", Vector2i(card_idx, 0))
		card.add_child(sb)

	return card

func spawn_card_deck(pos: Vector3, count: int, col: Color):
	var deck = Node3D.new()
	deck.position = pos
	var dm = BoxMesh.new()
	dm.size = Vector3(0.7, count * 0.02, 1.0)
	var inst = MeshInstance3D.new()
	inst.mesh = dm
	var mat = StandardMaterial3D.new()
	mat.albedo_color = col
	mat.roughness = 0.3
	inst.material_override = mat
	inst.position = Vector3(0, count * 0.01, 0)
	deck.add_child(inst)

	# Klickbar zum Nachziehen
	var sb = StaticBody3D.new()
	var col_shape = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(0.8, 0.5, 1.1)
	col_shape.shape = shape
	sb.add_child(col_shape)
	sb.set_meta("grid_pos", Vector2i(-99, 0))
	deck.add_child(sb)

	add_child(deck)

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

	var draw_btn = Button.new()
	draw_btn.text = "🎴 Karte ziehen"
	draw_btn.custom_minimum_size = Vector2(0, 44)
	draw_btn.pressed.connect(draw_card)
	vbox.add_child(draw_btn)

	var uno_btn = Button.new()
	uno_btn.text = "📢 UNO rufen!"
	uno_btn.custom_minimum_size = Vector2(0, 38)
	uno_btn.pressed.connect(func():
		emit_signal("sound_triggered", "win")
		emit_signal("status_changed", "UNO gerufen! Du bist kurz vor dem Sieg!")
	)
	vbox.add_child(uno_btn)

func handle_tile_clicked(grid_pos: Vector2i):
	if grid_pos.x == -99:
		draw_card()
	else:
		play_hand_card(grid_pos.x)

func draw_card():
	var colors = [Color(0.85, 0.15, 0.15), Color(0.15, 0.45, 0.9), Color(0.15, 0.8, 0.25), Color(0.95, 0.8, 0.1)]
	var col = colors.pick_random()
	var val = str(randi_range(0, 9))
	var card = {"color": col, "value": val, "name": "Gezogen " + val}
	player_hand.append(card)
	emit_signal("sound_triggered", "card")
	render_player_hand()
	emit_signal("status_changed", "Eine neue Karte gezogen! Handkarten: " + str(player_hand.size()))

var ai_hand_count: int = 5
var victory_modal: PanelContainer = null

func play_hand_card(idx: int):
	if idx < 0 or idx >= player_hand.size(): return
	var card = player_hand[idx]

	# Uno Regeln: Gleiche Farbe oder gleiche Zahl/Wert
	var matches_color = (card.color == top_card.color)
	var matches_value = (card.value == top_card.value)

	if matches_color or matches_value:
		top_card = card
		player_hand.remove_at(idx)
		emit_signal("sound_triggered", "card")
		render_center_card()
		render_player_hand()

		if player_hand.is_empty():
			show_uno_end(true)
			return
		elif player_hand.size() == 1:
			emit_signal("status_changed", "LETZTE KARTE! Drücke 'UNO rufen'!")
		else:
			emit_signal("status_changed", card.name + " ausgespielt! Gegner ist am Zug...")
			get_tree().create_timer(0.7).timeout.connect(ai_turn)
	else:
		emit_signal("status_changed", "Karte passt nicht! Wähle gleiche Farbe oder gleiche Zahl.")

func ai_turn():
	emit_signal("sound_triggered", "card")
	if randf() > 0.3:
		# Bot legt ab
		ai_hand_count -= 1
		# Zufällige passende Karte generieren
		if randf() > 0.5:
			top_card = {"color": top_card.color, "value": str(randi_range(0, 9)), "name": "Bot Karte"}
		else:
			var colors = [Color(0.85, 0.15, 0.15), Color(0.15, 0.45, 0.9), Color(0.15, 0.8, 0.25), Color(0.95, 0.8, 0.1)]
			top_card = {"color": colors.pick_random(), "value": top_card.value, "name": "Bot Karte"}
		render_center_card()

		if ai_hand_count <= 0:
			show_uno_end(false)
			return
		elif ai_hand_count == 1:
			emit_signal("status_changed", "⚠️ BOT RUFT UNO! Er hat nur noch 1 Karte!")
		else:
			emit_signal("status_changed", "Gegner legt eine Karte ab (" + str(ai_hand_count) + " Rest). Du bist am Zug!")
	else:
		# Bot zieht
		ai_hand_count += 1
		emit_signal("status_changed", "Gegner kann nicht bedienen und zieht eine Karte (" + str(ai_hand_count) + " Handkarten).")

func show_uno_end(won: bool):
	emit_signal("sound_triggered", "win" if won else "shoot")
	if not victory_modal:
		victory_modal = PanelContainer.new()
		victory_modal.anchors_preset = Control.PRESET_CENTER
		victory_modal.offset_left = -200
		victory_modal.offset_top = -100
		victory_modal.offset_right = 200
		victory_modal.offset_bottom = 100
		ui_layer.add_child(victory_modal)

		var vbox = VBoxContainer.new()
		vbox.add_theme_constant_override("separation", 10)
		victory_modal.add_child(vbox)

		var title = Label.new()
		title.name = "EndTitle"
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(title)

		var btn = Button.new()
		btn.text = "🔄 Neues UNO-Spiel"
		btn.custom_minimum_size = Vector2(0, 46)
		btn.pressed.connect(func():
			victory_modal.visible = false
			reset_game()
		)
		vbox.add_child(btn)

	victory_modal.visible = true
	var t_lbl = victory_modal.find_child("EndTitle", true, false) as Label
	if won:
		if t_lbl: t_lbl.text = "🏆 UNO-SIEG! ALLE KARTEN ABGELEGT!"
		emit_signal("status_changed", "🏆 GEWONNEN! Du hast als Erster alle Karten abgelegt!")
	else:
		if t_lbl: t_lbl.text = "💀 BOT HAT GEWONNEN!"
		emit_signal("status_changed", "Der Bot hat alle Karten abgelegt!")
