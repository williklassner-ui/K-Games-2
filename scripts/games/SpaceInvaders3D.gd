extends Node3D

class_name SpaceInvaders3D

const TextureHelper = preload("res://scripts/TextureHelper.gd")

signal status_changed(msg: String)
signal sound_triggered(sound_name: String)

var cannon_node: Node3D = null
var cannon_pos_x: float = 0.0
var aliens: Array = []
var alien_bombs: Array = []
var player_lasers: Array = []
var bunkers: Array = []

var alien_dir: float = 1.0
var alien_march_timer: float = 0.0
var alien_march_interval: float = 0.7
var alien_bomb_timer: float = 0.0

var score: int = 0
var lives: int = 3
var is_game_over: bool = false

var ui_layer: CanvasLayer = null
var end_modal: PanelContainer = null

func _ready():
	setup_stage()
	setup_game_ui()
	reset_game()

func _process(delta: float):
	if is_game_over: return

	# 1. Alien-Marsch Bewegung
	alien_march_timer += delta
	if alien_march_timer >= alien_march_interval:
		alien_march_timer = 0.0
		march_aliens()

	# 2. Feindliche Alien-Bomben
	alien_bomb_timer += delta
	if alien_bomb_timer >= 1.5:
		alien_bomb_timer = 0.0
		drop_alien_bomb()

	# 3. Projektile bewegen
	move_projectiles(delta)

func setup_stage():
	var floor_m = BoxMesh.new()
	floor_m.size = Vector3(16.0, 0.4, 14.0)
	var fl = MeshInstance3D.new()
	fl.mesh = floor_m
	fl.material_override = TextureHelper.get_metal_material(Color(0.04, 0.05, 0.08), 0.9)
	fl.position = Vector3(0, 0.15, 0)
	add_child(fl)

	# 3D Verteidiger-Kanone
	cannon_pos_x = 0.0
	cannon_node = spawn_cannon(Vector3(cannon_pos_x, 0.4, 5.0))

func spawn_cannon(pos: Vector3) -> Node3D:
	var can = Node3D.new()
	can.position = pos
	var mat = TextureHelper.get_metal_material(Color(0.18, 0.85, 0.35), 0.8)

	var base = MeshInstance3D.new()
	var bm = BoxMesh.new()
	bm.size = Vector3(1.2, 0.35, 0.9)
	base.mesh = bm
	base.material_override = mat
	base.position = Vector3(0, 0.18, 0)
	can.add_child(base)

	var barrel = MeshInstance3D.new()
	var barm = CylinderMesh.new()
	barm.top_radius = 0.1
	barm.bottom_radius = 0.12
	barm.height = 0.65
	barrel.mesh = barm
	barrel.material_override = mat
	barrel.position = Vector3(0, 0.55, 0)
	can.add_child(barrel)

	add_child(can)
	return can

func spawn_alien(pos: Vector3, col: Color) -> Node3D:
	var a = Node3D.new()
	a.position = pos
	var mat = StandardMaterial3D.new()
	mat.albedo_color = col
	mat.emission_enabled = true
	mat.emission = col
	mat.emission_energy_multiplier = 0.6

	var body = MeshInstance3D.new()
	var bm = BoxMesh.new()
	bm.size = Vector3(0.8, 0.45, 0.6)
	body.mesh = bm
	body.material_override = mat
	body.position = Vector3(0, 0.25, 0)
	a.add_child(body)

	for side in [-0.28, 0.28]:
		var eye = MeshInstance3D.new()
		var em = CylinderMesh.new()
		em.top_radius = 0.08
		em.bottom_radius = 0.08
		em.height = 0.3
		eye.mesh = em
		eye.material_override = mat
		eye.position = Vector3(side, 0.5, 0)
		a.add_child(eye)

	add_child(a)
	return a

func spawn_bunkers():
	for b in bunkers:
		if is_instance_valid(b): b.queue_free()
	bunkers.clear()

	for b_idx in range(4):
		var b_pos = Vector3((b_idx - 1.5) * 3.4, 0.4, 3.2)
		var bun = MeshInstance3D.new()
		var bm = BoxMesh.new()
		bm.size = Vector3(1.6, 0.6, 0.8)
		bun.mesh = bm
		var mat = TextureHelper.get_metal_material(Color(0.2, 0.75, 0.85), 0.8)
		bun.material_override = mat
		bun.position = b_pos
		bun.set_meta("hp", 4)
		add_child(bun)
		bunkers.append(bun)

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
	vbox.add_theme_constant_override("separation", 6)
	panel.add_child(vbox)

	var info = Label.new()
	info.name = "InvadersInfo"
	info.text = "Punkte: 0 | Leben: 3"
	vbox.add_child(info)

	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 6)
	vbox.add_child(hbox)

	var btn_left = Button.new()
	btn_left.text = "⬅️ Links"
	btn_left.custom_minimum_size = Vector2(100, 44)
	btn_left.pressed.connect(func(): move_cannon(-0.8))
	hbox.add_child(btn_left)

	var fire_btn = Button.new()
	fire_btn.text = "🚀 Laser"
	fire_btn.custom_minimum_size = Vector2(90, 44)
	fire_btn.pressed.connect(fire_laser)
	hbox.add_child(fire_btn)

	var btn_right = Button.new()
	btn_right.text = "Rechts ➡️"
	btn_right.custom_minimum_size = Vector2(100, 44)
	btn_right.pressed.connect(func(): move_cannon(0.8))
	hbox.add_child(btn_right)

	# End Modal
	end_modal = PanelContainer.new()
	end_modal.anchors_preset = Control.PRESET_CENTER
	end_modal.offset_left = -200
	end_modal.offset_top = -110
	end_modal.offset_right = 200
	end_modal.offset_bottom = 110
	end_modal.visible = false
	ui_layer.add_child(end_modal)

	var em_vbox = VBoxContainer.new()
	em_vbox.add_theme_constant_override("separation", 10)
	end_modal.add_child(em_vbox)

	var em_title = Label.new()
	em_title.name = "EndTitle"
	em_title.text = "🏆 SIEG!"
	em_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	em_vbox.add_child(em_title)

	var em_desc = Label.new()
	em_desc.name = "EndDesc"
	em_desc.text = ""
	em_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	em_vbox.add_child(em_desc)

	var em_btn = Button.new()
	em_btn.text = "🔄 Neues Spiel"
	em_btn.custom_minimum_size = Vector2(0, 46)
	em_btn.pressed.connect(reset_game)
	em_vbox.add_child(em_btn)

func reset_game():
	score = 0
	lives = 3
	is_game_over = false
	alien_dir = 1.0
	alien_march_timer = 0.0
	alien_march_interval = 0.7

	for a in aliens:
		if is_instance_valid(a): a.queue_free()
	aliens.clear()

	for b in alien_bombs:
		if is_instance_valid(b): b.queue_free()
	alien_bombs.clear()

	for l in player_lasers:
		if is_instance_valid(l): l.queue_free()
	player_lasers.clear()

	# 3 Reihen x 6 Spalten Aliens
	for row in range(3):
		for col in range(6):
			var a_pos = Vector3((col - 2.5) * 1.6, 0.45, (row - 3.2) * 1.3)
			var a_col = Color(0.95, 0.2, 0.3) if row == 0 else (Color(0.25, 0.95, 0.4) if row == 1 else Color(0.2, 0.85, 1.0))
			var alien = spawn_alien(a_pos, a_col)
			aliens.append(alien)

	spawn_bunkers()
	cannon_pos_x = 0.0
	if cannon_node: cannon_node.position.x = 0.0

	if end_modal: end_modal.visible = false
	update_ui()
	emit_signal("status_changed", "Space Invaders 3D: Aliens marschieren vor! Steuere mit A/D/Pfeilen und feuere mit Leertaste!")

func _unhandled_key_input(event: InputEvent):
	if is_game_over: return
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_LEFT, KEY_A: move_cannon(-0.8)
			KEY_RIGHT, KEY_D: move_cannon(0.8)
			KEY_SPACE: fire_laser()

func move_cannon(dx: float):
	cannon_pos_x = clamp(cannon_pos_x + dx, -6.5, 6.5)
	if cannon_node: cannon_node.position.x = cannon_pos_x
	emit_signal("sound_triggered", "click")

func march_aliens():
	var hit_edge = false
	for a in aliens:
		if is_instance_valid(a):
			if (a.position.x > 6.2 and alien_dir > 0) or (a.position.x < -6.2 and alien_dir < 0):
				hit_edge = true
				break

	if hit_edge:
		alien_dir = -alien_dir
		for a in aliens:
			if is_instance_valid(a):
				a.position.z += 0.4
				if a.position.z >= 4.5:
					# Invasion erfolgreich -> Niederlage
					show_end_screen(false)
					return
		# Schneller werden
		alien_march_interval = max(0.2, alien_march_interval - 0.04)
	else:
		for a in aliens:
			if is_instance_valid(a):
				a.position.x += alien_dir * 0.4

	emit_signal("sound_triggered", "move")

func drop_alien_bomb():
	if aliens.is_empty(): return
	var shooter = aliens.pick_random()
	if not is_instance_valid(shooter): return

	var bomb = MeshInstance3D.new()
	var sm = SphereMesh.new()
	sm.radius = 0.14
	sm.height = 0.28
	bomb.mesh = sm
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.2, 0.2)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.2, 0.2)
	bomb.material_override = mat
	bomb.position = shooter.position + Vector3(0, 0, 0.4)
	add_child(bomb)
	alien_bombs.append(bomb)

func fire_laser():
	if player_lasers.size() >= 3: return
	emit_signal("sound_triggered", "shoot")

	var laser = MeshInstance3D.new()
	var cm = CylinderMesh.new()
	cm.top_radius = 0.06
	cm.bottom_radius = 0.06
	cm.height = 0.7
	laser.mesh = cm
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.2, 1.0, 0.4)
	mat.emission_enabled = true
	mat.emission = Color(0.2, 1.0, 0.4)
	mat.emission_energy_multiplier = 1.2
	laser.material_override = mat
	laser.position = Vector3(cannon_pos_x, 0.5, 4.2)
	laser.rotation_degrees = Vector3(90, 0, 0)
	add_child(laser)
	player_lasers.append(laser)

func move_projectiles(delta: float):
	# Laser nach vorne
	var lasers_to_remove = []
	for l in player_lasers:
		if is_instance_valid(l):
			l.position.z -= delta * 12.0
			if l.position.z < -6.0:
				lasers_to_remove.append(l)
			else:
				# Trefferprüfung Aliens
				for a in aliens:
					if is_instance_valid(a):
						if l.position.distance_to(a.position) < 0.7:
							aliens.erase(a)
							a.queue_free()
							lasers_to_remove.append(l)
							score += 50
							emit_signal("sound_triggered", "win")
							emit_signal("status_changed", "Alien vernichtet! +50 Punkte!")
							update_ui()
							if aliens.is_empty():
								show_end_screen(true)
							break
	for l in lasers_to_remove:
		if is_instance_valid(l):
			player_lasers.erase(l)
			l.queue_free()

	# Bomben nach hinten
	var bombs_to_remove = []
	for b in alien_bombs:
		if is_instance_valid(b):
			b.position.z += delta * 6.0
			if b.position.z > 6.0:
				bombs_to_remove.append(b)
			elif abs(b.position.x - cannon_pos_x) < 0.7 and b.position.z >= 4.7:
				bombs_to_remove.append(b)
				lives -= 1
				emit_signal("sound_triggered", "shoot")
				emit_signal("status_changed", "⚠️ Kanone getroffen! Leben übrig: " + str(lives))
				update_ui()
				if lives <= 0:
					show_end_screen(false)
	for b in bombs_to_remove:
		if is_instance_valid(b):
			alien_bombs.erase(b)
			b.queue_free()

func show_end_screen(won: bool):
	is_game_over = true
	if end_modal:
		end_modal.visible = true
		var t_lbl = end_modal.find_child("EndTitle", true, false) as Label
		var d_lbl = end_modal.find_child("EndDesc", true, false) as Label
		if won:
			emit_signal("sound_triggered", "win")
			if t_lbl: t_lbl.text = "🏆 SIEG - ERDE GERETTET!"
			if d_lbl: d_lbl.text = "Alle Alien-Invasoren vernichtet!\nScore: " + str(score) + " Punkte!"
		else:
			emit_signal("sound_triggered", "shoot")
			if t_lbl: t_lbl.text = "💀 INVASION ERFOLGREICH!"
			if d_lbl: d_lbl.text = "Deine Verteidigungskanone wurde zerstört!\nScore: " + str(score)

func update_ui():
	var lbl = ui_layer.get_node_or_null("PanelContainer/VBoxContainer/InvadersInfo") as Label
	if lbl:
		lbl.text = "Punkte: " + str(score) + " | Leben: " + str(lives) + " | Aliens: " + str(aliens.size())
