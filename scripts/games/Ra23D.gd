extends Node3D

class_name Ra23D

const TextureHelper = preload("res://scripts/TextureHelper.gd")

signal status_changed(msg: String)
signal sound_triggered(sound_name: String)

var credits: int = 2400
var player_tanks: int = 3
var soviet_tanks: int = 3
var soviet_base_hp: int = 100
var allied_base_hp: int = 100
var is_bot_opponent: bool = true

var units: Array = []
var buildings: Array = []
var kirov_node: Node3D = null
var tesla_light: OmniLight3D = null
var tesla_coil_node: Node3D = null
var miner_node: Node3D = null
var is_attacking: bool = false
var miner_phase: int = 0
var miner_timer: float = 0.0

var ui_layer: CanvasLayer = null
var credits_label: Label = null
var radar_rect: Control = null
var end_modal: PanelContainer = null

func _ready():
	setup_stage()
	setup_game_ui()
	reset_game()

func _process(delta: float):
	# Kontinuierlicher Kirov-Luftschiff-Überflug (Schwimmende Drohung am Himmel)
	if is_instance_valid(kirov_node):
		kirov_node.position.x += delta * 0.8
		kirov_node.position.y = 7.5 + sin(Time.get_ticks_msec() * 0.0015) * 0.25
		if kirov_node.position.x > 18.0:
			kirov_node.position.x = -18.0

	# Automatischer War-Miner Zyklus: Raffinerie <-> Gold-Erzfeld
	if is_instance_valid(miner_node):
		miner_timer += delta
		match miner_phase:
			0: # Fahrt zum Erzfeld
				var target = Vector3(0.0, 0.48, 0.0)
				miner_node.position = miner_node.position.move_toward(target, delta * 2.2)
				miner_node.rotation_degrees.y = 0.0
				if miner_node.position.distance_to(target) < 0.2:
					miner_phase = 1
					miner_timer = 0.0
					emit_signal("status_changed", "⛏️ Erzsammler baut goldenes Tiberium-Erz ab...")
			1: # Erz abbauen (Bohrer rotieren, 3.5s)
				var drill = miner_node.find_child("AugerDrill", true, false)
				if drill: drill.rotation_degrees.x += delta * 500.0
				if miner_timer > 3.5:
					miner_phase = 2
					miner_timer = 0.0
					emit_signal("status_changed", "🚚 Erzsammler voll beladen! Rückkehr zur Erz-Raffinerie...")
			2: # Rückfahrt zur Raffinerie
				var ref_target = Vector3(10.5, 0.48, 1.2)
				miner_node.position = miner_node.position.move_toward(ref_target, delta * 2.0)
				miner_node.rotation_degrees.y = 180.0
				if miner_node.position.distance_to(ref_target) < 0.3:
					miner_phase = 3
					miner_timer = 0.0
			3: # Abladen in der Raffinerie (+500 Credits)
				if miner_timer > 1.8:
					credits += 500
					update_credits_display()
					emit_signal("sound_triggered", "select")
					emit_signal("status_changed", "💰 +$500 Credits! Roherz in der Sowjet-Raffinerie verarbeitet.")
					miner_phase = 0
					miner_timer = 0.0

	# Animiertes Tesla-Spulen Plasma-Pulsieren
	if is_instance_valid(tesla_light):
		tesla_light.light_energy = 1.2 + sin(Time.get_ticks_msec() * 0.01) * 0.8

func setup_stage():
	# 1. Großes C&C Schlachtfeld (32x20) mit Tundra-, Sand- und Betonflächen
	var ground_mesh = BoxMesh.new()
	ground_mesh.size = Vector3(32.0, 0.45, 20.0)
	var ground = MeshInstance3D.new()
	ground.mesh = ground_mesh
	ground.material_override = TextureHelper.get_stone_material(Color(0.26, 0.23, 0.18))
	ground.position = Vector3(0, 0.2, 0)
	add_child(ground)

	# Taktische Straßen- und Panzerspuren zwischen den Basen
	var road_mesh = BoxMesh.new()
	road_mesh.size = Vector3(31.0, 0.02, 3.2)
	var road = MeshInstance3D.new()
	road.mesh = road_mesh
	var road_mat = TextureHelper.get_stone_material(Color(0.18, 0.16, 0.14))
	road.material_override = road_mat
	road.position = Vector3(0, 0.44, 0)
	add_child(road)

	# 2. Alliierte Basis (Westen) mit 1:1 Red Alert 2 Architektur
	spawn_allied_conyard(Vector3(-11.5, 0.45, -4.5))
	spawn_allied_barracks(Vector3(-7.5, 0.45, -5.2))
	spawn_allied_refinery(Vector3(-11.8, 0.45, -0.5))
	spawn_allied_warfactory(Vector3(-7.8, 0.45, -1.2))
	spawn_prism_tower(Vector3(-4.5, 0.45, 2.2))

	# 3. Sowjetische Basis (Osten) mit 1:1 Red Alert 2 Architektur
	spawn_soviet_conyard(Vector3(11.5, 0.45, 4.5))
	spawn_soviet_barracks(Vector3(7.5, 0.45, 5.2))
	spawn_soviet_refinery(Vector3(11.8, 0.45, 0.8))
	spawn_soviet_warfactory(Vector3(7.8, 0.45, 1.2))
	spawn_tesla_coil(Vector3(4.5, 0.45, -2.2))
	spawn_tesla_reactor(Vector3(12.0, 0.45, -4.5))

	# 4. Zentrales Tiberium- & Golderz-Feld
	spawn_ore_field(Vector3(0, 0.45, 0))

	# 5. Kirov-Luftschiff am Himmel (Legendärer Red Alert 2 Zeppelin)
	spawn_kirov_airship(Vector3(-12.0, 7.5, -2.0))

	# 6. War-Miner Erntemaschine
	miner_node = spawn_war_miner(Vector3(10.5, 0.48, 1.0))

	# 7. Panzer-Einheiten spawnen
	spawn_initial_tanks()

func spawn_ore_field(center: Vector3):
	var patch_mesh = BoxMesh.new()
	patch_mesh.size = Vector3(7.5, 0.04, 7.5)
	var patch = MeshInstance3D.new()
	patch.mesh = patch_mesh
	var p_mat = TextureHelper.get_stone_material(Color(0.35, 0.3, 0.12))
	patch.material_override = p_mat
	patch.position = center + Vector3(0, 0.01, 0)
	add_child(patch)

	for i in range(28):
		var crystal = MeshInstance3D.new()
		var p = PrismMesh.new()
		p.size = Vector3(randf_range(0.35, 0.55), randf_range(0.65, 1.1), randf_range(0.35, 0.55))
		crystal.mesh = p
		var c_mat = StandardMaterial3D.new()
		c_mat.albedo_color = Color(1.0, randf_range(0.75, 0.9), 0.05)
		c_mat.metallic = 0.85
		c_mat.roughness = 0.2
		c_mat.emission_enabled = true
		c_mat.emission = Color(1.0, 0.8, 0.1)
		c_mat.emission_energy_multiplier = 1.2
		crystal.material_override = c_mat
		crystal.position = center + Vector3(randf_range(-3.2, 3.2), 0.45, randf_range(-3.2, 3.2))
		crystal.rotation_degrees = Vector3(randf_range(-15, 15), randf_range(0, 360), randf_range(-15, 15))
		add_child(crystal)

func spawn_initial_tanks():
	for u in units:
		if is_instance_valid(u.node): u.node.queue_free()
	units.clear()

	# Alliierte Grizzly-Panzer
	for i in range(player_tanks):
		var p = spawn_rhino_tank(Vector3(-4.0, 0.48, -3.2 + i * 1.8), Color(0.2, 0.45, 0.92), false, 100 + i)
		units.append({"id": 100 + i, "is_enemy": false, "node": p})

	# Sowjetische Rhino-Schwerpanzer
	for i in range(soviet_tanks):
		var p = spawn_rhino_tank(Vector3(4.0, 0.48, 3.2 - i * 1.8), Color(0.88, 0.2, 0.2), true, 200 + i)
		units.append({"id": 200 + i, "is_enemy": true, "node": p})

# -------------------------------------------------------------
# 1:1 Red Alert 2 Gebäude-Modellierung
# -------------------------------------------------------------
func spawn_soviet_conyard(pos: Vector3):
	var node = Node3D.new()
	node.position = pos
	var metal_mat = TextureHelper.get_metal_material(Color(0.24, 0.24, 0.26), 0.85)
	var red_mat = TextureHelper.get_metal_material(Color(0.82, 0.18, 0.18), 0.8)
	var yellow_mat = TextureHelper.get_metal_material(Color(0.95, 0.8, 0.1), 0.7)

	# Achteckige Beton-Fundamentplatte mit Warnstreifen
	var base_mesh = CylinderMesh.new()
	base_mesh.top_radius = 2.0
	base_mesh.bottom_radius = 2.2
	base_mesh.height = 0.35
	var base_inst = MeshInstance3D.new()
	base_inst.mesh = base_mesh
	base_inst.material_override = metal_mat
	base_inst.position = Vector3(0, 0.18, 0)
	node.add_child(base_inst)

	# Zentrale Kommandobunker-Kuppel
	var dome_mesh = SphereMesh.new()
	dome_mesh.radius = 1.3
	dome_mesh.height = 1.6
	var dome_inst = MeshInstance3D.new()
	dome_inst.mesh = dome_mesh
	dome_inst.material_override = red_mat
	dome_inst.position = Vector3(0, 0.45, 0)
	node.add_child(dome_inst)

	# Roter Sowjetstern-Relief auf der Kuppel
	var star_lbl = Label3D.new()
	star_lbl.text = "★"
	star_lbl.font_size = 48
	star_lbl.pixel_size = 0.02
	star_lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	star_lbl.position = Vector3(0, 1.4, 0)
	star_lbl.modulate = Color(1.0, 0.85, 0.1)
	node.add_child(star_lbl)

	# 2 riesige gelbe Baukräne mit Seilwinden
	for side in [-1.4, 1.4]:
		var crane_p = MeshInstance3D.new()
		var cpm = BoxMesh.new()
		cpm.size = Vector3(0.18, 1.8, 0.18)
		crane_p.mesh = cpm
		crane_p.material_override = yellow_mat
		crane_p.position = Vector3(side, 0.9, -1.0)
		node.add_child(crane_p)

		var boom = MeshInstance3D.new()
		var bm = BoxMesh.new()
		bm.size = Vector3(0.14, 0.14, 1.6)
		boom.mesh = bm
		boom.material_override = yellow_mat
		boom.position = Vector3(side, 1.8, -0.2)
		node.add_child(boom)

	attach_building_label(node, "Sowjetischer Bauhof", 1.9)
	add_child(node)
	buildings.append({"name": "Sowjet Bauhof", "pos": pos, "node": node})

func spawn_allied_conyard(pos: Vector3):
	var node = Node3D.new()
	node.position = pos
	var metal_mat = TextureHelper.get_metal_material(Color(0.25, 0.28, 0.35), 0.85)
	var blue_mat = TextureHelper.get_metal_material(Color(0.2, 0.48, 0.92), 0.8)

	var base = MeshInstance3D.new()
	var bm = BoxMesh.new()
	bm.size = Vector3(3.6, 0.4, 3.2)
	base.mesh = bm
	base.material_override = metal_mat
	base.position = Vector3(0, 0.2, 0)
	node.add_child(base)

	var hq = MeshInstance3D.new()
	var hm = BoxMesh.new()
	hm.size = Vector3(2.4, 1.2, 2.0)
	hq.mesh = hm
	hq.material_override = blue_mat
	hq.position = Vector3(0, 0.8, 0)
	node.add_child(hq)

	# Radardrehteller
	var dish = MeshInstance3D.new()
	var dm = CylinderMesh.new()
	dm.top_radius = 0.45
	dm.bottom_radius = 0.1
	dm.height = 0.2
	dish.mesh = dm
	dish.material_override = metal_mat
	dish.rotation_degrees = Vector3(45, 0, 0)
	dish.position = Vector3(0.6, 1.5, 0)
	node.add_child(dish)

	attach_building_label(node, "Alliierter Bauhof", 1.8)
	add_child(node)
	buildings.append({"name": "Allied Bauhof", "pos": pos, "node": node})

func spawn_soviet_barracks(pos: Vector3):
	var node = Node3D.new()
	node.position = pos
	var concrete_mat = TextureHelper.get_stone_material(Color(0.3, 0.3, 0.32))
	var red_mat = TextureHelper.get_metal_material(Color(0.85, 0.2, 0.2), 0.8)

	# Bunker mit Schießscharten
	var bunker = MeshInstance3D.new()
	var bm = BoxMesh.new()
	bm.size = Vector3(2.4, 1.1, 1.8)
	bunker.mesh = bm
	bunker.material_override = concrete_mat
	bunker.position = Vector3(0, 0.55, 0)
	node.add_child(bunker)

	# Rotes Panzertor mit Warnlicht
	var door = MeshInstance3D.new()
	var dm = BoxMesh.new()
	dm.size = Vector3(0.7, 0.8, 0.1)
	door.mesh = dm
	door.material_override = red_mat
	door.position = Vector3(0, 0.4, 0.9)
	node.add_child(door)

	# Rote Sowjet-Fahne am Mast
	var pole = MeshInstance3D.new()
	var pm = CylinderMesh.new()
	pm.top_radius = 0.02
	pm.bottom_radius = 0.02
	pm.height = 1.8
	pole.mesh = pm
	pole.position = Vector3(1.1, 1.2, 0.8)
	node.add_child(pole)

	var flag = MeshInstance3D.new()
	var fm = BoxMesh.new()
	fm.size = Vector3(0.5, 0.3, 0.02)
	flag.mesh = fm
	flag.material_override = red_mat
	flag.position = Vector3(1.35, 1.8, 0.8)
	node.add_child(flag)

	attach_building_label(node, "Sowjet-Kaserne", 1.5)
	add_child(node)
	buildings.append({"name": "Sowjet Kaserne", "pos": pos, "node": node})

func spawn_allied_barracks(pos: Vector3):
	var node = Node3D.new()
	node.position = pos
	var blue_mat = TextureHelper.get_metal_material(Color(0.2, 0.48, 0.92), 0.8)
	var b = MeshInstance3D.new()
	var bm = BoxMesh.new()
	bm.size = Vector3(2.2, 1.0, 1.8)
	b.mesh = bm
	b.material_override = blue_mat
	b.position = Vector3(0, 0.5, 0)
	node.add_child(b)

	attach_building_label(node, "Alliierte Kaserne", 1.4)
	add_child(node)
	buildings.append({"name": "Allied Kaserne", "pos": pos, "node": node})

func spawn_soviet_warfactory(pos: Vector3):
	var node = Node3D.new()
	node.position = pos
	var metal_mat = TextureHelper.get_metal_material(Color(0.28, 0.28, 0.3), 0.85)
	var red_mat = TextureHelper.get_metal_material(Color(0.85, 0.2, 0.2), 0.8)
	var hazard_mat = TextureHelper.get_metal_material(Color(0.95, 0.8, 0.1), 0.7)

	# Montagehalle mit Giebeldach
	var hall = MeshInstance3D.new()
	var hm = BoxMesh.new()
	hm.size = Vector3(3.2, 1.4, 2.6)
	hall.mesh = hm
	hall.material_override = metal_mat
	hall.position = Vector3(0, 0.7, 0)
	node.add_child(hall)

	# Großes Panzerausfahrtstor mit gelb-schwarzem Warnstreifen
	var gate = MeshInstance3D.new()
	var gm = BoxMesh.new()
	gm.size = Vector3(1.6, 1.1, 0.15)
	gate.mesh = gm
	gate.material_override = hazard_mat
	gate.position = Vector3(0, 0.55, 1.3)
	node.add_child(gate)

	# 2 Industrie-Schornsteine
	for i in [-0.9, 0.9]:
		var chim = MeshInstance3D.new()
		var cm = CylinderMesh.new()
		cm.top_radius = 0.12
		cm.bottom_radius = 0.15
		cm.height = 1.0
		chim.mesh = cm
		chim.material_override = red_mat
		chim.position = Vector3(i, 1.8, -0.8)
		node.add_child(chim)

	attach_building_label(node, "Sowjet-Waffenfabrik", 1.8)
	add_child(node)
	buildings.append({"name": "Sowjet Waffenfabrik", "pos": pos, "node": node})

func spawn_allied_warfactory(pos: Vector3):
	var node = Node3D.new()
	node.position = pos
	var blue_mat = TextureHelper.get_metal_material(Color(0.2, 0.45, 0.88), 0.8)
	var hall = MeshInstance3D.new()
	var hm = BoxMesh.new()
	hm.size = Vector3(3.0, 1.3, 2.4)
	hall.mesh = hm
	hall.material_override = blue_mat
	hall.position = Vector3(0, 0.65, 0)
	node.add_child(hall)

	attach_building_label(node, "Alliierte Waffenfabrik", 1.7)
	add_child(node)
	buildings.append({"name": "Allied Waffenfabrik", "pos": pos, "node": node})

func spawn_soviet_refinery(pos: Vector3):
	var node = Node3D.new()
	node.position = pos
	var metal_mat = TextureHelper.get_metal_material(Color(0.3, 0.3, 0.34), 0.85)
	var red_mat = TextureHelper.get_metal_material(Color(0.85, 0.2, 0.2), 0.8)

	# 2 große zylindrische Erzsilos
	for i in [-0.8, 0.8]:
		var silo = MeshInstance3D.new()
		var sm = CylinderMesh.new()
		sm.top_radius = 0.65
		sm.bottom_radius = 0.7
		sm.height = 1.8
		silo.mesh = sm
		silo.material_override = metal_mat
		silo.position = Vector3(i, 0.9, -0.6)
		node.add_child(silo)

	# Schräge Entlade-Rampe für den War-Miner
	var ramp = MeshInstance3D.new()
	var rm = BoxMesh.new()
	rm.size = Vector3(1.8, 0.3, 1.6)
	ramp.mesh = rm
	ramp.material_override = red_mat
	ramp.rotation_degrees = Vector3(15, 0, 0)
	ramp.position = Vector3(0, 0.25, 0.7)
	node.add_child(ramp)

	attach_building_label(node, "Erz-Raffinerie", 1.9)
	add_child(node)
	buildings.append({"name": "Sowjet Raffinerie", "pos": pos, "node": node})

func spawn_allied_refinery(pos: Vector3):
	var node = Node3D.new()
	node.position = pos
	var blue_mat = TextureHelper.get_metal_material(Color(0.2, 0.45, 0.88), 0.8)
	var b = MeshInstance3D.new()
	var bm = BoxMesh.new()
	bm.size = Vector3(2.8, 1.2, 2.2)
	b.mesh = bm
	b.material_override = blue_mat
	b.position = Vector3(0, 0.6, 0)
	node.add_child(b)

	attach_building_label(node, "Alliierte Raffinerie", 1.6)
	add_child(node)
	buildings.append({"name": "Allied Raffinerie", "pos": pos, "node": node})

func spawn_tesla_reactor(pos: Vector3):
	var node = Node3D.new()
	node.position = pos
	var metal_mat = TextureHelper.get_metal_material(Color(0.26, 0.28, 0.3), 0.85)

	# 2 Kühltürme
	for i in [-0.7, 0.7]:
		var tower = MeshInstance3D.new()
		var tm = CylinderMesh.new()
		tm.top_radius = 0.5
		tm.bottom_radius = 0.75
		tm.height = 1.6
		tower.mesh = tm
		tower.material_override = metal_mat
		tower.position = Vector3(i, 0.8, 0)
		node.add_child(tower)

	# Glühender Plasmakern in der Mitte
	var core = MeshInstance3D.new()
	var cm = SphereMesh.new()
	cm.radius = 0.35
	cm.height = 0.7
	core.mesh = cm
	var p_mat = StandardMaterial3D.new()
	p_mat.albedo_color = Color(1.0, 0.8, 0.1)
	p_mat.emission_enabled = true
	p_mat.emission = Color(1.0, 0.8, 0.1)
	p_mat.emission_energy_multiplier = 2.5
	core.material_override = p_mat
	core.position = Vector3(0, 0.8, 0)
	node.add_child(core)

	attach_building_label(node, "Tesla-Kraftwerk", 1.8)
	add_child(node)
	buildings.append({"name": "Tesla Reactor", "pos": pos, "node": node})

func spawn_tesla_coil(pos: Vector3):
	tesla_coil_node = Node3D.new()
	tesla_coil_node.position = pos

	var metal_mat = TextureHelper.get_metal_material(Color(0.24, 0.25, 0.28), 0.9)
	var copper_mat = TextureHelper.get_metal_material(Color(0.85, 0.55, 0.2), 0.95)

	# Gestufter pyramidaler Sockel
	var base = MeshInstance3D.new()
	var bm = CylinderMesh.new()
	bm.top_radius = 0.65
	bm.bottom_radius = 1.0
	bm.height = 0.8
	base.mesh = bm
	base.material_override = metal_mat
	base.position = Vector3(0, 0.4, 0)
	tesla_coil_node.add_child(base)

	# 4 Kupfer-Induktionsringe (Toroids)
	for i in range(4):
		var ring = MeshInstance3D.new()
		var rm = TorusMesh.new()
		rm.inner_radius = 0.22 - float(i) * 0.03
		rm.outer_radius = 0.48 - float(i) * 0.05
		ring.mesh = rm
		ring.material_override = copper_mat
		ring.position = Vector3(0, 0.9 + float(i) * 0.32, 0)
		tesla_coil_node.add_child(ring)

	# Leuchtende elektrische Plasmakugel an der Spitze (10.000 Volt)
	var sphere = MeshInstance3D.new()
	var sm = SphereMesh.new()
	sm.radius = 0.28
	sm.height = 0.56
	sphere.mesh = sm
	var p_mat = StandardMaterial3D.new()
	p_mat.albedo_color = Color(0.25, 0.75, 1.0)
	p_mat.emission_enabled = true
	p_mat.emission = Color(0.3, 0.8, 1.0)
	p_mat.emission_energy_multiplier = 3.5
	sphere.material_override = p_mat
	sphere.position = Vector3(0, 2.25, 0)
	tesla_coil_node.add_child(sphere)

	tesla_light = OmniLight3D.new()
	tesla_light.light_color = Color(0.3, 0.75, 1.0)
	tesla_light.light_energy = 2.0
	tesla_light.omni_range = 6.0
	tesla_light.position = Vector3(0, 2.25, 0)
	tesla_coil_node.add_child(tesla_light)

	attach_building_label(tesla_coil_node, "⚡ Tesla-Spule", 2.6)
	add_child(tesla_coil_node)
	buildings.append({"name": "Tesla Coil", "pos": pos, "node": tesla_coil_node})

func spawn_prism_tower(pos: Vector3):
	var node = Node3D.new()
	node.position = pos
	var metal_mat = TextureHelper.get_metal_material(Color(0.85, 0.88, 0.95), 0.9)
	var tower = MeshInstance3D.new()
	var tm = CylinderMesh.new()
	tm.top_radius = 0.22
	tm.bottom_radius = 0.65
	tm.height = 2.2
	tower.mesh = tm
	tower.material_override = metal_mat
	tower.position = Vector3(0, 1.1, 0)
	node.add_child(tower)

	# Prisma-Kristall an der Spitze
	var crystal = MeshInstance3D.new()
	var cm = PrismMesh.new()
	cm.size = Vector3(0.5, 0.6, 0.5)
	crystal.mesh = cm
	var c_mat = StandardMaterial3D.new()
	c_mat.albedo_color = Color(0.9, 0.95, 1.0)
	c_mat.emission_enabled = true
	c_mat.emission = Color(0.7, 0.9, 1.0)
	c_mat.emission_energy_multiplier = 2.0
	crystal.material_override = c_mat
	crystal.position = Vector3(0, 2.4, 0)
	node.add_child(crystal)

	attach_building_label(node, "🔷 Prisma-Turm", 2.7)
	add_child(node)
	buildings.append({"name": "Prism Tower", "pos": pos, "node": node})

func attach_building_label(parent: Node3D, text: String, y_pos: float):
	var lbl = Label3D.new()
	lbl.text = text
	lbl.font_size = 22
	lbl.pixel_size = 0.012
	lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lbl.position = Vector3(0, y_pos, 0)
	lbl.outline_size = 4
	parent.add_child(lbl)

# -------------------------------------------------------------
# 1:1 Red Alert 2 Einheiten-Modellierung
# -------------------------------------------------------------
func spawn_rhino_tank(pos: Vector3, col: Color, is_soviet: bool, t_id: int) -> Node3D:
	var tank = Node3D.new()
	tank.position = pos
	tank.set_meta("t_id", t_id)
	tank.set_meta("is_soviet", is_soviet)

	var armor_mat = TextureHelper.get_metal_material(col, 0.85)
	var tread_mat = TextureHelper.get_metal_material(Color(0.14, 0.14, 0.15), 0.9)
	var barrel_mat = TextureHelper.get_metal_material(Color(0.12, 0.13, 0.15), 0.95)

	# Breite Panzerwanne
	var hull = MeshInstance3D.new()
	var hm = BoxMesh.new()
	hm.size = Vector3(1.3, 0.28, 0.85)
	hull.mesh = hm
	hull.material_override = armor_mat
	hull.position = Vector3(0, 0.22, 0)
	tank.add_child(hull)

	# 2 schwere Kettenlaufwerke mit Rollen
	for side in [-0.46, 0.46]:
		var tread = MeshInstance3D.new()
		var tm = BoxMesh.new()
		tm.size = Vector3(1.4, 0.24, 0.18)
		tread.mesh = tm
		tread.material_override = tread_mat
		tread.position = Vector3(0, 0.12, side)
		tank.add_child(tread)

	# Drehbare Turm-Einheit
	var turret_node = Node3D.new()
	turret_node.name = "Turret"
	turret_node.position = Vector3(0.05, 0.38, 0)

	var turret = MeshInstance3D.new()
	var tum = BoxMesh.new()
	tum.size = Vector3(0.68, 0.22, 0.58)
	turret.mesh = tum
	turret.material_override = armor_mat
	turret_node.add_child(turret)

	# Kommandantenkuppel
	var cupola = MeshInstance3D.new()
	var cm = CylinderMesh.new()
	cm.top_radius = 0.1
	cm.bottom_radius = 0.12
	cm.height = 0.08
	cupola.mesh = cm
	cupola.material_override = tread_mat
	cupola.position = Vector3(-0.1, 0.15, 0.12)
	turret_node.add_child(cupola)

	# 120mm schwere Panzerkanone mit Mündungsbremse
	var barrel = MeshInstance3D.new()
	var bm = CylinderMesh.new()
	bm.top_radius = 0.035
	bm.bottom_radius = 0.045
	bm.height = 0.88
	barrel.mesh = bm
	barrel.material_override = barrel_mat
	barrel.rotation_degrees = Vector3(0, 0, 90)
	var dir = 1.0 if not is_soviet else -1.0
	barrel.position = Vector3(0.55 * dir, 0.02, 0)
	turret_node.add_child(barrel)

	# Mündungsfeuer-Marker
	var flash_node = Node3D.new()
	flash_node.name = "MuzzleFlash"
	flash_node.position = Vector3(1.0 * dir, 0.02, 0)
	turret_node.add_child(flash_node)

	tank.add_child(turret_node)

	# 2 Treibstoff-Fässer am Heck
	for f_z in [-0.2, 0.2]:
		var barrel_fuel = MeshInstance3D.new()
		var bfm = CylinderMesh.new()
		bfm.top_radius = 0.08
		bfm.bottom_radius = 0.08
		bfm.height = 0.28
		barrel_fuel.mesh = bfm
		barrel_fuel.material_override = armor_mat
		barrel_fuel.rotation_degrees = Vector3(0, 0, 90)
		barrel_fuel.position = Vector3(-0.68 * dir, 0.25, f_z)
		tank.add_child(barrel_fuel)

	# Klickbarer StaticBody
	var sb = StaticBody3D.new()
	var cs = CollisionShape3D.new()
	var b_shape = BoxShape3D.new()
	b_shape.size = Vector3(1.5, 0.8, 1.2)
	cs.shape = b_shape
	sb.add_child(cs)
	sb.set_meta("grid_pos", Vector2i(t_id, 0))
	tank.add_child(sb)

	add_child(tank)
	return tank

func spawn_war_miner(pos: Vector3) -> Node3D:
	var miner = Node3D.new()
	miner.position = pos
	var metal_mat = TextureHelper.get_metal_material(Color(0.3, 0.32, 0.35), 0.85)
	var yellow_mat = TextureHelper.get_metal_material(Color(0.9, 0.78, 0.12), 0.75)
	var tread_mat = TextureHelper.get_metal_material(Color(0.12, 0.12, 0.14), 0.9)

	# Gepanzerte Ernte-Wanne
	var body = MeshInstance3D.new()
	var bm = BoxMesh.new()
	bm.size = Vector3(1.5, 0.45, 0.95)
	body.mesh = bm
	body.material_override = yellow_mat
	body.position = Vector3(0, 0.3, 0)
	miner.add_child(body)

	# 6 Schwerlast-Räder / Ketten
	for side in [-0.52, 0.52]:
		var tread = MeshInstance3D.new()
		var tm = BoxMesh.new()
		tm.size = Vector3(1.55, 0.28, 0.2)
		tread.mesh = tm
		tread.material_override = tread_mat
		tread.position = Vector3(0, 0.15, side)
		miner.add_child(tread)

	# Rotierender Front-Schneckenbohrer (Auger Drill)
	var drill = MeshInstance3D.new()
	drill.name = "AugerDrill"
	var dm = CylinderMesh.new()
	dm.top_radius = 0.22
	dm.bottom_radius = 0.22
	dm.height = 0.9
	drill.mesh = dm
	drill.material_override = metal_mat
	drill.rotation_degrees = Vector3(0, 0, 90)
	drill.position = Vector3(0.92, 0.24, 0)
	miner.add_child(drill)

	# Lademulde mit Gold-Nuggets
	var ore_load = MeshInstance3D.new()
	var om = BoxMesh.new()
	om.size = Vector3(0.65, 0.2, 0.7)
	ore_load.mesh = om
	var g_mat = StandardMaterial3D.new()
	g_mat.albedo_color = Color(1.0, 0.82, 0.1)
	g_mat.metallic = 0.9
	ore_load.material_override = g_mat
	ore_load.position = Vector3(-0.35, 0.58, 0)
	miner.add_child(ore_load)

	add_child(miner)
	return miner

func spawn_kirov_airship(pos: Vector3):
	kirov_node = Node3D.new()
	kirov_node.position = pos

	var red_mat = TextureHelper.get_metal_material(Color(0.85, 0.18, 0.18), 0.8)
	var belly_mat = TextureHelper.get_metal_material(Color(0.3, 0.32, 0.35), 0.85)

	# Massiver Zeppelin-Rumpf
	var zep = MeshInstance3D.new()
	var zm = SphereMesh.new()
	zm.radius = 1.1
	zm.height = 3.6
	zep.mesh = zm
	zep.material_override = red_mat
	zep.rotation_degrees = Vector3(0, 0, 90)
	kirov_node.add_child(zep)

	# Unterbauch-Gondel (Cockpit)
	var gondola = MeshInstance3D.new()
	var gm = BoxMesh.new()
	gm.size = Vector3(1.2, 0.35, 0.4)
	gondola.mesh = gm
	gondola.material_override = belly_mat
	gondola.position = Vector3(0, -1.1, 0)
	kirov_node.add_child(gondola)

	# Haifisch-Maul Nose-Art (Schrift/Symbol an der Schnauze)
	var teeth_lbl = Label3D.new()
	teeth_lbl.text = "🦈 KIROV REPORTING"
	teeth_lbl.font_size = 28
	teeth_lbl.pixel_size = 0.016
	teeth_lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	teeth_lbl.position = Vector3(0, 1.4, 0)
	teeth_lbl.outline_size = 4
	teeth_lbl.modulate = Color(1.0, 0.9, 0.1)
	kirov_node.add_child(teeth_lbl)

	# Heckflossen mit Sowjetstern
	for rot in [0, 90]:
		var fin = MeshInstance3D.new()
		var fm = BoxMesh.new()
		fm.size = Vector3(0.65, 0.05, 1.8)
		fin.mesh = fm
		fin.material_override = red_mat
		fin.rotation_degrees = Vector3(rot, 0, 0)
		fin.position = Vector3(-1.6, 0, 0)
		kirov_node.add_child(fin)

	add_child(kirov_node)

func setup_game_ui():
	ui_layer = CanvasLayer.new()
	add_child(ui_layer)

	# C&C Red Alert 2 EVA Seitenleiste (Rechts)
	var sidebar = PanelContainer.new()
	sidebar.anchors_preset = Control.PRESET_RIGHT_WIDE
	sidebar.offset_left = -260
	sidebar.offset_top = 65
	sidebar.offset_right = -10
	sidebar.offset_bottom = -15
	ui_layer.add_child(sidebar)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	sidebar.add_child(vbox)

	var eva_title = Label.new()
	eva_title.text = "📻 C&C EVA INTERFACE"
	eva_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(eva_title)

	credits_label = Label.new()
	credits_label.text = "💰 CREDITS: $" + str(credits)
	credits_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(credits_label)

	var attack_btn = Button.new()
	attack_btn.text = "⚔️ PANZER-ANGRIFF BEFEHLEN"
	attack_btn.custom_minimum_size = Vector2(0, 48)
	attack_btn.pressed.connect(execute_tank_assault)
	vbox.add_child(attack_btn)

	var build_rhino_btn = Button.new()
	build_rhino_btn.text = "🚜 Rhino Panzer bauen ($900)"
	build_rhino_btn.custom_minimum_size = Vector2(0, 40)
	build_rhino_btn.pressed.connect(func():
		if credits >= 900:
			credits -= 900
			update_credits_display()
			player_tanks += 1
			emit_signal("sound_triggered", "click")
			spawn_initial_tanks()
			emit_signal("status_changed", "🏭 Einheit bereit: Rhino-Schwerpanzer rollt aus der Waffenfabrik!")
		else:
			emit_signal("status_changed", "⚠️ Zu wenig Credits! Benötigt: $900")
	)
	vbox.add_child(build_rhino_btn)

	var tesla_strike_btn = Button.new()
	tesla_strike_btn.text = "⚡ Tesla-Schlag auslösen ($1200)"
	tesla_strike_btn.custom_minimum_size = Vector2(0, 40)
	tesla_strike_btn.pressed.connect(trigger_tesla_supercharge)
	vbox.add_child(tesla_strike_btn)

	var reset_btn = Button.new()
	reset_btn.text = "🔄 Schlachtfeld neu laden"
	reset_btn.custom_minimum_size = Vector2(0, 36)
	reset_btn.pressed.connect(reset_game)
	vbox.add_child(reset_btn)

	# End-Modal
	end_modal = PanelContainer.new()
	end_modal.anchors_preset = Control.PRESET_CENTER
	end_modal.offset_left = -220
	end_modal.offset_top = -120
	end_modal.offset_right = 220
	end_modal.offset_bottom = 120
	end_modal.visible = false
	ui_layer.add_child(end_modal)

	var m_vbox = VBoxContainer.new()
	m_vbox.add_theme_constant_override("separation", 10)
	end_modal.add_child(m_vbox)

	var m_title = Label.new()
	m_title.name = "ModalTitle"
	m_title.text = "🏆 MISSION ERFOLGREICH!"
	m_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	m_vbox.add_child(m_title)

	var m_desc = Label.new()
	m_desc.name = "ModalDesc"
	m_desc.text = "Feindliche Basis wurde vernichtet!"
	m_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	m_vbox.add_child(m_desc)

	var m_btn = Button.new()
	m_btn.text = "🔄 Neues Gefecht"
	m_btn.custom_minimum_size = Vector2(0, 44)
	m_btn.pressed.connect(reset_game)
	m_vbox.add_child(m_btn)

func update_credits_display():
	if credits_label:
		credits_label.text = "💰 CREDITS: $" + str(credits)

func execute_tank_assault():
	if is_attacking: return
	is_attacking = true
	emit_signal("sound_triggered", "shoot")
	emit_signal("status_changed", "⚔️ VOLLER PANZERANGRIFF! Panzer feuern 120mm Granaten!")

	# Panzer rollen vor und eröffnen das Feuer
	for u in units:
		if is_instance_valid(u.node):
			var node = u.node
			var fwd = 2.4 if not u.is_enemy else -2.4
			var tw = create_tween()
			tw.tween_property(node, "position:x", node.position.x + fwd, 0.45)

	get_tree().create_timer(0.5).timeout.connect(func():
		for u in units:
			if is_instance_valid(u.node):
				var flash = u.node.find_child("MuzzleFlash", true, false)
				if flash: spawn_cannon_projectile(flash.global_position, u.is_enemy)

		get_tree().create_timer(0.6).timeout.connect(func():
			soviet_base_hp = max(0, soviet_base_hp - 35)
			if is_bot_opponent:
				allied_base_hp = max(0, allied_base_hp - 20)
			
			if soviet_base_hp <= 0:
				show_match_result(true)
			elif allied_base_hp <= 0:
				show_match_result(false)
			else:
				is_attacking = false
				emit_signal("status_changed", "Feindbasis schwer beschädigt! Sowjet-Basis HP: " + str(soviet_base_hp) + "% | Alliierte HP: " + str(allied_base_hp) + "%")
		)
	)

func trigger_tesla_supercharge():
	if credits < 1200:
		emit_signal("status_changed", "⚠️ Zu wenig Credits für Tesla-Schlag ($1200 benötigt)!")
		return
	credits -= 1200
	update_credits_display()

	emit_signal("sound_triggered", "shoot")
	emit_signal("status_changed", "⚡ TESLA-SPULE VOLL GELADEN! 10.000 Volt Blitzschlag!")

	if is_instance_valid(tesla_coil_node):
		var tw = create_tween()
		tw.tween_property(tesla_light, "light_energy", 9.0, 0.15)
		tw.tween_property(tesla_light, "light_energy", 1.2, 0.35)

		# Schlage Blitze auf gegnerische Einheiten ein
		for u in units:
			if not u.is_enemy and is_instance_valid(u.node):
				spawn_tesla_bolt(tesla_coil_node.position + Vector3(0, 2.2, 0), u.node.position + Vector3(0, 0.5, 0))

func spawn_cannon_projectile(from_pos: Vector3, is_enemy: bool):
	var p = MeshInstance3D.new()
	var sm = SphereMesh.new()
	sm.radius = 0.14
	sm.height = 0.28
	p.mesh = sm
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.6, 0.1)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.5, 0.05)
	mat.emission_energy_multiplier = 3.0
	p.material_override = mat
	p.position = from_pos
	add_child(p)

	var target = from_pos + Vector3(-7.5 if is_enemy else 7.5, 0.2, randf_range(-0.5, 0.5))
	var tw = create_tween()
	tw.tween_property(p, "position", target, 0.32)
	tw.tween_callback(func():
		emit_signal("sound_triggered", "shoot")
		p.queue_free()
	)

func spawn_tesla_bolt(from_p: Vector3, to_p: Vector3):
	var bolt = Node3D.new()
	add_child(bolt)

	var steps = 8
	var prev = from_p
	for s in range(1, steps + 1):
		var t = float(s) / float(steps)
		var next = from_p.lerp(to_p, t) + Vector3(randf_range(-0.4, 0.4), randf_range(-0.2, 0.4), randf_range(-0.4, 0.4))
		if s == steps: next = to_p

		var seg = MeshInstance3D.new()
		var cm = CylinderMesh.new()
		cm.top_radius = 0.04
		cm.bottom_radius = 0.04
		cm.height = prev.distance_to(next)
		seg.mesh = cm
		var b_mat = StandardMaterial3D.new()
		b_mat.albedo_color = Color(0.4, 0.85, 1.0)
		b_mat.emission_enabled = true
		b_mat.emission = Color(0.3, 0.8, 1.0)
		b_mat.emission_energy_multiplier = 4.0
		seg.material_override = b_mat

		seg.position = (prev + next) * 0.5
		seg.look_at(next, Vector3.UP)
		seg.rotate_object_local(Vector3.RIGHT, PI * 0.5)
		bolt.add_child(seg)
		prev = next

	get_tree().create_timer(0.35).timeout.connect(bolt.queue_free)

func show_match_result(player_won: bool):
	is_attacking = false
	if end_modal:
		end_modal.visible = true
		var t_lbl = end_modal.find_child("ModalTitle", true, false) as Label
		var d_lbl = end_modal.find_child("ModalDesc", true, false) as Label
		if player_won:
			emit_signal("sound_triggered", "win")
			if t_lbl: t_lbl.text = "🏆 MISSION ERFOLGREICH!"
			if d_lbl: d_lbl.text = "Sowjetischer Bauhof vernichtet! Die Schlacht um die Freiheit ist gewonnen!"
			emit_signal("status_changed", "🏆 SIEG! Feindliche Basis vernichtet!")
		else:
			emit_signal("sound_triggered", "loss")
			if t_lbl: t_lbl.text = "💀 BASIS VERNICHTET!"
			if d_lbl: d_lbl.text = "Die feindlichen Panzer haben deine Basis überrannt!"
			emit_signal("status_changed", "NIEDERLAGE! Deine Basis wurde zerstört!")

func reset_game():
	credits = 2400
	player_tanks = 3
	soviet_tanks = 3
	soviet_base_hp = 100
	allied_base_hp = 100
	is_attacking = false
	miner_phase = 0
	miner_timer = 0.0
	if end_modal: end_modal.visible = false
	update_credits_display()
	spawn_initial_tanks()
	emit_signal("status_changed", "Command & Conquer Red Alert 2: Sowjetischer Bauhof online. Erzsammler aktiv. Bereit zum Gefecht!")
