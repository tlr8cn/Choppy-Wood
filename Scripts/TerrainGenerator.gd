extends Spatial


var noise = OpenSimplexNoise.new()

var mdt = MeshDataTool.new()
var st = SurfaceTool.new()

# TODO: There should be multiple plane meshes, each just large enough to fit the ground texture
var plane_mesh = PlaneMesh.new()

var rng = RandomNumberGenerator.new()

var height_factor = 10

var tuft_options = Array()

var tree_likelihood = 25
var grass_likelihood = 40

# Called when the node enters the scene tree for the first time.
func _ready():
	rng.randomize()
	
	var grass_tuft_small = get_node("GrassField").get_node("GrassTuftSmall")
	var grass_tuft_large = get_node("GrassField").get_node("GrassTuftLarge")
	tuft_options.append(grass_tuft_small)
	tuft_options.append(grass_tuft_large)
	
	#var grass_material = load("res://materials/grass_texture.tres")
	#var dirt_material = load("res://materials/dirt_texture1.tres")
	var tree_generator = load("res://Scenes/NaturalTree.tscn")
	var shack = load("res://Scenes/Shack.tscn")
	
	noise.seed = rng.randi()
	# Number of OpenSimplex noise layers that are sampled to get the fractal noise. Higher values result in more detailed noise but take more time to generate.
	noise.octaves = 10
	# Period of the base octave. A lower period results in a higher-frequency noise (more value changes across the same distance).
	noise.period = 26.0
	# Contribution factor of the different octaves. A persistence value of 1 means all the octaves have the same contribution, a value of 0.5 means each octave contributes half as much as the previous one.
	noise.persistence = 0.25
	
	plane_mesh.subdivide_width = 64
	plane_mesh.subdivide_depth = 64
	plane_mesh.size = Vector2(plane_mesh.subdivide_width, plane_mesh.subdivide_depth)
	
	st.create_from(plane_mesh, 0)
	# Returns a constructed ArrayMesh from current information passed in 
	var array_plane = st.commit()
	mdt.create_from_surface(array_plane, 0)
	
	var uv_x = 0.0
	var uv_y = 0.0
	var uv_inc = 1.0/64.0
	var old_z = mdt.get_vertex(0).z
	# uvs should run from 0, 1/64, 2/64, .., 1
	for i in range(mdt.get_vertex_count()):
		var vertex = mdt.get_vertex(i)
		var new_z = vertex.z
		var noise_val = noise.get_noise_2d(float(vertex.x), float(vertex.z))
		
		vertex.y = height_factor*noise_val
		mdt.set_vertex_uv(i, Vector2(uv_x, uv_y))
		mdt.set_vertex(i, vertex)
		
		# on every nth vertex, roll to create a tree
		if i % 75 == 0:
			roll_to_add_tree(tree_generator, vertex)
		
		# on every index, roll to create grass
		roll_to_add_grass(vertex)
		
		# Check for house spawn
		if i == 1000:
			spawn_house(shack, vertex)
		
		uv_x += uv_inc
		if uv_x < 0:
			uv_x = 0.0
		
		if old_z != new_z:
			uv_y += uv_inc
			uv_x = 0.0
		
		old_z = new_z
		
	add_tree_to_scene(array_plane)
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func roll_to_add_grass(grass_location):
	var roll = rng.randi_range(0, 100)
	if roll <= grass_likelihood:
		var index = rng.randi_range(0, 1)
		var instance = tuft_options[index].duplicate()
		var minor_offset_x = rng.randf_range(-0.125, 0.125)
		var minor_offset_z = rng.randf_range(-0.125, 0.125)
		var pos = Vector3(grass_location.x + minor_offset_x, grass_location.y, grass_location.z + minor_offset_z)
		instance.global_translate(pos)
		
		# Random, minor offsets in the x and z directions
		#var pos = Vector3(current_x + minor_offset_x, transform.origin.y + instance_y_offset, current_z + minor_offset_z)
		#instance.global_translate(pos)
		var random_rotation = rng.randf_range(0, 2*PI)
		instance.transform.basis = instance.transform.basis.rotated(Vector3(0, 1, 0), transform.basis.get_euler().y + random_rotation)
		instance.scale = Vector3(0.35, 0.35, 0.35)
		instance.visible = true
		add_child(instance)

func roll_to_add_tree(tree_generator, tree_location):
	var roll = rng.randi_range(0, 100)
	if roll <= tree_likelihood:
		var new_tree = tree_generator.instance()
		new_tree.translate(Vector3(tree_location.x, tree_location.y - 1.0, tree_location.z))
		add_child(new_tree)

func add_tree_to_scene(array_plane):
	for s in range(array_plane.get_surface_count()):
		array_plane.surface_remove(s)
		mdt.commit_to_surface(array_plane)
		st.create_from(array_plane, 0)
		st.generate_normals()
		# TODO: this should be separated into chunks eventually
		var meshInstance = MeshInstance.new()
		meshInstance.set_mesh(st.commit())
		meshInstance.global_transform.origin = Vector3(0, 0, 0)
		#var ttg = TerrainTextureGenerator.new(plane_mesh.subdivide_width*128, plane_mesh.subdivide_depth*128)
		#var terrain_texture = ttg.get_terrain_texture()
		var material = SpatialMaterial.new()
		#material.albedo_texture = terrain_texture
		material.albedo_color = Color("#3A2218")
		
		meshInstance.material_override = material
		meshInstance.create_trimesh_collision()
		add_child(meshInstance)

func spawn_house(house, location):
	var new_house = house.instance()
	new_house.translate(Vector3(location.x, location.y + 0.1, location.z + 1.0))
	add_child(new_house)
