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
var plane_width = 256
var plane_depth = 256
var plane_divider = 16
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
var vertex_map = {}

var terrain_nodes = []
var terrain_nodes_map = {}
var generation_queue = []

func _ready():
	
	rng.randomize()
	var noise_seed = rng.randi()
	
	rng.randomize()
	
	plane_mesh = PlaneMesh.new()
	mdt = MeshDataTool.new()
	st = SurfaceTool.new()
	
	self.plane_node_size = plane_width/plane_divider
	
	noise = OpenSimplexNoise.new()
	noise.seed = noise_seed
	noise.octaves = noise_octaves
	noise.period = noise_period
	noise.persistence = noise_persistence
	
	self.plane_width = plane_width
	plane_mesh.subdivide_width = plane_width
	plane_mesh.subdivide_depth = plane_depth
	plane_mesh.size = Vector2(plane_mesh.subdivide_width, plane_mesh.subdivide_depth)
	
	st.create_from(plane_mesh, 0)
	# Returns a constructed ArrayMesh from current information passed in 
	array_plane = st.commit()
	mdt.create_from_surface(array_plane, 0)
	
	# TODO: loop through mdt, and create a mapping from x, z to i in the mdt.vertices array
	# TODO: use that data structure to create sections of the total grid
	#
	
	generate_terrain_nodes()
	pass

func generate_terrain_nodes():
	var i = 0
	var column_number = 1 # once this reaches plane_node_size - 1, increase by plane_node_size + plane_width*(plane_node_size - 2)
	while i < mdt.get_vertex_count():
		var row_number = 1
		self.vertex_map[i] = []
		var target = i
		while(true):
			# if we can add horizontal vertices, += 1 and add them 
			if (target + 1) % (self.plane_width - 1) != 0:
				target += 1
				column_number += 1
				self.vertex_map[i].push_back(target)
			# else if we can add vertical vertices, += i + row*plane_width 
			elif row_number + 1 < self.plane_node_size:
				target = i + row_number*self.plane_width
				row_number += 1
				self.vertex_map[i].push_back(target)
			# else, we create the terrain node and break
			else:
				break
			
		var node = TerrainNode.new(st, mdt, i, self.vertex_map[i], noise, array_plane, self.plane_width, self.plane_node_size, rng, self.height_factor, self.tree_likelihood, self.rock_likelihood)
		node.connect("player_entered", self, "_on_player_entered")
		#connect("generate_terrain", node, "_on_generate")
		terrain_nodes.push_back(node)
		
		if i == 0 || (self.plane_width - 2) % i == 0: # an edge
			i += 1 + (plane_node_size - 1)*self.plane_width
		else:
			i += plane_node_size
	
	#print(vertex_map)
	
	for j in range(self.terrain_nodes.size()):
		var node = self.terrain_nodes[j]
		add_child(node)
		terrain_nodes_map[node.name] = node
	pass

# TODO: create another signal handler to set mdt_is_locked = false
func _on_player_entered(terrain_node_name):
	print("terrain node added to generation queue")
	generation_queue.push_front(terrain_node_name)
	pass

func get_mdt():
	return self.mdt

func get_plane_mesh():
	return self.plane_mesh

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if generation_queue.size() > 0 && !mdt_is_locked:
		print("pulling node from generation queue; calling generate_terrain")
		var next_terrain_node = generation_queue.pop_back()
		if terrain_nodes_map.has(next_terrain_node.name):
			var node = terrain_nodes_map[next_terrain_node.name]
			node.draw_terrain()
			mdt_is_locked = true
	pass
