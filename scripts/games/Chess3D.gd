extends Node3D

class_name Chess3D

var board_root: Node3D
var pieces_root: Node3D

func _ready():
	setup_stage()

func setup_stage():
	board_root = Node3D.new()
	board_root.name = "BoardRoot"
	add_child(board_root)
	
	pieces_root = Node3D.new()
	pieces_root.name = "PiecesRoot"
	add_child(pieces_root)

	# Holz- und Marmorrahmen für das 3D-Schachbrett
	var frame_mesh = BoxMesh.new()
	frame_mesh.size = Vector3(9.2, 0.4, 9.2)
	var frame_inst = MeshInstance3D.new()
	frame_inst.mesh = frame_mesh
	var frame_mat = StandardMaterial3D.new()
	frame_mat.albedo_color = Color(0.18, 0.10, 0.05)
	frame_mat.roughness = 0.25
	frame_mat.metallic = 0.1
	frame_inst.material_override = frame_mat
	frame_inst.position = Vector3(0, 0.15, 0)
	board_root.add_child(frame_inst)

	# 64 3D Felder mit Bevel und PBR
	for x in range(8):
		for z in range(8):
			var tile_mesh = BoxMesh.new()
			tile_mesh.size = Vector3(0.98, 0.1, 0.98)
			var tile = MeshInstance3D.new()
			tile.mesh = tile_mesh
			var is_white = (x + z) % 2 == 0
			var mat = StandardMaterial3D.new()
			if is_white:
				mat.albedo_color = Color(0.92, 0.90, 0.82)
				mat.roughness = 0.2
			else:
				mat.albedo_color = Color(0.12, 0.15, 0.20)
				mat.roughness = 0.35
				mat.metallic = 0.15
			tile.material_override = mat
			tile.position = Vector3((x - 3.5), 0.4, (z - 3.5))
			board_root.add_child(tile)

	create_chess_pieces()

func create_chess_pieces():
	# 3D Schachfiguren mit geometrischen Profilen (König, Dame, Turm, Läufer, Springer, Bauern)
	for x in range(8):
		# Bauern
		spawn_piece(Vector3(x - 3.5, 0.5, 2.5), "pawn", false)
		spawn_piece(Vector3(x - 3.5, 0.5, -2.5), "pawn", true)

	var major = ["rook", "knight", "bishop", "queen", "king", "bishop", "knight", "rook"]
	for x in range(8):
		spawn_piece(Vector3(x - 3.5, 0.5, 3.5), major[x], false)
		spawn_piece(Vector3(x - 3.5, 0.5, -3.5), major[x], true)

func spawn_piece(pos: Vector3, type: String, is_white: bool):
	var piece = Node3D.new()
	piece.position = pos
	
	var mat = StandardMaterial3D.new()
	if is_white:
		mat.albedo_color = Color(0.95, 0.92, 0.85)
		mat.roughness = 0.15
		mat.metallic = 0.1
	else:
		mat.albedo_color = Color(0.08, 0.08, 0.12)
		mat.roughness = 0.25
		mat.metallic = 0.4

	# Sockel
	var base_mesh = CylinderMesh.new()
	base_mesh.top_radius = 0.32
	base_mesh.bottom_radius = 0.38
	base_mesh.height = 0.15
	var base_inst = MeshInstance3D.new()
	base_inst.mesh = base_mesh
	base_inst.material_override = mat
	base_inst.position = Vector3(0, 0.08, 0)
	piece.add_child(base_inst)

	# Schaft
	var body_mesh = CylinderMesh.new()
	body_mesh.bottom_radius = 0.28
	body_mesh.top_radius = 0.18
	body_mesh.height = 0.6
	var body_inst = MeshInstance3D.new()
	body_inst.mesh = body_mesh
	body_inst.material_override = mat
	body_inst.position = Vector3(0, 0.45, 0)
	piece.add_child(body_inst)

	# Kopf nach Figurentyp
	var head_mesh: Mesh
	if type == "king":
		var k = BoxMesh.new()
		k.size = Vector3(0.25, 0.4, 0.25)
		head_mesh = k
	elif type == "queen":
		var q = SphereMesh.new()
		q.radius = 0.26
		q.height = 0.45
		head_mesh = q
	elif type == "knight":
		var kn = PrismMesh.new()
		kn.size = Vector3(0.35, 0.5, 0.35)
		head_mesh = kn
	elif type == "rook":
		var r = CylinderMesh.new()
		r.top_radius = 0.25
		r.bottom_radius = 0.25
		r.height = 0.3
		head_mesh = r
	else:
		var p = SphereMesh.new()
		p.radius = 0.2
		p.height = 0.35
		head_mesh = p

	var head_inst = MeshInstance3D.new()
	head_inst.mesh = head_mesh
	head_inst.material_override = mat
	head_inst.position = Vector3(0, 0.85, 0)
	piece.add_child(head_inst)

	pieces_root.add_child(piece)
