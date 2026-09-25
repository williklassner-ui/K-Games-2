extends Node3D

class_name Risiko3D

signal status_changed(msg: String)
signal sound_triggered(sound_name: String)

var territories: Array = []
var player_armies = 20
var selected_index = 0
var ui_layer: CanvasLayer

func _ready():
	setup_stage()
	setup_game_ui()
	emit_signal("status_changed", "Risiko 3D: Wähle einen Kontinenten zum Verstärken oder Angreifen!")

func setup_stage():
	# Weltkarten-Sockel
	var map_mesh = BoxMesh.new()
	map_mesh.size = Vector3(13.0, 0.4, 8.5)
	var map_inst = MeshInstance3D.new()
	map_inst.mesh = map_mesh
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.08, 0.16, 0.24)
	mat.roughness = 0.4
	map_inst.material_override = mat
	map_inst.position = Vector3(0, 0.15, 0)
	add_child(map_inst)

	territories = [
		{"name": "Nordamerika", "pos": Vector3(-4.0, 0.38, -1.8), "size": Vector3(3.2, 0.15, 2.5), "col": Color(0.85, 0.75, 0.25), "owner": "player", "armies": 5},
		{"name": "Südamerika", "pos": Vector3(-3.2, 0.38, 1.8), "size": Vector3(2.0, 0.15, 2.8), "col": Color(0.82, 0.38, 0.15), "owner": "enemy", "armies": 3},
		{"name": "Europa", "pos": Vector3(0.2, 0.38, -2.0), "size": Vector3(2.4, 0.15, 1.8), "col": Color(0.22, 0.55, 0.85), "owner": "player", "armies": 4},
		{"name": "Afrika", "pos": Vector3(0.3, 0.38, 1.2), "size": Vector3(2.6, 0.15, 2.8), "col": Color(0.75, 0.65, 0.2), "owner": "enemy", "armies": 4},
		{"name": "Asien", "pos": Vector3(3.8, 0.38, -1.5), "size": Vector3(4.2, 0.15, 3.2), "col": Color(0.25, 0.75, 0.4), "owner": "enemy", "armies": 6},
		{"name": "Australien", "pos": Vector3(4.2, 0.38, 2.2), "size": Vector3(2.2, 0.15, 1.8), "col": Color(0.65, 0.3, 0.75), "owner": "player", "armies": 3}
	]

	for i in range(territories.size()):
		var c = territories[i]
		var c_mesh = BoxMesh.new()
		c_mesh.size = c.size
		var c_inst = MeshInstance3D.new()
		c_inst.mesh = c_mesh
		
		var c_mat = StandardMaterial3D.new()
		c_mat.albedo_color = c.col
		c_mat.roughness = 0.35
		c_inst.material_override = c_mat
		c_inst.position = c.pos

		# 3D Klick-StaticBody
		var sb = StaticBody3D.new()
		var col = CollisionShape3D.new()
		var shape = BoxShape3D.new()
		shape.size = c.size + Vector3(0.2, 0.3, 0.2)
		col.shape = shape
		sb.add_child(col)
		sb.set_meta("grid_pos", Vector2i(i, 0))
		c_inst.add_child(sb)

		# 3D Text Label für Armeen
		var lbl = Label3D.new()
		lbl.name = "ArmyLabel"
		lbl.text = c.name + "\n" + ("(Du) " if c.owner == "player" else "(Gegner) ") + str(c.armies) + " ⚔️"
		lbl.pixel_size = 0.012
		lbl.position = Vector3(0, 0.5, 0)
		lbl.rotation_degrees = Vector3(-50, 0, 0)
		c_inst.add_child(lbl)

		add_child(c_inst)
		c["node"] = c_inst

func setup_game_ui():
	ui_layer = CanvasLayer.new()
	add_child(ui_layer)

	var panel = PanelContainer.new()
	panel.anchors_preset = Control.PRESET_BOTTOM_RIGHT
	panel.offset_left = -320
	panel.offset_top = -150
	panel.offset_right = -20
	panel.offset_bottom = -20
	ui_layer.add_child(panel)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	panel.add_child(vbox)

	var attack_btn = Button.new()
	attack_btn.text = "⚔️ Angriff würfeln (Attacke)"
	attack_btn.custom_minimum_size = Vector2(0, 44)
	attack_btn.pressed.connect(attack_territory)
	vbox.add_child(attack_btn)

	var recruit_btn = Button.new()
	recruit_btn.text = "🛡️ Verstärkung anfordern (+3 Armeen)"
	recruit_btn.custom_minimum_size = Vector2(0, 40)
	recruit_btn.pressed.connect(recruit_armies)
	vbox.add_child(recruit_btn)

func handle_tile_clicked(grid_pos: Vector2i):
	var idx = grid_pos.x
	if idx >= 0 and idx < territories.size():
		selected_index = idx
		var t = territories[idx]
		emit_signal("sound_triggered", "select")
		emit_signal("status_changed", t.name + " ausgewählt! Besitzer: " + t.owner + " | Armeen: " + str(t.armies))

func attack_territory():
	var t = territories[selected_index]
	if t.owner == "player":
		emit_signal("status_changed", "Wähle einen feindlichen Kontinenten zum Angreifen aus!")
		return

	emit_signal("sound_triggered", "dice")
	var p_roll = randi_range(1, 6) + randi_range(1, 6)
	var e_roll = randi_range(1, 6) + randi_range(1, 6)

	if p_roll > e_roll:
		t.armies = max(1, t.armies - 2)
		emit_signal("sound_triggered", "win")
		if t.armies <= 1:
			t.owner = "player"
			t.armies = 3
			emit_signal("status_changed", "KONTINENT EROBERT! " + t.name + " gehört nun dir!")
		else:
			emit_signal("status_changed", "Sieg im Gefecht! (" + str(p_roll) + " vs " + str(e_roll) + ") Feind verliert 2 Armeen!")
	else:
		emit_signal("sound_triggered", "shoot")
		emit_signal("status_changed", "Angriff abgewehrt! (" + str(p_roll) + " vs " + str(e_roll) + ") Du hast Truppen verloren.")

	update_labels()

func recruit_armies():
	var t = territories[selected_index]
	if t.owner != "player":
		emit_signal("status_changed", "Du kannst nur eigene Territorien verstärken!")
		return
	t.armies += 3
	emit_signal("sound_triggered", "move")
	emit_signal("status_changed", t.name + " mit +3 Armeen verstärkt! Jetzt: " + str(t.armies))
	update_labels()

func update_labels():
	for t in territories:
		var lbl = t.node.get_node_or_null("ArmyLabel") as Label3D
		if lbl:
			lbl.text = t.name + "\n" + ("(Du) " if t.owner == "player" else "(Gegner) ") + str(t.armies) + " ⚔️"
