extends Node3D

class_name Ra23D

const TextureHelper = preload("res://scripts/TextureHelper.gd")

signal status_changed(msg: String)
signal sound_triggered(sound_name: String)

var credits: int = 1500
var player_tanks: int = 3
var soviet_tanks: int = 3
var soviet_base_hp: int = 100
var allied_base_hp: int = 100
var is_bot_opponent: bool = true

var units: Array = []
var buildings: Array = []
var tesla_light: OmniLight3D = null
var tesla_coil_node: Node3D = null
var miner_node: Node3D = null
var is_attacking: bool = false

var ui_layer: CanvasLayer = null
var end_modal: PanelContainer = null

func _ready():
	setup_stage()
	setup_game_ui()
	reset_game()

func setup_stage():
	# 1. Großes Schlachtfeld mit Tundra- & Fels-Terrain (30x18)
	var ground_mesh = BoxMesh.new()
	ground_mesh.size = Vector3(30.0, 0.45, 18.0)
	var ground = MeshInstance3D.new()
	ground.mesh = ground_mesh
	ground.material_override = TextureHelper.get_stone_material(Color(0.24, 0.22, 0.19))
	ground.position = Vector3(0, 0.2, 0)
	add_child(ground)

	# 2. Alliierte Basis (Westen)
	spawn_building(Vector3(-10.5, 0.45, -4.5), Vector3(3.2, 1.4, 2.6), Color(0.18, 0.42, 0.88), "Allied Bauhof", 0)
	spawn_building(Vector3(-7.0, 0.45, -5.0), Vector3(2.2, 1.0, 1.8), Color(0.2, 0.5, 0.9), "Kaserne", 1)
	spawn_building(Vector3(-11.0, 0.45, -1.0), Vector3(2.8, 1.2, 2.2), Color(0.18, 0.45, 0.85), "Erz-Raffinerie", 2)
	spawn_building(Vector3(-7.5, 0.45, -1.5), Vector3(2.6, 1.3, 2.2), Color(0.2, 0.45, 0.85), "Waffenfabrik", 3)
	spawn_prism_tower(Vector3(-4.5, 0.45, 1.8))

	# 3. Sowjetische Basis (Osten)
	spawn_building(Vector3(10.5, 0.45, 4.5), Vector3(3.2, 1.4, 2.6), Color(0.85, 0.2, 0.2), "Sowjet Bauhof", 4)
	spawn_building(Vector3(7.0, 0.45, 5.0), Vector3(2.2, 1.0, 1.8), Color(0.88, 0.22, 0.22), "Sowjet Kaserne", 5)
	spawn_building(Vector3(11.0, 0.45, 1.0), Vector3(2.8, 1.2, 2.2), Color(0.85, 0.2, 0.2), "Sowjet Raffinerie", 6)
	spawn_building(Vector3(7.5, 0.45, 1.5), Vector3(2.6, 1.3, 2.2), Color(0.85, 0.2, 0.2), "Sowjet Waffenfabrik", 7)
	spawn_tesla_coil(Vector3(4.5, 0.45, -1.8))

	# 4. Zentrales Tiberium- / Erz-Feld
	for i in range(24):
		var crystal = MeshInstance3D.new()
		var p = PrismMesh.new()
		p.size = Vector3(0.45, 0.75, 0.45)
		crystal.mesh = p
		var c_mat = TextureHelper.get_metal_material(Color(0.98, 0.82, 0.1), 0.9)
		c_mat.emission_enabled = true
		c_mat.emission = Color(0.98, 0.8, 0.1)
		c_mat.emission_energy_multiplier = 0.8
		crystal.material_override = c_mat
		crystal.position = Vector3(randf_range(-3.0, 3.0), 0.55, randf_range(-4.5, 4.5))
		add_child(crystal)

	# 5. Chrono-Miner Erntemaschine
	miner_node = spawn_harvester(Vector3(-9.0, 0.48, -1.0))

	# 6. Panzer-Einheiten spawnen
	spawn_initial_tanks()

func spawn_initial_tanks():
	for u in units:
		if is_instance_valid(u.node): u.node.queue_free()
	units.clear()

	for i in range(player_tanks):
		var p = spawn_tank(Vector3(-4.0, 0.48, -3.0 + i * 1.6), Color(0.2, 0.5, 0.95), false, 100 + i)
		units.append({"id": 100 + i, "is_enemy": false, "node": p})

	for i in range(soviet_tanks):
		var p = spawn_tank(Vector3(4.0, 0.48, 3.0 - i * 1.6), Color(0.92, 0.22, 0.22), true, 200 + i)
		units.append({"id": 200 + i, "is_enemy": true, "node": p})

func spawn_building(pos: Vector3, size: Vector3, col: Color, b_name: String, b_id: int):
	var b = Node3D.new()
	b.position = pos
	var m = BoxMesh.new()
	m.size = size
	var inst = MeshInstance3D.new()
	inst.mesh = m
	inst.material_override = TextureHelper.get_metal_material(col, 0.85)
	inst.position = Vector3(0, size.y * 0.5, 0)
	b.add_child(inst)

	var sb = StaticBody3D.new()
	var col_shape = CollisionShape3D.new()
	var b_shape = BoxShape3D.new()
	b_shape.size = size + Vector3(0.4, 0.6, 0.4)
	col_shape.shape = b_shape
	sb.add_child(col_shape)
	sb.set_meta("grid_pos", Vector2i(b_id, 0))
	b.add_child(sb)

	var lbl = Label3D.new()
	lbl.text = "🏭 " + b_name
	lbl.pixel_size = 0.012
	lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lbl.position = Vector3(0, size.y + 0.4, 0)
	lbl.outline_size = 4
	b.add_child(lbl)

	add_child(b)
	buildings.append({"name": b_name, "pos": pos, "node": b})

func spawn_prism_tower(pos: Vector3):
	var tower = Node3D.new()
	tower.position = pos
	var mat = TextureHelper.get_metal_material(Color(0.2, 0.5, 0.95), 0.85)

	var base = MeshInstance3D.new()
	var bm = CylinderMesh.new()
	bm.top_radius = 0.28
	bm.bottom_radius = 0.45
	bm.height = 1.6
	base.mesh = bm
	base.material_override = mat
	base.position = Vector3(0, 0.8, 0)
	tower.add_child(base)

	var prism = MeshInstance3D.new()
	var pm = PrismMesh.new()
	pm.size = Vector3(0.6, 0.7, 0.6)
	prism.mesh = pm
	var pmat = TextureHelper.get_marble_material(Color(0.4, 0.85, 1.0))
	pmat.emission_enabled = true
	pmat.emission = Color(0.4, 0.85, 1.0)
	pmat.emission_energy_multiplier = 1.8
	prism.material_override = pmat
	prism.position = Vector3(0, 1.8, 0)
	tower.add_child(prism)
	add_child(tower)

func spawn_tesla_coil(pos: Vector3):
	tesla_coil_node = Node3D.new()
	tesla_coil_node.position = pos
	var mat = TextureHelper.get_metal_material(Color(0.85, 0.2, 0.2), 0.85)

	var base = MeshInstance3D.new()
	var bm = CylinderMesh.new()
	bm.top_radius = 0.28
	bm.bottom_radius = 0.48
	bm.height = 1.6
	base.mesh = bm
	base.material_override = mat
	base.position = Vector3(0, 0.8, 0)
	tesla_coil_node.add_child(base)

	var sphere = MeshInstance3D.new()
	var sm = SphereMesh.new()
	sm.radius = 0.35
	sm.height = 0.55
	sphere.mesh = sm
	var smat = TextureHelper.get_metal_material(Color(0.3, 0.8, 1.0), 0.9)
	smat.emission_enabled = true
	smat.emission = Color(0.3, 0.8, 1.0)
	smat.emission_energy_multiplier = 2.5
	sphere.material_override = smat
	sphere.position = Vector3(0, 1.7, 0)
	tesla_coil_node.add_child(sphere)

	tesla_light = OmniLight3D.new()
	tesla_light.light_color = Color(0.3, 0.8, 1.0)
	tesla_light.light_energy = 0.0
	tesla_light.omni_range = 8.0
	sphere.add_child(tesla_light)
	add_child(tesla_coil_node)

func spawn_tank(pos: Vector3, col: Color, is_heavy: bool, u_id: int) -> Node3D:
	var tank = Node3D.new()
	tank.position = pos
	var mat = TextureHelper.get_metal_material(col, 0.85)

	var l = 1.4 if is_heavy else 1.1
	var w = 0.9 if is_heavy else 0.7
	var hull = MeshInstance3D.new()
	var hm = BoxMesh.new()
	hm.size = Vector3(l, 0.35, w)
	hull.mesh = hm
	hull.material_override = mat
	hull.position = Vector3(0, 0.2, 0)
	tank.add_child(hull)

	var turret = MeshInstance3D.new()
	var tm = CylinderMesh.new()
	tm.top_radius = 0.3 if is_heavy else 0.24
	tm.bottom_radius = 0.34 if is_heavy else 0.28
	tm.height = 0.25
	turret.mesh = tm
	turret.material_override = mat
	turret.position = Vector3(0, 0.44, 0)
	tank.add_child(turret)

	var barrel = MeshInstance3D.new()
	var barm = CylinderMesh.new()
	barm.top_radius = 0.06
	barm.bottom_radius = 0.06
	barm.height = 0.85 if is_heavy else 0.7
	barrel.mesh = barm
	barrel.material_override = mat
	barrel.rotation_degrees = Vector3(0, 0, 90)
	barrel.position = Vector3(0.55 if not is_heavy else -0.55, 0.44, 0)
	tank.add_child(barrel)

	var sb = StaticBody3D.new()
	var col_shape = CollisionShape3D.new()
	var b_shape = BoxShape3D.new()
	b_shape.size = Vector3(l + 0.4, 0.9, w + 0.4)
	col_shape.shape = b_shape
	sb.add_child(col_shape)
	sb.set_meta("grid_pos", Vector2i(u_id, 0))
	tank.add_child(sb)

	add_child(tank)
	return tank

func spawn_harvester(pos: Vector3) -> Node3D:
	var h = Node3D.new()
	h.position = pos
	var mat = TextureHelper.get_metal_material(Color(0.85, 0.7, 0.15), 0.8)

	var body = MeshInstance3D.new()
	var bm = BoxMesh.new()
	bm.size = Vector3(1.5, 0.5, 0.9)
	body.mesh = bm
	body.material_override = mat
	body.position = Vector3(0, 0.25, 0)
	h.add_child(body)
	add_child(h)
	return h

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
	info.name = "Ra2Info"
	info.text = "Credits: $1500 | Grizzly-Panzer: 3 | Sowjet-Panzer: 3\nSowjet-Basis: 100% | Eigene Basis: 100%"
	vbox.add_child(info)

	var tank_btn = Button.new()
	tank_btn.text = "🛡️ Grizzly-Panzer bauen ($500)"
	tank_btn.custom_minimum_size = Vector2(0, 42)
	tank_btn.pressed.connect(build_tank)
	vbox.add_child(tank_btn)

	var attack_btn = Button.new()
	attack_btn.text = "⚔️ Panzer-Vorstoß auf Sowjetbasis!"
	attack_btn.custom_minimum_size = Vector2(0, 42)
	attack_btn.pressed.connect(attack_soviet_base)
	vbox.add_child(attack_btn)

	var harvest_btn = Button.new()
	harvest_btn.text = "💰 Chrono-Miner Erzeinsatz (+400)"
	harvest_btn.custom_minimum_size = Vector2(0, 38)
	harvest_btn.pressed.connect(harvest_ore)
	vbox.add_child(harvest_btn)

	# End Modal
	end_modal = PanelContainer.new()
	end_modal.anchors_preset = Control.PRESET_CENTER
	end_modal.offset_left = -220
	end_modal.offset_top = -120
	end_modal.offset_right = 220
	end_modal.offset_bottom = 120
	end_modal.visible = false
	ui_layer.add_child(end_modal)

	var em_vbox = VBoxContainer.new()
	em_vbox.add_theme_constant_override("separation", 10)
	end_modal.add_child(em_vbox)

	var em_title = Label.new()
	em_title.name = "EndTitle"
	em_title.text = "🏆 ALLIIERTER SIEG!"
	em_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	em_vbox.add_child(em_title)

	var em_desc = Label.new()
	em_desc.name = "EndDesc"
	em_desc.text = ""
	em_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	em_vbox.add_child(em_desc)

	var em_btn = Button.new()
	em_btn.text = "🔄 Neues Gefecht"
	em_btn.custom_minimum_size = Vector2(0, 48)
	em_btn.pressed.connect(reset_game)
	em_vbox.add_child(em_btn)

func reset_game():
	credits = 1500
	player_tanks = 3
	soviet_tanks = 3
	soviet_base_hp = 100
	allied_base_hp = 100
	is_attacking = false

	if end_modal: end_modal.visible = false
	spawn_initial_tanks()
	update_ui()
	emit_signal("status_changed", "C&C Alarmstufe Rot 2 3D: Basis bereit! Baue Einheiten und führe Panzerangriffe durch.")

func handle_tile_clicked(grid_pos: Vector2i):
	emit_signal("sound_triggered", "select")
	var id = grid_pos.x
	if id >= 100:
		emit_signal("status_changed", "Panzer-Bataillon ausgewählt! Bereit für Vorstoßbefehl.")
	else:
		emit_signal("status_changed", "Basis-Gebäude angewählt! Alle Systeme einsatzbereit.")

func build_tank():
	if credits < 500:
		emit_signal("status_changed", "Nicht genug Credits ($500 benötigt)!")
		return
	credits -= 500
	player_tanks += 1
	var spawn_pos = Vector3(-4.0, 0.48, -3.0 + player_tanks * 1.2)
	var t = spawn_tank(spawn_pos, Color(0.2, 0.5, 0.95), false, 100 + player_tanks)
	units.append({"id": 100 + player_tanks, "is_enemy": false, "node": t})
	emit_signal("sound_triggered", "win")
	emit_signal("status_changed", "🛡️ Grizzly-Panzer fertiggestellt und einsatzbereit!")
	update_ui()

func harvest_ore():
	if not miner_node: return
	emit_signal("sound_triggered", "move")
	emit_signal("status_changed", "💰 Chrono-Miner fährt zum Erzfeld...")

	# Miner fährt zum Feld
	var tween = create_tween()
	tween.tween_property(miner_node, "position", Vector3(0, 0.48, 0), 0.6)
	tween.tween_interval(0.4)
	tween.tween_property(miner_node, "position", Vector3(-9.0, 0.48, -1.0), 0.6)
	tween.tween_callback(func():
		credits += 400
		emit_signal("sound_triggered", "win")
		emit_signal("status_changed", "💰 Erz abgeliefert! +400 Credits gebunkert!")
		update_ui()
	)

func attack_soviet_base():
	if is_attacking: return
	if player_tanks <= 0:
		emit_signal("status_changed", "Keine Grizzly-Panzer verfügbar!")
		return

	is_attacking = true
	emit_signal("sound_triggered", "shoot")
	emit_signal("status_changed", "⚔️ Panzerdivision rückt vor auf die sowjetische Basis!")

	# Panzer fahren vorwärts
	for u in units:
		if not u.is_enemy and is_instance_valid(u.node):
			var tw = create_tween()
			tw.tween_property(u.node, "position:x", u.node.position.x + 4.5, 0.5)

	get_tree().create_timer(0.6).timeout.connect(func():
		# Mündungsfeuer & Explosionen bei Feindbasis
		spawn_battle_effects(Vector3(7.5, 0.8, 1.5))
		emit_signal("sound_triggered", "shoot")

		var dmg = player_tanks * 20 + randi_range(10, 20)
		soviet_base_hp = max(0, soviet_base_hp - dmg)

		# Tesla-Spulen Gegenschlag!
		fire_tesla_strike()

		get_tree().create_timer(0.6).timeout.connect(func():
			# Panzer zurückziehen
			for u in units:
				if not u.is_enemy and is_instance_valid(u.node):
					var tw = create_tween()
					tw.tween_property(u.node, "position:x", u.node.position.x - 4.5, 0.5)

			is_attacking = false
			check_combat_outcome(dmg)
		)
	)

func fire_tesla_strike():
	if tesla_light:
		var lt = create_tween()
		lt.tween_property(tesla_light, "light_energy", 6.0, 0.1)
		lt.tween_property(tesla_light, "light_energy", 0.0, 0.3)

	emit_signal("sound_triggered", "shoot")
	# Wenn Feind noch Verteidigung hat, verliert Spieler einen Panzer
	if randf() > 0.4 and player_tanks > 1:
		player_tanks -= 1
		for u in units:
			if not u.is_enemy and is_instance_valid(u.node):
				spawn_battle_effects(u.node.position)
				u.node.queue_free()
				units.erase(u)
				break
		emit_signal("status_changed", "⚡ TESLA-BLITZ! Ein eigener Grizzly-Panzer wurde vernichtet!")

func spawn_battle_effects(pos: Vector3):
	var fx = Node3D.new()
	fx.position = pos
	add_child(fx)

	var light = OmniLight3D.new()
	light.light_color = Color(1.0, 0.6, 0.1)
	light.light_energy = 5.0
	light.omni_range = 4.0
	fx.add_child(light)

	var p_mesh = SphereMesh.new()
	p_mesh.radius = 0.5
	p_mesh.height = 1.0
	var p = MeshInstance3D.new()
	p.mesh = p_mesh
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.4, 0.05)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.4, 0.05)
	mat.emission_energy_multiplier = 2.0
	p.material_override = mat
	fx.add_child(p)

	var tw = create_tween()
	tw.tween_property(p, "scale", Vector3(2.5, 2.5, 2.5), 0.35)
	tw.parallel().tween_property(light, "light_energy", 0.0, 0.35)
	tw.tween_callback(fx.queue_free)

func check_combat_outcome(dmg: int):
	if soviet_base_hp <= 0:
		emit_signal("sound_triggered", "win")
		if end_modal:
			end_modal.visible = true
			var t_lbl = end_modal.find_child("EndTitle", true, false) as Label
			var d_lbl = end_modal.find_child("EndDesc", true, false) as Label
			if t_lbl: t_lbl.text = "🏆 ALLIIERTER SIEG!"
			if d_lbl: d_lbl.text = "Die sowjetische Hauptbasis wurde vollständig vernichtet!"
			emit_signal("status_changed", "🏆 SOWJETBASIS VERNICHTET! Glorreicher Sieg für die Alliierten!")
	else:
		emit_signal("status_changed", "💥 Einschlag auf Feindbasis! " + str(dmg) + "% Schaden (Rest-Zustand: " + str(soviet_base_hp) + "%).")

	update_ui()

func update_ui():
	var lbl = ui_layer.get_node_or_null("PanelContainer/VBoxContainer/Ra2Info") as Label
	if lbl:
		lbl.text = "Credits: $" + str(credits) + " | Grizzly-Panzer: " + str(player_tanks) + " | Sowjet-Panzer: " + str(soviet_tanks) + "\nSowjet-Basis: " + str(soviet_base_hp) + "% | Eigene Basis: " + str(allied_base_hp) + "%"
