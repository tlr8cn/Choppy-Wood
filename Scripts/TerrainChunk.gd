extends Spatial

class_name TerrainChunk

var noise:OpenSimplexNoise
var rng:RandomNumberGenerator
var mdt:MeshDataTool
var st:SurfaceTool
var plane_mesh:PlaneMesh

var dirt_material:ShaderMaterial
var shack 
var rock1 
var tuft_options = []
var mushroom
var mushroom_man

var tree_likelihood
var grass_likelihood
var rock_likelihood
var height_factor

var array_plane

var plane_width

var tree_generators = []

var plane_node_size

# key: index with collision shape; value: array of indices in group
var vertex_map = {}

var terrain_nodes = []

# TODO: split a large plane into many chunks (which are connected)
# As the player progresses, a large area surrounding the player will intersect
# with colliders placed at certain vertices
# When the player area intersects with the collider, add that chunk to a queue on the TerrainOrchestrator
# Pull that chunk off the queue, and generate terrain for all vertices surrounding it
func _init(noise_seed, plane_width=64, plane_depth=64, plane_divider=16, height_factor=10, tree_likelihood=25, grass_likelihood=40, rock_likelihood=10, noise_octaves=8.0, noise_period=55.0, noise_persistence=0.125):
	rng = RandomNumberGenerator.new()
	rng.randomize()
	
	plane_mesh = PlaneMesh.new()
	mdt = MeshDataTool.new()
	st = SurfaceTool.new()
	
	self.height_factor = height_factor
	self.tree_likelihood = tree_likelihood
	self.rock_likelihood = rock_likelihood
	self.grass_likelihood = grass_likelihood
	self.plane_node_size = plane_width/plane_divider
	
	noise = OpenSimplexNoise.new()
	noise.seed = noise_seed
	# Number of OpenSimplex noise layers that are sampled to get the fractal noise. Higher values result in more detailed noise but take more time to generate.
	noise.octaves = noise_octaves
	# Period of the base octave. A lower period results in a higher-frequency noise (more value changes across the same distance).
	noise.period = noise_period
	# Contribution factor of the different octaves. A persistence value of 1 means all the octaves have the same contribution, a value of 0.5 means each octave contributes half as much as the previous one.
	noise.persistence = noise_persistence
	
	self.plane_width = plane_width
	plane_mesh.subdivide_width = plane_width
	plane_mesh.subdivide_depth = plane_depth
	plane_mesh.size = Vector2(plane_mesh.subdivide_width, plane_mesh.subdivide_depth)
	
	st.create_from(plane_mesh, 0)
	# Returns a constructed ArrayMesh from current information passed in 
	array_plane = st.commit()
	mdt.create_from_surface(array_plane, 0)
	
	# TODO: generate TerrainNodes at center of each section
	generate_terrain_nodes()
	
	for i in range(self.terrain_nodes.size()):
		var node = self.terrain_nodes[i]
		add_child(node)
	# TODO: only do this when player enters the area (move to TerrainNode)
	#draw_terrain(plane_width, plane_depth)
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
		terrain_nodes.push_back(node)
		
		if i == 0 || (self.plane_width - 2) % i == 0: # an edge
			i += 1 + (plane_node_size - 1)*self.plane_width
		else:
			i += plane_node_size
	
	print(vertex_map)
	pass

func get_mdt():
	return self.mdt

func get_plane_mesh():
	return self.plane_mesh
