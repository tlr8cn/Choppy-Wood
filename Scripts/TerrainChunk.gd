extends Spatial

class_name TerrainChunk

var noise:OpenSimplexNoise
var noiseb:OpenSimplexNoise
var rng:RandomNumberGenerator
var mdt:MeshDataTool
var st:SurfaceTool
var cube_mesh:CubeMesh

var dirt_material:ShaderMaterial
var grass_material:ShaderMaterial
var shack 
var rock1
var large_rock1
var mushroom
var mushroom_man
var campfire

var tree_likelihood
var grass_likelihood
var rock_likelihood
var height_factor

var array_plane

var cube_width
var cube_depth
var cube_height

var west_face = []
var east_face = []
var north_face = []
var south_face = []
var top_face = []
var bottom_face = []

# Only for the top face right now
var xz_to_i = {}

var tree_generators = []

var biome_settings_manager = BiomeSettingsManager.new()

# TODO: split a large plane into many chunks (which are connected)
# As the player progresses, a large area surrounding the player will intersect
# with colliders placed at certain vertices
# When the player area intersects with the collider, add that chunk to a queue on the TerrainOrchestrator
# Pull that chunk off the queue, and generate terrain for all vertices surrounding it
func _init(noise_seed, biome_divisions, cube_width=64, cube_depth=64, cube_height=64, height_factor=10, tree_likelihood=18, grass_likelihood=40, rock_likelihood=5, noise_octaves=8.0, noise_period=55.0, noise_persistence=0.125):
	rng = RandomNumberGenerator.new()
	rng.randomize()
	
	cube_mesh = CubeMesh.new()
	mdt = MeshDataTool.new()
	st = SurfaceTool.new()
	
	self.height_factor = height_factor
	self.tree_likelihood = tree_likelihood
	self.rock_likelihood = rock_likelihood
	self.grass_likelihood = grass_likelihood
	
	var grass_blade_mesh = load("res://Assets/Models/Grass/flat-grass.obj")
	
	var original_tree_generator = load("res://Scenes/NaturalTree.tscn")
	var magnolia_tree_generator = load("res://Scenes/NaturalTree_Magnolia.tscn")
	tree_generators = [original_tree_generator, magnolia_tree_generator]
	
	shack = load("res://Scenes/Shack.tscn")
	rock1 = load("res://Scenes/Rock1.tscn")
	large_rock1 = load("res://Scenes/LargeRock1.tscn")
	dirt_material = load("res://Assets/Materials/dirt_material.tres")
	mushroom = load("res://Scenes/Mushroom.tscn")
	mushroom_man = load("res://Scenes/MushroomMan.tscn")
	campfire =  load("res://Scenes/Campfire.tscn")
	
	grass_material = load("res://Assets/Materials/grass_material.tres")
	
	noise = OpenSimplexNoise.new()
	noiseb = OpenSimplexNoise.new()
	noise.seed = noise_seed
	noiseb.seed = rng.randi()
	noise.octaves = noise_octaves
	noiseb.octaves = 5.0
	# Period of the base octave. A lower period results in a higher-frequency noise (more value changes across the same distance).
	noise.period = noise_period
	noiseb.period = 25.0
	# Contribution factor of the different octaves. A persistence value of 1 means all the octaves have the same contribution, a value of 0.5 means each octave contributes half as much as the previous one.
	noise.persistence = noise_persistence
	noiseb.persistence = noise_persistence
	
	self.cube_width = cube_width
	self.cube_depth = cube_depth
	self.cube_height = cube_height
	# Subdivide actually represents how many subdivisions are made to the plane in a particular direction
	# It is NOT to be confused with the vertex count. In order to map width to number of vertices, subtract 2
	# from the subdivision width/depth
	cube_mesh.subdivide_width = cube_width - 2
	cube_mesh.subdivide_depth = cube_depth - 2
	cube_mesh.subdivide_height = cube_height - 2
	
	# TODO: try using the width, depth, and height members of this class
	cube_mesh.size = Vector3(cube_mesh.subdivide_width, cube_mesh.subdivide_depth, cube_mesh.subdivide_height)
	
	st.create_from(cube_mesh, 0)
	# Returns a constructed ArrayMesh from current information passed in 
	array_plane = st.commit()
	mdt.create_from_surface(array_plane, 0)

	var biome_grid = divide_terrain_into_biomes(biome_divisions)
	# TODO: draw terrain given the biomes array
	draw_terrain(cube_width, cube_depth, cube_height, biome_grid)
	
	# TODO: add terrain smoothing function
	
	#place_grass(grass_blade_mesh)
	pass

# TODO: only divide the top of the cube into biomes
func divide_terrain_into_biomes(biome_divisions):
	generate_faces_and_xz_to_i()
	
	var biome_grid = []
	for x in range(biome_divisions):
		biome_grid.push_back([])
		for z in range(biome_divisions):
			biome_grid[x].push_back(null)
	
	var increment = cube_width/biome_divisions
	var west_boundary = 0
	var north_boundary = increment
	var east_boundary = increment
	var south_boundary = 0
	var biome_i_array = []
	
	var number_of_biomes = pow(biome_divisions, 2)
	var biome_count = 0
	
	# Place a single mountain randomly in the grid
	var mountain_x = rng.randi_range(1, biome_grid.size()-2)
	var mountain_z = rng.randi_range(1, biome_grid.size()-2)
	
	var division_x = 0
	var division_z = 0
	while biome_count < number_of_biomes:
		var biome_i_to_xz = {}
		for x in range(west_boundary, east_boundary):
			for z in range(south_boundary, north_boundary):
				var i = xz_to_i[[x, z]]
				biome_i_to_xz[i] = [x, z]
				biome_i_array.push_back(i)
		
		var biome_settings = load_biome_settings(biome_grid, division_x, division_z, mountain_x, mountain_z)
		var biome = TerrainBiome.new(west_boundary, north_boundary, east_boundary, south_boundary, biome_divisions, biome_settings, biome_i_array, biome_i_to_xz, division_x, division_z)
		biome_grid[division_x][division_z] = biome
		
		# set neighbors
		var south_neighbor = null
		if division_z > 0:
			south_neighbor = biome_grid[division_x][division_z - 1]
			biome.set_south_neighbor(south_neighbor)
			south_neighbor.set_north_neighbor(biome)
		var west_neighbor = null
		if division_x > 0:
			west_neighbor = biome_grid[division_x - 1][division_z]
			biome.set_west_neighbor(west_neighbor)
			west_neighbor.set_east_neighbor(biome)
		
		if north_boundary >= cube_depth - 1:
			division_z = 0
			division_x += 1
			north_boundary = increment
			south_boundary = 0
			west_boundary += increment
			east_boundary += increment
		else:
			division_z += 1
			north_boundary += increment
			south_boundary += increment
		biome_count += 1
		biome_i_array = []
	return biome_grid

# Plane:
#              (i + 1) % plane_width == 0
#                      \/
# (plane_width - 1) -------- (vertex_count - 1)
#                  |          |
#                  |    ^     |
#                  0 -------- vertex_count - plane_width
#                       ^
#                  i % plane_width == 0
func draw_terrain(plane_width, plane_depth, cube_height, biome_grid):
	var uv_x = 0.0
	var uv_y = 0.0
	var uv_inc = 1.0/8.0
	var old_z = mdt.get_vertex(0).z
	
	for biome_x in range(biome_grid.size()):
		for biome_z in range(biome_grid[biome_x].size()):
			var biome = biome_grid[biome_x][biome_z]
			var biome_i_array = biome.get_i_array()
			var biome_settings = biome.get_biome_settings()
			var height_map = biome_settings.get_height_map()
			
			for ii in range(biome_i_array.size()):
				var i = biome_i_array[ii]
				
				var height_factor = biome.get_height_factor_for_index(i)
				var vertex = mdt.get_vertex(i)
				var new_z = vertex.z
				var noise_val = noise.get_noise_2d(float(vertex.x), float(vertex.z))
				var noise_valb = noiseb.get_noise_2d(float(vertex.x), float(vertex.z))
				var final_noise_val = (noise_val + noise_valb)/2
				
				#height_factor = biome.apply_height_smoothing(i)
				
				vertex.y = height_factor*final_noise_val
				
				mdt.set_vertex_uv(i, Vector2(uv_x, uv_y))
				mdt.set_vertex(i, vertex)
				
				# on every nth vertex, roll to create a tree
				if i % 50 == 0:
					roll_to_add_tree(tree_generators, vertex, i)
				
				# TODO: rocks should be partial to terrain peaks. Meaning the highest y values on the mesh should have a higher concentration of rocks
				roll_to_add_rock(vertex)
				
				# TODO: write a helper function to determine if the area around the selected vertex
				# is flat; if so, spawn the campfire
				if i == 32896:
					add_campfire(vertex)
				
				uv_x += uv_inc
				if uv_x < 0:
					uv_x = 0.0
				
				if old_z != new_z:
					uv_y += uv_inc
					uv_x = 0.0
				
				old_z = new_z
	
	# add features
	#add_terrain_features()
	add_tree_to_scene(array_plane)
	pass

func add_terrain_features(plane_width):
	var large_rock_counter = 0
	for i in range(mdt.get_vertex_count()):
		var vertex = mdt.get_vertex(i)
		
		# TODO: mountainous terrain
			#    1. Slope the terrain up gradually on either side to create a valley, which will propel the player forward
		#    2. When slope becomes extreme enough, the texture should change to rock or loose sliding soil
		#    3. The extent of the slope should determine whether or not can climb the slope -- should be before reaching rock features
		#    4. At the peaks, add rock features
		if (i >= 0 && i < plane_width) || (i >= (mdt.get_vertex_count() - 1) - plane_width && i < mdt.get_vertex_count()):
			large_rock_counter += 1
			if large_rock_counter % 24 == 0:
				add_large_rock(vertex)
				large_rock_counter = 0
		

		
		# Check for house spawn
		#if i == 125:
		#	spawn_house(shack, vertex)
	pass

func load_biome_settings(biome_grid, division_x, division_z, mountain_x, mountain_z):
	var grid_width = biome_grid.size() - 1
	
	if division_x == mountain_x && division_z == mountain_z:
		return biome_settings_manager.get_mountain_biome_settings()
	elif division_x == mountain_x && division_z + 1 == mountain_z:
		return BiomeSettings.new("FOOTHILLS", 0)
	elif division_x - 1 == mountain_x && division_z == mountain_z:
		return BiomeSettings.new("FOOTHILLS", 90)
	elif division_x == mountain_x && division_z - 1 == mountain_z:
		return BiomeSettings.new("FOOTHILLS", 180)
	elif division_x + 1 == mountain_x && division_z == mountain_z:
		return BiomeSettings.new("FOOTHILLS", 270)
	# CORNERS
	elif division_x + 1 == mountain_x && division_z + 1 == mountain_z:
		return BiomeSettings.new("FOOTHILLS_CORNER", 270)
	elif division_x - 1 == mountain_x && division_z - 1 == mountain_z:
		return BiomeSettings.new("FOOTHILLS_CORNER", 90)
	elif division_x - 1 == mountain_x && division_z + 1 == mountain_z:
		return BiomeSettings.new("FOOTHILLS_CORNER", 0)
	elif division_x + 1 == mountain_x && division_z - 1 == mountain_z:
		return BiomeSettings.new("FOOTHILLS_CORNER", 180)
	
	return biome_settings_manager.get_default_biome_settings()

func generate_faces_and_xz_to_i():
	var x = 0
	var z = 0
	for i in range(mdt.get_vertex_count()):
		if i < 2*(cube_depth * cube_height):
			if i % 2 == 0:
				west_face.push_back(i)
			elif i % 2 == 1:
				east_face.push_back(i)
		elif i >= 2*(cube_width * cube_height) && i < 4*(cube_width * cube_height):
			if i % 2 == 0:
				south_face.push_back(i)
			elif i % 2 == 1:
				north_face.push_back(i)
		elif i >= 4 * (cube_width * cube_depth) && i < 6 * (cube_width * cube_depth):
			if i % 2 == 0:
				top_face.push_back(i)
				xz_to_i[[x, z]] = i
				if z == cube_depth - 1:
					z = 0
					x += 1
				else:
					z += 1
			elif i % 2 == 1:
				bottom_face.push_back(i)
	return xz_to_i

func add_large_rock(rock_location):
	var instance = large_rock1.instance()
	instance.transform.origin = Vector3(rock_location.x, rock_location.y - 2.5, rock_location.z)
	add_child(instance)
	pass

func roll_to_add_rock(rock_location):
	var roll = rng.randi_range(0, 2500)
	if roll <= self.rock_likelihood:
		add_rock(rock_location)
	pass

func add_rock(rock_location):
	var instance = rock1.instance()
	var minor_offset_x = rng.randf_range(-0.15, 0.15)
	var minor_offset_z = rng.randf_range(-0.15, 0.15)
	var pos = Vector3(rock_location.x + minor_offset_x, rock_location.y - 0.15, rock_location.z + minor_offset_z)
	instance.transform.origin = pos
	
	var random_rotation = rng.randf_range(0, 2*PI)
	instance.transform.basis = instance.transform.basis.rotated(Vector3(1, 0, 0), transform.basis.get_euler().x + random_rotation)
	random_rotation = rng.randf_range(0, 2*PI)
	instance.transform.basis = instance.transform.basis.rotated(Vector3(0, 1, 0), transform.basis.get_euler().y + random_rotation)
	random_rotation = rng.randf_range(0, 2*PI)
	instance.transform.basis = instance.transform.basis.rotated(Vector3(0, 0, 1), transform.basis.get_euler().z + random_rotation)
	add_child(instance)
	pass

func add_campfire(location):
	var instance = campfire.instance()
	instance.transform.origin = Vector3(location.x, location.y + 0.075, location.z)
	add_child(instance)
	pass

func roll_to_add_tree(tree_generators, tree_location, vertex_index):
	# TODO: roll for tree type after likelihood
	var tree_type_roll = rng.randi_range(0, 100)
	var tree_generator = null
	if tree_type_roll >= 65:
		tree_generator = tree_generators[0]
	else:
		tree_generator = tree_generators[1]
	
	var roll = rng.randi_range(0, 100)
	if roll <= self.tree_likelihood:
		# Add tree
		var new_tree = tree_generator.instance()
		new_tree.translate(Vector3(tree_location.x, tree_location.y, tree_location.z))
		add_child(new_tree)
		
		# Roll again for mushrooms
		roll = rng.randi_range(0, 100)
		if roll <= 25:
			var nearby_vertices = []
			for i in 4:
				if vertex_index - i >= 0:
					nearby_vertices.push_back(mdt.get_vertex(vertex_index - i))
				if vertex_index + i <= mdt.get_vertex_count() - 1:
					nearby_vertices.push_back(mdt.get_vertex(vertex_index + i))
				if vertex_index + i*cube_width <= mdt.get_vertex_count() - 1:
					nearby_vertices.push_back(mdt.get_vertex(vertex_index + i*cube_width))
				if vertex_index - i*cube_width >= 0:
					nearby_vertices.push_back(mdt.get_vertex(vertex_index - i*cube_width))
			
			var num_mushrooms_cap = (nearby_vertices.size() - 1)/4
			var num_mushrooms = rng.randi_range(0, num_mushrooms_cap)
			var visited = {}
			var mushroom_man_was_spawned = false
			for i in num_mushrooms:
				var mush_index = 0
				var found_open_vertex = false
				while !found_open_vertex:
					var vertex_roll = rng.randi_range(0, nearby_vertices.size() - 1)
					if !visited.has(vertex_roll):
						visited[vertex_roll] = true
						found_open_vertex = true
						mush_index = vertex_roll
				var mushroom_location = nearby_vertices[mush_index]
				
				var new_mushroom
				var mushroom_man_roll = rng.randi_range(0, 1000)
				var now_dats_alota_mushrooms = num_mushrooms >= num_mushrooms_cap - 2 && num_mushrooms <= num_mushrooms_cap
				if mushroom_man_roll < 60 && !mushroom_man_was_spawned && now_dats_alota_mushrooms:
					mushroom_man_was_spawned = true
					new_mushroom = mushroom_man.instance()
					new_mushroom.transform.origin = Vector3(mushroom_location.x, mushroom_location.y - 0.75, mushroom_location.z)
				else:
					new_mushroom = mushroom.instance()
					new_mushroom.translate(Vector3(mushroom_location.x, mushroom_location.y, mushroom_location.z))
				add_child(new_mushroom)
	pass

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
		
		#material.albedo_texture = terrain_texture
		#material.albedo_color = Color("#3A2218")
		
		meshInstance.material_override = dirt_material
		meshInstance.create_trimesh_collision()
		add_child(meshInstance)
	pass

func place_grass(grass_blade_mesh):
	rng.randomize()
	var multimesh = MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.instance_count = 1
	multimesh.set_mesh(grass_blade_mesh)
	
	for i in multimesh.instance_count:
		var mdt_vertex = mdt.get_vertex(i)
		
		var grass_transform = Transform.IDENTITY
		var random_offset_x = rng.randf_range(-0.5, 0.5)
		var random_offset_z = rng.randf_range(-0.5, 0.5)
		grass_transform.origin = Vector3(mdt_vertex.x + random_offset_x, mdt_vertex.y, mdt_vertex.z + random_offset_z)
		
		# can be anything
		var random_rotation_y = rng.randf_range(0, 2*PI)
		grass_transform.basis = grass_transform.basis.rotated(Vector3(0, 1, 0), random_rotation_y)
		
		# can be small (represents tilt)
		var random_rotation_x = rng.randf_range(-PI/16, PI/16)
		var random_rotation_z = rng.randf_range(-PI/16, PI/16)
		grass_transform.basis = grass_transform.basis.rotated(Vector3(1, 0, 0), random_rotation_x)
		grass_transform.basis = grass_transform.basis.rotated(Vector3(0, 0, 1), random_rotation_z)
		
		grass_transform.basis = grass_transform.basis.scaled(Vector3(0.375, 0.375, 0.375))
		
		multimesh.set_instance_transform(i, grass_transform)
	
	# TODO: assign vertex and visual shader to multimesh instance
	var multimesh_instance = MultiMeshInstance.new()
	multimesh_instance.multimesh = multimesh
	multimesh_instance.material_override = grass_material
	add_child(multimesh_instance)

func spawn_house(house, location):
	var new_house = house.instance()
	new_house.translate(Vector3(location.x, location.y + 0.1, location.z + 1.0))
	add_child(new_house)
	pass

func get_mdt():
	return self.mdt

func get_plane_mesh():
	return self.plane_mesh
