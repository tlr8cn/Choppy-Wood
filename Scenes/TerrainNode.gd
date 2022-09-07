extends Area

class_name TerrainNode

signal player_entered

var noise:OpenSimplexNoise
var rng:RandomNumberGenerator
var st:SurfaceTool

var dirt_material:ShaderMaterial
var shack 
var rock1 
var tuft_options = []
var mushroom
var mushroom_man
var tree_generators = []

var height_factor

var plane_width
var plane_divider
var plane_subdivision_width

var mdt
var array_plane
var mdt_index
var group_indices

var tree_likelihood
var rock_likelihood

var was_generated = false

# TODO: I think, in addition to the mdt, we need a list of vertices that we can use to access this node
func _init(st, mdt, mdt_index, group_indices, noise, array_plane, plane_width, plane_divider, rng, height_factor, tree_likelihood, rock_likelihood):
	self.rng = rng
	self.height_factor = height_factor
	self.tree_likelihood = tree_likelihood
	self.rock_likelihood = rock_likelihood
	
	self.st = st
	self.mdt = mdt
	self.array_plane = array_plane
	self.noise = noise
	#self.mdt_vertices = mdt_vertices
	self.plane_width = plane_width
	self.plane_divider = plane_divider
	self.plane_subdivision_width = self.plane_width/self.plane_divider
	self.mdt_index = mdt_index
	self.group_indices = group_indices
	
	var grass_small = load("res://Scenes/GrassTuftSmall.tscn")
	var grass_large = load("res://Scenes/GrassTuftLarge.tscn")
	tuft_options = [grass_small, grass_large]
	
	var original_tree_generator = load("res://Scenes/NaturalTree.tscn")
	var magnolia_tree_generator = load("res://Scenes/NaturalTree_Magnolia.tscn")
	tree_generators = [original_tree_generator, magnolia_tree_generator]
	
	shack = load("res://Scenes/Shack.tscn")
	rock1 = load("res://Scenes/Rock1.tscn")
	dirt_material = load("res://Assets/Materials/dirt_material.tres")
	mushroom = load("res://Scenes/Mushroom.tscn")
	mushroom_man = load("res://Scenes/MushroomMan.tscn")

	var collision_shape = SphereShape.new()
	collision_shape.set_radius(2.0)
	
	# TODO: move the CollisionShape to the bottom corner vertex
	var vertex = mdt.get_vertex(mdt_index)
	self.transform.origin = vertex
	var collision = CollisionShape.new()
	collision.set_shape(collision_shape)

	add_child(collision)
	
	connect("body_entered", self, "callback")

func callback(body):
	var body_name = body.get_name()
	if body_name == "Player" && !was_generated:
		draw_terrain()
		was_generated = true

# Called when the node enters the scene tree for the first time.
#func _ready():
#	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func draw_terrain():
	var uv_x = 0.0
	var uv_y = 0.0
	var uv_inc = 1.0/8.0
	var old_z = self.mdt.get_vertex(self.mdt_index).z
	# uvs should run from 0, 1/64, 2/64, .., 1
	for i in range(self.group_indices.size()):
		var vertex = mdt.get_vertex(self.group_indices[i])
		var new_z = vertex.z
		var noise_val = noise.get_noise_2d(float(vertex.x), float(vertex.z))
		vertex.y = self.height_factor*noise_val
		
		#mdt.set_vertex_uv(i, Vector2(uv_x, uv_y))
		mdt.set_vertex(i, vertex)
		
		# on every nth vertex, roll to create a tree
		#if i % 75 == 0:
		#	roll_to_add_tree(tree_generator, vertex, i, mdt)
		
		# on every index, roll to create grass
		#roll_to_add_grass(vertex)
		
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
	for i in range(self.group_indices.size()):
		var vertex = mdt.get_vertex(self.group_indices[i])
		
		# on every nth vertex, roll to create a tree
		if i % 50 == 0:
			roll_to_add_tree(tree_generators, vertex, i, mdt)
		
		# on every index, roll to create grass
		#roll_to_add_grass(vertex)
		
		roll_to_add_rock(vertex)
		
		# Check for house spawn
		#if i == 1000:
		#	spawn_house(shack, vertex)
	
	add_tree_to_scene()
	pass

func roll_to_add_rock(rock_location):
	var roll = rng.randi_range(0, 2500)
	if roll <= self.rock_likelihood:
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

func roll_to_add_grass(grass_location):
	var roll = rng.randi_range(0, 100)
	if roll <= self.grass_likelihood:
		var index = rng.randi_range(0, 1)
		var instance = tuft_options[index].instance()
		var minor_offset_x = rng.randf_range(-0.125, 0.125)
		var minor_offset_z = rng.randf_range(-0.125, 0.125)
		var pos = Vector3(grass_location.x + minor_offset_x, grass_location.y, grass_location.z + minor_offset_z)
		instance.transform.origin = pos
		
		# Random, minor offsets in the x and z directions
		#var pos = Vector3(current_x + minor_offset_x, transform.origin.y + instance_y_offset, current_z + minor_offset_z)
		#instance.global_translate(pos)
		var random_rotation = rng.randf_range(0, 2*PI)
		instance.transform.basis = instance.transform.basis.rotated(Vector3(0, 1, 0), transform.basis.get_euler().y + random_rotation)
		instance.scale = Vector3(0.35, 0.35, 0.35)
		instance.visible = true
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

func add_tree_to_scene():
	for s in range(self.array_plane.get_surface_count()):
		self.array_plane.surface_remove(s)
		mdt.commit_to_surface(self.array_plane)
		st.create_from(self.array_plane, 0)
		st.generate_normals()

		var meshInstance = MeshInstance.new()
		meshInstance.set_mesh(st.commit())
		meshInstance.global_transform.origin = Vector3(0, 0, 0)
		
		meshInstance.material_override = dirt_material
		meshInstance.create_trimesh_collision()
		add_child(meshInstance)
	pass

func spawn_house(house, location):
	var new_house = house.instance()
	new_house.translate(Vector3(location.x, location.y + 0.1, location.z + 1.0))
	add_child(new_house)
	pass
