extends ImmediateGeometry

# Declare member variables here. Examples:
# var a = 2
# var b = "text"
export var height_inc = 0.5
export var radius_dec = 0.025
var radius_mod = 4 # amounts to the number of tree sections 
var id = 1
export var initial_radius = 0.5
# stores precalculated radii for n circles packed evenly within a unit circle
# array indexed by n_1(-1), ..., n_6(-1)
# values pulled from website dedicated to circle packing http://www.packomania.com/
var packing_radii = [1.0, 0.5, 0.464101615138, 0.414213562373, 0.370191908159, 0.333333333333]

var rng = RandomNumberGenerator.new()

export var skew_min = 0.01 # should be closer to zero
export var skew_max = 0.125 # should be further from zero
export var skew_widener = 0.0015

# limits the number of branch splits per tree
export var max_splits = 5
export var spread_amount = 0.125
export var initial_split_chance = 35

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

#onready var leaves_med = preload("res://Scenes/Leaf Bunch.tscn")
#nready var leaves_trunk = preload("res://Scenes/Trunk Leaves.tscn")
#onready var leaf = get_child(0)
onready var canopy = preload("res://Scenes/Canopy.tscn")
onready var canopy_material = preload("res://Assets/Materials/tree_material.tres")
onready var big_log = preload("res://Scenes/BigLog.tscn")

export var bark_material:SpatialMaterial

var initial_fell_rotation = 0.0
var fell_rotation_step = 0.0005
var is_falling = false
var never_fall_again = false
var fell_counter = 0.0

var leaf_collisions = []
var root = null
var tree_height=0.0

# Called when the node enters the scene tree for the firsst time.
func _ready():
	var Vertex = load("res://Scripts/Vertex.gd")
	rng.randomize()
	
	self.begin(Mesh.PRIMITIVE_TRIANGLES, null) # Add vertices in counter clockwise order
	var texture = load("res://Assets/Textures/bark.png")
	#var material = SpatialMaterial.new()
	#material.albedo_texture = texture
	#material.albedo_color = Color("#463A2E")
	self.set_material_override(bark_material)

	#var currentRadius = 1.0
	var currentHeight = 0
	var centerPointOuter = Vector3(0, 0, 0)
	var radiusCounter = 0 

	var numVertices = 6
	
	# center_point for root is the outer center point; parent is null
	root = TreeNode.new(1, centerPointOuter, initial_radius, null)
	var natural_tree = NaturalTree.new(root)
	
	# TODO: tree needs a name
	# TODO: tree needs a simple cylinder collider at the trunk
	
	buildTreeRecursively(root, natural_tree, 1, initial_radius, currentHeight, numVertices, centerPointOuter)
	
	# branches is a 2D array of nodes representing branches of the tree
	var branches = natural_tree.dfs_for_branches()
	
	var trunk = branches[0]
	var trunk_bottom = trunk[0].get_center_point()
	var trunk_top = trunk[trunk.size()-1].get_center_point()
	
	var collision_object = StaticBody.new()
	var shape = CylinderShape.new()
	shape.radius = initial_radius
	shape.height = trunk_top.y - trunk_bottom.y
	#collision_object.shape = shape
	collision_object.create_shape_owner(self)
	collision_object.set_ray_pickable(true)
	collision_object.set_name("Tree")
	
	var owners = collision_object.get_shape_owners()
	var this_owner = owners[0]
	collision_object.shape_owner_add_shape(this_owner, shape)
	add_child(collision_object)
	
	#var body = RigidBody.new()
	#body.add_child(TestCube.new())
	#var shape = CylinderShape.new()
	#shape.radius = initial_radius
	#shape.height = trunk_top.y - trunk_bottom.y
	#body.add_shape(shape)
	#body.set_translation(Vector3(0, shape.height/2.0, 0))
	#add_child(body)
	
	draw_tree(branches)
	
	draw_canopy(branches)
	
	self.end()
	pass # Replace with function body.

func _process(delta):
	self.fell_counter += delta
	
	if !never_fall_again:
		if is_falling:
			if transform.basis.get_euler().x >= self.initial_fell_rotation.get_euler().x + 85*(PI/180):
				self.is_falling = false
				self.never_fall_again = true
				
				var log_length = 5.5
				var length_counter = 0.0
				print(self.tree_height)
				while length_counter < self.tree_height:
					var big_log_instance = big_log.instance()
					big_log_instance.global_translate(Vector3(self.transform.origin.x, self.transform.origin.y + 0.35, self.transform.origin.z + length_counter + 2.75))
					big_log_instance.transform.basis = big_log_instance.transform.basis.rotated(Vector3(0, 1, 0), PI/2)
					get_parent().add_child(big_log_instance)
					length_counter += log_length
				queue_free()
				pass
			
			transform.basis = transform.basis.rotated(Vector3(1, 0, 0), self.fell_rotation_step)
			
			if self.fell_counter >= 0.6125:
				self.fell_rotation_step += 1.1*self.fell_rotation_step
				self.fell_counter = 0.0
	pass

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
func buildTreeRecursively(current_node, natural_tree, n, current_radius, current_height, num_vertices, center_point_outer, ring_counter=0, split_chance=initial_split_chance, branch_skew_x=0, branch_skew_z=0, split_counter=0, branch_spread_x=0.0, branch_spread_z=0.0):
	var new_ring_counter = ring_counter
	var new_split_counter = split_counter
	var new_height = current_height + height_inc
	var new_radius = current_radius
	var do_spawn_leaves = false
	
	var should_shrink_radius = ring_counter % radius_mod == 0
	if should_shrink_radius:
		new_radius = new_radius - radius_dec
	
	# base case
	# TODO (BUG): it seems like leaves don't have rings at the moment
	if current_radius <= 0.0 || new_radius <= 0.0:
		var new_tree_height = current_node.get_center_point().y - self.root.get_center_point().y
		if new_tree_height > self.tree_height:
			self.tree_height = new_tree_height
		
		current_node.set_is_leaf(true)
		natural_tree.add_leaf(current_node)
		
		var roll = rng.randi_range(0, 500)
		if roll <= 50:
			var canopy_location = current_node.get_first_ring_vertex()
			var instance1 = canopy.instance()
			instance1.global_translate(canopy_location)
			#add_child(instance1)
		return
	elif current_radius > 0.0 && current_radius <= 4*radius_dec:
		do_spawn_leaves = true

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
		
		current_ring = addVerticesToRing(current_ring, num_vertices, packed_center_point, packed_center_angle, center_point_outer, current_radius, do_spawn_leaves)
		
		new_ring_counter = new_ring_counter + 1
		var new_id = id
		id = id + 1
		
		var skew = calculateSkew(packed_center_angle)
		var new_skew_x = skew.x
		var new_skew_z = skew.y
		var new_node = TreeNode.new(new_id, packed_center_point, current_radius, current_node, packed_center_angle, branch_spread_x, branch_spread_z, new_skew_x, new_skew_z, current_ring)
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
			var roll = rng.randi_range(0, 625)
			# this percent chance of splitting will become more likely as we progress up the tree
			if roll < split_chance:
				# do a random split
				var spread = calculate_spread(child_angle)
				new_branch_spread = Vector2(new_branch_spread.x + spread.x, new_branch_spread.y + spread.y)
				new_n = rng.randi_range(2, 4)
				if new_n > 1:
					# TODO: Instead of splitting by the new_n evenly, we should randomly divide
					# TODO (BUG): this is hacky -- when new_n = 2, the branches are too big -- should try using packing radii
					#radius_copy = (radius_copy/new_n)*1.525
					radius_copy = radius_copy*packing_radii[new_n]*1.25
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
		
		buildTreeRecursively(child, natural_tree, new_n, radius_copy, new_height, num_vertices, new_center_point, ring_counter + 1, new_split_chance, branch_skew_x + new_skew_x, branch_skew_z + new_skew_z, new_split_counter, new_branch_spread.x, new_branch_spread.y)

func calculate_spread(packed_center_angle):
	var spread_x = 0.0
	var spread_z = 0.0
	
	var spread_min = 0.005
	
	if packed_center_angle >= 0 && packed_center_angle < PI/2: # +x, +z
		spread_x = rng.randf_range(spread_min, spread_amount)
		spread_z = rng.randf_range(spread_min, spread_amount/4)
	elif packed_center_angle >= PI/2 && packed_center_angle < PI: # -x, +z
		spread_x = rng.randf_range(-spread_amount, -spread_min)
		spread_z =  rng.randf_range(spread_min, spread_amount/4)
	elif packed_center_angle >= PI && packed_center_angle < 3*(PI/2): # -x, -z
		spread_x = rng.randf_range(-spread_amount, -spread_min)
		spread_z = rng.randf_range(-spread_amount, -spread_min)
	elif packed_center_angle >= 3*(PI/2) && packed_center_angle < 2*PI: # +x, -z
		spread_x = rng.randf_range(spread_min, spread_amount)
		spread_z = rng.randf_range(-spread_amount, -spread_min)
		
	return Vector2(spread_x, spread_z)

# addVerticesToRing adds all vertices to current ring
func addVerticesToRing(ring, num_vertices, packed_center_point, packed_center_angle, center_point_outer, radius, do_spawn_leaves):
	for j in range(num_vertices):
		var current_angle = (j*(360/num_vertices))*(PI/180)
		
		# spread and radius should be added to the node's packed_center point before we get here
		var ring_coord_a = Vector3(packed_center_point.x + radius*cos(current_angle), packed_center_point.y, packed_center_point.z + radius*sin(current_angle))
		var ring_normal_a = Vector3(ring_coord_a.x - packed_center_point.x, ring_coord_a.y - center_point_outer.y, ring_coord_a.z - packed_center_point.z)
		var ring_vertex_a = Vertex.new(ring_coord_a, ring_normal_a, current_angle, Vector3(packed_center_point.x, center_point_outer.y, packed_center_point.z))
		
		var ring_coord_b = Vector3(packed_center_point.x + ((radius+radius)/2)*cos(current_angle), packed_center_point.y + height_inc, packed_center_point.z + ((radius+radius)/2)*sin(current_angle))
		var ring_normal_b = Vector3(ring_coord_b.x - packed_center_point.x, ring_coord_b.y - center_point_outer.y, ring_coord_b.z - packed_center_point.z)
		var ring_vertex_b = Vertex.new(ring_coord_b, ring_normal_b, current_angle, Vector3(packed_center_point.x, center_point_outer.y + height_inc, packed_center_point.z))
		
		ring[0].append(ring_vertex_a)
		ring[1].append(ring_vertex_b)
		
		#var roll = rng.randi_range(0, 100)
		#if roll <= 35:
		#	continue
		
		#if radius <= initial_radius && radius >= initial_radius - initial_radius*0.90:
			
		#	var roll2 = rng.randi_range(0, 500)
		#	if roll2 <= 10:
		#		var instance1 = leaves_trunk.instance()
		#		instance1.global_translate(ring_coord_a)
				#var relative_normal = instance1.transform.origin + ring_normal_a
				#instance1.look_at(relative_normal, Vector3.UP)
				# TODO: rotate to orient with trunk normal
		#		add_child(instance1)
		
	return ring

func draw_tree(branches):
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

# TODO: as trees get taller, the width of the generated plane gets larger; this causes
# the texture at the top of the tree to be more stretched (larger) than what is closer to the bottom
# Maybe I can generate extra layers of triangles so i can keep the same size texture at the top of the trees
func draw_canopy(branches):
	#var vertices = input[0]
	#var normals = input[1]
	#var uvs = input[2]
	
	var ig = ImmediateGeometry.new()
	ig.begin(Mesh.PRIMITIVE_TRIANGLES, null) # Add vertices in counter clockwise order
	ig.set_material_override(canopy_material)
	var plane_height_increment = 0.0325
	
	var radius_threshold = 0.35
	var uv_horiz_separation = 0.1
	
	var initial_plane_height = 0.125
	
	for i in range(branches.size()):
		var branch = branches[i]
		var vertex_index = 0
		var plane_height = initial_plane_height
		# for each branch, we want to generate a spiral plane
		# each treenode ring has 2 sections (array)  
		var old_tv2 = Vector3()
		var old_rv2 = Vector3()
		var uv_horizontal = 0.0
		var uv_vertical_cap = 1.0
		for j in range(branch.size()):
			# first triangle
			var t1 = []
			# second triangle
			var t2 = []
			
			var node = branch[j]
			var ring = node.get_ring()
			var radius = node.get_radius()
			#if ring.size() < 2:
			#	print("wut") # TODO: figure out why sometimes 2 sections of the ring are not being generated
			if ring.size() > 1 && node.get_radius() <= radius_threshold:
				uv_vertical_cap = radius/radius_threshold 
				# TODO: need to connect the two rectangles
				# persist tv2 and rv2 from the last loop
				# this loop, once tv1 and rv1 are calculated, go ahead and connect
				var ring_lower = ring[0]
				var trunk_vertex_lower = ring_lower[vertex_index]
				var tv1 = trunk_vertex_lower.get_coord()
				vertex_index = vertex_index + 1
				if vertex_index > 5:
					vertex_index = 0
				
				var ring_upper = ring[1]
				var trunk_vertex_upper = ring_upper[vertex_index]
				var tv2 = trunk_vertex_upper.get_coord()
				vertex_index = vertex_index + 1
				if vertex_index > 5:
					vertex_index = 0
				
				var vertex_separation = tv1.distance_to(tv2)
				# TODO: signs should probably be calculated for both trunk vertices
				var signs_upper = get_xz_signs_from_angle(trunk_vertex_upper.get_angle())
				var x_sign_upper = signs_upper.x
				var z_sign_upper = signs_upper.y
				var signs_lower = get_xz_signs_from_angle(trunk_vertex_lower.get_angle())
				var x_sign_lower = signs_lower.x
				var z_sign_lower = signs_lower.y
				
				#var rando_plane_height = rng.randf_range(plane_height - plane_height*0.9, 1.25*plane_height)
				# rv = "raised vertex"
				var rv1 = Vector3(tv1.x + (x_sign_lower)*plane_height, tv1.y + vertex_separation/2, tv1.z + (z_sign_lower)*plane_height)
				var rv2 = Vector3(tv2.x + (x_sign_upper)*plane_height, tv2.y + vertex_separation/2, tv2.z + (z_sign_upper)*plane_height)
				
				# connect the last rectangle to this one if available
				if old_rv2 != Vector3() && old_tv2 != Vector3():
					var middle_t1 = [old_tv2, tv1, old_rv2]
					var uvs_mid1 = [Vector2(uv_horizontal - uv_horiz_separation, 0.0), Vector2(uv_horizontal, 0.0), Vector2(uv_horizontal - uv_horiz_separation, 1.0)]
					for k in middle_t1.size():
						ig.set_uv(uvs_mid1[k])
						ig.add_vertex(middle_t1[k])
						ig.set_normal(Vector3(x_sign_lower, 0.0, z_sign_lower))
					var middle_t2 = [old_rv2, tv1, rv1]
					var uvs_mid2 = [Vector2(uv_horizontal - uv_horiz_separation, 1.0), Vector2(uv_horizontal, 0.0), Vector2(uv_horizontal, 1.0)]
					for k in middle_t2.size():
						ig.set_uv(uvs_mid2[k])
						ig.add_vertex(middle_t2[k])
						ig.set_normal(Vector3(x_sign_upper, 0.0, z_sign_upper))
				
				
				t1 = [rv1, tv1, rv2]
				var uvs1 = [Vector2(uv_horizontal, 1.0), Vector2(uv_horizontal, 0.0), Vector2(uv_horizontal + uv_horiz_separation, 1.0)]
				t2 = [rv2, tv1, tv2]
				var uvs2 = [Vector2(uv_horizontal + uv_horiz_separation, 1.0), Vector2(uv_horizontal, 0.0), Vector2(uv_horizontal + uv_horiz_separation, 0.0)]
				
				for k in t1.size():
					ig.set_uv(uvs1[k])
					ig.add_vertex(t1[k])
					ig.set_normal(Vector3(x_sign_lower, 0.0, z_sign_lower))
				
				for k in t2.size():
					ig.set_uv(uvs2[k])
					ig.add_vertex(t2[k])
					ig.set_normal(Vector3(x_sign_upper, 0.0, z_sign_upper))
				
				old_rv2 = rv2
				old_tv2 = tv2
				plane_height = plane_height + plane_height_increment
				uv_horizontal = uv_horizontal + uv_horiz_separation
		
	ig.end()
	add_child(ig)

func get_xz_signs_from_angle(angle):
	var sign_x = 1
	var sign_z = 1
	
	if angle >= 0 && angle <= PI/2: # +x, +z
		sign_x = sign_x 
		sign_z = sign_z
	elif angle > PI/2 && angle <= PI: # -x, +z
		sign_x = -sign_x
		sign_z = sign_z
	elif angle > PI && angle <= (3*PI)/2: # -x, -z
		sign_x = -sign_x
		sign_z = -sign_z
	elif angle > (3*PI)/2 && angle <= 2*PI: # +x, -z
		sign_x = sign_x
		sign_z = -sign_z
	return Vector2(sign_x, sign_z)


func _on_chop(self_ref, split_dir):
	if self_ref == self:
		# WIP
		self.initial_fell_rotation = transform.basis
		self.is_falling = true
		#transform.basis = transform.basis.rotated(Vector3(1, 0, 0), transform.basis.get_euler().x + PI/2)
	return
