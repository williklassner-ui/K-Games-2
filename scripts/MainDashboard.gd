extends Node3D

# K-Games 2: Native Vulkan 3D Game Suite
const VERSION = "0.008"

const SoundManagerScript = preload("res://scripts/SoundManager.gd")
var sound_mgr: Node = null

@onready var camera_pivot = $CameraPivot
@onready var camera_3d = $CameraPivot/Camera3D
@onready var status_label = $UI/TopBar/StatusLabel
@onready var version_label = $UI/TopBar/VersionLabel
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

# UI Dialoge
var main_menu_modal: Control = null
var settings_modal: Control = null
var game_selection_modal: Control = null
var bottom_bar: Control = null

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

func _ready():
	print("=== K-Games 2 Suite v", VERSION, " Initialized ===")
	sound_mgr = SoundManagerScript.new()
	sound_mgr.name = "SoundManager"
	add_child(sound_mgr)

	if version_label:
		version_label.text = "v" + VERSION + " (Vulkan Forward+)"
	setup_3d_tabletop_scene()
	build_topbar_actions()
	build_modals()
	build_quick_bottom_bar()

	# Startspiel initialisieren
	switch_game("chess")

	# Startet mit zentrierter Spielauswahl über die gesamte Fenstergröße
	toggle_game_selection()

func play_sound(s_name: String):
	if sound_mgr and sound_mgr.has_method("play"):
		sound_mgr.play(s_name)

func _unhandled_input(event):
	if is_modal_open():
		return

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				is_dragging = true
				is_tap = true
				drag_start_mouse = event.position
				touch_start_pos = event.position
			else:
				is_dragging = false
				if is_tap:
					raycast_click(event.position)
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			is_dragging = event.pressed
			drag_start_mouse = event.position
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			camera_3d.position.z = max(5.0, camera_3d.position.z - 0.5)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			camera_3d.position.z = min(25.0, camera_3d.position.z + 0.5)
			
	elif event is InputEventMouseMotion and is_dragging:
		var delta = event.position - drag_start_mouse
		if delta.length() > 5.0:
			is_tap = false
		drag_start_mouse = event.position
		rot_y -= delta.x * 0.005
		rot_x = clamp(rot_x - delta.y * 0.005, -1.2, 0.2)
		camera_pivot.rotation.y = rot_y
		camera_pivot.rotation.x = rot_x

func raycast_click(screen_pos: Vector2):
	if not current_game_instance or not is_instance_valid(camera_3d): return
	var ray_origin = camera_3d.project_ray_origin(screen_pos)
	var ray_normal = camera_3d.project_ray_normal(screen_pos)
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(ray_origin, ray_origin + ray_normal * 100.0)
	query.collide_with_areas = true
	query.collide_with_bodies = true
	var result = space_state.intersect_ray(query)
	if result and result.collider and result.collider.has_meta("grid_pos"):
		var g_pos = result.collider.get_meta("grid_pos")
		if current_game_instance.has_method("handle_tile_clicked"):
			current_game_instance.handle_tile_clicked(g_pos)

func setup_3d_tabletop_scene():
	var table_mesh = BoxMesh.new()
	table_mesh.size = Vector3(18.0, 0.6, 18.0)
	var table_inst = MeshInstance3D.new()
	table_inst.mesh = table_mesh
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.06, 0.09, 0.14)
	mat.roughness = 0.25
	mat.metallic = 0.5
	table_inst.material_override = mat
	table_inst.position = Vector3(0, -0.3, 0)
	world_3d.add_child(table_inst)

func switch_game(game_id: String):
	current_game = game_id
	if current_game_instance:
		current_game_instance.queue_free()
		current_game_instance = null

	close_all_modals()

	if SCRIPTS.has(game_id):
		var game_node = Node3D.new()
		game_node.name = game_id.capitalize() + "Instance"
		game_node.set_script(SCRIPTS[game_id])
		if game_node.has_signal("status_changed"):
			game_node.connect("status_changed", Callable(self, "_on_game_status_changed"))
		if game_node.has_signal("sound_triggered"):
			game_node.connect("sound_triggered", Callable(self, "play_sound"))

		world_3d.add_child(game_node)
		current_game_instance = game_node

		for meta in GAME_METADATA:
			if meta.id == game_id:
				if status_label:
					status_label.text = meta.icon + " " + meta.name + " (" + meta.cat + ")"
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

	print("Switched to: ", game_id)

func _on_game_status_changed(msg: String):
	if status_label:
		status_label.text = msg

# ==================== UI SYSTEM ====================

func build_topbar_actions():
	var topbar = $UI/TopBar
	topbar.mouse_filter = Control.MOUSE_FILTER_STOP
	
	# Menü-Buttons links & rechts in der TopBar (Optimiert für Touch & Maus: 48px Touch-Target)
	var menu_btn = Button.new()
	menu_btn.text = "☰ Menü"
	menu_btn.custom_minimum_size = Vector2(100, 44)
	menu_btn.position = Vector2(12, 8)
	menu_btn.mouse_filter = Control.MOUSE_FILTER_STOP
	menu_btn.pressed.connect(func():
		play_sound("click")
		toggle_main_menu()
	)
	topbar.add_child(menu_btn)

	var games_btn = Button.new()
	games_btn.text = "🎮 Alle Spiele (17)"
	games_btn.custom_minimum_size = Vector2(150, 44)
	games_btn.position = Vector2(122, 8)
	games_btn.mouse_filter = Control.MOUSE_FILTER_STOP
	games_btn.pressed.connect(func():
		play_sound("click")
		toggle_game_selection()
	)
	topbar.add_child(games_btn)

	var settings_btn = Button.new()
	settings_btn.text = "⚙️ Settings"
	settings_btn.custom_minimum_size = Vector2(110, 44)
	settings_btn.position = Vector2(282, 8)
	settings_btn.mouse_filter = Control.MOUSE_FILTER_STOP
	settings_btn.pressed.connect(func():
		play_sound("click")
		toggle_settings()
	)
	topbar.add_child(settings_btn)

	# Labels vor Blockieren bewahren
	var title = topbar.get_node_or_null("TitleLabel")
	if title:
		title.offset_left = 410.0
		title.mouse_filter = Control.MOUSE_FILTER_IGNORE

	if status_label:
		status_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if version_label:
		version_label.mouse_filter = Control.MOUSE_FILTER_IGNORE

func build_modals():
	var ui = $UI

	# 1. Hauptmenü Modal (Komplette Fenstergröße, zentriert)
	var mm_data = create_fullscreen_modal_panel("K-Games 2 - Hauptmenü")
	main_menu_modal = mm_data["container"]
	var mm_vbox = mm_data["vbox"]

	var btn_continue = create_dialog_button("▶️ Weiterspielen", func():
		play_sound("click")
		close_all_modals()
	)
	var btn_all_games = create_dialog_button("🎮 Spielauswahl öffnen (17 Spiele)", func():
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
	var s_data = create_fullscreen_modal_panel("⚙️ App-Einstellungen (Settings)")
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

	var s_close = create_dialog_button("Schließen", func():
		play_sound("click")
		close_all_modals()
	)
	s_vbox.add_child(s_close)
	ui.add_child(settings_modal)

	# 3. Spielauswahl Modal (Komplette Fenstergröße, zentriert mit Scroll-Grid)
	var gs_data = create_fullscreen_modal_panel("🎮 Spielauswahl - 17 Klassiker in 3D")
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
			switch_game(gid)
		)
		grid.add_child(card)

	gs_vbox.add_child(scroll)
	var gs_close = create_dialog_button("Schließen", func():
		play_sound("click")
		close_all_modals()
	)
	gs_vbox.add_child(gs_close)
	ui.add_child(game_selection_modal)

	close_all_modals()

func create_fullscreen_modal_panel(title_str: String) -> Dictionary:
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
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_bottom", 20)
	margin.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.name = "VBox"
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 14)
	vbox.mouse_filter = Control.MOUSE_FILTER_STOP
	margin.add_child(vbox)

	var title = Label.new()
	title.text = title_str
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(title)

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

func build_quick_bottom_bar():
	var ui = $UI
	bottom_bar = PanelContainer.new()
	bottom_bar.name = "QuickBottomBar"
	bottom_bar.mouse_filter = Control.MOUSE_FILTER_PASS
	bottom_bar.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bottom_bar.offset_top = -80
	bottom_bar.offset_bottom = -10
	bottom_bar.offset_left = 12
	bottom_bar.offset_right = -12

	var scroll = ScrollContainer.new()
	scroll.mouse_filter = Control.MOUSE_FILTER_PASS
	scroll.custom_minimum_size = Vector2(0, 64)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	bottom_bar.add_child(scroll)

	var hbox = HBoxContainer.new()
	hbox.mouse_filter = Control.MOUSE_FILTER_PASS
	hbox.add_theme_constant_override("separation", 10)
	scroll.add_child(hbox)

	for g in GAME_METADATA:
		var btn = Button.new()
		btn.text = g.icon + " " + g.name
		btn.mouse_filter = Control.MOUSE_FILTER_STOP
		btn.custom_minimum_size = Vector2(175, 52)
		var gid = g.id
		btn.pressed.connect(func():
			switch_game(gid)
		)
		hbox.add_child(btn)

	ui.add_child(bottom_bar)

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

func is_modal_open() -> bool:
	return (main_menu_modal and main_menu_modal.visible) or (settings_modal and settings_modal.visible) or (game_selection_modal and game_selection_modal.visible)

func reset_camera():
	rot_y = 0.0
	rot_x = -0.5
	camera_pivot.rotation.y = rot_y
	camera_pivot.rotation.x = rot_x
	camera_3d.position = Vector3(0, 0, 12)
	close_all_modals()
