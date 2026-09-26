class_name TextureHelper
extends RefCounted

# Procedural PBR Texture and Material Generator for K-Games 2
# Eliminates flat plastic look by providing rich tactile grain, roughness, and normal maps.

static var _cached_materials: Dictionary = {}

static func get_wood_material(tint: Color = Color(0.25, 0.14, 0.08)) -> StandardMaterial3D:
	var key = "wood_" + str(tint.to_html())
	if _cached_materials.has(key):
		return _cached_materials[key]

	var mat = StandardMaterial3D.new()
	mat.albedo_color = tint
	mat.roughness = 0.35
	mat.metallic = 0.05

	var noise = FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.frequency = 0.06
	noise.fractal_octaves = 3

	var tex = NoiseTexture2D.new()
	tex.width = 256
	tex.height = 256
	tex.seamless = true
	tex.noise = noise

	mat.roughness_texture = tex
	mat.roughness_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_RED
	
	var norm_tex = NoiseTexture2D.new()
	norm_tex.width = 256
	norm_tex.height = 256
	norm_tex.seamless = true
	norm_tex.as_normal_map = true
	norm_tex.bump_strength = 2.5
	norm_tex.noise = noise

	mat.normal_enabled = true
	mat.normal_texture = norm_tex

	_cached_materials[key] = mat
	return mat

static func get_marble_material(tint: Color = Color(0.92, 0.90, 0.85)) -> StandardMaterial3D:
	var key = "marble_" + str(tint.to_html())
	if _cached_materials.has(key):
		return _cached_materials[key]

	var mat = StandardMaterial3D.new()
	mat.albedo_color = tint
	mat.roughness = 0.15
	mat.metallic = 0.15
	mat.clearcoat_enabled = true
	mat.clearcoat = 0.8

	var noise = FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_CELLULAR
	noise.frequency = 0.03
	noise.fractal_octaves = 2

	var tex = NoiseTexture2D.new()
	tex.width = 256
	tex.height = 256
	tex.seamless = true
	tex.noise = noise

	mat.roughness_texture = tex
	_cached_materials[key] = mat
	return mat

static func get_grass_material(tint: Color = Color(0.22, 0.62, 0.24)) -> StandardMaterial3D:
	var key = "grass_" + str(tint.to_html())
	if _cached_materials.has(key):
		return _cached_materials[key]

	var mat = StandardMaterial3D.new()
	mat.albedo_color = tint
	mat.roughness = 0.75
	mat.metallic = 0.02
	mat.rim_enabled = true
	mat.rim = 0.4

	var noise = FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	noise.frequency = 0.08
	noise.fractal_octaves = 4

	var norm_tex = NoiseTexture2D.new()
	norm_tex.width = 256
	norm_tex.height = 256
	norm_tex.seamless = true
	norm_tex.as_normal_map = true
	norm_tex.bump_strength = 3.5
	norm_tex.noise = noise

	mat.normal_enabled = true
	mat.normal_texture = norm_tex

	_cached_materials[key] = mat
	return mat

static func get_stone_material(tint: Color = Color(0.65, 0.62, 0.58)) -> StandardMaterial3D:
	var key = "stone_" + str(tint.to_html())
	if _cached_materials.has(key):
		return _cached_materials[key]

	var mat = StandardMaterial3D.new()
	mat.albedo_color = tint
	mat.roughness = 0.8
	mat.metallic = 0.05

	var noise = FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_CELLULAR
	noise.frequency = 0.05
	noise.fractal_octaves = 3

	var norm_tex = NoiseTexture2D.new()
	norm_tex.width = 256
	norm_tex.height = 256
	norm_tex.seamless = true
	norm_tex.as_normal_map = true
	norm_tex.bump_strength = 4.0
	norm_tex.noise = noise

	mat.normal_enabled = true
	mat.normal_texture = norm_tex

	_cached_materials[key] = mat
	return mat

static func get_parchment_material(tint: Color = Color(0.88, 0.82, 0.68)) -> StandardMaterial3D:
	var key = "parchment_" + str(tint.to_html())
	if _cached_materials.has(key):
		return _cached_materials[key]

	var mat = StandardMaterial3D.new()
	mat.albedo_color = tint
	mat.roughness = 0.6
	mat.metallic = 0.0

	var noise = FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.frequency = 0.02
	noise.fractal_octaves = 3

	var tex = NoiseTexture2D.new()
	tex.width = 256
	tex.height = 256
	tex.seamless = true
	tex.noise = noise

	mat.roughness_texture = tex
	_cached_materials[key] = mat
	return mat

static func get_metal_material(tint: Color = Color(0.35, 0.38, 0.45), metallic_val: float = 0.85) -> StandardMaterial3D:
	var key = "metal_" + str(tint.to_html()) + "_" + str(metallic_val)
	if _cached_materials.has(key):
		return _cached_materials[key]

	var mat = StandardMaterial3D.new()
	mat.albedo_color = tint
	mat.metallic = metallic_val
	mat.roughness = 0.25

	var noise = FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.frequency = 0.05
	noise.fractal_octaves = 3

	var norm_tex = NoiseTexture2D.new()
	norm_tex.width = 256
	norm_tex.height = 256
	norm_tex.seamless = true
	norm_tex.as_normal_map = true
	norm_tex.bump_strength = 1.5
	norm_tex.noise = noise

	mat.normal_enabled = true
	mat.normal_texture = norm_tex

	_cached_materials[key] = mat
	return mat

static func get_water_material(tint: Color = Color(0.04, 0.32, 0.60, 0.88)) -> StandardMaterial3D:
	var key = "water_" + str(tint.to_html())
	if _cached_materials.has(key):
		return _cached_materials[key]

	var mat = StandardMaterial3D.new()
	mat.albedo_color = tint
	mat.roughness = 0.08
	mat.metallic = 0.7
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.clearcoat_enabled = true
	mat.clearcoat = 1.0

	var noise = FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.frequency = 0.04
	noise.fractal_octaves = 3

	var norm_tex = NoiseTexture2D.new()
	norm_tex.width = 256
	norm_tex.height = 256
	norm_tex.seamless = true
	norm_tex.as_normal_map = true
	norm_tex.bump_strength = 3.0
	norm_tex.noise = noise

	mat.normal_enabled = true
	mat.normal_texture = norm_tex

	_cached_materials[key] = mat
	return mat
