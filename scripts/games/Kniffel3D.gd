extends Node3D

class_name Kniffel3D

const TextureHelper = preload("res://scripts/TextureHelper.gd")
const DiceHelper = preload("res://scripts/DiceHelper.gd")

signal status_changed(msg: String)
signal sound_triggered(sound_name: String)

var dice_nodes: Array = []
var dice_values: Array = [1, 2, 3, 4, 5]
var dice_held: Array = [false, false, false, false, false]
var rolls_left: int = 3
var is_rolling: bool = false
var total_score: int = 0
var rounds_played: int = 0

# Kniffel-Kategorien
var scores: Dictionary = {
	"1er": -1, "2er": -1, "3er": -1, "4er": -1, "5er": -1, "6er": -1,
	"3er-Pasch": -1, "4er-Pasch": -1, "Full House": -1,
	"Kl. Straße": -1, "Gr. Straße": -1, "Kniffel": -1, "Chance": -1
}

var ui_layer: CanvasLayer = null
var victory_modal: PanelContainer = null

func _ready():
	setup_stage()
	setup_game_ui()
	reset_game()

func setup_stage():
	# Großer lederner Würfelteller (8.5 Radius mit Holzrahmen)
	var tray_mesh = CylinderMesh.new()
	tray_mesh.top_radius = 6.5
	tray_mesh.bottom_radius = 6.8
	tray_mesh.height = 0.5
	var tray_inst = MeshInstance3D.new()
	tray_inst.mesh = tray_mesh
	tray_inst.material_override = TextureHelper.get_wood_material(Color(0.12, 0.08, 0.04))
	tray_inst.position = Vector3(0, 0.2, 0)
	add_child(tray_inst)

	# Grüner Samtboden
	var felt_mesh = CylinderMesh.new()
	felt_mesh.top_radius = 6.2
	felt_mesh.bottom_radius = 6.2
	felt_mesh.height = 0.52
	var felt_inst = MeshInstance3D.new()
	felt_inst.mesh = felt_mesh
	felt_inst.material_override = TextureHelper.get_grass_material(Color(0.08, 0.35, 0.18))
	felt_inst.position = Vector3(0, 0.22, 0)
	add_child(felt_inst)

	# 5 3D-Würfel
	dice_nodes.clear()
	var coords = [
		Vector3(-3.2, 0.8, 0.0),
		Vector3(-1.6, 0.8, 0.0),
		Vector3(0.0, 0.8, 0.0),
		Vector3(1.6, 0.8, 0.0),
		Vector3(3.2, 0.8, 0.0)
	]

	for i in range(5):
		var die = DiceHelper.create_3d_die(1.15, Color(0.98, 0.98, 0.94))
		die.position = coords[i]
		die.set_meta("die_idx", i)
		die.set_meta("grid_pos", Vector2i(i, 0))
		add_child(die)
		dice_nodes.append(die)

func setup_game_ui():
	ui_layer = CanvasLayer.new()
	add_child(ui_layer)

	var panel = PanelContainer.new()
	panel.anchors_preset = Control.PRESET_BOTTOM_RIGHT
	panel.offset_left = -380
	panel.offset_top = -240
	panel.offset_right = -20
	panel.offset_bottom = -20
	ui_layer.add_child(panel)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	panel.add_child(vbox)

	var info = Label.new()
	info.name = "KniffelInfo"
	info.text = "Kniffel 3D: Noch 3 Würfe | Gesamtpunkte: 0"
	vbox.add_child(info)

	var roll_btn = Button.new()
	roll_btn.name = "RollBtn"
	roll_btn.text = "🎲 5 Würfel rollen (3 übrig)"
	roll_btn.custom_minimum_size = Vector2(0, 46)
	roll_btn.pressed.connect(roll_dice_action)
	vbox.add_child(roll_btn)

	var h_grid = HBoxContainer.new()
	h_grid.add_theme_constant_override("separation", 6)
	vbox.add_child(h_grid)

	for i in range(5):
		var b = Button.new()
		b.text = "W" + str(i + 1)
		b.custom_minimum_size = Vector2(60, 36)
		var d_i = i
		b.pressed.connect(func(): toggle_hold(d_i))
		h_grid.add_child(b)

	var score_btn = Button.new()
	score_btn.name = "ScoreBtn"
	score_btn.text = "✅ Beste Kategorie werten"
	score_btn.custom_minimum_size = Vector2(0, 40)
	score_btn.pressed.connect(auto_score_category)
	vbox.add_child(score_btn)

	# Victory Modal
	victory_modal = PanelContainer.new()
	victory_modal.anchors_preset = Control.PRESET_CENTER
	victory_modal.offset_left = -200
	victory_modal.offset_top = -120
	victory_modal.offset_right = 200
	victory_modal.offset_bottom = 120
	victory_modal.visible = false
	ui_layer.add_child(victory_modal)

	var vm_vbox = VBoxContainer.new()
	vm_vbox.add_theme_constant_override("separation", 10)
	victory_modal.add_child(vm_vbox)

	var vm_title = Label.new()
	vm_title.name = "VictoryTitle"
	vm_title.text = "🏆 SPIEL BEENDET!"
	vm_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vm_vbox.add_child(vm_title)

	var vm_desc = Label.new()
	vm_desc.name = "VictoryDesc"
	vm_desc.text = ""
	vm_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vm_vbox.add_child(vm_desc)

	var vm_btn = Button.new()
	vm_btn.text = "🔄 Neues Kniffel-Spiel"
	vm_btn.custom_minimum_size = Vector2(0, 48)
	vm_btn.pressed.connect(reset_game)
	vm_vbox.add_child(vm_btn)

func reset_game():
	rolls_left = 3
	total_score = 0
	rounds_played = 0
	is_rolling = false
	for k in scores.keys():
		scores[k] = -1

	for i in range(5):
		dice_held[i] = false
		dice_values[i] = i + 1
		DiceHelper.apply_value_rotation(dice_nodes[i], dice_values[i])
		update_die_held_visual(i)

	if victory_modal: victory_modal.visible = false
	update_ui()
	emit_signal("status_changed", "Kniffel 3D: 5 echte 3D-Würfel bereit! Klicke auf Würfel zum Halten/Freigeben.")

func handle_tile_clicked(grid_pos: Vector2i):
	var idx = grid_pos.x
	if idx >= 0 and idx < 5:
		toggle_hold(idx)
	else:
		roll_dice_action()

func toggle_hold(idx: int):
	dice_held[idx] = not dice_held[idx]
	emit_signal("sound_triggered", "click")
	update_die_held_visual(idx)
	var state = "gehalten" if dice_held[idx] else "freigegeben"
	emit_signal("status_changed", "Würfel " + str(idx + 1) + " (" + str(dice_values[idx]) + ") " + state)

func update_die_held_visual(idx: int):
	var die = dice_nodes[idx]
	var cube = die.get_child(0) as MeshInstance3D
	if cube and cube.material_override:
		var mat = cube.material_override as StandardMaterial3D
		if dice_held[idx]:
			mat.albedo_color = Color(0.98, 0.82, 0.2) # Gold
			die.position.y = 1.3 # Erhöht
		else:
			mat.albedo_color = Color(0.98, 0.98, 0.94)
			die.position.y = 0.8

func roll_dice_action():
	if is_rolling: return
	if rolls_left <= 0:
		emit_signal("status_changed", "Keine Würfe mehr frei! Bitte Punkte eintragen.")
		return

	is_rolling = true
	rolls_left -= 1
	emit_signal("sound_triggered", "dice")

	var coords = [
		Vector3(-3.2, 0.8, 0.0),
		Vector3(-1.6, 0.8, 0.0),
		Vector3(0.0, 0.8, 0.0),
		Vector3(1.6, 0.8, 0.0),
		Vector3(3.2, 0.8, 0.0)
	]

	var rolled_count = 0
	for i in range(5):
		if not dice_held[i]:
			rolled_count += 1
			dice_values[i] = randi_range(1, 6)
			DiceHelper.roll_die(dice_nodes[i], dice_values[i], coords[i], 0.5)

	get_tree().create_timer(0.55).timeout.connect(func():
		is_rolling = false
		emit_signal("sound_triggered", "click")
		var sum = 0
		for v in dice_values: sum += v
		emit_signal("status_changed", "Gewürfelt! Augensumme: " + str(sum) + " | Noch " + str(rolls_left) + " Würfe.")
		update_ui()
	)

func auto_score_category():
	if is_rolling: return
	# Suche beste freie Kategorie
	var counts = {}
	var sum = 0
	for v in dice_values:
		counts[v] = counts.get(v, 0) + 1
		sum += v

	var best_cat = ""
	var best_pts = -1

	# Kniffel (50 Pkt)
	if scores["Kniffel"] == -1:
		for c in counts.values():
			if c == 5:
				best_cat = "Kniffel"
				best_pts = 50
				break

	# Full House (25 Pkt)
	if best_cat == "" and scores["Full House"] == -1:
		var has_3 = false
		var has_2 = false
		for c in counts.values():
			if c == 3: has_3 = true
			if c == 2: has_2 = true
		if has_3 and has_2:
			best_cat = "Full House"
			best_pts = 25

	# Große Straße (40 Pkt)
	if best_cat == "" and scores["Gr. Straße"] == -1:
		var s = dice_values.duplicate()
		s.sort()
		if s == [1,2,3,4,5] or s == [2,3,4,5,6]:
			best_cat = "Gr. Straße"
			best_pts = 40

	# 4er-Pasch
	if best_cat == "" and scores["4er-Pasch"] == -1:
		for c in counts.values():
			if c >= 4:
				best_cat = "4er-Pasch"
				best_pts = sum

	# 3er-Pasch
	if best_cat == "" and scores["3er-Pasch"] == -1:
		for c in counts.values():
			if c >= 3:
				best_cat = "3er-Pasch"
				best_pts = sum

	# Ziffern 6 bis 1
	if best_cat == "":
		for num in [6, 5, 4, 3, 2, 1]:
			var key = str(num) + "er"
			if scores[key] == -1 and counts.get(num, 0) > 0:
				best_cat = key
				best_pts = counts[num] * num
				break

	# Chance
	if best_cat == "" and scores["Chance"] == -1:
		best_cat = "Chance"
		best_pts = sum

	# Fallback auf irgendeine freie Kategorie mit 0 Punkten (Streichen)
	if best_cat == "":
		for k in scores.keys():
			if scores[k] == -1:
				best_cat = k
				best_pts = 0
				break

	if best_cat != "":
		scores[best_cat] = best_pts
		total_score += best_pts
		rounds_played += 1
		emit_signal("sound_triggered", "win")
		emit_signal("status_changed", "Kategorie '" + best_cat + "' gewertet mit +" + str(best_pts) + " Punkten!")

		if rounds_played >= 13:
			show_game_over()
		else:
			# Nächste Runde vorbereiten
			rolls_left = 3
			for i in range(5):
				dice_held[i] = false
				update_die_held_visual(i)
			update_ui()

func show_game_over():
	if victory_modal:
		victory_modal.visible = true
		var t_lbl = victory_modal.find_child("VictoryTitle", true, false) as Label
		var d_lbl = victory_modal.find_child("VictoryDesc", true, false) as Label
		if t_lbl: t_lbl.text = "🏆 KNIFFEL ABGESCHLOSSEN!"
		if d_lbl: d_lbl.text = "Alle 13 Runden gespielt!\nEndpunktzahl: " + str(total_score) + " Punkte!"
		emit_signal("status_changed", "Kniffel beendet! Endstand: " + str(total_score) + " Punkte!")

func update_ui():
	var info = ui_layer.get_node_or_null("PanelContainer/VBoxContainer/KniffelInfo") as Label
	if info:
		info.text = "Runde: " + str(rounds_played + 1) + "/13 | Würfe übrig: " + str(rolls_left) + "\nGesamtpunkte: " + str(total_score)

	var btn = ui_layer.get_node_or_null("PanelContainer/VBoxContainer/RollBtn") as Button
	if btn:
		btn.text = "🎲 Würfeln (" + str(rolls_left) + " übrig)"
