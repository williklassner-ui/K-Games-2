extends RefCounted

# DiceHelper: Hochwertiges 3D-Würfelsystem für K-Games 2
# Erzeugt interaktive 3D-Würfel mit allen 6 Augenseiten, Wurf- und Taumel-Animationen

const TextureHelper = preload("res://scripts/TextureHelper.gd")

# Zielflächen-Ausrichtungen, damit die Augenzahl (1-6) exakt nach oben (+Y) zeigt:
# 1 = +Y, 6 = -Y, 2 = +Z, 5 = -Z, 3 = +X, 4 = -X (Gegenüberliegende Summe = 7)
const FACE_ROTATIONS = {
	1: Vector3(0, 0, 0),
	2: Vector3(-90, 0, 0),
	3: Vector3(0, 0, 90),
	4: Vector3(0, 0, -90),
	5: Vector3(90, 0, 0),
	6: Vector3(180, 0, 0)
}

const DIE_PIP_UNICODE = {
	1: "⚀", 2: "⚁", 3: "⚂", 4: "⚃", 5: "⚄", 6: "⚅"
}

static func create_3d_die(die_size: float = 0.9, base_color: Color = Color(0.96, 0.96, 0.93), is_red: bool = false) -> Node3D:
	var die = Node3D.new()
	die.name = "Die3D"

	var col = Color(0.85, 0.15, 0.15) if is_red else base_color
	var mat = TextureHelper.get_marble_material(col)

	# Würfelkörper mit abgerundeten Kantenoptik
	var cube = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(die_size, die_size, die_size)
	cube.mesh = box
	cube.material_override = mat
	die.add_child(cube)

	# Alle 6 Seiten beschriften mit 3D Pips / Ziffern
	var text_color = Color(0.98, 0.98, 0.95) if is_red else Color(0.12, 0.12, 0.14)
	var half_s = die_size * 0.5 + 0.01

	# Seite 1: +Y (Oben)
	add_face_label(die, "1", Vector3(0, half_s, 0), Vector3(-90, 0, 0), text_color, die_size)
	# Seite 6: -Y (Unten)
	add_face_label(die, "6", Vector3(0, -half_s, 0), Vector3(90, 0, 0), text_color, die_size)
	# Seite 2: +Z (Vorne)
	add_face_label(die, "2", Vector3(0, 0, half_s), Vector3(0, 0, 0), text_color, die_size)
	# Seite 5: -Z (Hinten)
	add_face_label(die, "5", Vector3(0, 0, -half_s), Vector3(0, 180, 0), text_color, die_size)
	# Seite 3: +X (Rechts)
	add_face_label(die, "3", Vector3(half_s, 0, 0), Vector3(0, 90, 0), text_color, die_size)
	# Seite 4: -X (Links)
	add_face_label(die, "4", Vector3(-half_s, 0, 0), Vector3(0, -90, 0), text_color, die_size)

	# 3D StaticBody für Klick/Touch
	var sb = StaticBody3D.new()
	var cs = CollisionShape3D.new()
	var b_shape = BoxShape3D.new()
	b_shape.size = Vector3(die_size * 1.2, die_size * 1.2, die_size * 1.2)
	cs.shape = b_shape
	sb.add_child(cs)
	sb.set_meta("is_die", true)
	die.add_child(sb)

	die.set_meta("die_value", 1)
	return die

static func add_face_label(parent: Node3D, txt: String, pos: Vector3, rot: Vector3, col: Color, die_size: float):
	var lbl = Label3D.new()
	lbl.text = txt
	lbl.font_size = int(die_size * 48)
	lbl.pixel_size = 0.008
	lbl.modulate = col
	lbl.outline_size = 3
	lbl.outline_modulate = Color(0, 0, 0, 0.4)
	lbl.position = pos
	lbl.rotation_degrees = rot
	parent.add_child(lbl)

# Wirft den Würfel und animiert ihn taumelnd auf den gewünschten Zielwert
static func roll_die(die: Node3D, target_value: int, target_pos: Vector3, duration: float = 0.55, on_finish: Callable = Callable()):
	if not is_instance_valid(die): return
	die.set_meta("die_value", target_value)

	var tree = die.get_tree()
	if not tree:
		apply_value_rotation(die, target_value)
		die.position = target_pos
		if on_finish.is_valid(): on_finish.call()
		return

	var start_rot = die.rotation_degrees
	# Zufällige Drehungen vor der Landung
	var spins_x = (randi_range(2, 4) * 360)
	var spins_z = (randi_range(2, 4) * 360)
	var base_target_rot = FACE_ROTATIONS.get(target_value, Vector3.ZERO)
	# Zufällige 90°-Drehung um die Y-Achse
	var final_y = randi_range(0, 3) * 90.0
	var final_rot = base_target_rot + Vector3(0, final_y, 0)

	var tween = tree.create_tween().set_parallel(true)
	
	# Hochspringen und Taumeln
	var high_pos = target_pos + Vector3(randf_range(-0.3, 0.3), randf_range(1.5, 2.5), randf_range(-0.3, 0.3))
	tween.tween_property(die, "position", high_pos, duration * 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(die, "rotation_degrees", start_rot + Vector3(spins_x * 0.5, 180, spins_z * 0.5), duration * 0.4)

	# Aufprall und elastisches Auspendeln
	var tween_land = tree.create_tween().set_parallel(true)
	tween_land.tween_property(die, "position", target_pos, duration * 0.6).set_delay(duration * 0.4).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	tween_land.tween_property(die, "rotation_degrees", final_rot, duration * 0.6).set_delay(duration * 0.4).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	if on_finish.is_valid():
		tween_land.chain().tween_callback(on_finish)

static func apply_value_rotation(die: Node3D, val: int):
	var base = FACE_ROTATIONS.get(val, Vector3.ZERO)
	die.rotation_degrees = base
