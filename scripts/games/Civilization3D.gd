extends Node3D

class_name Civilization3D

func _ready():
	setup_stage()

func setup_stage():
	# Hexagonales / Isometrisches 3D-Geländerelief mit Ebenen, Hügeln und Bergen
	for x in range(12):
		for z in range(8):
			var tile = Node3D.new()
			var world_x = (x - 5.5) * 1.05
			var world_z = (z - 3.5) * 1.05
			
			var is_mountain = (x == 3 and z == 4) or (x == 4 and z == 4) or (x == 8 and z == 2)
			var is_hill = (x == 2 and z == 3) or (x == 5 and z == 5) or (x == 7 and z == 3)
			var is_water = (z == 0 or (x <= 1 and z <= 2))

			var tile_mesh: Mesh
			var mat = StandardMaterial3D.new()

			if is_mountain:
				# 3D Bergmassiv mit Schneekappe
				var p = PrismMesh.new()
				p.size = Vector3(0.95, 1.2, 0.95)
				tile_mesh = p
				mat.albedo_color = Color(0.88, 0.90, 0.95)
				mat.roughness = 0.4
				tile.position = Vector3(world_x, 0.6, world_z)
			elif is_hill:
				# 3D Hügel
				var s = SphereMesh.new()
				s.radius = 0.5
				s.height = 0.6
				tile_mesh = s
				mat.albedo_color = Color(0.35, 0.55, 0.25)
				mat.roughness = 0.5
				tile.position = Vector3(world_x, 0.3, world_z)
			elif is_water:
				var b = BoxMesh.new()
				b.size = Vector3(1.0, 0.1, 1.0)
				tile_mesh = b
				mat.albedo_color = Color(0.08, 0.35, 0.65, 0.8)
				mat.roughness = 0.1
				mat.metallic = 0.5
				tile.position = Vector3(world_x, 0.05, world_z)
			else:
				var b = BoxMesh.new()
				b.size = Vector3(1.0, 0.2, 1.0)
				tile_mesh = b
				mat.albedo_color = Color(0.28, 0.50, 0.22)
				mat.roughness = 0.6
				tile.position = Vector3(world_x, 0.1, world_z)

			var inst = MeshInstance3D.new()
			inst.mesh = tile_mesh
			inst.material_override = mat
			tile.add_child(inst)

			# 3D-Stadtplatzierung
			if x == 5 and z == 2:
				spawn_city(tile, "Athen")
			if x == 9 and z == 5:
				spawn_city(tile, "Sparta")

			add_child(tile)

func spawn_city(parent: Node3D, city_name: String):
	var city = Node3D.new()
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.95, 0.92, 0.85)
	mat.roughness = 0.3

	# Tempel / Akropolis
	var b = BoxMesh.new()
	b.size = Vector3(0.5, 0.4, 0.5)
	var inst = MeshInstance3D.new()
	inst.mesh = b
	inst.material_override = mat
	inst.position = Vector3(0, 0.3, 0)
	city.add_child(inst)

	parent.add_child(city)
