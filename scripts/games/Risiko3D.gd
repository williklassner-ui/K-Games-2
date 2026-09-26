extends Node3D

class_name Risiko3D

const TextureHelper = preload("res://scripts/TextureHelper.gd")

signal status_changed(msg: String)
signal sound_triggered(sound_name: String)

var territories: Array = []
var selected_index: int = 0
var target_attack_index: int = -1
var is_bot_opponent: bool = true
var player_armies_reserve: int = 15
var current_turn: String = "player" # "player" oder "ai"
var ui_layer: CanvasLayer = null

func _ready():
	setup_stage()
	setup_game_ui()
	emit_signal("status_changed", "Risiko 3D: Wähle ein eigenes Gebiet zum Angriff oder Verstärken!")

func setup_stage():
	# 1. Großer antiker Strategietisch mit Holzrahmen & Pergament-Weltkarte (26x16)
	var map_mesh = BoxMesh.new()
	map_mesh.size = Vector3(26.0, 0.45, 16.0)
	var map_inst = MeshInstance3D.new()
	map_inst.mesh = map_mesh
	map_inst.material_override = TextureHelper.get_parchment_material(Color(0.86, 0.80, 0.68))
	map_inst.position = Vector3(0, 0.2, 0)
	add_child(map_inst)

	# Holzrand um die Weltkarte
	var frame_mesh = BoxMesh.new()
	frame_mesh.size = Vector3(26.8, 0.4, 16.8)
	var frame_inst = MeshInstance3D.new()
	frame_inst.mesh = frame_mesh
	frame_inst.material_override = TextureHelper.get_wood_material(Color(0.18, 0.10, 0.05))
	frame_inst.position = Vector3(0, 0.1, 0)
	add_child(frame_inst)

	# 2. Die 42 offiziellen Territorien der Risiko-Weltkarte in 6 Kontinenten
	territories = [
		# NORDAMERIKA (9 Gebiete) - Gelb/Gold
		{"name": "Alaska", "pos": Vector3(-10.5, 0.45, -5.5), "size": Vector3(1.8, 0.12, 1.3), "col": Color(0.92, 0.78, 0.22), "cont": "Nordamerika", "owner": "player", "armies": 4},
		{"name": "Nordwest-Territorium", "pos": Vector3(-8.2, 0.45, -5.8), "size": Vector3(2.2, 0.12, 1.2), "col": Color(0.92, 0.78, 0.22), "cont": "Nordamerika", "owner": "player", "armies": 3},
		{"name": "Grönland", "pos": Vector3(-4.8, 0.45, -6.2), "size": Vector3(2.4, 0.12, 1.4), "col": Color(0.92, 0.78, 0.22), "cont": "Nordamerika", "owner": "player", "armies": 2},
		{"name": "Alberta", "pos": Vector3(-9.0, 0.45, -4.2), "size": Vector3(1.8, 0.12, 1.2), "col": Color(0.92, 0.78, 0.22), "cont": "Nordamerika", "owner": "player", "armies": 3},
		{"name": "Ontario", "pos": Vector3(-7.0, 0.45, -4.3), "size": Vector3(1.7, 0.12, 1.2), "col": Color(0.92, 0.78, 0.22), "cont": "Nordamerika", "owner": "player", "armies": 3},
		{"name": "Quebec", "pos": Vector3(-5.0, 0.45, -4.4), "size": Vector3(1.8, 0.12, 1.3), "col": Color(0.92, 0.78, 0.22), "cont": "Nordamerika", "owner": "player", "armies": 2},
		{"name": "Weststaaten (USA)", "pos": Vector3(-8.8, 0.45, -2.7), "size": Vector3(2.0, 0.12, 1.4), "col": Color(0.92, 0.78, 0.22), "cont": "Nordamerika", "owner": "player", "armies": 4},
		{"name": "Oststaaten (USA)", "pos": Vector3(-6.5, 0.45, -2.8), "size": Vector3(2.2, 0.12, 1.4), "col": Color(0.92, 0.78, 0.22), "cont": "Nordamerika", "owner": "player", "armies": 3},
		{"name": "Mittelamerika", "pos": Vector3(-7.6, 0.45, -1.0), "size": Vector3(1.8, 0.12, 1.4), "col": Color(0.92, 0.78, 0.22), "cont": "Nordamerika", "owner": "player", "armies": 3},

		# SÜDAMERIKA (4 Gebiete) - Orange/Rotbraun
		{"name": "Venezuela", "pos": Vector3(-6.8, 0.45, 0.8), "size": Vector3(1.9, 0.12, 1.3), "col": Color(0.88, 0.42, 0.16), "cont": "Südamerika", "owner": "enemy", "armies": 3},
		{"name": "Peru", "pos": Vector3(-7.2, 0.45, 2.5), "size": Vector3(1.8, 0.12, 1.5), "col": Color(0.88, 0.42, 0.16), "cont": "Südamerika", "owner": "enemy", "armies": 2},
		{"name": "Brasilien", "pos": Vector3(-5.0, 0.45, 2.2), "size": Vector3(2.4, 0.12, 1.8), "col": Color(0.88, 0.42, 0.16), "cont": "Südamerika", "owner": "enemy", "armies": 4},
		{"name": "Argentinien", "pos": Vector3(-6.2, 0.45, 4.6), "size": Vector3(1.8, 0.12, 2.0), "col": Color(0.88, 0.42, 0.16), "cont": "Südamerika", "owner": "enemy", "armies": 3},

		# EUROPA (7 Gebiete) - Blau
		{"name": "Island", "pos": Vector3(-2.8, 0.45, -5.6), "size": Vector3(1.4, 0.12, 1.0), "col": Color(0.24, 0.55, 0.88), "cont": "Europa", "owner": "player", "armies": 3},
		{"name": "Großbritannien", "pos": Vector3(-2.4, 0.45, -4.0), "size": Vector3(1.5, 0.12, 1.3), "col": Color(0.24, 0.55, 0.88), "cont": "Europa", "owner": "player", "armies": 4},
		{"name": "Westeuropa", "pos": Vector3(-2.2, 0.45, -2.2), "size": Vector3(1.8, 0.12, 1.5), "col": Color(0.24, 0.55, 0.88), "cont": "Europa", "owner": "player", "armies": 5},
		{"name": "Südeuropa", "pos": Vector3(-0.2, 0.45, -1.8), "size": Vector3(1.8, 0.12, 1.4), "col": Color(0.24, 0.55, 0.88), "cont": "Europa", "owner": "player", "armies": 3},
		{"name": "Nordeuropa", "pos": Vector3(-0.4, 0.45, -3.4), "size": Vector3(1.8, 0.12, 1.3), "col": Color(0.24, 0.55, 0.88), "cont": "Europa", "owner": "player", "armies": 4},
		{"name": "Skandinavien", "pos": Vector3(-0.6, 0.45, -5.2), "size": Vector3(1.9, 0.12, 1.6), "col": Color(0.24, 0.55, 0.88), "cont": "Europa", "owner": "player", "armies": 3},
		{"name": "Ukraine / Russland", "pos": Vector3(1.8, 0.45, -4.0), "size": Vector3(2.4, 0.12, 2.6), "col": Color(0.24, 0.55, 0.88), "cont": "Europa", "owner": "player", "armies": 5},

		# AFRIKA (6 Gebiete) - Ocker/Gelbbraun
		{"name": "Nordafrika", "pos": Vector3(-1.6, 0.45, 0.8), "size": Vector3(2.4, 0.12, 1.8), "col": Color(0.82, 0.68, 0.22), "cont": "Afrika", "owner": "enemy", "armies": 3},
		{"name": "Ägypten", "pos": Vector3(0.8, 0.45, 0.4), "size": Vector3(1.8, 0.12, 1.4), "col": Color(0.82, 0.68, 0.22), "cont": "Afrika", "owner": "enemy", "armies": 3},
		{"name": "Ostafrika", "pos": Vector3(1.4, 0.45, 2.4), "size": Vector3(1.8, 0.12, 1.8), "col": Color(0.82, 0.68, 0.22), "cont": "Afrika", "owner": "enemy", "armies": 2},
		{"name": "Kongo", "pos": Vector3(-0.4, 0.45, 2.8), "size": Vector3(1.7, 0.12, 1.6), "col": Color(0.82, 0.68, 0.22), "cont": "Afrika", "owner": "enemy", "armies": 3},
		{"name": "Südafrika", "pos": Vector3(0.4, 0.45, 4.8), "size": Vector3(2.0, 0.12, 1.7), "col": Color(0.82, 0.68, 0.22), "cont": "Afrika", "owner": "enemy", "armies": 4},
		{"name": "Madagaskar", "pos": Vector3(2.8, 0.45, 4.5), "size": Vector3(1.2, 0.12, 1.4), "col": Color(0.82, 0.68, 0.22), "cont": "Afrika", "owner": "enemy", "armies": 2},

		# ASIEN (12 Gebiete) - Grün
		{"name": "Ural", "pos": Vector3(4.2, 0.45, -4.8), "size": Vector3(1.8, 0.12, 2.2), "col": Color(0.25, 0.72, 0.35), "cont": "Asien", "owner": "enemy", "armies": 4},
		{"name": "Sibirien", "pos": Vector3(6.0, 0.45, -5.2), "size": Vector3(1.8, 0.12, 2.0), "col": Color(0.25, 0.72, 0.35), "cont": "Asien", "owner": "enemy", "armies": 3},
		{"name": "Jakutien", "pos": Vector3(8.0, 0.45, -5.6), "size": Vector3(1.8, 0.12, 1.6), "col": Color(0.25, 0.72, 0.35), "cont": "Asien", "owner": "enemy", "armies": 3},
		{"name": "Kamtschatka", "pos": Vector3(10.2, 0.45, -5.2), "size": Vector3(1.8, 0.12, 1.8), "col": Color(0.25, 0.72, 0.35), "cont": "Asien", "owner": "enemy", "armies": 4},
		{"name": "Irkutsk", "pos": Vector3(7.4, 0.45, -3.6), "size": Vector3(1.8, 0.12, 1.4), "col": Color(0.25, 0.72, 0.35), "cont": "Asien", "owner": "enemy", "armies": 2},
		{"name": "Mongolei", "pos": Vector3(7.8, 0.45, -2.0), "size": Vector3(2.0, 0.12, 1.4), "col": Color(0.25, 0.72, 0.35), "cont": "Asien", "owner": "enemy", "armies": 3},
		{"name": "Japan", "pos": Vector3(10.5, 0.45, -2.2), "size": Vector3(1.4, 0.12, 1.6), "col": Color(0.25, 0.72, 0.35), "cont": "Asien", "owner": "enemy", "armies": 3},
		{"name": "Afghanistan", "pos": Vector3(4.0, 0.45, -2.2), "size": Vector3(2.0, 0.12, 1.6), "col": Color(0.25, 0.72, 0.35), "cont": "Asien", "owner": "enemy", "armies": 4},
		{"name": "China", "pos": Vector3(6.6, 0.45, -0.4), "size": Vector3(2.5, 0.12, 1.8), "col": Color(0.25, 0.72, 0.35), "cont": "Asien", "owner": "enemy", "armies": 5},
		{"name": "Indien", "pos": Vector3(4.8, 0.45, 0.8), "size": Vector3(2.0, 0.12, 1.8), "col": Color(0.25, 0.72, 0.35), "cont": "Asien", "owner": "enemy", "armies": 4},
		{"name": "Südostasien", "pos": Vector3(7.4, 0.45, 1.4), "size": Vector3(1.8, 0.12, 1.6), "col": Color(0.25, 0.72, 0.35), "cont": "Asien", "owner": "enemy", "armies": 3},
		{"name": "Naher Osten", "pos": Vector3(2.4, 0.45, -0.4), "size": Vector3(2.0, 0.12, 1.6), "col": Color(0.25, 0.72, 0.35), "cont": "Asien", "owner": "enemy", "armies": 3},

		# AUSTRALIEN (4 Gebiete) - Violett/Purpur
		{"name": "Indonesien", "pos": Vector3(8.0, 0.45, 3.4), "size": Vector3(2.0, 0.12, 1.3), "col": Color(0.75, 0.35, 0.85), "cont": "Australien", "owner": "player", "armies": 4},
		{"name": "Neuguinea", "pos": Vector3(10.4, 0.45, 3.2), "size": Vector3(1.6, 0.12, 1.2), "col": Color(0.75, 0.35, 0.85), "cont": "Australien", "owner": "player", "armies": 3},
		{"name": "Westaustralien", "pos": Vector3(8.6, 0.45, 5.2), "size": Vector3(2.0, 0.12, 1.7), "col": Color(0.75, 0.35, 0.85), "cont": "Australien", "owner": "player", "armies": 4},
		{"name": "Ostaustralien", "pos": Vector3(10.6, 0.45, 5.4), "size": Vector3(1.8, 0.12, 1.8), "col": Color(0.75, 0.35, 0.85), "cont": "Australien", "owner": "player", "armies": 3}
	]

	# Erschaffe alle 42 Territorien auf dem Spielfeld mit Textur und Collision
	for i in range(territories.size()):
		var t = territories[i]
		var t_node = Node3D.new()
		t_node.name = "Territory_" + str(i)
		t_node.position = t.pos

		# 3D Bodenplatte des Territoriums
		var tile_mesh = BoxMesh.new()
		tile_mesh.size = t.size
		var tile_inst = MeshInstance3D.new()
		tile_inst.mesh = tile_mesh
		tile_inst.material_override = TextureHelper.get_stone_material(t.col)
		tile_inst.position = Vector3(0, t.size.y * 0.5, 0)
		t_node.add_child(tile_inst)

		# 3D StaticBody für verlässliches Touch- & Klick-Picking
		var sb = StaticBody3D.new()
		var col_shape = CollisionShape3D.new()
		var shape = BoxShape3D.new()
		shape.size = t.size + Vector3(0.3, 0.6, 0.3)
		col_shape.shape = shape
		sb.add_child(col_shape)
		sb.set_meta("grid_pos", Vector2i(i, 0))
		t_node.add_child(sb)

		# 3D Heeresfigur (Kanonen- und Infanterie-Sockel)
		var army_fig = create_army_figure(t.owner == "player")
		army_fig.name = "ArmyFigure"
		army_fig.position = Vector3(0, t.size.y, 0)
		t_node.add_child(army_fig)

		# 3D Namens- & Truppenbanner
		var lbl = Label3D.new()
		lbl.name = "ArmyLabel"
		lbl.pixel_size = 0.012
		lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		lbl.position = Vector3(0, 0.9, 0)
		lbl.outline_size = 4
		t_node.add_child(lbl)

		add_child(t_node)
		t["node"] = t_node

	update_all_labels()
	spawn_connecting_sea_routes()

func create_army_figure(is_player: bool) -> Node3D:
	var fig = Node3D.new()
	var col = Color(0.15, 0.45, 0.95) if is_player else Color(0.9, 0.2, 0.2)
	var mat = TextureHelper.get_metal_material(col, 0.8)

	var base_m = CylinderMesh.new()
	base_m.top_radius = 0.2
	base_m.bottom_radius = 0.25
	base_m.height = 0.15
	var base_inst = MeshInstance3D.new()
	base_inst.mesh = base_m
	base_inst.material_override = mat
	base_inst.position = Vector3(0, 0.08, 0)
	fig.add_child(base_inst)

	var cannon_m = CylinderMesh.new()
	cannon_m.top_radius = 0.08
	cannon_m.bottom_radius = 0.12
	cannon_m.height = 0.35
	var cannon_inst = MeshInstance3D.new()
	cannon_inst.mesh = cannon_m
	cannon_inst.material_override = mat
	cannon_inst.position = Vector3(0, 0.28, 0)
	fig.add_child(cannon_inst)

	return fig

func spawn_connecting_sea_routes():
	# Symbolische Seewege (Pazifik-Route Alaska <-> Kamtschatka etc.)
	var sea_mat = TextureHelper.get_water_material(Color(0.1, 0.35, 0.65, 0.7))
	var pacific_line = BoxMesh.new()
	pacific_line.size = Vector3(24.0, 0.02, 0.15)
	var pl_inst = MeshInstance3D.new()
	pl_inst.mesh = pacific_line
	pl_inst.material_override = sea_mat
	pl_inst.position = Vector3(0, 0.44, -5.35)
	add_child(pl_inst)

func setup_game_ui():
	ui_layer = CanvasLayer.new()
	add_child(ui_layer)

	var panel = PanelContainer.new()
	panel.anchors_preset = Control.PRESET_BOTTOM_RIGHT
	panel.offset_left = -380
	panel.offset_top = -210
	panel.offset_right = -20
	panel.offset_bottom = -20
	ui_layer.add_child(panel)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	panel.add_child(vbox)

	var info_lbl = Label.new()
	info_lbl.name = "TerritoryInfo"
	info_lbl.text = "Gebiet: Alaska | Besitzer: Du | Armeen: 4"
	vbox.add_child(info_lbl)

	var attack_btn = Button.new()
	attack_btn.text = "⚔️ Feindliches Gebiet angreifen (Würfeln)"
	attack_btn.custom_minimum_size = Vector2(0, 44)
	attack_btn.pressed.connect(attack_selected)
	vbox.add_child(attack_btn)

	var recruit_btn = Button.new()
	recruit_btn.text = "🛡️ Verstärkung platzieren (+2 Armeen)"
	recruit_btn.custom_minimum_size = Vector2(0, 40)
	recruit_btn.pressed.connect(recruit_armies)
	vbox.add_child(recruit_btn)

	var end_turn_btn = Button.new()
	end_turn_btn.text = "⏩ Zug beenden (Gegner / Bot zieht)"
	end_turn_btn.custom_minimum_size = Vector2(0, 40)
	end_turn_btn.pressed.connect(end_turn)
	vbox.add_child(end_turn_btn)

func handle_tile_clicked(grid_pos: Vector2i):
	var idx = grid_pos.x
	if idx < 0 or idx >= territories.size(): return
	var t = territories[idx]
	selected_index = idx
	emit_signal("sound_triggered", "select")
	
	var owner_str = "Du" if t.owner == "player" else ("Gegner (Bot)" if is_bot_opponent else "Spieler 2")
	emit_signal("status_changed", t.name + " (" + t.cont + ") gewählt | " + owner_str + " | " + str(t.armies) + " ⚔️")
	
	var info = ui_layer.get_node_or_null("PanelContainer/VBoxContainer/TerritoryInfo") as Label
	if info:
		info.text = "Gebiet: " + t.name + " [" + t.cont + "]\nBesitzer: " + owner_str + " | Armeen: " + str(t.armies)

func attack_selected():
	var t = territories[selected_index]
	if t.owner == "player":
		# Suche feindliches Nachbargebiet
		var enemy_found = -1
		for i in range(territories.size()):
			if territories[i].owner != "player":
				enemy_found = i
				break
		if enemy_found != -1:
			execute_battle(selected_index, enemy_found)
	else:
		# Suche stärkstes eigenes Gebiet zum Angriff
		var best_player_idx = -1
		var best_armies = 0
		for i in range(territories.size()):
			if territories[i].owner == "player" and territories[i].armies > best_armies:
				best_armies = territories[i].armies
				best_player_idx = i
		if best_player_idx != -1:
			execute_battle(best_player_idx, selected_index)

func execute_battle(attacker_idx: int, defender_idx: int):
	var att = territories[attacker_idx]
	var def = territories[defender_idx]
	if att.armies <= 1:
		emit_signal("status_changed", att.name + " hat nicht genug Armeen zum Angreifen (mind. 2 erforderlich)!")
		return

	emit_signal("sound_triggered", "dice")
	# Original Risiko Würfelkampf: Angreifer rollt bis zu 3W6, Verteidiger bis zu 2W6
	var att_dice = [randi_range(1, 6), randi_range(1, 6)]
	if att.armies >= 4: att_dice.append(randi_range(1, 6))
	att_dice.sort_custom(func(a, b): return a > b)

	var def_dice = [randi_range(1, 6)]
	if def.armies >= 2: def_dice.append(randi_range(1, 6))
	def_dice.sort_custom(func(a, b): return a > b)

	var def_loss = 0
	var att_loss = 0
	if att_dice[0] > def_dice[0]:
		def_loss += 1
	else:
		att_loss += 1

	if att_dice.size() > 1 and def_dice.size() > 1:
		if att_dice[1] > def_dice[1]:
			def_loss += 1
		else:
			att_loss += 1

	att.armies = max(1, att.armies - att_loss)
	def.armies -= def_loss

	if def.armies <= 0:
		# Gebiet erobert!
		def.owner = att.owner
		def.armies = max(1, att.armies - 1)
		att.armies = 1
		emit_signal("sound_triggered", "win")
		emit_signal("status_changed", "🏆 KONTINENT-SCHLACHT GEWONNEN! " + def.name + " wurde erobert!")
	else:
		emit_signal("sound_triggered", "shoot")
		emit_signal("status_changed", "Gefecht bei " + def.name + ": Angreifer verliert " + str(att_loss) + ", Verteidiger verliert " + str(def_loss) + "!")

	update_all_labels()

func recruit_armies():
	var t = territories[selected_index]
	if t.owner != "player":
		emit_signal("status_changed", "Du kannst nur eigene Gebiete verstärken!")
		return
	t.armies += 2
	emit_signal("sound_triggered", "move")
	emit_signal("status_changed", t.name + " mit +2 Armeen verstärkt! Jetzt: " + str(t.armies) + " ⚔️")
	update_all_labels()

func end_turn():
	if is_bot_opponent:
		emit_signal("status_changed", "Der Bot-Gegner plant seinen Strategiezug...")
		get_tree().create_timer(0.8).timeout.connect(bot_take_turn)
	else:
		emit_signal("status_changed", "Spieler 2 ist am Zug!")

func bot_take_turn():
	# Bot sucht eigenes starkes Gebiet und greift an
	var bot_territories = []
	for i in range(territories.size()):
		if territories[i].owner == "enemy":
			bot_territories.append(i)

	if bot_territories.is_empty():
		emit_signal("sound_triggered", "win")
		emit_signal("status_changed", "WELTHERRSCHAFT! Du hast alle 42 Gebiete der Welt erobert!")
		return

	# Bot verstärkt
	var pick = bot_territories.pick_random()
	territories[pick].armies += 2

	# Bot greift zufälliges Spielergebiet an
	var player_territories = []
	for i in range(territories.size()):
		if territories[i].owner == "player":
			player_territories.append(i)

	if not player_territories.is_empty():
		var target = player_territories.pick_random()
		execute_battle(pick, target)
	update_all_labels()

func update_all_labels():
	for t in territories:
		var node = t.node as Node3D
		if node:
			var lbl = node.get_node_or_null("ArmyLabel") as Label3D
			if lbl:
				var owner_icon = "🔵 Du" if t.owner == "player" else "🔴 Feind"
				lbl.text = t.name + "\n" + owner_icon + ": " + str(t.armies) + " ⚔️"
				lbl.modulate = Color(0.2, 0.6, 1.0) if t.owner == "player" else Color(1.0, 0.3, 0.3)
