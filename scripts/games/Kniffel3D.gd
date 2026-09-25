extends Node3D

class_name Kniffel3D

signal status_changed(msg: String)
signal sound_triggered(sound_name: String)

var dice_nodes: Array = []
var dice_values: Array = [1, 2, 3, 4, 5]
var dice_held: Array = [false, false, false, false, false]
var rolls_left = 3
var total_score = 0

var dice_root: Node3D
var ui_layer: CanvasLayer

func _ready():
	setup_stage()
	setup_game_ui()
	reset_round()

func setup_stage():
	# Lederner 3D-Würfelteller
	var tray_mesh = CylinderMesh.new()
	tray_mesh.top_radius = 4.2
	tray_mesh.bottom_radius = 4.4
	tray_mesh.height = 0.5
	var tray_inst = MeshInstance3D.new()
	tray_inst.mesh = tray_mesh
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.08, 0.28, 0.15)
	mat.roughness = 0.45
	tray_inst.material_override = mat
	tray_inst.position = Vector3(0, 0.2, 0)
	add_child(tray_inst)

	dice_root = Node3D.new()
	dice_root.name = "DiceRoot"
	add_child(dice_root)

	var dice_coords = [
		Vector3(-2.2, 0.55, 0.0),
		Vector3(-1.1, 0.55, 0.0),
		Vector3(0.0, 0.55, 0.0),
		Vector3(1.1, 0.55, 0.0),
		Vector3(2.2, 0.55, 0.0)
	]

	for i in range(5):
		spawn_die(dice_coords[i], i)

func spawn_die(pos: Vector3, index: int):
	var die = Node3D.new()
	die.position = pos
	die.name = "Die_" + str(index)

	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.96, 0.96, 0.94)
	mat.roughness = 0.12
	mat.metallic = 0.05

	var m = BoxMesh.new()
	m.size = Vector3(0.75, 0.75, 0.75)
	var inst = MeshInstance3D.new()
	inst.mesh = m
	inst.material_override = mat
	inst.position = Vector3(0, 0.375, 0)
	die.add_child(inst)

	# StaticBody für 3D Klick zum Behalten / Freigeben
	var sb = StaticBody3D.new()
	var col = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(0.85, 0.85, 0.85)
	col.shape = shape
	sb.add_child(col)
	sb.set_meta("die_index", index)
	sb.set_meta("grid_pos", Vector2i(index, 0))
	die.add_child(sb)

	# Label 3D für Augenzahl
	var lbl = Label3D.new()
	lbl.name = "PipLabel"
	lbl.text = str(dice_values[index])
	lbl.pixel_size = 0.015
	lbl.position = Vector3(0, 0.77, 0)
	lbl.rotation_degrees = Vector3(-90, 0, 0)
	lbl.modulate = Color(0.1, 0.1, 0.1)
	die.add_child(lbl)

	dice_root.add_child(die)
	dice_nodes.append(die)

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
	info.name = "KniffelInfo"
	info.text = "Kniffel 3D: Würfel anklicken um sie zu halten"
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(info)

	var roll_btn = Button.new()
	roll_btn.name = "RollBtn"
	roll_btn.text = "🎲 Würfeln (3 übrig)"
	roll_btn.custom_minimum_size = Vector2(0, 44)
	roll_btn.pressed.connect(roll_dice)
	vbox.add_child(roll_btn)

	var take_btn = Button.new()
	take_btn.name = "TakeBtn"
	take_btn.text = "✅ Punkte werten & Nächste Runde"
	take_btn.custom_minimum_size = Vector2(0, 38)
	take_btn.pressed.connect(score_round)
	vbox.add_child(take_btn)

func handle_tile_clicked(grid_pos: Vector2i):
	var idx = grid_pos.x
	if idx >= 0 and idx < 5:
		toggle_hold(idx)

func toggle_hold(index: int):
	dice_held[index] = not dice_held[index]
	emit_signal("sound_triggered", "click")
	update_dice_visuals()
	var held_str = "gehalten" if dice_held[index] else "freigegeben"
	emit_signal("status_changed", "Würfel " + str(index + 1) + " (" + str(dice_values[index]) + ") " + held_str)

func update_dice_visuals():
	for i in range(5):
		var die = dice_nodes[i]
		var inst = die.get_child(0) as MeshInstance3D
		if inst and inst.material_override:
			var mat = inst.material_override as StandardMaterial3D
			if dice_held[i]:
				mat.albedo_color = Color(0.95, 0.85, 0.2) # Gold für gehalten
				die.position.y = 0.25 # leicht angehoben
			else:
				mat.albedo_color = Color(0.96, 0.96, 0.94)
				die.position.y = 0.0

		var lbl = die.get_node_or_null("PipLabel") as Label3D
		if lbl:
			lbl.text = str(dice_values[i])

func roll_dice():
	if rolls_left <= 0:
		emit_signal("status_changed", "Keine Würfe mehr übrig! Bitte Punkte werten.")
		return

	rolls_left -= 1
	emit_signal("sound_triggered", "dice")

	for i in range(5):
		if not dice_held[i]:
			dice_values[i] = randi_range(1, 6)
			var die = dice_nodes[i]
			# Würfel-Roll-Animation
			var tween = create_tween()
			var target_rot = Vector3(randf_range(-15, 15), randf_range(0, 360), randf_range(-15, 15))
			tween.tween_property(die, "position:y", 0.8, 0.1)
			tween.tween_property(die, "position:y", 0.0, 0.15)
			die.rotation_degrees = target_rot

	update_dice_visuals()

	var btn = ui_layer.get_node_or_null("PanelContainer/VBoxContainer/RollBtn") as Button
	if btn:
		btn.text = "🎲 Würfeln (" + str(rolls_left) + " übrig)"

	var sum = 0
	for v in dice_values: sum += v
	emit_signal("status_changed", "Gewürfelt! Augensumme: " + str(sum) + " | Noch " + str(rolls_left) + " Würfe.")

func score_round():
	var sum = 0
	for v in dice_values: sum += v
	total_score += sum
	emit_signal("sound_triggered", "win")
	emit_signal("status_changed", "Runde gewertet mit +" + str(sum) + " Punkten! Gesamtpunkte: " + str(total_score))
	reset_round()

func reset_round():
	rolls_left = 3
	for i in range(5):
		dice_held[i] = false
	var btn = ui_layer.get_node_or_null("PanelContainer/VBoxContainer/RollBtn") as Button
	if btn:
		btn.text = "🎲 Würfeln (3 übrig)"
	roll_dice()
