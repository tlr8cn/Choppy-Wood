extends Node

signal generate_terrain

# Declare member variables here. Examples:
# var a = 2
# var b = "text"
onready var rng = RandomNumberGenerator.new()
# TODO: might be able to delete this scene
#onready var chunk = load("res://Scenes/TerrainChunk.tscn")

# TODO: try one big plane where sections are recalcalated based on proximity?
#var num_chunks = 1
var plane_width = 100
var plane_depth = 100
var plane_divider = 10
#var chunk_size = 64
var plane_node_size

var chunk_grid = []


# TODO: the terrain orchestrator should store all variables that apply to the terrain as a whole
# The mdt, scenes, array_plane, plane size, map of index to group of indices, etc
#
# TerrainNode should store any variables specific to that chunk of land like...
# main vertex, biome information, was_generated, etc.
#
# Whenever the player enters a plane node's area, send a signal from that TerrainNode to the TerrainOrchestrator
# This will add the TerrainNode's section to a queue to be generated (maybe partially) on the next process step
#
# With the above, the TerrainChunk script should be dissolved into TerrainNode and TerrainOrchestrator

var noise:OpenSimplexNoise
# Number of OpenSimplex noise layers that are sampled to get the fractal noise. Higher values result in more detailed noise but take more time to generate.
var noise_octaves = 8.0
# Period of the base octave. A lower period results in a higher-frequency noise (more value changes across the same distance).
var noise_period = 55.0
# Contribution factor of the different octaves. A persistence value of 1 means all the octaves have the same contribution, a value of 0.5 means each octave contributes half as much as the previous one.
var noise_persistence = 0.125

var mdt:MeshDataTool
var mdt_is_locked = false
var st:SurfaceTool
var plane_mesh:PlaneMesh

var dirt_material:ShaderMaterial
var shack 
var rock1 
var tuft_options = []
var mushroom
var mushroom_man

var tree_likelihood = 25
var grass_likelihood = 40
var rock_likelihood = 10
var height_factor = 10

var array_plane

#var plane_width

var tree_generators = []

# key: index with collision shape; value: array of indices in group
var terrain_node_to_vertices = {}

var terrain_nodes = []
var terrain_nodes_map = {}
var generation_queue = []
var nodes_generated = {}

# a 2D array on top of the mdt.vertices flat array
# e.g. i_mapping[0][0] = 0, i_mapping[0][1] = self.plane_node_size
var i_mapping = []

func _ready():
	
	self.rng.randomize()
	var noise_seed = rng.randi()
	
	self.rng.randomize()
	
	self.plane_mesh = PlaneMesh.new()
	self.mdt = MeshDataTool.new()
	self.st = SurfaceTool.new()
	
	self.plane_node_size = plane_width/plane_divider
	
	self.noise = OpenSimplexNoise.new()
	self.noise.seed = noise_seed
	self.noise.octaves = noise_octaves
	self.noise.period = noise_period
	self.noise.persistence = noise_persistence
	
	self.plane_width = plane_width
	self.plane_mesh.subdivide_width = plane_width-2 # just don't question it
	self.plane_mesh.subdivide_depth = plane_depth-2
	#print(self.plane_mesh.subdivide_depth)
	#print(self.plane_mesh.subdivide_width)
	self.plane_mesh.size = Vector2(plane_mesh.subdivide_width, plane_mesh.subdivide_depth)
	
	self.st.create_from(plane_mesh, 0)
	# Returns a constructed ArrayMesh from current information passed in 
	self.array_plane = st.commit()
	# TODO (BUG?): I'm getting more vertices than expected; seems to correspond with
	# (where n = plane_width): n*n +
	self.mdt.create_from_surface(array_plane, 0)
	
	# TODO: loop through mdt, and create a mapping from x, z to i in the mdt.vertices array
	# TODO: use that data structure to create sections of the total grid
	var x = 0
	var z = 0
	for i in range(self.mdt.get_vertex_count()):
		if i < self.plane_width:
			self.i_mapping.push_back([])
		
		self.i_mapping[x].push_back(i)
		
		if i != 0 && (i + 1) % self.plane_width == 0:
			x = 0
			z += 1
		else:
			x += 1
	
	generate_terrain_nodes()
	pass

func generate_terrain_nodes():
	var x = 0
	var initial_x = 0
	var z = 0
	var initial_z = 0
	var i = 0
	var indices = []
	while i < mdt.get_vertex_count():
		if x >= self.plane_width || z >= self.plane_width:
			break
		
		i = i_mapping[x][z]
		indices.push_back(i)
		
		if (z+1) >= initial_z + self.plane_node_size:
			z = initial_z
			
			if (x+1) >= initial_x + self.plane_node_size:
				var node = TerrainNode.new(st, mdt, i, indices, noise, array_plane, self.plane_width, self.plane_node_size, rng, self.height_factor, self.tree_likelihood, self.rock_likelihood)
				node.connect("player_entered", self, "_on_player_entered")
				node.connect("terrain_generated", self, "_on_terrain_generated")
				#connect("generate_terrain", node, "_on_generate")
				terrain_nodes.push_back(node)
				indices = []
			
			if x == i_mapping.size() - 1:
				initial_z += self.plane_node_size
				x = 0
			else:
				x += 1
		else:
			z += 1
	
	#print(vertex_map)
	
	for j in range(self.terrain_nodes.size()):
		var node = self.terrain_nodes[j]
		add_child(node)
		terrain_nodes_map[node.name] = node
	pass

# TODO: create another signal handler to set mdt_is_locked = false
func _on_player_entered(terrain_node_name):
	if !self.nodes_generated.has(terrain_node_name):
		self.generation_queue.push_front(terrain_node_name)
	pass

func get_mdt():
	return self.mdt

func get_plane_mesh():
	return self.plane_mesh

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if generation_queue.size() > 0 && !self.mdt_is_locked:
		var next_terrain_node = generation_queue.pop_back()
		if terrain_nodes_map.has(next_terrain_node.name):
			var node = terrain_nodes_map[next_terrain_node.name]
			self.mdt_is_locked = true
			self.nodes_generated[next_terrain_node.name] = true
			node.draw_terrain()
	pass

func _on_terrain_generated(vertex_mapping):
	for key in vertex_mapping.keys():
		var vertex = vertex_mapping[key]
		mdt.set_vertex(key, vertex)
	
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
	
	self.mdt_is_locked = false
	pass

# TODO: we want to loop through the vertices by x and z, and use those values to get an i
func get_i_mapping(x, z):
	return self.i_mapping[x][z]
