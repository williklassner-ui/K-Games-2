extends Node3D

class_name UnoExtreme3D

signal status_changed(msg: String)
signal sound_triggered(sound_name: String)

var player_cards = 5
var top_color: Color = Color(0.9, 0.15, 0.15)
var launcher_button: MeshInstance3D = null
var card_root: Node3D = null
var ui_layer: CanvasLayer

func _ready():
	setup_stage()
	setup_game_ui()
	emit_signal("status_changed", "UNO Extreme 3D: Drücke den roten Launcher-Knopf wenn du nicht bedienen kannst!")

func setup_stage():
	# Poker-Tisch
	var table_m = CylinderMesh.new()
	table_m.top_radius = 4.5
	table_m.bottom_radius = 4.8
	table_m.height = 0.4
	var t_inst = MeshInstance3D.new()
	t_inst.mesh = table_m
	var t_mat = StandardMaterial3D.new()
	t_mat.albedo_color = Color(0.18, 0.12, 0.28)
	t_mat.roughness = 0.4
	t_inst.material_override = t_mat
	t_inst.position = Vector3(0, 0.15, 0)
	add_child(t_inst)

	card_root = Node3D.new()
	add_child(card_root)

	spawn_launcher(Vector3(0, 0.35, -0.4))
	render_table_cards()

func spawn_launcher(pos: Vector3):
	var l = Node3D.new()
	l.position = pos

	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.15, 0.15, 0.18)
	mat.metallic = 0.6
	mat.roughness = 0.25

	var body = MeshInstance3D.new()
	var bm = BoxMesh.new()
	bm.size = Vector3(1.4, 0.7, 1.8)
	body.mesh = bm
	body.material_override = mat
	body.position = Vector3(0, 0.35, 0)
	l.add_child(body)

	var slot = MeshInstance3D.new()
	var sm = BoxMesh.new()
	sm.size = Vector3(0.9, 0.12, 0.3)
	slot.mesh = sm
	var smat = StandardMaterial3D.new()
	smat.albedo_color = Color(0.02, 0.02, 0.02)
	slot.material_override = smat
	slot.position = Vector3(0, 0.5, 0.85)
	l.add_child(slot)

	# Roter Auslöser
	launcher_button = MeshInstance3D.new()
	var btm = CylinderMesh.new()
	btm.top_radius = 0.35
	btm.bottom_radius = 0.38
	btm.height = 0.15
	launcher_button.mesh = btm
	var bmat = StandardMaterial3D.new()
	bmat.albedo_color = Color(0.95, 0.15, 0.15)
	bmat.emission_enabled = true
	bmat.emission = Color(0.95, 0.15, 0.15)
	bmat.emission_energy_multiplier = 0.5
	launcher_button.material_override = bmat
	launcher_button.position = Vector3(0, 0.75, 0)

	var sb = StaticBody3D.new()
	var col = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(0.8, 0.4, 0.8)
	col.shape = shape
	sb.add_child(col)
	sb.set_meta("grid_pos", Vector2i(999, 0))
	launcher_button.add_child(sb)

	l.add_child(launcher_button)
	add_child(l)

func render_table_cards():
	for c in card_root.get_children(): c.queue_free()
	# Mitte
	spawn_card(Vector3(0.0, 0.38, 1.2), top_color)
	# Handkarten
	for i in range(min(8, player_cards)):
		var ox = (i - float(min(8, player_cards) - 1) * 0.5) * 0.6
		var col = Color(0.15, 0.45, 0.9) if i % 2 == 0 else Color(0.95, 0.8, 0.1)
		spawn_card(Vector3(ox, 0.42, 2.4), col)

func spawn_card(pos: Vector3, col: Color):
	var card = MeshInstance3D.new()
	var cm = BoxMesh.new()
	cm.size = Vector3(0.65, 0.02, 0.95)
	card.mesh = cm
	var mat = StandardMaterial3D.new()
	mat.albedo_color = col
	card.material_override = mat
	card.position = pos
	card_root.add_child(card)

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

	var play_btn = Button.new()
	play_btn.text = "🃏 Karte ablegen"
	play_btn.custom_minimum_size = Vector2(0, 44)
	play_btn.pressed.connect(play_card)
	vbox.add_child(play_btn)

	var fire_btn = Button.new()
	fire_btn.text = "🔴 EXTREME Launcher drücken!"
	fire_btn.custom_minimum_size = Vector2(0, 40)
	fire_btn.pressed.connect(press_launcher)
	vbox.add_child(fire_btn)

func handle_tile_clicked(grid_pos: Vector2i):
	if grid_pos.x == 999:
		press_launcher()
	else:
		play_card()

func play_card():
	if player_cards <= 0: return
	player_cards -= 1
	top_color = [Color(0.9, 0.15, 0.15), Color(0.15, 0.45, 0.9), Color(0.15, 0.8, 0.25), Color(0.95, 0.8, 0.1)].pick_random()
	emit_signal("sound_triggered", "card")
	render_table_cards()

	if player_cards == 0:
		emit_signal("sound_triggered", "win")
		emit_signal("status_changed", "GEWONNEN! Alle Extreme-Karten losgeworden!")
	else:
		emit_signal("status_changed", "Karte abgelegt! Verbleibende Handkarten: " + str(player_cards))

func press_launcher():
	emit_signal("sound_triggered", "click")
	var tween = create_tween()
	tween.tween_property(launcher_button, "position:y", 0.68, 0.1)
	tween.tween_property(launcher_button, "position:y", 0.75, 0.1)

	var outcome = randi_range(0, 3)
	if outcome == 0:
		emit_signal("sound_triggered", "move")
		emit_signal("status_changed", "ZISCH! Glück gehabt! Keine Karten ausgeworfen.")
	else:
		emit_signal("sound_triggered", "shoot")
		player_cards += outcome
		render_table_cards()
		emit_signal("status_changed", "BZZT! Der Launcher spuckt " + str(outcome) + " Strafkarten aus! Handkarten: " + str(player_cards))
