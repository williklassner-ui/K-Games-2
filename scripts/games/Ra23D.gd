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
var ui_layer: CanvasLayer = null

func _ready():
	setup_stage()
	setup_game_ui()
	emit_signal("status_changed", "C&C Alarmstufe Rot 2 3D: Basis bereit! Baue Panzerdivisionen und zerstöre die sowjetische Basis!")

func setup_stage():
	# 1. Großes Schlachtfeld mit Tundra- & Fels-Terrain (22x14)
	var ground_mesh = BoxMesh.new()
	ground_mesh.size = Vector3(22.0, 0.45, 14.0)
	var ground = MeshInstance3D.new()
	ground.mesh = ground_mesh
	ground.material_override = TextureHelper.get_stone_material(Color(0.24, 0.22, 0.19))
	ground.position = Vector3(0, 0.2, 0)
	add_child(ground)

	# 2. Alliierte Basis (Westen)
	spawn_building(Vector3(-7.5, 0.45, -3.5), Vector3(2.4, 1.2, 2.0), Color(0.18, 0.42, 0.88), "Allied ConYard", 0)
	spawn_building(Vector3(-4.8, 0.45, -4.0), Vector3(1.6, 0.8, 1.4), Color(0.2, 0.5, 0.9), "Barracks", 1)
	spawn_building(Vector3(-7.8, 0.45, -0.8), Vector3(2.2, 1.0, 1.8), Color(0.18, 0.45, 0.85), "Ore Refinery", 2)
	spawn_building(Vector3(-5.0, 0.45, -1.0), Vector3(2.0, 1.1, 1.8), Color(0.2, 0.45, 0.85), "War Factory", 3)
	spawn_prism_tower(Vector3(-3.2, 0.45, 1.2))

	# 3. Sowjetische Basis (Osten)
	spawn_building(Vector3(7.5, 0.45, 3.5), Vector3(2.4, 1.2, 2.0), Color(0.85, 0.2, 0.2), "Soviet ConYard", 4)
	spawn_building(Vector3(4.8, 0.45, 4.0), Vector3(1.6, 0.8, 1.4), Color(0.88, 0.22, 0.22), "Soviet Barracks", 5)
	spawn_building(Vector3(7.8, 0.45, 0.8), Vector3(2.2, 1.0, 1.8), Color(0.85, 0.2, 0.2), "Soviet Refinery", 6)
	spawn_building(Vector3(5.0, 0.45, 1.0), Vector3(2.0, 1.1, 1.8), Color(0.85, 0.2, 0.2), "Soviet War Factory", 7)
	spawn_tesla_coil(Vector3(3.2, 0.45, -1.2))

	# 4. Zentrales Erz- & Tib-Feld
	for i in range(16):
		var crystal = MeshInstance3D.new()
		var p = PrismMesh.new()
		p.size = Vector3(0.35, 0.6, 0.35)
		crystal.mesh = p
		var c_mat = TextureHelper.get_metal_material(Color(0.95, 0.82, 0.1), 0.9)
		c_mat.emission_enabled = true
		c_mat.emission = Color(0.95, 0.8, 0.1)
		c_mat.emission_energy_multiplier = 0.6
		crystal.material_override = c_mat
		crystal.position = Vector3(randf_range(-2.2, 2.2), 0.5, randf_range(-3.0, 3.0))
		add_child(crystal)

	# 5. Panzer-Bataillone
	units.clear()
	spawn_tank(Vector3(-2.5, 0.48, -2.5), Color(0.2, 0.48, 0.9), false, 100)
	spawn_tank(Vector3(-2.8, 0.48, -1.0), Color(0.2, 0.48, 0.9), false, 101)
	spawn_tank(Vector3(-2.2, 0.48, 0.5), Color(0.2, 0.48, 0.9), false, 102)

	spawn_tank(Vector3(2.5, 0.48, 2.5), Color(0.9, 0.22, 0.22), true, 200)
	spawn_tank(Vector3(2.8, 0.48, 1.0), Color(0.9, 0.22, 0.22), true, 201)
	spawn_tank(Vector3(2.2, 0.48, -0.5), Color(0.9, 0.22, 0.22), true, 202)

func spawn_building(pos: Vector3, size: Vector3, col: Color, b_name: String, b_id: int):
	var b = Node3D.new()
	b.position = pos
	var m = BoxMesh.new()
	m.size = size
	var inst = MeshInstance3D.new()
	inst.mesh = m
	inst.material_override = TextureHelper.get_metal_material(col, 0.8)
	inst.position = Vector3(0, size.y * 0.5, 0)
	b.add_child(inst)

	# StaticBody für Klicks
	var sb = StaticBody3D.new()
	var col_shape = CollisionShape3D.new()
	var b_shape = BoxShape3D.new()
	b_shape.size = size + Vector3(0.3, 0.5, 0.3)
	col_shape.shape = b_shape
	sb.add_child(col_shape)
	sb.set_meta("grid_pos", Vector2i(b_id, 0))
	b.add_child(sb)

	var lbl = Label3D.new()
	lbl.text = "🏭 " + b_name
	lbl.pixel_size = 0.011
	lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lbl.position = Vector3(0, size.y + 0.35, 0)
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
	bm.top_radius = 0.22
	bm.bottom_radius = 0.38
	bm.height = 1.4
	base.mesh = bm
	base.material_override = mat
	base.position = Vector3(0, 0.7, 0)
	tower.add_child(base)

	var prism = MeshInstance3D.new()
	var pm = PrismMesh.new()
	pm.size = Vector3(0.5, 0.6, 0.5)
	prism.mesh = pm
	var pmat = TextureHelper.get_marble_material(Color(0.4, 0.85, 1.0))
	pmat.emission_enabled = true
	pmat.emission = Color(0.4, 0.85, 1.0)
	pmat.emission_energy_multiplier = 1.5
	prism.material_override = pmat
	prism.position = Vector3(0, 1.6, 0)
	tower.add_child(prism)

	add_child(tower)

func spawn_tesla_coil(pos: Vector3):
	var coil = Node3D.new()
	coil.position = pos
	var mat = TextureHelper.get_metal_material(Color(0.85, 0.2, 0.2), 0.85)

	var base = MeshInstance3D.new()
	var bm = CylinderMesh.new()
	bm.top_radius = 0.24
	bm.bottom_radius = 0.4
	bm.height = 1.3
	base.mesh = bm
	base.material_override = mat
	base.position = Vector3(0, 0.65, 0)
	coil.add_child(base)

	var sphere = MeshInstance3D.new()
	var sm = SphereMesh.new()
	sm.radius = 0.28
	sm.height = 0.45
	sphere.mesh = sm
	var smat = TextureHelper.get_metal_material(Color(0.3, 0.75, 1.0), 0.9)
	smat.emission_enabled = true
	smat.emission = Color(0.3, 0.75, 1.0)
	smat.emission_energy_multiplier = 2.0
	sphere.material_override = smat
	sphere.position = Vector3(0, 1.45, 0)
	coil.add_child(sphere)

	tesla_light = OmniLight3D.new()
	tesla_light.light_color = Color(0.3, 0.75, 1.0)
	tesla_light.light_energy = 2.5
	tesla_light.omni_range = 4.0
	sphere.add_child(tesla_light)

	add_child(coil)

func spawn_tank(pos: Vector3, col: Color, is_heavy: bool, u_id: int):
	var tank = Node3D.new()
	tank.position = pos
	var mat = TextureHelper.get_metal_material(col, 0.85)

	var l = 1.3 if is_heavy else 1.0
	var w = 0.85 if is_heavy else 0.65
	var hull = MeshInstance3D.new()
	var hm = BoxMesh.new()
	hm.size = Vector3(l, 0.3, w)
	hull.mesh = hm
	hull.material_override = mat
	hull.position = Vector3(0, 0.18, 0)
	tank.add_child(hull)

	var turret = MeshInstance3D.new()
	var tm = CylinderMesh.new()
	tm.top_radius = 0.28 if is_heavy else 0.22
	tm.bottom_radius = 0.32 if is_heavy else 0.26
	tm.height = 0.22
	turret.mesh = tm
	turret.material_override = mat
	turret.position = Vector3(0, 0.4, 0)
	tank.add_child(turret)

	var barrel = MeshInstance3D.new()
	var barm = CylinderMesh.new()
	barm.top_radius = 0.05
	barm.bottom_radius = 0.05
	barm.height = 0.8 if is_heavy else 0.65
	barrel.mesh = barm
	barrel.material_override = mat
	barrel.rotation_degrees = Vector3(0, 0, 90)
	barrel.position = Vector3(0.5, 0.4, 0)
	tank.add_child(barrel)

	# StaticBody für Klicks
	var sb = StaticBody3D.new()
	var col_shape = CollisionShape3D.new()
	var b_shape = BoxShape3D.new()
	b_shape.size = Vector3(l + 0.3, 0.8, w + 0.3)
	col_shape.shape = b_shape
	sb.add_child(col_shape)
	sb.set_meta("grid_pos", Vector2i(u_id, 0))
	tank.add_child(sb)

	add_child(tank)
	units.append({"id": u_id, "is_heavy": is_heavy, "node": tank})

func setup_game_ui():
	ui_layer = CanvasLayer.new()
	add_child(ui_layer)

	var panel = PanelContainer.new()
	panel.anchors_preset = Control.PRESET_BOTTOM_RIGHT
	panel.offset_left = -390
	panel.offset_top = -220
	panel.offset_right = -20
	panel.offset_bottom = -20
	ui_layer.add_child(panel)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	panel.add_child(vbox)

	var info = Label.new()
	info.name = "Ra2Info"
	info.text = "Credits: $1500 | Alliierte Panzer: 3 | Sowjetische Panzer: 3\nSowjet-Basis Zustand: 100%"
	vbox.add_child(info)

	var tank_btn = Button.new()
	tank_btn.text = "🛡️ Grizzly-Panzer bauen ($500)"
	tank_btn.custom_minimum_size = Vector2(0, 42)
	tank_btn.pressed.connect(build_tank)
	vbox.add_child(tank_btn)

	var attack_btn = Button.new()
	attack_btn.text = "⚔️ Panzer-Vorstoß auf Sowjetbasis befehlen!"
	attack_btn.custom_minimum_size = Vector2(0, 40)
	attack_btn.pressed.connect(attack_soviet_base)
	vbox.add_child(attack_btn)

	var harvest_btn = Button.new()
	harvest_btn.text = "💰 Erz abbauen (Chrono-Miner: +$400)"
	harvest_btn.custom_minimum_size = Vector2(0, 38)
	harvest_btn.pressed.connect(harvest_ore)
	vbox.add_child(harvest_btn)

func handle_tile_clicked(grid_pos: Vector2i):
	emit_signal("sound_triggered", "select")
	var id = grid_pos.x
	if id >= 100:
		emit_signal("status_changed", "Panzer-Bataillon angewählt! Bereit für Gefechtsbefehl.")
	else:
		emit_signal("status_changed", "Basis-Gebäude angewählt! Konstruktionsparameter intakt.")

func build_tank():
	if credits < 500:
		emit_signal("status_changed", "Nicht genug Credits für Panzerbau ($500 nötig)!")
		return
	credits -= 500
	player_tanks += 1
	var spawn_pos = Vector3(-2.5, 0.48, -2.5 + player_tanks * 0.8)
	spawn_tank(spawn_pos, Color(0.2, 0.48, 0.9), false, 100 + player_tanks)
	emit_signal("sound_triggered", "win")
	emit_signal("status_changed", "🛡️ Einheit einsatzbereit! Grizzly-Panzer rollt aus der Waffenfabrik.")
	update_ui()

func harvest_ore():
	credits += 400
	emit_signal("sound_triggered", "move")
	emit_signal("status_changed", "💰 Chrono-Miner kehrt zurück! +400 Erz-Credits gebunkert.")
	update_ui()

func attack_soviet_base():
	if player_tanks <= 0:
		emit_signal("status_changed", "Keine einsatzfähigen Panzer vorhanden!")
		return

	emit_signal("sound_triggered", "shoot")
	var dmg = player_tanks * 15 + randi_range(5, 15)
	soviet_base_hp = max(0, soviet_base_hp - dmg)

	if soviet_base_hp <= 0:
		emit_signal("sound_triggered", "win")
		emit_signal("status_changed", "🏆 SOWJETBASIS VERNICHTET! Sieg für die Alliierten!")
	else:
		emit_signal("status_changed", "💥 Beschuss auf Feindbasis! " + str(dmg) + "% Schaden verursacht (Rest: " + str(soviet_base_hp) + "%).")
		# Feindlicher Gegenschlag
		if randf() > 0.5 and player_tanks > 1:
			player_tanks -= 1
			emit_signal("status_changed", "⚠️ Tesla-Schlag! Ein eigener Panzer wurde vernichtet!")

	update_ui()

func update_ui():
	var lbl = ui_layer.get_node_or_null("PanelContainer/VBoxContainer/Ra2Info") as Label
	if lbl:
		lbl.text = "Credits: $" + str(credits) + " | Eigene Panzer: " + str(player_tanks) + " | Feindpanzer: " + str(soviet_tanks) + "\nSowjet-Basis Zustand: " + str(soviet_base_hp) + "%"
