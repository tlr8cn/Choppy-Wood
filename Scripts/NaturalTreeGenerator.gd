extends ImmediateGeometry

# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var height_inc = 0.5
var radius_dec = 0.0275
var radius_mod = 4 # amounts to the number of tree sections 
var id = 1
# stores precalculated radii for n circles packed evenly within a unit circle
# array indexed by n_1(-1), ..., n_6(-1)
# values pulled from website dedicated to circle packing http://www.packomania.com/
var packing_radii = [1.0, 0.5, 0.464101615138, 0.414213562373, 0.370191908159, 0.333333333333]

var rng = RandomNumberGenerator.new()

var skew_min = 0.0075 # should be closer to zero
var skew_max = 0.115 # should be further from zero
var skew_widener = 0.00125

# limits the number of branch splits per tree
var max_splits = 5
var spread_amount = 0.125

#TODO: This can be compressed
enum TriType {
	NABLA_RIGHT,
	PRE_DELTA_LEFT,
	PRE_DELTA_RIGHT,
	DELTA_LEFT,
	DELTA_RIGHT,
	PRE_NABLA_LEFT,
	PRE_NABLA_RIGHT
	NABLA_LEFT,
}

# Called when the node enters the scene tree for the firsst time.
func _ready():
	var Vertex = load("res://Scripts/Vertex.gd")
	rng.randomize()
	
	self.begin(Mesh.PRIMITIVE_TRIANGLES, null) # Add vertices in counter clockwise order
	var texture = load("res://Assets/Textures/bark.png")
	var material = SpatialMaterial.new()
	material.albedo_texture = texture
	#material.albedo_color = Color("#463A2E")
	self.set_material_override(material)

	#var currentRadius = 1.0
	var currentHeight = 0
	var centerPointOuter = Vector3(0, 0, 0)
	var radiusCounter = 0 

	var numVertices = 6
	
	# center_point for root is the outer center point; parent is null
	var root = TreeNode.new(1, centerPointOuter, null)

	buildTreeRecursively(root, 1, 0.5, currentHeight, numVertices, centerPointOuter)
	
	var natural_tree = NaturalTree.new(root)
	# branches is a 2D array of nodes representing branches of the tree
	var branches = natural_tree.dfs_for_branches()
	
	drawTree(branches)
	
	self.end()
	pass # Replace with function body.

# TODO: change "current" to "parent"
# buildTreeRecursively is a recursive helper function used to build a tree to be drawn later
# @param current_node - the node we're building now
# @param n - the number of existing branches in the tree
# @param current_radius - the current radius of the branch you're on
# @param current_height - the height you're currently at
# @param num_vertices - the number of vertices per ring TODO: should decrease over time (less frequently than radius)
# @param ring_counter - keeps track of how many rings we've laid
# @param split_counter - keeps track of how many times we've split
# @param branch_spread - keeps track of the spread for the current branch (spread is added when vertices are created)
func buildTreeRecursively(current_node, n, current_radius, current_height, num_vertices, center_point_outer, ring_counter=0, split_chance=50, branch_skew_x=0, branch_skew_z=0, split_counter=0, branch_spread_x=0.0, branch_spread_z=0.0):
	var new_ring_counter = ring_counter
	var new_split_counter = split_counter
	var new_height = current_height + height_inc
	var new_radius = current_radius
	
	var should_shrink_radius = ring_counter % radius_mod == 0
	if should_shrink_radius:
		new_radius = new_radius - radius_dec
	
	# base case
	if current_radius <= 0.0 || new_radius <= 0.0:
		current_node.set_is_leaf(true)
		return

	# Create and add nodes using current parameter values
	for i in range(n):
		var current_ring = [] # array of vertices representing a ring of the tree
		current_ring.append([])
		current_ring.append([])
		
		var packed_center_angle = i*(360/n)*(PI/180)
		if packed_center_angle == 0 && current_node.get_packed_center_angle() > 0:
			packed_center_angle = current_node.get_packed_center_angle()
		
		var packed_center_x = current_radius*cos(packed_center_angle) + center_point_outer.x
		var packed_center_z = current_radius*sin(packed_center_angle) + center_point_outer.z
		var packed_center_point = Vector3(packed_center_x, center_point_outer.y, packed_center_z)
		if n == 1:
			packed_center_point = center_point_outer
		
		addVerticesToRing(current_ring, num_vertices, packed_center_point, packed_center_angle, center_point_outer, current_radius)
		
		new_ring_counter = new_ring_counter + 1
		var new_id = id
		id = id + 1
		
		var skew = calculateSkew(packed_center_angle)
		var new_skew_x = skew.x
		var new_skew_z = skew.y
		var new_node = TreeNode.new(new_id, packed_center_point, current_node, packed_center_angle, branch_spread_x, branch_spread_z, new_skew_x, new_skew_z, current_ring)
		current_node.append_child(new_node)
	
	# calculate new values before the recursive call on each of current_node's children
	var children = current_node.get_children()
	for i in range(children.size()):
		var child = children[i]
		var child_angle = child.get_packed_center_angle()
		# each child should have their own copy of radius so we don't modify the original with each loop
		var radius_copy = new_radius
		var new_n = 1
		var new_branch_spread = Vector2(child.get_branch_spread_x(), child.get_branch_spread_z())
		
		# only check for a split if we haven't exceeded the max
		if new_split_counter < max_splits:
			# roll to see if n splits
			var roll = rng.randi_range(0, 500)
			# this percent chance of splitting will become more likely as we progress up the tree
			if roll < split_chance:
				# do a random split
				var spread = calculate_spread(child_angle)
				new_branch_spread = Vector2(new_branch_spread.x + spread.x, new_branch_spread.y + spread.y)
				new_n = rng.randi_range(2, 4)
				if new_n > 1:
					# TODO: Instead of splitting by the new_n evenly, we should randomly divide
					radius_copy = (radius_copy/new_n)*1.75
				new_split_counter += new_n
		
		var new_split_chance = split_chance
		if radius_copy < current_radius: # if radius changed, widen the possible skew
			skew_max += skew_widener
			new_split_chance = new_split_chance + 1
		
		# set the next center point to be the center of this child (could be split, could not)
		var child_center_point = child.get_center_point()
		var new_center_point = Vector3(child_center_point.x, new_height, child_center_point.z)
		
		var new_skew_x = child.get_branch_skew_x()
		var new_skew_z = child.get_branch_skew_z()
		
		var new_chance = split_chance
		
		buildTreeRecursively(child, new_n, radius_copy, new_height, num_vertices, new_center_point, ring_counter + 1, new_split_chance, branch_skew_x + new_skew_x, branch_skew_z + new_skew_z, new_split_counter, new_branch_spread.x, new_branch_spread.y)

# TODO (BUG): spread is fucked up and causing trees to point diagonally -- seems like everything is getting the same spread signs
func calculate_spread(packed_center_angle):
	var spread_x = 0.0
	var spread_z = 0.0
	
	if packed_center_angle >= 0 && packed_center_angle < PI/2: # +x, +z
		spread_x = spread_amount
		spread_z = spread_amount/4
	elif packed_center_angle >= PI/2 && packed_center_angle < PI: # -x, +z
		spread_x = -spread_amount
		spread_z = spread_amount/4
	elif packed_center_angle >= PI && packed_center_angle < 3*(PI/2): # -x, -z
		spread_x = -spread_amount
		spread_z = -spread_amount
	elif packed_center_angle >= 3*(PI/2) && packed_center_angle < 2*PI: # +x, -z
		spread_x = spread_amount
		spread_z = -spread_amount
		
	return Vector2(spread_x, spread_z)

# addVerticesToRing adds all vertices to current ring
func addVerticesToRing(ring, num_vertices, packed_center_point, packed_center_angle, center_point_outer, radius):
	for j in range(num_vertices):
		var current_angle = (j*(360/num_vertices))*(PI/180)
		
		# TODO (BUG): I think the reason branches are grouping together is because we are not persisting he ring_coordinates which we add the offset to
		# spread and radius should be added to the node's packed_center point before we get here
		var ring_coord_a = Vector3(packed_center_point.x + radius*cos(current_angle), packed_center_point.y, packed_center_point.z + radius*sin(current_angle))
		var ring_normal_a = Vector3(ring_coord_a.x - packed_center_point.x, ring_coord_a.y - center_point_outer.y, ring_coord_a.z - packed_center_point.z)
		var ring_vertex_a = Vertex.new(ring_coord_a, ring_normal_a, current_angle, Vector3(packed_center_point.x, center_point_outer.y, packed_center_point.z))
		
		var ring_coord_b = Vector3(packed_center_point.x + ((radius+radius)/2)*cos(current_angle), packed_center_point.y + height_inc, packed_center_point.z + ((radius+radius)/2)*sin(current_angle))
		var ring_normal_b = Vector3(ring_coord_b.x - packed_center_point.x, ring_coord_b.y - center_point_outer.y, ring_coord_b.z - packed_center_point.z)
		var ring_vertex_b = Vertex.new(ring_coord_b, ring_normal_b, current_angle, Vector3(packed_center_point.x, center_point_outer.y + height_inc, packed_center_point.z))
		
		ring[0].append(ring_vertex_a)
		ring[1].append(ring_vertex_b)

func drawTree(branches):
	var sectionHeight = 2
	var sectionWidth = 2
	for i in range(branches.size()):
		for j in range(branches[i].size()):
			var this_uv_y = float(j%sectionHeight)/(sectionHeight)
			var next_uv_y = float((j+1)%sectionHeight)/(sectionHeight)
			if next_uv_y == 0.0:
				next_uv_y = 1.0
			
			var node = branches[i][j]
			var parent = node.get_parent()
			var ring = node.get_ring()
			if ring.size() != 2:
				continue
			
			var tri_type = TriType.NABLA_RIGHT
			for k in range(ring[0].size()):
				var this_uv_x = float(k%(sectionWidth+1))/sectionWidth
				var next_uv_x = float((k+1)%(sectionWidth+1))/sectionWidth
				#if this_uv_x == 1.0:
				#	continue
				
				var next_k = k + 1
				if k + 1 == ring[0].size():
					next_k = 0
				
				var v_a = ring[0][k]
				var v_b = ring[0][next_k]
				if parent != null:
					var p_ring = parent.get_ring()
					if p_ring.size() > 1:
						v_a = p_ring[1][k]
						v_b = p_ring[1][next_k]
				
				# Set UVs prior to drawing
				v_a.set_uv(Vector2(this_uv_x, this_uv_y))
				v_b.set_uv(Vector2(next_uv_x, this_uv_y))
				ring[1][k].set_uv(Vector2(this_uv_x, next_uv_y))
				ring[1][next_k].set_uv(Vector2(next_uv_x, next_uv_y))
				
				# Where we draw rectangles that look like |/|
				if tri_type == TriType.NABLA_RIGHT || tri_type == TriType.PRE_DELTA_RIGHT:
					# ring[0] is the bottom of the ring; ring[1] is the top
					drawTriangle([v_a, ring[1][next_k], ring[1][k]])
					drawTriangle([v_a, v_b, ring[1][next_k]])
					
				# Where we draw rectangles that look like |\|
				elif tri_type == TriType.DELTA_RIGHT || tri_type == TriType.PRE_NABLA_RIGHT:
					drawTriangle([v_a, ring[1][k], v_b])
					drawTriangle([ring[1][k], ring[1][next_k], v_b])
				
				if tri_type == TriType.DELTA_RIGHT:
					tri_type = TriType.PRE_NABLA_RIGHT
				elif tri_type == TriType.PRE_NABLA_RIGHT:
					tri_type = TriType.NABLA_RIGHT
				
			
		# restart drawing
		self.end()
		self.begin(Mesh.PRIMITIVE_TRIANGLES, null)

func drawTriangle(tArray): 
	for i in 3:
		var vertex = tArray[i]
		var coord = vertex.get_coord()
		var centerPoint = vertex.get_centerPoint()
		
		# UV x is the fraction of the total 360 rotation
		# UV y should be a fraction of the height the texture occupies
		var uv = vertex.get_uv() 
		self.set_uv(uv)
		self.add_vertex(Vector3(coord.x, coord.y, coord.z))
		self.set_normal(Vector3(coord.x - centerPoint.x, coord.y - centerPoint.y, coord.z - centerPoint.z)) # normals pointing out

func calculateSkew(angle):
	# sign of skew variables based on x,z quadrants
	var skew_x = 0
	var skew_z = 0
	if angle > 0 && angle <= PI/2: # +x, +z
		skew_x = rng.randf_range(-skew_min, skew_max)
		skew_z = rng.randf_range(-skew_min, skew_max)
	elif angle > PI/2 && angle <= PI: # -x, +z
		skew_x = rng.randf_range(-skew_max, skew_min)
		skew_z = rng.randf_range(-skew_min, skew_max)
	elif angle > PI && angle <= (3*PI)/2: # -x, -z
		skew_x = rng.randf_range(-skew_max, skew_min)
		skew_z = rng.randf_range(-skew_max, skew_min)
	elif angle > (3*PI)/2 && angle <= 2*PI: # +x, -z
		skew_x = rng.randf_range(-skew_min, skew_max)
		skew_z = rng.randf_range(-skew_max, skew_min)
	else: # 0
		skew_x = rng.randf_range(-skew_max/2, skew_max/2)
		skew_z = rng.randf_range(-skew_max/2, skew_max/2)
	
	return Vector2(skew_x, skew_z)
# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
