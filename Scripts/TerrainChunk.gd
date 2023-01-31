extends Spatial

class_name TerrainChunk

var noise:OpenSimplexNoise
var noiseb:OpenSimplexNoise
var rng:RandomNumberGenerator
var mdt:MeshDataTool
var st:SurfaceTool
var plane_mesh:PlaneMesh

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

var plane_width

var tree_generators = []

var south_side = []
var west_side = []
var north_side = []
var east_side = []

# TODO: split a large plane into many chunks (which are connected)
# As the player progresses, a large area surrounding the player will intersect
# with colliders placed at certain vertices
# When the player area intersects with the collider, add that chunk to a queue on the TerrainOrchestrator
# Pull that chunk off the queue, and generate terrain for all vertices surrounding it
func _init(noise_seed, neighboring_sides_map, chunk_offset, plane_width=64, plane_depth=64, height_factor=10, tree_likelihood=18, grass_likelihood=40, rock_likelihood=5, noise_octaves=8.0, noise_period=55.0, noise_persistence=0.125):
	rng = RandomNumberGenerator.new()
	rng.randomize()
	
	plane_mesh = PlaneMesh.new()
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
	
	self.plane_width = plane_width
	# Subdivide actually represents how many subdivisions are made to the plane in a particular direction
	# It is NOT to be confused with the vertex count. In order to map width to number of vertices, subtract 2
	# from the subdivision width/depth
	plane_mesh.subdivide_width = plane_width - 2
	plane_mesh.subdivide_depth = plane_depth - 2
	plane_mesh.size = Vector2(plane_mesh.subdivide_width, plane_mesh.subdivide_depth)
	
	st.create_from(plane_mesh, 0)
	# Returns a constructed ArrayMesh from current information passed in 
	array_plane = st.commit()
	mdt.create_from_surface(array_plane, 0)
	
	draw_terrain(plane_width, plane_depth, neighboring_sides_map, chunk_offset)
	
	place_grass(grass_blade_mesh)
	pass


# Plane:
#              (i + 1) % plane_width == 0
#                      \/
# (plane_width - 1) -------- (vertex_count - 1)
#                  |          |
#                  |    ^     |
#                  0 -------- vertex_count - plane_width
#                       ^
#                  i % plane_width == 0
func draw_terrain(plane_width, plane_depth, neighboring_sides_map, chunk_offset):
	var uv_x = 0.0
	var uv_y = 0.0
	var uv_inc = 1.0/8.0
	var old_z = mdt.get_vertex(0).z
	# uvs should run from 0, 1/64, 2/64, .., 1
	
	var west_vertex_index = 0
	var south_vertex_index = 0
	for i in range(mdt.get_vertex_count()):
		var vertex = mdt.get_vertex(i)
		
		if i >= mdt.get_vertex_count() - plane_width && i < mdt.get_vertex_count() && neighboring_sides_map["WEST"] != null:
			var west_neighbor_side = neighboring_sides_map["WEST"]
			var snap_vertex = west_neighbor_side[west_vertex_index]
			vertex = snap_vertex
			#add_rock(vertex)
			west_vertex_index += 1
			
		elif (i + 1) % plane_width == 0 && neighboring_sides_map["SOUTH"] != null:
			var south_neighbor_side = neighboring_sides_map["SOUTH"]
			var snap_vertex = south_neighbor_side[south_vertex_index]
			vertex = snap_vertex
			#add_rock(vertex)
			south_vertex_index += 1
		else:
			var noise_val = noise.get_noise_2d(float(vertex.x), float(vertex.z))
			var noise_valb = noiseb.get_noise_2d(float(vertex.x), float(vertex.z))
			var final_noise_val = (noise_val + noise_valb)/2
			#if noise_val <= noise_valb:
			#	final_noise_val = noise_val + noise_valb
			#else:
			#	final_noise_val = noise_val - noise_valb
			vertex.y = self.height_factor*final_noise_val
		
		var new_z = vertex.z
		
		mdt.set_vertex_uv(i, Vector2(uv_x, uv_y))
		mdt.set_vertex(i, vertex)
		
		mark_chunk_sides(i, vertex, chunk_offset)
		
		# on every nth vertex, roll to create a tree
		#if i % 75 == 0:
		#	roll_to_add_tree(tree_generator, vertex, i, mdt)
		
		#roll_to_add_rock(vertex)
		
		# Check for house spawn
		#if i == 1000:
		#	spawn_house(shack, vertex)
		
		uv_x += uv_inc
		if uv_x < 0:
			uv_x = 0.0
		
		if old_z != new_z:
			uv_y += uv_inc
			uv_x = 0.0
		
		old_z = new_z
	
	# add features
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
			#	add_large_rock(vertex)
				large_rock_counter = 0
		
		# on every nth vertex, roll to create a tree
		if i % 50 == 0:
			roll_to_add_tree(tree_generators, vertex, i, mdt)
		
		# TODO: rocks should be partial to terrain peaks. Meaning the highest y values on the mesh should have a higher concentration of rocks
		#roll_to_add_rock(vertex)
		
		# TODO: write a helper function to determine if the area around the selected vertex
		# is flat; if so, spawn the campfire
		if i == 32896:
			add_campfire(vertex)
		
		# Check for house spawn
		#if i == 125:
		#	spawn_house(shack, vertex)
	
	add_tree_to_scene(array_plane)
	pass

func mark_chunk_sides(i, vertex, chunk_offset):
	vertex.x += chunk_offset.x
	vertex.z += chunk_offset.y
	
	if i % plane_width == 0:
		self.north_side.push_back(vertex)
	if i >= 0 && i < plane_width:
		self.east_side.push_back(vertex)
	if (i + 1) % plane_width == 0:
		self.south_side.push_back(vertex)
	if i >= mdt.get_vertex_count() - plane_width && i < mdt.get_vertex_count():
		self.west_side.push_back(vertex)
	pass

func get_south_side():
	return south_side

func get_west_side():
	return west_side

func get_north_side():
	return north_side

func get_east_side():
	return east_side

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

func roll_to_add_tree(tree_generators, tree_location, vertex_index, mdt):
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
				if vertex_index + i*plane_width <= mdt.get_vertex_count() - 1:
					nearby_vertices.push_back(mdt.get_vertex(vertex_index + i*plane_width))
				if vertex_index - i*plane_width >= 0:
					nearby_vertices.push_back(mdt.get_vertex(vertex_index - i*plane_width))
			
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
		#meshInstance.global_transform.origin = Vector3(0, 0, 0)
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
