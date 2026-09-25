extends Node3D

class_name SpaceInvaders3D

signal status_changed(msg: String)
signal sound_triggered(sound_name: String)

var cannon_node: Node3D = null
var cannon_pos_x: float = 0.0
var aliens: Array = []
var score = 0
var ui_layer: CanvasLayer

func _ready():
	setup_stage()
	setup_game_ui()
	emit_signal("status_changed", "Space Invaders 3D: Steuere die Kanone (Links/Rechts) und feuere Laser!")

func setup_stage():
	var floor_m = BoxMesh.new()
	floor_m.size = Vector3(12.0, 0.4, 9.0)
	var fl = MeshInstance3D.new()
	fl.mesh = floor_m
	var f_mat = StandardMaterial3D.new()
	f_mat.albedo_color = Color(0.04, 0.05, 0.08)
	fl.material_override = f_mat
	fl.position = Vector3(0, 0.15, 0)
	add_child(fl)

	# 3D-Aliens in Staffeln (3 Reihen x 6 Spalten)
	aliens.clear()
	for row in range(3):
		for col in range(6):
			var a_pos = Vector3((col - 2.5) * 1.3, 0.45, (row - 2.5) * 1.1)
			var a_col = Color(0.9, 0.2, 0.3) if row == 0 else (Color(0.2, 0.9, 0.4) if row == 1 else Color(0.2, 0.8, 1.0))
			var alien = spawn_alien(a_pos, a_col)
			aliens.append(alien)

	# 3D Verteidiger-Kanone
	cannon_pos_x = 0.0
	cannon_node = spawn_cannon(Vector3(cannon_pos_x, 0.4, 3.2))

	# Schutzbunker
	for b in range(4):
		var b_pos = Vector3((b - 1.5) * 2.5, 0.4, 2.0)
		spawn_bunker(b_pos)

func spawn_alien(pos: Vector3, col: Color) -> Node3D:
	var a = Node3D.new()
	a.position = pos
	var mat = StandardMaterial3D.new()
	mat.albedo_color = col
	mat.emission_enabled = true
	mat.emission = col
	mat.emission_energy_multiplier = 0.5

	var body = MeshInstance3D.new()
	var bm = BoxMesh.new()
	bm.size = Vector3(0.6, 0.35, 0.5)
	body.mesh = bm
	body.material_override = mat
	body.position = Vector3(0, 0.2, 0)
	a.add_child(body)

	for side in [-0.22, 0.22]:
		var eye = MeshInstance3D.new()
		var em = CylinderMesh.new()
		em.top_radius = 0.06
		em.bottom_radius = 0.06
		em.height = 0.25
		eye.mesh = em
		eye.material_override = mat
		eye.position = Vector3(side, 0.4, 0)
		a.add_child(eye)

	add_child(a)
	return a

func spawn_cannon(pos: Vector3) -> Node3D:
	var can = Node3D.new()
	can.position = pos
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.15, 0.85, 0.35)
	mat.metallic = 0.7

	var base = MeshInstance3D.new()
	var bm = BoxMesh.new()
	bm.size = Vector3(0.9, 0.3, 0.7)
	base.mesh = bm
	base.material_override = mat
	base.position = Vector3(0, 0.15, 0)
	can.add_child(base)

	var barrel = MeshInstance3D.new()
	var barm = CylinderMesh.new()
	barm.top_radius = 0.08
	barm.bottom_radius = 0.1
	barm.height = 0.5
	barrel.mesh = barm
	barrel.material_override = mat
	barrel.position = Vector3(0, 0.45, 0)
	can.add_child(barrel)

	add_child(can)
	return can

func spawn_bunker(pos: Vector3):
	var bun = MeshInstance3D.new()
	var bm = PrismMesh.new()
	bm.size = Vector3(1.1, 0.5, 0.6)
	bun.mesh = bm
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.2, 0.7, 0.8)
	bun.material_override = mat
	bun.position = pos + Vector3(0, 0.25, 0)
	add_child(bun)

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

	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 8)
	vbox.add_child(hbox)

	var btn_left = Button.new()
	btn_left.text = "⬅️ Kanone Links"
	btn_left.custom_minimum_size = Vector2(130, 42)
	btn_left.pressed.connect(func(): move_cannon(-0.6))
	hbox.add_child(btn_left)

	var btn_right = Button.new()
	btn_right.text = "Kanone Rechts ➡️"
	btn_right.custom_minimum_size = Vector2(130, 42)
	btn_right.pressed.connect(func(): move_cannon(0.6))
	hbox.add_child(btn_right)

	var fire_btn = Button.new()
	fire_btn.text = "🚀 Laser abfeuern!"
	fire_btn.custom_minimum_size = Vector2(0, 44)
	fire_btn.pressed.connect(fire_laser)
	vbox.add_child(fire_btn)

func move_cannon(dx: float):
	cannon_pos_x = clamp(cannon_pos_x + dx, -4.5, 4.5)
	if cannon_node:
		cannon_node.position.x = cannon_pos_x
	emit_signal("sound_triggered", "click")

func fire_laser():
	emit_signal("sound_triggered", "shoot")

	# Laser Projektil
	var laser = MeshInstance3D.new()
	var lm = CylinderMesh.new()
	lm.top_radius = 0.05
	lm.bottom_radius = 0.05
	lm.height = 0.6
	laser.mesh = lm
	var l_mat = StandardMaterial3D.new()
	l_mat.albedo_color = Color(0.2, 1.0, 0.4)
	l_mat.emission_enabled = true
	l_mat.emission = Color(0.2, 1.0, 0.4)
	l_mat.emission_energy_multiplier = 1.0
	laser.material_override = l_mat
	laser.position = Vector3(cannon_pos_x, 0.5, 2.7)
	laser.rotation_degrees = Vector3(90, 0, 0)
	add_child(laser)

	var tween = create_tween()
	tween.tween_property(laser, "position:z", -4.0, 0.3)
	tween.tween_callback(func():
		laser.queue_free()
		check_laser_hit()
	)

func check_laser_hit():
	# Treffer-Prüfung gegen Aliens
	var hit_alien = null
	for a in aliens:
		if is_instance_valid(a):
			if abs(a.position.x - cannon_pos_x) < 0.8:
				hit_alien = a
				break

	if hit_alien:
		aliens.erase(hit_alien)
		hit_alien.queue_free()
		score += 50
		emit_signal("sound_triggered", "win")
		emit_signal("status_changed", "TREFFER! Alien zerstört! +50 Punkte | Score: " + str(score) + " | Verbleibend: " + str(aliens.size()))
		if aliens.is_empty():
			emit_signal("status_changed", "GLÜCKWUNSCH! Alle Alien-Invasoren vernichtet!")
	else:
		emit_signal("status_changed", "Schuss verfehlt! Justiere die Kanone und feuere erneut.")
