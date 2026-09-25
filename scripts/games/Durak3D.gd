extends Node3D

class_name Durak3D

signal status_changed(msg: String)
signal sound_triggered(sound_name: String)

var player_hand: Array = []
var table_cards: Array = [] # Angriff & Abwehr
var hand_nodes: Array = []
var table_nodes: Array = []
var trump_suit = "Herz"
var ui_layer: CanvasLayer

func _ready():
	setup_stage()
	setup_game_ui()
	reset_game()

func setup_stage():
	# Russischer Holztisch
	var table_m = BoxMesh.new()
	table_m.size = Vector3(10.0, 0.4, 8.0)
	var t_inst = MeshInstance3D.new()
	t_inst.mesh = table_m
	var t_mat = StandardMaterial3D.new()
	t_mat.albedo_color = Color(0.24, 0.16, 0.1)
	t_mat.roughness = 0.4
	t_inst.material_override = t_mat
	t_inst.position = Vector3(0, 0.15, 0)
	add_child(t_inst)

	# Trumpfkarte quer unter dem Nachziehstapel (36 Karten Deck)
	spawn_card_deck(Vector3(-2.8, 0.38, 0), 18, Color(0.12, 0.25, 0.6))

func reset_game():
	trump_suit = "Herz"
	player_hand = [
		{"suit": "Pik", "val": 10, "text": "Pik 10", "col": Color(0.15, 0.15, 0.15)},
		{"suit": "Herz", "val": 8, "text": "Herz 8 (Trumpf)", "col": Color(0.85, 0.15, 0.15)},
		{"suit": "Karo", "val": 14, "text": "Karo Ass", "col": Color(0.85, 0.15, 0.15)},
		{"suit": "Kreuz", "val": 7, "text": "Kreuz 7", "col": Color(0.15, 0.15, 0.15)},
		{"suit": "Herz", "val": 12, "text": "Herz Dame (Trumpf)", "col": Color(0.85, 0.15, 0.15)},
		{"suit": "Pik", "val": 9, "text": "Pik 9", "col": Color(0.15, 0.15, 0.15)}
	]
	table_cards.clear()
	render_hand()
	render_table()
	emit_signal("status_changed", "Durak 3D: Trumpffarbe ist HERZ. Klicke eine Karte um anzugreifen oder zu verteidigen!")

func render_hand():
	for n in hand_nodes: n.queue_free()
	hand_nodes.clear()

	var total = player_hand.size()
	for i in range(total):
		var offset_x = (i - float(total - 1) * 0.5) * 0.85
		var card = player_hand[i]
		var c_node = spawn_card(Vector3(offset_x, 0.42, 2.5), card.col, card.text, i)
		add_child(c_node)
		hand_nodes.append(c_node)

func render_table():
	for n in table_nodes: n.queue_free()
	table_nodes.clear()

	for i in range(table_cards.size()):
		var card = table_cards[i]
		var offset_x = (i - 1.0) * 1.1
		var c_node = spawn_card(Vector3(offset_x, 0.38, 0.1), card.col, card.text, -1)
		add_child(c_node)
		table_nodes.append(c_node)

func spawn_card(pos: Vector3, col: Color, card_text: String, index: int) -> Node3D:
	var card = Node3D.new()
	card.position = pos

	var cm = BoxMesh.new()
	cm.size = Vector3(0.7, 0.02, 1.05)
	var inst = MeshInstance3D.new()
	inst.mesh = cm
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.96, 0.96, 0.94)
	mat.roughness = 0.15
	inst.material_override = mat
	card.add_child(inst)

	var sym = MeshInstance3D.new()
	var sm = SphereMesh.new()
	sm.radius = 0.14
	sm.height = 0.05
	sym.mesh = sm
	var s_mat = StandardMaterial3D.new()
	s_mat.albedo_color = col
	sym.material_override = s_mat
	sym.position = Vector3(0, 0.02, -0.15)
	card.add_child(sym)

	var lbl = Label3D.new()
	lbl.text = card_text
	lbl.pixel_size = 0.012
	lbl.position = Vector3(0, 0.03, 0.15)
	lbl.rotation_degrees = Vector3(-90, 0, 0)
	lbl.modulate = col
	card.add_child(lbl)

	if index >= 0:
		var sb = StaticBody3D.new()
		var cs = CollisionShape3D.new()
		var shape = BoxShape3D.new()
		shape.size = Vector3(0.75, 0.3, 1.1)
		cs.shape = shape
		sb.add_child(cs)
		sb.set_meta("grid_pos", Vector2i(index, 0))
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
	inst.material_override = mat
	inst.position = Vector3(0, count * 0.01, 0)
	deck.add_child(inst)
	add_child(deck)

func setup_game_ui():
	ui_layer = CanvasLayer.new()
	add_child(ui_layer)

	var panel = PanelContainer.new()
	panel.anchors_preset = Control.PRESET_BOTTOM_RIGHT
	panel.offset_left = -280
	panel.offset_top = -140
	panel.offset_right = -20
	panel.offset_bottom = -20
	ui_layer.add_child(panel)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	panel.add_child(vbox)

	var pass_btn = Button.new()
	pass_btn.text = "🛡️ Verteidigt / Weitergeben"
	pass_btn.custom_minimum_size = Vector2(0, 44)
	pass_btn.pressed.connect(bito_turn)
	vbox.add_child(pass_btn)

	var draw_btn = Button.new()
	draw_btn.text = "📥 Karte aufnehmen"
	draw_btn.custom_minimum_size = Vector2(0, 38)
	draw_btn.pressed.connect(take_cards)
	vbox.add_child(draw_btn)

func handle_tile_clicked(grid_pos: Vector2i):
	var idx = grid_pos.x
	if idx >= 0 and idx < player_hand.size():
		play_card(idx)

func play_card(idx: int):
	var c = player_hand[idx]
	player_hand.remove_at(idx)
	table_cards.append(c)
	emit_signal("sound_triggered", "card")
	render_hand()
	render_table()

	if player_hand.is_empty():
		emit_signal("sound_triggered", "win")
		emit_signal("status_changed", "GEWONNEN! Du bist kein Durak! Alle Handkarten erfolgreich ausgespielt!")
	else:
		emit_signal("status_changed", c.text + " auf den Tisch gelegt! Gegner muss bedienen.")
		get_tree().create_timer(0.6).timeout.connect(ai_respond)

func ai_respond():
	var ai_card = {"suit": "Karo", "val": 11, "text": "Gegner: Karo Bube", "col": Color(0.85, 0.15, 0.15)}
	table_cards.append(ai_card)
	emit_signal("sound_triggered", "card")
	render_table()
	emit_signal("status_changed", "Gegner legt Karo Bube ab! Schlage oder drücke 'Verteidigt'.")

func bito_turn():
	table_cards.clear()
	render_table()
	emit_signal("sound_triggered", "move")
	emit_signal("status_changed", "Karten abgeräumt (Bito)! Nächster Angriff ist bereit.")

func take_cards():
	for c in table_cards:
		player_hand.append(c)
	table_cards.clear()
	emit_signal("sound_triggered", "card")
	render_hand()
	render_table()
	emit_signal("status_changed", "Karten vom Tisch aufgenommen. Handkarten: " + str(player_hand.size()))
