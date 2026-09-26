extends Node3D

# K-Games 2: Native Vulkan 3D Game Suite
const VERSION = "0.013"

const SoundManagerScript = preload("res://scripts/SoundManager.gd")
const TextureHelper = preload("res://scripts/TextureHelper.gd")
var sound_mgr: Node = null

@onready var camera_pivot = $CameraPivot
@onready var camera_3d = $CameraPivot/Camera3D
@onready var status_label = $UI/TopBar/StatusLabel
@onready var title_label = $UI/TopBar/TitleLabel
@onready var world_3d = $World3D

var current_game_instance: Node3D = null
var current_game = "overview"

# Touch- und Orbit-Kamerasteuerung
var is_dragging = false
var drag_start_mouse = Vector2.ZERO
var rot_y = 0.0
var rot_x = -0.5
var touch_start_pos = Vector2.ZERO
var is_tap = false
var last_click_time_msec: int = 0

# UI Dialoge
var main_menu_modal: Control = null
var settings_modal: Control = null
var game_selection_modal: Control = null
var player_setup_modal: Control = null
var selected_game_to_launch: String = ""

# App Settings State
var sound_enabled = true
var shadows_enabled = true
var msaa_quality = 2 # 0=Aus, 1=2x, 2=4x

# Alle 17 Spiele aus K-Games als 3D-Klassen
const SCRIPTS = {
	"chess": preload("res://scripts/games/Chess3D.gd"),
	"risiko": preload("res://scripts/games/Risiko3D.gd"),
	"battleship": preload("res://scripts/games/Battleship3D.gd"),
	"ctp2": preload("res://scripts/games/Civilization3D.gd"),
	"mensch": preload("res://scripts/games/MenschAergereDichNicht3D.gd"),
	"monopoly": preload("res://scripts/games/Monopoly3D.gd"),
	"kniffel": preload("res://scripts/games/Kniffel3D.gd"),
	"lotti": preload("res://scripts/games/LottiKarotti3D.gd"),
	"katan": preload("res://scripts/games/Katan3D.gd"),
	"scotland": preload("res://scripts/games/ScotlandYard3D.gd"),
	"ra2": preload("res://scripts/games/Ra23D.gd"),
	"snakes": preload("res://scripts/games/SnakesAndLadders3D.gd"),
	"space": preload("res://scripts/games/SpaceInvaders3D.gd"),
	"tetris": preload("res://scripts/games/Tetris3D.gd"),
	"uno": preload("res://scripts/games/Uno3D.gd"),
	"uno_extreme": preload("res://scripts/games/UnoExtreme3D.gd"),
	"durak": preload("res://scripts/games/Durak3D.gd")
}

const GAME_METADATA = [
	{"id": "chess", "name": "Schach 3D", "icon": "♟️", "cat": "Brettspiel"},
	{"id": "ctp2", "name": "Civilization CtP2 3D", "icon": "🏛️", "cat": "Strategie"},
	{"id": "ra2", "name": "C&C Alarmstufe Rot 2 3D", "icon": "⚡", "cat": "Strategie"},
	{"id": "risiko", "name": "Risiko 3D", "icon": "🌍", "cat": "Strategie"},
	{"id": "battleship", "name": "Schiffe versenken 3D", "icon": "🚢", "cat": "Taktik"},
	{"id": "monopoly", "name": "Monopoly 3D", "icon": "🎩", "cat": "Brettspiel"},
	{"id": "mensch", "name": "Mensch ärgere dich nicht 3D", "icon": "🎲", "cat": "Klassiker"},
	{"id": "katan", "name": "Siedler von Katan 3D", "icon": "🌾", "cat": "Brettspiel"},
	{"id": "scotland", "name": "Scotland Yard 3D", "icon": "🕵️", "cat": "Taktik"},
	{"id": "lotti", "name": "Lotti Karotti 3D", "icon": "🥕", "cat": "Familie"},
	{"id": "kniffel", "name": "Kniffel 3D", "icon": "🎯", "cat": "Würfelspiel"},
	{"id": "snakes", "name": "Snakes & Ladders 3D", "icon": "🐍", "cat": "Klassiker"},
	{"id": "space", "name": "Space Invaders 3D", "icon": "👾", "cat": "Arcade"},
	{"id": "tetris", "name": "Tetris 3D", "icon": "🧱", "cat": "Puzzle"},
	{"id": "uno", "name": "UNO 3D", "icon": "🃏", "cat": "Kartenspiel"},
	{"id": "uno_extreme", "name": "UNO Extreme 3D", "icon": "🚀", "cat": "Kartenspiel"},
	{"id": "durak", "name": "Durak 3D", "icon": "🂡", "cat": "Kartenspiel"}
]

func _notification(what):
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		# Android Hardware-Zurücktaste
		play_sound("click")
		if is_modal_open():
			close_all_modals()
		else:
			toggle_main_menu()

func _ready():
	print("=== K-Games 2 Suite v", VERSION, " Initialized ===")
	sound_mgr = SoundManagerScript.new()
	sound_mgr.name = "SoundManager"
	add_child(sound_mgr)

	if title_label:
		title_label.text = "K-GAMES 2 (3D VULKAN ENGINE)"

	setup_3d_tabletop_scene()
	build_topbar_actions()
	build_modals()

	# Startspiel initialisieren
	switch_game("chess")

	# Startet mit zentrierter Spielauswahl über die gesamte Fenstergröße
	toggle_game_selection()

func play_sound(s_name: String):
	if sound_mgr and sound_mgr.has_method("play"):
		sound_mgr.play(s_name)

func _unhandled_input(event):
	# Schließen aller Menüs/Settings mit ESC oder Zurücktaste (Windows & Android)
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE or event.keycode == KEY_BACK:
			play_sound("click")
			if is_modal_open():
				close_all_modals()
			else:
				toggle_main_menu()
			get_viewport().set_input_as_handled()
			return

	if is_modal_open():
		return

	if event is InputEventScreenTouch:
		if event.pressed:
			is_dragging = false
			is_tap = true
			drag_start_mouse = event.position
			touch_start_pos = event.position
		else:
			if is_tap:
				raycast_click(event.position)
			is_dragging = false
			is_tap = false
	elif event is InputEventScreenDrag:
		var total_dist = (event.position - touch_start_pos).length()
		if total_dist > 18.0:
			is_tap = false
			is_dragging = true
			var delta = event.position - drag_start_mouse
			drag_start_mouse = event.position
			rot_y -= delta.x * 0.005
			rot_x = clamp(rot_x - delta.y * 0.005, -1.2, 0.2)
			camera_pivot.rotation.y = rot_y
			camera_pivot.rotation.x = rot_x
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				is_dragging = false
				is_tap = true
				drag_start_mouse = event.position
				touch_start_pos = event.position
			else:
				if is_tap:
					raycast_click(event.position)
				is_dragging = false
				is_tap = false
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			is_dragging = event.pressed
			drag_start_mouse = event.position
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			camera_3d.position.z = max(5.0, camera_3d.position.z - 0.75)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			camera_3d.position.z = min(35.0, camera_3d.position.z + 0.75)
	elif event is InputEventMouseMotion and is_dragging:
		var delta = event.position - drag_start_mouse
		drag_start_mouse = event.position
		rot_y -= delta.x * 0.005
		rot_x = clamp(rot_x - delta.y * 0.005, -1.2, 0.2)
		camera_pivot.rotation.y = rot_y
		camera_pivot.rotation.x = rot_x

func raycast_click(screen_pos: Vector2):
	var now = Time.get_ticks_msec()
	if now - last_click_time_msec < 160:
		return
	last_click_time_msec = now

	if not current_game_instance or not is_instance_valid(camera_3d): return
	var ray_origin = camera_3d.project_ray_origin(screen_pos)
	var ray_normal = camera_3d.project_ray_normal(screen_pos)
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(ray_origin, ray_origin + ray_normal * 150.0)
	query.collide_with_areas = true
	query.collide_with_bodies = true
	var result = space_state.intersect_ray(query)
	if result and result.collider:
		var target_col = result.collider
		var g_pos = null
		if target_col.has_meta("grid_pos"):
			g_pos = target_col.get_meta("grid_pos")
		elif target_col.get_parent() and target_col.get_parent().has_meta("grid_pos"):
			g_pos = target_col.get_parent().get_meta("grid_pos")
		elif target_col.get_owner() and target_col.get_owner().has_meta("grid_pos"):
			g_pos = target_col.get_owner().get_meta("grid_pos")
		
		if g_pos != null and current_game_instance.has_method("handle_tile_clicked"):
			current_game_instance.handle_tile_clicked(g_pos)

func setup_3d_tabletop_scene():
	var table_mesh = BoxMesh.new()
	table_mesh.size = Vector3(40.0, 0.8, 40.0)
	var table_inst = MeshInstance3D.new()
	table_inst.mesh = table_mesh
	table_inst.material_override = TextureHelper.get_wood_material(Color(0.12, 0.07, 0.04))
	table_inst.position = Vector3(0, -0.4, 0)
	world_3d.add_child(table_inst)

func switch_game(game_id: String, bot_opponent: bool = true):
	current_game = game_id
	if current_game_instance:
		current_game_instance.queue_free()
		current_game_instance = null

	close_all_modals()

	if SCRIPTS.has(game_id):
		var game_node = Node3D.new()
		game_node.name = game_id.capitalize() + "Instance"
		game_node.set_script(SCRIPTS[game_id])
		if "is_bot_opponent" in game_node:
			game_node.is_bot_opponent = bot_opponent
		if game_node.has_signal("status_changed"):
			game_node.connect("status_changed", Callable(self, "_on_game_status_changed"))
		if game_node.has_signal("sound_triggered"):
			game_node.connect("sound_triggered", Callable(self, "play_sound"))

		world_3d.add_child(game_node)
		current_game_instance = game_node

		for meta in GAME_METADATA:
			if meta.id == game_id:
				if status_label:
					var mode_str = " (gegen Bot)" if bot_opponent else " (2 Spieler Pass & Play)"
					status_label.text = meta.icon + " " + meta.name + mode_str
				break

	# Entsprechenden Sound für Spielstart spielen
	match game_id:
		"chess", "mensch", "monopoly", "katan", "scotland", "lotti", "snakes":
			play_sound("move")
		"kniffel":
			play_sound("dice")
		"durak", "uno", "uno_extreme":
			play_sound("card")
		"battleship", "ra2", "space":
			play_sound("shoot")
		"tetris", "ctp2", "risiko":
			play_sound("select")
		_:
			play_sound("click")

	print("Switched to: ", game_id, " (Bot: ", bot_opponent, ")")

func _on_game_status_changed(msg: String):
	if status_label:
		status_label.text = msg

# ==================== UI SYSTEM ====================

func build_topbar_actions():
	var topbar = $UI/TopBar
	topbar.mouse_filter = Control.MOUSE_FILTER_STOP
	
	# Nur noch der Menü-Button in der TopBar (Spiele & Settings ins Menü verschoben)
	var menu_btn = Button.new()
	menu_btn.text = "☰ Menü"
	menu_btn.custom_minimum_size = Vector2(110, 44)
	menu_btn.position = Vector2(14, 8)
	menu_btn.mouse_filter = Control.MOUSE_FILTER_STOP
	menu_btn.pressed.connect(func():
		play_sound("click")
		toggle_main_menu()
	)
	topbar.add_child(menu_btn)

	# TitleLabel oben rechts positionieren (wie gefordert)
	var title = topbar.get_node_or_null("TitleLabel")
	if title:
		title.set_anchors_preset(Control.PRESET_TOP_RIGHT)
		title.offset_left = -340.0
		title.offset_right = -16.0
		title.offset_top = 14.0
		title.offset_bottom = 44.0
		title.grow_horizontal = Control.GROW_DIRECTION_BEGIN
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		title.text = "K-GAMES 2 (3D VULKAN ENGINE)"
		title.mouse_filter = Control.MOUSE_FILTER_IGNORE

	if status_label:
		status_label.mouse_filter = Control.MOUSE_FILTER_IGNORE

func build_modals():
	var ui = $UI

	# 1. Hauptmenü Modal (Komplette Fenstergröße, zentriert)
	var mm_data = create_fullscreen_modal_panel("K-Games 2 - Hauptmenü", func():
		play_sound("click")
		close_all_modals()
	)
	main_menu_modal = mm_data["container"]
	var mm_vbox = mm_data["vbox"]

	var btn_continue = create_dialog_button("▶️ Weiterspielen / Zurück (ESC)", func():
		play_sound("click")
		close_all_modals()
	)
	var btn_all_games = create_dialog_button("🎮 Spielauswahl öffnen (17 Spiele in 3D)", func():
		play_sound("click")
		toggle_game_selection()
	)
	var btn_settings = create_dialog_button("⚙️ Einstellungen / Settings", func():
		play_sound("click")
		toggle_settings()
	)
	var btn_reset_cam = create_dialog_button("🔄 3D-Kamera zurücksetzen", func():
		play_sound("click")
		reset_camera()
	)
	var btn_quit = create_dialog_button("❌ Beenden", func():
		play_sound("click")
		get_tree().quit()
	)

	mm_vbox.add_child(btn_continue)
	mm_vbox.add_child(btn_all_games)
	mm_vbox.add_child(btn_settings)
	mm_vbox.add_child(btn_reset_cam)
	mm_vbox.add_child(btn_quit)
	ui.add_child(main_menu_modal)

	# 2. Settings Modal (Komplette Fenstergröße, zentriert)
	var s_data = create_fullscreen_modal_panel("⚙️ App-Einstellungen (Settings)", func():
		play_sound("click")
		toggle_main_menu()
	)
	settings_modal = s_data["container"]
	var s_vbox = s_data["vbox"]

	# Audio Toggle
	var sound_chk = CheckBox.new()
	sound_chk.text = "🔊 Sound-Effekte & Audio aktiviert"
	sound_chk.button_pressed = sound_enabled
	sound_chk.toggled.connect(func(val):
		sound_enabled = val
		if sound_mgr and sound_mgr.has_method("set_sound_enabled"):
			sound_mgr.set_sound_enabled(val)
		if val:
			play_sound("select")
	)
	s_vbox.add_child(sound_chk)

	# Schatten Toggle
	var shadow_chk = CheckBox.new()
	shadow_chk.text = "💡 Dynamischer 3D-Schattenwurf (High Quality)"
	shadow_chk.button_pressed = shadows_enabled
	shadow_chk.toggled.connect(func(val):
		play_sound("click")
		shadows_enabled = val
		var dir_light = get_node_or_null("DirectionalLight3D")
		if dir_light: dir_light.shadow_enabled = val
	)
	s_vbox.add_child(shadow_chk)

	# App Info
	var info_lbl = Label.new()
	info_lbl.text = "\nApp Info:\n• Version: v" + VERSION + " (Format: x.xxx)\n• Render-Engine: Godot 4.7 (Vulkan Forward+ / Mobile)\n• Multiplattform: Windows 64-bit & Android APK\n• Entwickler: Willi Klassner"
	s_vbox.add_child(info_lbl)

	var s_close = create_dialog_button("◀️ Zurück zum Hauptmenü (ESC)", func():
		play_sound("click")
		toggle_main_menu()
	)
	s_vbox.add_child(s_close)
	ui.add_child(settings_modal)

	# 3. Spielauswahl Modal (Komplette Fenstergröße, zentriert mit Scroll-Grid)
	var gs_data = create_fullscreen_modal_panel("🎮 Spielauswahl - 17 Klassiker in 3D", func():
		play_sound("click")
		toggle_main_menu()
	)
	game_selection_modal = gs_data["container"]
	var gs_vbox = gs_data["vbox"]

	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	
	var grid = GridContainer.new()
	grid.columns = 3
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 16)
	grid.add_theme_constant_override("v_separation", 14)
	scroll.add_child(grid)

	for g in GAME_METADATA:
		var card = Button.new()
		card.text = g.icon + " " + g.name + "\n[" + g.cat + "]"
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.custom_minimum_size = Vector2(240, 72)
		card.mouse_filter = Control.MOUSE_FILTER_STOP
		var gid = g.id
		card.pressed.connect(func():
			prompt_player_setup(gid)
		)
		grid.add_child(card)

	gs_vbox.add_child(scroll)
	var gs_close = create_dialog_button("◀️ Zurück zum Hauptmenü (ESC)", func():
		play_sound("click")
		toggle_main_menu()
	)
	gs_vbox.add_child(gs_close)
	ui.add_child(game_selection_modal)

	# 4. Vor Spielstart Spieler- & Bot-Auswahl Modal (Komplette Fenstergröße, zentriert)
	var ps_data = create_fullscreen_modal_panel("👥 Spielmodus auswählen: Einzelspieler oder Mehrspieler", func():
		play_sound("click")
		toggle_game_selection()
	)
	player_setup_modal = ps_data["container"]
	var ps_vbox = ps_data["vbox"]

	var ps_info = Label.new()
	ps_info.name = "GameTitleLabel"
	ps_info.text = "Wähle deine Spielweise vor dem Spielbeginn:"
	ps_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ps_vbox.add_child(ps_info)

	var btn_bot = create_dialog_button("👤 Einzelspieler (Gegen intelligenten KI-Bot spielen)", func():
		play_sound("click")
		switch_game(selected_game_to_launch, true)
	)
	ps_vbox.add_child(btn_bot)

	var btn_human = create_dialog_button("👥 2 Spieler (Mensch gegen Mensch / Pass & Play)", func():
		play_sound("click")
		switch_game(selected_game_to_launch, false)
	)
	ps_vbox.add_child(btn_human)

	var btn_ps_cancel = create_dialog_button("◀️ Zurück zur Spielauswahl (ESC)", func():
		play_sound("click")
		toggle_game_selection()
	)
	ps_vbox.add_child(btn_ps_cancel)
	ui.add_child(player_setup_modal)

	close_all_modals()

func create_fullscreen_modal_panel(title_str: String, back_callback: Callable = Callable()) -> Dictionary:
	var container = Control.new()
	container.set_anchors_preset(Control.PRESET_FULL_RECT)
	container.offset_left = 0
	container.offset_top = 0
	container.offset_right = 0
	container.offset_bottom = 0
	container.mouse_filter = Control.MOUSE_FILTER_STOP

	# Hintergrund
	var bg = ColorRect.new()
	bg.color = Color(0.04, 0.06, 0.1, 0.88)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.offset_left = 0
	bg.offset_top = 0
	bg.offset_right = 0
	bg.offset_bottom = 0
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	container.add_child(bg)

	# Panel über das gesamte Fenster zentriert
	var panel = PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.offset_left = 32
	panel.offset_top = 32
	panel.offset_right = -32
	panel.offset_bottom = -32
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	container.add_child(panel)

	var margin = MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.offset_left = 0
	margin.offset_top = 0
	margin.offset_right = 0
	margin.offset_bottom = 0
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_bottom", 16)
	margin.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.name = "VBox"
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 12)
	vbox.mouse_filter = Control.MOUSE_FILTER_STOP
	margin.add_child(vbox)

	# Header-Leiste mit Zurück-Button, Titel und Schließen-Kreuz
	var header_hbox = HBoxContainer.new()
	header_hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_hbox.add_theme_constant_override("separation", 12)

	var top_back_btn = Button.new()
	top_back_btn.text = "◀️ Zurück (ESC)"
	top_back_btn.custom_minimum_size = Vector2(130, 42)
	top_back_btn.mouse_filter = Control.MOUSE_FILTER_STOP
	top_back_btn.pressed.connect(func():
		play_sound("click")
		if back_callback.is_valid():
			back_callback.call()
		else:
			close_all_modals()
	)
	header_hbox.add_child(top_back_btn)

	var title = Label.new()
	title.text = title_str
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header_hbox.add_child(title)

	var top_close_btn = Button.new()
	top_close_btn.text = "✖ Schließen"
	top_close_btn.custom_minimum_size = Vector2(110, 42)
	top_close_btn.mouse_filter = Control.MOUSE_FILTER_STOP
	top_close_btn.pressed.connect(func():
		play_sound("click")
		close_all_modals()
	)
	header_hbox.add_child(top_close_btn)

	vbox.add_child(header_hbox)

	var sep = HSeparator.new()
	sep.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(sep)

	return {"container": container, "vbox": vbox}

func create_dialog_button(txt: String, callback: Callable) -> Button:
	var btn = Button.new()
	btn.text = txt
	btn.custom_minimum_size = Vector2(0, 52)
	btn.mouse_filter = Control.MOUSE_FILTER_STOP
	btn.pressed.connect(callback)
	return btn

func prompt_player_setup(game_id: String):
	selected_game_to_launch = game_id
	close_all_modals()
	if player_setup_modal:
		var lbl = player_setup_modal.find_child("GameTitleLabel", true, false) as Label
		for g in GAME_METADATA:
			if g.id == game_id:
				if lbl:
					lbl.text = "Gewähltes Spiel: " + g.icon + " " + g.name + " (" + g.cat + ")\nWähle deine Spielweise vor dem Beginn:"
				break
		player_setup_modal.visible = true

func toggle_main_menu():
	var cur = main_menu_modal.visible
	close_all_modals()
	main_menu_modal.visible = not cur

func toggle_settings():
	var cur = settings_modal.visible
	close_all_modals()
	settings_modal.visible = not cur

func toggle_game_selection():
	var cur = game_selection_modal.visible
	close_all_modals()
	game_selection_modal.visible = not cur

func close_all_modals():
	if main_menu_modal: main_menu_modal.visible = false
	if settings_modal: settings_modal.visible = false
	if game_selection_modal: game_selection_modal.visible = false
	if player_setup_modal: player_setup_modal.visible = false

func is_modal_open() -> bool:
	return (main_menu_modal and main_menu_modal.visible) or (settings_modal and settings_modal.visible) or (game_selection_modal and game_selection_modal.visible) or (player_setup_modal and player_setup_modal.visible)

func reset_camera():
	rot_y = 0.0
	rot_x = -0.5
	camera_pivot.rotation.y = rot_y
	camera_pivot.rotation.x = rot_x
	camera_3d.position = Vector3(0, 0, 12)
	close_all_modals()
