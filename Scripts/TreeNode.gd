extends Node

class_name TreeNode

# id will be used to uniquely identify a node in the tree
# For now, the tree is unsorted so searching isn't optimized
var id
# parent is a TreeNode
var parent
# children is an array of TreeNodes
var children

# center_point is the center point of this section of the ring
var center_point
# ring is an array of Vertex objects representing a full loop around a section of the tree
# the first element is connected to the last
var ring
# visited is for traversal of the tree used to determine if this node has been visited
var visited
# isLeaf quickly tells us whether or not this node is a leaf
var is_leaf
# the x offset on this particular branch from its parent
var branch_skew_x
# the z offset on this particular branch from its parent
var branch_skew_z
# the x offset on this particular branch from its parent
var branch_spread_x
# the z offset on this particular branch from its parent
var branch_spread_z

var packed_center_angle

var radius

func _init(id, center_point, radius, parent, packed_center_angle=0.0, branch_spread_x=0, branch_spread_z=0, branch_skew_x=0, branch_skew_z=0, ring=[], children=[]):
	self.id = id
	self.ring = ring
#	if ring.size() < 2:
#		print("ID: ")
#		print(self.id)
#		print(self.ring)
#		print(radius)
	self.parent = parent
	self.children = children.duplicate() #copy(children)
	self.visited = false
	self.is_leaf = false
	self.branch_spread_x = branch_spread_x
	self.branch_spread_z = branch_spread_z
	self.branch_skew_x = branch_skew_x
	self.branch_skew_z = branch_skew_z
	# + branch_spread_x
	#  + branch_spread_z
	self.center_point = Vector3(center_point.x + branch_skew_x + branch_spread_x, center_point.y, center_point.z + branch_skew_z + branch_spread_z)
	self.packed_center_angle = packed_center_angle
	self.radius = radius
	pass

func get_id():
	return self.id

func get_center_point():
	return self.center_point

func get_ring():
	return self.ring

func get_children():
	return self.children

func get_parent():
	return self.parent

func set_visited(visited):
	self.visited = visited
	pass

func get_visited():
	return self.visited

func append_child(child):
	self.children.append(child)
	child.parent = self
	pass

func set_is_leaf(is_leaf):
	self.is_leaf = is_leaf

func is_leaf():
	#print("set to leaf: ")
	#print(self.get_id())
	return self.is_leaf

func get_branch_skew_x():
	return self.branch_skew_x

func get_branch_skew_z():
	return self.branch_skew_z

func get_branch_spread_x():
	return self.branch_spread_x

func get_branch_spread_z():
	return self.branch_spread_z

func get_packed_center_angle():
	return self.packed_center_angle

func get_first_ring_vertex():
	return self.ring[0][0].get_coord()

func get_radius():
	return self.radius


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
